import 'dart:async';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import 'bike_lock_mqtt_config.dart';
import 'bike_lock_service.dart';
import 'models/bike_lock_models.dart';

/// Creates the platform service used by the Rides screen Unlock section.
BikeLockService createBikeLockService() => MqttBikeLockService();

// The parameter must be declared as `Object`: mqtt_client casts this hook to
// `bool Function(Object)` internally, and a `bool Function(X509Certificate)`
// literal is not a subtype of it, which would throw while connecting.
bool acceptBrokerCertificate(Object certificate) => true;

/// MQTT over TLS implementation talking to the EMQX Cloud broker.
///
/// Subscribes to [BikeLockMqttConfig.statusTopic] for live lock state and
/// publishes `LOCK` / `UNLOCK` on [BikeLockMqttConfig.commandTopic]. The
/// underlying client owns automatic reconnection; this service only mirrors
/// the connection lifecycle onto [connectionStatus].
class MqttBikeLockService implements BikeLockService {
  final StreamController<BikeConnectionStatus> _connection =
      StreamController<BikeConnectionStatus>.broadcast();
  final StreamController<BikeLockUpdate> _updates =
      StreamController<BikeLockUpdate>.broadcast();

  MqttServerClient? _client;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _messages;
  Future<void>? _connecting;
  bool _disposed = false;
  BikeConnectionStatus _status = BikeConnectionStatus.idle;
  BikeLockStatus _lock = BikeLockStatus.unknown;

  /// Session identifier used by the app.
  ///
  /// Deliberately not [BikeLockMqttConfig.deviceClientId]: EMQX reads a
  /// duplicate identifier as a session takeover and would disconnect the
  /// ESP32 (or this app) every time the other one connects. The timestamp also
  /// keeps several phones controlling the same bike apart.
  static String appClientId() =>
      '${BikeLockMqttConfig.clientIdPrefix}'
      '-${DateTime.now().microsecondsSinceEpoch}';

  @override
  Stream<BikeConnectionStatus> get connectionStatus => _connection.stream;

  @override
  Stream<BikeLockUpdate> get lockUpdates => _updates.stream;

  @override
  BikeConnectionStatus get currentConnectionStatus => _status;

  @override
  BikeLockStatus get currentLockStatus => _lock;

  @override
  Future<void> connect() {
    if (_disposed) return Future.value();
    if (_status == BikeConnectionStatus.connected) return Future.value();
    final pending = _connecting;
    if (pending != null) return pending;

    if (!BikeLockMqttConfig.isConfigured) {
      return Future.error(
        const BikeLockServiceException(
          'EMQX broker host is not configured. Fill in brokerHost in '
          'bike_lock_mqtt_config.dart or pass --dart-define=MQTT_BROKER_HOST.',
        ),
      );
    }

    final operation = _connect();
    _connecting = operation;
    return operation.whenComplete(() => _connecting = null);
  }

  Future<void> _connect() async {
    _emit(BikeConnectionStatus.connecting);
    final client = MqttServerClient.withPort(
      BikeLockMqttConfig.brokerHost,
      appClientId(),
      BikeLockMqttConfig.brokerPort,
    );
    client
      ..secure = true
      ..keepAlivePeriod = BikeLockMqttConfig.keepAliveSeconds
      ..autoReconnect = true;
    client.logging(on: false);
    // EMQX Cloud presents a CA signed certificate; the hook only keeps
    // private or self-signed deployment chains reachable.
    client.onBadCertificate = acceptBrokerCertificate;
    client
      ..onConnected = _afterReconnect
      ..onAutoReconnected = _afterReconnect
      ..onDisconnected = () {
        if (!_disposed && _status != BikeConnectionStatus.disconnected) {
          // The client keeps retrying on its own, the UI just shows it.
          _emit(BikeConnectionStatus.reconnecting);
        }
      };

    _client = client;
    try {
      final status = await client.connect(
        BikeLockMqttConfig.username,
        BikeLockMqttConfig.password,
      );
      if (status?.state != MqttConnectionState.connected) {
        final rejected = _isAuthFailure(status?.returnCode);
        _emit(BikeConnectionStatus.disconnected);
        throw BikeLockServiceException(
          rejected
              ? 'The broker rejected the GreenBici credentials'
              : 'Unable to reach the EMQX broker',
          detail: 'return code ${status?.returnCode}',
        );
      }
      _attach(client);
      _emit(BikeConnectionStatus.connected);
    } on BikeLockServiceException {
      _teardownClient();
      rethrow;
    } catch (error) {
      // The first attempt failed, so no background retry is running yet. The
      // panel offers an explicit Connect retry from the Disconnected state.
      _teardownClient();
      _emit(BikeConnectionStatus.disconnected);
      throw BikeLockServiceException(
        'Unable to reach the EMQX broker',
        detail: '$error',
      );
    }
  }

