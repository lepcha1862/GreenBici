import 'dart:async';

import 'models/bike_lock_models.dart';

/// Contract used by the smart bike lock UI in the Rides screen Unlock section.
///
/// Implemented by an MQTT client on platforms with `dart:io` and by an
/// unavailable stub on platforms without it (web), so the feature never breaks
/// other builds.
abstract class BikeLockService {
  Stream<BikeConnectionStatus> get connectionStatus;

  Stream<BikeLockUpdate> get lockUpdates;

  BikeConnectionStatus get currentConnectionStatus;

  BikeLockStatus get currentLockStatus;

  /// Opens the TLS connection and subscribes to the status topic.
  ///
  /// Completes with a [BikeLockServiceException] when the broker cannot be
  /// reached or rejects the credentials.
  Future<void> connect();

  /// Publishes the `UNLOCK` command.
  Future<void> unlock();

  /// Publishes the `LOCK` command.
  Future<void> lock();

  /// Closes the connection and releases the broker session.
  Future<void> disconnect();

  /// Frees every resource held by the service. Safe to call more than once.
  void dispose();
}

/// Human readable failure raised by [BikeLockService] operations.
class BikeLockServiceException implements Exception {
  const BikeLockServiceException(this.message, {this.detail});

  final String message;
  final String? detail;

  @override
  String toString() => detail == null ? message : '$message ($detail)';
}
