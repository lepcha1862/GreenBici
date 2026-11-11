import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenbici/ride/mqtt/bike_lock_mqtt_config.dart';
import 'package:greenbici/ride/mqtt/bike_lock_service.dart';
import 'package:greenbici/ride/mqtt/models/bike_lock_models.dart';
import 'package:greenbici/ride/mqtt/mqtt_bike_lock_service.dart';
import 'package:greenbici/ride/mqtt/smart_bike_lock_card.dart';
import 'package:greenbici/ride/ride_page.dart';
import 'package:greenbici/theme/app_style.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

void main() {
  testWidgets('Shows the lock state reported by the bike', (tester) async {
    final service = _FakeBikeLockService();
    await _pumpCard(tester, service);

    expect(find.text('Locked'), findsOneWidget);
    expect(find.text('Connected · TLS 8883'), findsOneWidget);

    service.emitLock(BikeLockStatus.unlocked);
    await tester.pumpAndSettle();
    expect(find.text('Unlocked · ESP32 relocks automatically'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Unlock publishes the UNLOCK command and counts down to relock', (
    tester,
  ) async {
    final service = _FakeBikeLockService();
    await _pumpCard(tester, service);

    await tester.tap(find.byKey(const ValueKey('smart-lock-unlock')));
    await tester.pumpAndSettle();

    expect(service.published, ['UNLOCK']);
    expect(find.text('Auto-relocks in 15 s'), findsOneWidget);

    for (var second = 0; second < 15; second++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pumpAndSettle();

    // The ESP32 relocks on its own, so the panel falls back to Locked.
    expect(find.text('Locked'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Lock publishes the LOCK command', (tester) async {
    final service = _FakeBikeLockService();
    await _pumpCard(tester, service);

    await tester.tap(find.byKey(const ValueKey('smart-lock-lock')));
    await tester.pumpAndSettle();

    expect(service.published, ['LOCK']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Connect errors stay visible without breaking the section', (
    tester,
  ) async {
    final service = _FakeBikeLockService()
      ..currentConnectionStatus = BikeConnectionStatus.idle
      ..connectError = const BikeLockServiceException(
        'The broker rejected the GreenBici credentials',
        detail: 'return code badUsernameOrPassword',
      );
    await _pumpCard(tester, service);

    expect(find.text('Broker session idle'), findsOneWidget);

    service.connectionSink.add(BikeConnectionStatus.disconnected);
    await tester.pumpAndSettle();
    expect(find.text('Disconnected'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('smart-lock-unlock')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('The broker rejected the GreenBici credentials'),
      findsOneWidget,
    );
    expect(service.published, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('A dropped link offers a retry while the client reconnects', (
    tester,
  ) async {
    final service = _FakeBikeLockService();
    await _pumpCard(tester, service);

    service.connectionSink.add(BikeConnectionStatus.reconnecting);
    await tester.pumpAndSettle();

    expect(find.text('Reconnecting to EMQX…'), findsOneWidget);
    expect(find.text('Retry now'), findsOneWidget);

    service.connectionSink.add(BikeConnectionStatus.connected);
    await tester.pumpAndSettle();
    expect(find.text('Disconnect'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Actions stay reachable on a narrow screen with large text', (
    tester,
  ) async {
    final service = _FakeBikeLockService();
    await _pumpCard(tester, service, size: const Size(320, 640), textScale: 3);

    for (final key in [
      'smart-lock-unlock',
      'smart-lock-lock',
      'smart-lock-disconnect',
    ]) {
      final action = find.byKey(ValueKey(key));
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      expect(action.hitTestable(), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('The Ride screen sample bikes keep their own unlock flow', (
    tester,
  ) async {
    await _pumpRidePage(tester);

    expect(find.byKey(const ValueKey('smart-bike-lock-card')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('unlock-GB-204')));
    await tester.pumpAndSettle();
    expect(find.text('Unlock unavailable'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('The certificate hook keeps the signature mqtt_client casts it to', () {
    // The package does `onBadCertificate as bool Function(Object)?`, so a
    // X509Certificate typed literal throws a type cast while connecting.
    final client = MqttServerClient.withPort(
      'broker.test',
      'greenbici-test',
      8883,
    )..onBadCertificate = acceptBrokerCertificate;

    // Mirrors the cast the package performs inside connect().
    final hook = client.onBadCertificate as bool Function(Object)?;
    expect(hook, isNotNull);
    expect(hook!(Object()), isTrue);
  });

  test('The app never takes the ESP32 session identifier', () async {
    const deviceId = BikeLockMqttConfig.deviceClientId;
    final first = MqttBikeLockService.appClientId();
    await Future<void>.delayed(const Duration(milliseconds: 2));
    final second = MqttBikeLockService.appClientId();

    expect(first, isNot(deviceId));
    expect(first, startsWith('${BikeLockMqttConfig.clientIdPrefix}-'));
    // A duplicate identifier would make EMQX drop the other client's session.
    expect(second, isNot(first));
  });

  test('Payload parsing understands words and JSON from the ESP32', () {
    expect(parseBikeLockPayload('LOCKED'), BikeLockStatus.locked);
    expect(parseBikeLockPayload('LOCK'), BikeLockStatus.locked);
    expect(parseBikeLockPayload('UNLOCK'), BikeLockStatus.unlocked);
    expect(parseBikeLockPayload('unlocked'), BikeLockStatus.unlocked);
    expect(parseBikeLockPayload('1'), BikeLockStatus.locked);
    expect(parseBikeLockPayload('0'), BikeLockStatus.unlocked);
    expect(
      parseBikeLockPayload('{"lock":"UNLOCKED"}'),
      BikeLockStatus.unlocked,
    );
    expect(parseBikeLockPayload('{"status":1}'), BikeLockStatus.locked);
    expect(parseBikeLockPayload('garbage'), BikeLockStatus.unknown);
  });
}

Future<void> _pumpCard(
  WidgetTester tester,
  _FakeBikeLockService service, {
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  addTearDown(service.closeSinks);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppStyle.theme,
      home: Scaffold(
        body: SingleChildScrollView(child: SmartBikeLockCard(service: service)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpRidePage(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppStyle.theme,
      home: const Scaffold(body: RidePage()),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeBikeLockService implements BikeLockService {
  final StreamController<BikeConnectionStatus> connectionSink =
      StreamController<BikeConnectionStatus>.broadcast();
  final StreamController<BikeLockUpdate> lockSink =
      StreamController<BikeLockUpdate>.broadcast();
  final List<String> published = [];

  BikeLockServiceException? connectError;

  @override
  BikeConnectionStatus currentConnectionStatus = BikeConnectionStatus.connected;

  @override
  BikeLockStatus currentLockStatus = BikeLockStatus.locked;

  @override
  Stream<BikeConnectionStatus> get connectionStatus => connectionSink.stream;

  @override
  Stream<BikeLockUpdate> get lockUpdates => lockSink.stream;

  @override
  Future<void> connect() async {
    final error = connectError;
    if (error != null) throw error;
    currentConnectionStatus = BikeConnectionStatus.connected;
    connectionSink.add(currentConnectionStatus);
  }

  @override
  Future<void> unlock() => _publish(BikeLockStatus.unlocked, 'UNLOCK');

  @override
  Future<void> lock() => _publish(BikeLockStatus.locked, 'LOCK');

  @override
  Future<void> disconnect() async {
    currentConnectionStatus = BikeConnectionStatus.disconnected;
    connectionSink.add(currentConnectionStatus);
  }

  @override
  void dispose() {}

  void closeSinks() {
    unawaited(connectionSink.close());
    unawaited(lockSink.close());
  }

  void emitLock(BikeLockStatus status) {
    currentLockStatus = status;
    lockSink.add(BikeLockUpdate(status: status, raw: status.name));
  }

  Future<void> _publish(BikeLockStatus status, String command) async {
    if (connectError != null) throw connectError!;
    published.add(command);
    emitLock(status);
  }
}
