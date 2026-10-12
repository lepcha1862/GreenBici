import 'package:flutter/foundation.dart';

import 'maps_loader_stub.dart'
    if (dart.library.js_interop) 'maps_loader_web.dart'
    as loader;

/// One build-time setting for the native SDKs and Maps JavaScript API.
abstract final class MapsConfiguration {
  static const String apiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  static bool get isSupported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  static bool get isConfigured => apiKey.trim().isNotEmpty;

  /// Must finish before constructing a GoogleMap on the web.
  /// Native SDKs receive the same key at application startup.
  static Future<void> prepare() async {
    if (!isSupported) {
      throw UnsupportedError('Maps are supported on Android, iOS, and web.');
    }
    if (!isConfigured) {
      throw StateError('GOOGLE_MAPS_API_KEY is not configured.');
    }
    await loader.prepareMaps(apiKey.trim());
  }
}
