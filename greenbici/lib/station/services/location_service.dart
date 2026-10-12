import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/geo_point.dart';

enum LocationFailureKind {
  denied,
  deniedForever,
  serviceDisabled,
  unavailable,
  timedOut,
}

class LocationFailure implements Exception {
  const LocationFailure(this.kind);

  final LocationFailureKind kind;

  @override
  String toString() => 'LocationFailure(${kind.name})';
}

abstract interface class LocationService {
  Future<GeoPoint> currentPosition({bool requestPermission = true});
  Future<bool> openAppSettings();
  Future<bool> openLocationSettings();
}

/// Uses a single foreground fix. It never starts background location tracking.
class DeviceLocationService implements LocationService {
  DeviceLocationService({
    GeolocatorPlatform? platform,
    this.timeout = const Duration(seconds: 15),
    this.isWeb = kIsWeb,
  }) : _platform = platform ?? GeolocatorPlatform.instance;

  final GeolocatorPlatform _platform;
  final bool isWeb;
  final Duration timeout;

  @override
  Future<GeoPoint> currentPosition({bool requestPermission = true}) async {
    try {
      if (!await _platform.isLocationServiceEnabled().timeout(timeout)) {
        throw const LocationFailure(LocationFailureKind.serviceDisabled);
      }
      var permission = await _checkPermission();
      if (permission == LocationPermission.deniedForever) {
        throw const LocationFailure(LocationFailureKind.deniedForever);
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        if (!requestPermission) {
          throw const LocationFailure(LocationFailureKind.denied);
        }
        // On web a position request shows the browser's permission prompt and
        // also works when its Permissions API is absent. requestPermission()
        // there can misclassify a GPS timeout as permanent denial.
        if (!isWeb) {
          permission = await _platform.requestPermission();
          if (permission == LocationPermission.deniedForever) {
            throw const LocationFailure(LocationFailureKind.deniedForever);
          }
          if (permission != LocationPermission.whileInUse &&
              permission != LocationPermission.always) {
            throw const LocationFailure(LocationFailureKind.denied);
          }
        }
      }
      final position = await _platform
          .getCurrentPosition(
            locationSettings: LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: timeout,
            ),
          )
          .timeout(timeout);
      final point = GeoPoint(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (!point.isValid) {
        throw const LocationFailure(LocationFailureKind.unavailable);
      }
      return point;
    } on LocationFailure {
      rethrow;
    } on PermissionDeniedException {
      // Permission can be revoked after the preflight check.
      var kind = LocationFailureKind.denied;
      try {
        final permission = await _checkPermission();
        if (permission == LocationPermission.deniedForever ||
            (isWeb && permission == LocationPermission.denied)) {
          kind = LocationFailureKind.deniedForever;
        }
      } catch (_) {
        // Keep a recoverable denial when the platform cannot classify it.
      }
      throw LocationFailure(kind);
    } on LocationServiceDisabledException {
      throw const LocationFailure(LocationFailureKind.serviceDisabled);
    } on TimeoutException {
      throw const LocationFailure(LocationFailureKind.timedOut);
    } catch (_) {
      throw const LocationFailure(LocationFailureKind.unavailable);
    }
  }

  Future<LocationPermission> _checkPermission() async {
    try {
      return await _platform.checkPermission().timeout(timeout);
    } on UnsupportedError {
      if (isWeb) return LocationPermission.unableToDetermine;
      rethrow;
    }
  }

  @override
  Future<bool> openAppSettings() => _openSettings(_platform.openAppSettings);

  @override
  Future<bool> openLocationSettings() =>
      _openSettings(_platform.openLocationSettings);

  Future<bool> _openSettings(Future<bool> Function() open) async {
    try {
      return await open().timeout(timeout);
    } catch (_) {
      // Browsers do not expose an API for opening their location settings.
      return false;
    }
  }
}
