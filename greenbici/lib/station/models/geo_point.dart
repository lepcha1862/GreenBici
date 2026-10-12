import 'dart:math' as math;

/// A platform-independent coordinate, shared by station and location services.
class GeoPoint {
  const GeoPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  bool get isValid =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  /// Great-circle distance in meters. This is not a walking route distance.
  double distanceTo(GeoPoint other) {
    const radians = math.pi / 180;
    final latitudeDelta = (other.latitude - latitude) * radians;
    final longitudeDelta = (other.longitude - longitude) * radians;
    final a =
        math.pow(math.sin(latitudeDelta / 2), 2) +
        math.cos(latitude * radians) *
            math.cos(other.latitude * radians) *
            math.pow(math.sin(longitudeDelta / 2), 2);
    return 6371000 * 2 * math.asin(math.sqrt(a.clamp(0.0, 1.0)));
  }

  @override
  bool operator ==(Object other) =>
      other is GeoPoint &&
      latitude == other.latitude &&
      longitude == other.longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
}
