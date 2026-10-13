import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:greenbici/station/models/bicycle_station.dart';
import 'package:greenbici/station/models/geo_point.dart';
import 'package:greenbici/station/services/location_service.dart';
import 'package:greenbici/station/services/station_repository.dart';
import 'package:greenbici/station/station_controller.dart';

const _origin = GeoPoint(latitude: 43.25, longitude: 76.9);
const _near = BicycleStation(
  id: 'near',
  name: 'Park',
  latitude: 43.251,
  longitude: 76.9,
  operatorName: 'CityBikes',
);
const _far = BicycleStation(
  id: 'far',
  name: 'River',
  latitude: 43.26,
  longitude: 76.9,
);
const _fallback = GeoPoint(latitude: 26.8502058, longitude: 89.3939924);
const _fallbackStation = BicycleStation(
  id: 'cst-main',
  name: 'CST Main Courtyard',
  latitude: 26.8502058,
  longitude: 89.3939924,
);

void main() {
  late _Location location;
  late _Repository repository;
  late StationController controller;
  setUp(() {
    location = _Location();
    repository = _Repository();
    controller = StationController(
      locationService: location,
      repository: repository,
    );
  });
  tearDown(() => controller.dispose());

  test('GPS centers before a slow station fetch completes', () async {
    final results = Completer<List<BicycleStation>>();
    repository.result = () => results.future;
    final load = controller.locate();
    await Future<void>.delayed(Duration.zero);
    expect(controller.location, _origin);
    expect(controller.cameraRevision, 1);
    expect(controller.loadingStations, isTrue);
    results.complete([_far, _near]);
    await load;
    expect(controller.stations.map((s) => s.id), ['near', 'far']);
    expect(controller.selectedStation, _near);
    expect(controller.busy, isFalse);
  });

  test('selection and name/operator filtering stay consistent', () async {
    await controller.locate();
    controller.select(_far);
    expect(controller.selectedStation, _far);
    controller.search('  cityBIKES ');
    expect(controller.stations, [_near]);
    expect(controller.selectedStation, _near);
    controller.search('missing');
    expect(controller.stations, isEmpty);
    expect(controller.selectedStation, isNull);
    controller.search('');
    expect(controller.selectedStation, _far);
  });

  test('denied GPS does not query stations; retry recovers', () async {
    location.failure = const LocationFailure(LocationFailureKind.denied);
    await controller.locate();
    expect(controller.locationFailure!.kind, LocationFailureKind.denied);
    expect(repository.calls, 0);
    location.failure = null;
    await controller.locate();
    expect(repository.calls, 1);
    expect(controller.locationFailure, isNull);
  });

  test('revoked permission clears old location and station results', () async {
    await controller.locate();
    location.failure = const LocationFailure(LocationFailureKind.deniedForever);
    await controller.locate(requestPermission: false);
    expect(location.lastRequestPermission, isFalse);
    expect(controller.location, isNull);
    expect(controller.stations, isEmpty);
    expect(controller.selectedStation, isNull);
    expect(repository.calls, 1);
  });

  test('station retry retains location and does not reprompt GPS', () async {
    repository.result = () async => throw Exception('Offline');
    await controller.locate();
    expect(controller.stationLoadFailed, isTrue);
    expect(controller.location, _origin);
    expect(controller.stations, isEmpty);
    repository.result = () async => [_near];
    await controller.refreshStations();
    expect(location.calls, 1);
    expect(controller.stationLoadFailed, isFalse);
    expect(controller.selectedStation, _near);
  });

  test('GPS failure shows the configured CST fallback map', () async {
    final local = StationController(
      locationService: location,
      repository: repository,
      fallbackLocation: _fallback,
      fallbackStations: const [_fallbackStation],
    );
    addTearDown(local.dispose);
    location.failure = const LocationFailure(LocationFailureKind.unavailable);

    await local.locate();

    expect(local.location, _fallback);
    expect(local.stations, const [_fallbackStation]);
    expect(local.usingFallback, isTrue);
    expect(local.locationFailure?.kind, LocationFailureKind.unavailable);
    expect(repository.calls, 0);
  });

  test('CST fallback is visible while GPS is still resolving', () async {
    final position = Completer<GeoPoint>();
    location.result = () => position.future;
    final local = StationController(
      locationService: location,
      repository: repository,
      fallbackLocation: _fallback,
      fallbackStations: const [_fallbackStation],
    );
    addTearDown(local.dispose);

    final load = local.locate();

    expect(local.location, _fallback);
    expect(local.stations, const [_fallbackStation]);
    expect(local.usingFallback, isTrue);
    position.complete(_origin);
    await load;
    expect(local.location, _origin);
    expect(local.usingFallback, isFalse);
  });

  for (final stationResult in ['empty', 'failure']) {
    test(
      '$stationResult station lookup switches to the CST fallback map',
      () async {
        final local = StationController(
          locationService: location,
          repository: repository,
          fallbackLocation: _fallback,
          fallbackStations: const [_fallbackStation],
        );
        addTearDown(local.dispose);
        repository.result = stationResult == 'empty'
            ? () async => const []
            : () async => throw Exception('Map data unavailable');

        await local.locate();

        expect(local.location, _fallback);
        expect(local.stations, const [_fallbackStation]);
        expect(local.usingFallback, isTrue);
        expect(local.stationLoadFailed, isFalse);
        expect(repository.calls, 1);
      },
    );
  }

  test(
    'repeat taps do not issue concurrent location or search requests',
    () async {
      final position = Completer<GeoPoint>();
      location.result = () => position.future;
      final pending = controller.locate();
      await controller.locate();
      await controller.refreshStations();
      expect(location.calls, 1);
      expect(repository.calls, 0);
      position.complete(_origin);
      await pending;
      expect(repository.calls, 1);
    },
  );

  test('late async result is ignored after disposal', () async {
    final results = Completer<List<BicycleStation>>();
    repository.result = () => results.future;
    final local = StationController(
      locationService: location,
      repository: repository,
    );
    var notifications = 0;
    local.addListener(() => notifications++);
    final pending = local.locate();
    await Future<void>.delayed(Duration.zero);
    local.dispose();
    final before = notifications;
    results.complete([_near]);
    await pending;
    expect(notifications, before);
    expect(local.stations, isEmpty);
  });
}

class _Location implements LocationService {
  LocationFailure? failure;
  int calls = 0;
  bool? lastRequestPermission;
  Future<GeoPoint> Function() result = () async => _origin;

  @override
  Future<GeoPoint> currentPosition({bool requestPermission = true}) {
    calls++;
    lastRequestPermission = requestPermission;
    if (failure != null) throw failure!;
    return result();
  }

  @override
  Future<bool> openAppSettings() async => true;
  @override
  Future<bool> openLocationSettings() async => true;
}

class _Repository implements StationRepository {
  int calls = 0;
  Future<List<BicycleStation>> Function() result = () async => [_far, _near];
  @override
  Future<List<BicycleStation>> nearby(GeoPoint location) {
    calls++;
    return result();
  }
}