  @override
  Future<void> unlock() => _publish(BikeLockMqttConfig.unlockCommand);

  @override
  Future<void> lock() => _publish(BikeLockMqttConfig.lockCommand);

  Future<void> _publish(String command) async {
    final client = _client;
    if (_disposed || client == null) {
      throw const BikeLockServiceException(
        'The bike lock session has been closed.',
      );
    }
    if (client.connectionStatus?.state != MqttConnectionState.connected) {
      throw const BikeLockServiceException(
        'The broker link is not active, so the command was not sent.',
      );
    }
    try {
      client.publishMessage(
        BikeLockMqttConfig.commandTopic,
        MqttQos.atLeastOnce,
        AsciiPayloadConverter().convertToBytes(command),
      );
      // Mirrors the command at once; the ESP32 status message confirms it.
      _applyLock(
        command == BikeLockMqttConfig.unlockCommand
            ? BikeLockStatus.unlocked
            : BikeLockStatus.locked,
        command,
      );
    } catch (error) {
      throw BikeLockServiceException(
        'Could not deliver the $command command',
        detail: '$error',
      );
    }
  }

  @override
  Future<void> disconnect() async {
    _teardownClient();
    _emit(BikeConnectionStatus.disconnected);
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _teardownClient();
    unawaited(_connection.close());
    unawaited(_updates.close());
  }

  /// Auto reconnect restores subscriptions but recreates the update stream, so
  /// the message listener is always re attached after a (re)connection.
  void _afterReconnect() {
    final client = _client;
    if (_disposed || client == null) return;
    _attach(client);
    _emit(BikeConnectionStatus.connected);
  }

  void _attach(MqttServerClient client) {
    try {
      client.subscribe(BikeLockMqttConfig.statusTopic, MqttQos.atLeastOnce);
    } catch (_) {
      // Retried by the next reconnect cycle.
    }
    unawaited(_messages?.cancel());
    final stream = client.updates;
    if (stream == null) return;
    _messages = stream.listen(
      (batch) {
        for (final received in batch) {
          if (received.topic != BikeLockMqttConfig.statusTopic) continue;
          final payload = received.payload;
          if (payload is! MqttPublishMessage) continue;
          final text = MqttPublishPayload.bytesToStringAsString(
            payload.payload.message,
          );
          _applyLock(parseBikeLockPayload(text), text);
        }
      },
      onError: (Object _) {
        _emit(BikeConnectionStatus.reconnecting);
      },
    );
  }

  void _applyLock(BikeLockStatus status, String raw) {
    if (_disposed) return;
    _lock = status;
    _updates.add(BikeLockUpdate(status: status, raw: raw, at: DateTime.now()));
  }

  void _teardownClient() {
    final client = _client;
    _client = null;
    final messages = _messages;
    _messages = null;
    unawaited(messages?.cancel());
    if (client == null) return;
    try {
      client.disconnect();
    } catch (_) {
      // Already dropped by the broker, nothing left to close.
    }
  }

  void _emit(BikeConnectionStatus status) {
    if (_disposed || _status == status) return;
    _status = status;
    _connection.add(status);
  }

  bool _isAuthFailure(Object? code) {
    final name = '$code';
    return name.contains('badUsernameOrPassword') ||
        name.contains('notAuthorized') ||
        name.contains('badAuthenticationMethod');
  }
}
