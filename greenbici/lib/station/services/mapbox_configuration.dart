import 'package:flutter/foundation.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Build-time Mapbox configuration shared by Android, iOS, and web.
abstract final class MapboxConfiguration {
  static const String accessToken = String.fromEnvironment(
    'MAPBOX_ACCESS_TOKEN',
  );

  static bool get isSupported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  static bool get isConfigured => accessToken.trim().isNotEmpty;

  static void prepare() {
    if (isConfigured) {
      MapboxOptions.setAccessToken(accessToken.trim());
    }
  }
}
