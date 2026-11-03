// Platform selected factory for BikeLockService.
//
// The MQTT over TLS client needs `dart:io` sockets, so web builds fall back
// to a stub that reports the feature as unavailable instead of failing to
// compile.
export 'unavailable_bike_lock_service.dart'
    if (dart.library.io) 'mqtt_bike_lock_service.dart';
