import 'geo_point.dart';

class BicycleStation {
  const BicycleStation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.bikesAvailable,
    this.docksAvailable,
    this.capacity,
    this.operatorName,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;

  /// Null means the data source does not provide current availability.
  final int? bikesAvailable;
  final int? docksAvailable;

  /// Total station capacity, not the number of currently available docks.
  final int? capacity;
  final String? operatorName;

  GeoPoint get location => GeoPoint(latitude: latitude, longitude: longitude);
}
