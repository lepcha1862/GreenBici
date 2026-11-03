import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_card.dart';
import '../../theme/app_style.dart';
import 'bike_lock_mqtt_config.dart';
import 'bike_lock_service.dart';
import 'bike_lock_service_factory.dart';
import 'models/bike_lock_models.dart';

/// MQTT powered smart lock panel for the Unlock section of the Rides screen.
///
/// Connects to the EMQX Cloud broker over TLS, renders the live lock state
/// received on `ebike/lock01/status` and publishes `UNLOCK` / `LOCK` on
/// `ebike/lock01/cmd`. Standalone: it owns its service and never touches the
/// surrounding inventory layout.
class SmartBikeLockCard extends StatefulWidget {
  const SmartBikeLockCard({super.key, this.service, this.autoConnect = true});

  /// Injected in tests; created and owned by the card in the app.
  final BikeLockService? service;

  /// Opens the broker session as soon as the section becomes visible.
  final bool autoConnect;

  @override
  State<SmartBikeLockCard> createState() => _SmartBikeLockCardState();
}

class _SmartBikeLockCardState extends State<SmartBikeLockCard> {
  late final BikeLockService _service =
      widget.service ?? createBikeLockService();

  StreamSubscription<BikeConnectionStatus>? _connectionSub;
  StreamSubscription<BikeLockUpdate>? _lockSub;
  Timer? _relockTimer;

  BikeConnectionStatus _connection = BikeConnectionStatus.idle;
  BikeLockStatus _lock = BikeLockStatus.unknown;
  String? _message;
  bool _busy = false;
  int _relockIn = 0;

  @override
  void initState() {
    super.initState();
    _connection = _service.currentConnectionStatus;
    _lock = _service.currentLockStatus;
    _connectionSub = _service.connectionStatus.listen(_onConnection);
    _lockSub = _service.lockUpdates.listen(_onLockUpdate);
    if (widget.autoConnect && BikeLockMqttConfig.isConfigured) {
      unawaited(_connect(silent: true));
    }
  }

  @override
  void dispose() {
    _relockTimer?.cancel();
    _connectionSub?.cancel();
    _lockSub?.cancel();
    if (widget.service == null) _service.dispose();
    super.dispose();
  }

  void _onConnection(BikeConnectionStatus status) {
    if (!mounted) return;
    setState(() {
      _connection = status;
      if (status != BikeConnectionStatus.connected) _busy = false;
    });
  }

  void _onLockUpdate(BikeLockUpdate update) {
    if (!mounted) return;
    setState(() {
      _lock = update.status;
      // A report from the bike replaces the local countdown.
      if (update.status != BikeLockStatus.unlocked) {
        _relockTimer?.cancel();
        _relockIn = 0;
      }
    });
  }

  Future<void> _connect({bool silent = false}) async {
    if (!silent) setState(() => _busy = true);
    try {
      await _service.connect();
      if (!mounted) return;
      setState(() {
        _message = null;
        _busy = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = _describe(error);
      });
    }
  }

