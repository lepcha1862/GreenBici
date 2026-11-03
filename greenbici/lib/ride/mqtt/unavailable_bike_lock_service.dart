import 'dart:async';

import 'bike_lock_service.dart';
import 'models/bike_lock_models.dart';

/// Creates the service on platforms without `dart:io` (web), where the
/// `mqtt_client` TCP/TLS transport is unavailable.
BikeLockService createBikeLockService() => const UnavailableBikeLockService();

/// Neutral service used where MQTT over TLS sockets cannot be opened, so the
/// Unlock section still renders and reports why it cannot connect.
class UnavailableBikeLockService implements BikeLockService {
  const UnavailableBikeLockService();

  @override
  Stream<BikeConnectionStatus> get connectionStatus =>
      const Stream<BikeConnectionStatus>.empty();

  @override
  Stream<BikeLockUpdate> get lockUpdates =>
      const Stream<BikeLockUpdate>.empty();

  @override
  BikeConnectionStatus get currentConnectionStatus => BikeConnectionStatus.idle;

  @override
  BikeLockStatus get currentLockStatus => BikeLockStatus.unknown;

  @override
  Future<void> connect() => Future.error(
    const BikeLockServiceException(
      'Smart lock control needs a native app build, it is not available on web.',
    ),
  );

  @override
  Future<void> unlock() => Future.error(
    const BikeLockServiceException(
      'Smart lock control needs a native app build, it is not available on web.',
    ),
  );

  @override
  Future<void> lock() => unlock();

  @override
  Future<void> disconnect() async {}

  @override
  void dispose() {}
}
