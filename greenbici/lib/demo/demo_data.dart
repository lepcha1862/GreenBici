import '../station/models/bicycle_station.dart';
import '../station/models/geo_point.dart';

/// Temporary product data kept in one place so it can be replaced by API
/// mappers without changing the screen widgets.
abstract final class DemoData {
  static const focus = GeoPoint(latitude: 27.4728, longitude: 89.6393);
  static const focusLabel = 'CST, Bhutan';

  static const stations = <BicycleStation>[
    BicycleStation(
      id: 'cst-main',
      name: 'CST Main Courtyard',
      latitude: 27.4728,
      longitude: 89.6393,
      bikesAvailable: 8,
      docksAvailable: 10,
      capacity: 12,
      operatorName: 'GreenBici Bhutan',
    ),
    BicycleStation(
      id: 'norzin-lam',
      name: 'Norzin Lam Greenway',
      latitude: 27.4694,
      longitude: 89.6382,
      bikesAvailable: 5,
      docksAvailable: 7,
      capacity: 10,
      operatorName: 'GreenBici Bhutan',
    ),
    BicycleStation(
      id: 'memorial-chorten',
      name: 'Memorial Chorten Dock',
      latitude: 27.4766,
      longitude: 89.6399,
      bikesAvailable: 3,
      docksAvailable: 9,
      capacity: 12,
      operatorName: 'GreenBici Bhutan',
    ),
  ];

  static const rides = <DemoRide>[
    DemoRide(
      from: 'CST Main Courtyard',
      to: 'Norzin Lam Greenway',
      date: 'Oct 12, 2026',
      time: '8:32 AM',
      duration: '14 min',
      price: 'Nu. 24',
    ),
    DemoRide(
      from: 'Memorial Chorten Dock',
      to: 'CST Main Courtyard',
      date: 'Oct 11, 2026',
      time: '6:45 PM',
      duration: '18 min',
      price: 'Nu. 30',
    ),
    DemoRide(
      from: 'Norzin Lam Greenway',
      to: 'Memorial Chorten Dock',
      date: 'Oct 10, 2026',
      time: '12:20 PM',
      duration: '11 min',
      price: 'Nu. 20',
    ),
  ];
}

class DemoRide {
  const DemoRide({
    required this.from,
    required this.to,
    required this.date,
    required this.time,
    required this.duration,
    required this.price,
  });
  final String from;
  final String to;
  final String date;
  final String time;
  final String duration;
  final String price;
}