  Future<void> _send(String command) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      if (_connection != BikeConnectionStatus.connected) {
        await _service.connect();
      }
      if (command == BikeLockMqttConfig.unlockCommand) {
        await _service.unlock();
        _startRelockCountdown();
      } else {
        await _service.lock();
      }
    } catch (error) {
      if (mounted) setState(() => _message = _describe(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// The ESP32 relocks on its own, the countdown only mirrors it locally until
  /// the next status message lands.
  void _startRelockCountdown() {
    _relockTimer?.cancel();
    setState(() => _relockIn = BikeLockMqttConfig.autoRelockSeconds);
    _relockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || timer.tick >= BikeLockMqttConfig.autoRelockSeconds) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _relockIn = 0;
            _lock = BikeLockStatus.locked;
          });
        }
        return;
      }
      setState(
        () => _relockIn = BikeLockMqttConfig.autoRelockSeconds - timer.tick,
      );
    });
  }

  Future<void> _disconnect() async {
    _relockTimer?.cancel();
    setState(() => _busy = true);
    await _service.disconnect();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = null;
    });
  }

  String _describe(Object error) => error is BikeLockServiceException
      ? (error.detail == null
            ? error.message
            : '${error.message} · ${error.detail}')
      : 'Unexpected error: $error';

  @override
  Widget build(BuildContext context) {
    final lock = _lockVisuals(_lock);
    final connection = _connectionVisuals(_connection);
    final stacked = MediaQuery.textScalerOf(context).scale(14) > 21;

    return AppCard(
      key: const ValueKey('smart-bike-lock-card'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const ExcludeSemantics(
                child: CircleAvatar(
                  radius: 25,
                  backgroundColor: AppStyle.paleGreen,
                  child: Icon(
                    Icons.gpp_maybe_rounded,
                    size: 31,
                    color: AppStyle.green,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Bike Lock · ${BikeLockMqttConfig.statusTopic}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Icon(Icons.circle, size: 7, color: connection.color),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            connection.label,
                            style: const TextStyle(
                              color: AppStyle.muted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(lock.icon, size: 22, color: lock.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _lockLabel(_lock),
                  style: TextStyle(
                    color: lock.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          if (_relockIn > 0) ...[
            const SizedBox(height: 6),
            Text(
              'Auto-relocks in $_relockIn s',
              style: const TextStyle(color: AppStyle.muted, fontSize: 13),
            ),
          ],
          if (_message != null) ...[
            const SizedBox(height: 10),
            _MessageBanner(message: _message!),
          ],
          const SizedBox(height: 16),
          if (stacked)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _actions(),
            )
          else
            Wrap(spacing: 12, runSpacing: 12, children: _actions()),
        ],
      ),
    );
  }

  String _lockLabel(BikeLockStatus status) => switch (status) {
    BikeLockStatus.locked => 'Locked',
    BikeLockStatus.unlocked => 'Unlocked · ESP32 relocks automatically',
    BikeLockStatus.unknown => 'Status unknown',
  };

  List<Widget> _actions() {
    final connected = _connection == BikeConnectionStatus.connected;
    final unlock = FilledButton.icon(
      key: const ValueKey('smart-lock-unlock'),
      onPressed: _busy ? null : () => _send(BikeLockMqttConfig.unlockCommand),
      style: FilledButton.styleFrom(
        backgroundColor: AppStyle.darkGreen,
        foregroundColor: Colors.white,
        minimumSize: const Size(100, 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: const Icon(Icons.lock_open_rounded, size: 18),
      label: const Text('Unlock', semanticsLabel: 'Unlock smart bike lock'),
    );
    final lock = OutlinedButton.icon(
      key: const ValueKey('smart-lock-lock'),
      onPressed: _busy ? null : () => _send(BikeLockMqttConfig.lockCommand),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppStyle.darkGreen,
        minimumSize: const Size(100, 48),
        side: const BorderSide(color: AppStyle.border, width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: const Icon(Icons.lock_rounded, size: 18),
      label: const Text('Lock', semanticsLabel: 'Lock smart bike lock'),
    );
    final session = connected
        ? TextButton(
            key: const ValueKey('smart-lock-disconnect'),
            onPressed: _busy ? null : _disconnect,
            child: const Text('Disconnect'),
          )
        : TextButton(
            key: const ValueKey('smart-lock-connect'),
            onPressed: _busy || _connection == BikeConnectionStatus.connecting
                ? null
                : () => _connect(),
            child: Text(
              _connection == BikeConnectionStatus.reconnecting
                  ? 'Retry now'
                  : 'Connect',
            ),
          );
    return [unlock, lock, session];
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF3E0),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          size: 18,
          color: Color(0xFFB26A00),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: Color(0xFF7A4A00),
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Status {
  const _Status(this.label, this.color);

  final String label;
  final Color color;
}

class _LockVisuals {
  const _LockVisuals(this.icon, this.color);

  final IconData icon;
  final Color color;
}

_LockVisuals _lockVisuals(BikeLockStatus status) => switch (status) {
  BikeLockStatus.locked => const _LockVisuals(
    Icons.lock_rounded,
    AppStyle.darkGreen,
  ),
  BikeLockStatus.unlocked => const _LockVisuals(
    Icons.lock_open_rounded,
    AppStyle.blue,
  ),
  BikeLockStatus.unknown => const _LockVisuals(
    Icons.help_outline_rounded,
    AppStyle.muted,
  ),
};

_Status _connectionVisuals(BikeConnectionStatus status) => switch (status) {
  BikeConnectionStatus.idle => const _Status(
    'Broker session idle',
    AppStyle.muted,
  ),
  BikeConnectionStatus.connecting => const _Status(
    'Connecting to EMQX · TLS 8883',
    Color(0xFFB26A00),
  ),
  BikeConnectionStatus.connected => const _Status(
    'Connected · TLS 8883',
    AppStyle.green,
  ),
  BikeConnectionStatus.reconnecting => const _Status(
    'Reconnecting to EMQX…',
    Color(0xFFB26A00),
  ),
  BikeConnectionStatus.disconnected => const _Status(
    'Disconnected',
    Color(0xFFB4231F),
  ),
};
