import '../models/ride_bike.dart';

/// Reference inventory for the preview. No operator availability is connected.
abstract final class SampleInventory {
  static const stationName = 'CST Main Courtyard';
  static const distance = 'Demo focus · CST, Bhutan';
  static const bikes = [
    RideBike(id: 'GB-204'),
    RideBike(id: 'GB-217'),
    RideBike(id: 'GB-231'),
    RideBike(id: 'GB-248'),
  ];
}
