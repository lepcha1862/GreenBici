import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenbici/navbar/bottom_nav.dart';
import 'package:greenbici/station/models/bicycle_station.dart';
import 'package:greenbici/station/models/geo_point.dart';
import 'package:greenbici/station/services/location_service.dart';
import 'package:greenbici/station/services/location_search_service.dart';
import 'package:greenbici/station/services/station_repository.dart';
import 'package:greenbici/station/station_controller.dart';
import 'package:greenbici/station/station_page.dart';
import 'package:greenbici/station/widgets/station_details.dart';
import 'package:greenbici/station/widgets/station_map.dart';
import 'package:greenbici/theme/app_style.dart';

const _userLocation = GeoPoint(latitude: 40.78, longitude: -73.97);
const _cstLocation = GeoPoint(latitude: 26.8502058, longitude: 89.3939924);
const _cstStation = BicycleStation(
  id: 'cst-main',
  name: 'CST Main Courtyard',
  latitude: 26.8502058,
  longitude: 89.3939924,
  operatorName: 'GreenBici',
);
const _centralStation = BicycleStation(
  id: 'central',
  name: 'Central Park Dock',
  latitude: 40.781,
  longitude: -73.97,
  operatorName: 'GreenBici',
);
const _riversideStation = BicycleStation(
  id: 'riverside',
  name: 'Riverside Dock',
  latitude: 40.785,
  longitude: -73.975,
  operatorName: 'City Bikes',
);

void main() {
  testWidgets('Location request shows progress until a GPS fix is available', (
    tester,
  ) async {
    final position = Completer<GeoPoint>();
    final harness = _Harness(
      location: _FakeLocationService()..pendingPosition = position,
    );
    await _pumpPage(tester, harness, settle: false);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Finding your location'), findsNWidgets(2));
    expect(harness.repository.requests, isEmpty);
    expect(find.byKey(const ValueKey('map-preview')), findsNothing);

    position.complete(_userLocation);
    await tester.pumpAndSettle();
    expect(find.text('Current location'), findsOneWidget);
    expect(harness.map!.location, _userLocation);
    expect(harness.map!.cameraRevision, 1);
    expect(harness.repository.requests, [_userLocation]);
    await _unmount(tester);
  });

  testWidgets('Ride in Station returns the selected demo station', (
    tester,
  ) async {
    final harness = _Harness();
    BicycleStation? rideStation;
    await _pumpPage(
      tester,
      harness,
      onRideInStation: (station) => rideStation = station,
    );

    final action = find.text('Ride in Station');
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    await tester.tap(action);

    expect(rideStation, _centralStation);
    expect(find.text('Get Directions'), findsNothing);
    await _unmount(tester);
  });

  testWidgets('Location failure shows CST as the fallback map', (tester) async {
    final harness = _Harness(
      location: _FakeLocationService()
        ..failure = LocationFailureKind.unavailable,
      fallbackLocation: _cstLocation,
      fallbackStations: const [_cstStation],
    );
    await _pumpPage(tester, harness);

    expect(find.text('Fallback map · CST, Bhutan'), findsOneWidget);
    expect(find.byKey(const ValueKey('map-preview')), findsOneWidget);
    expect(harness.map!.isFallback, isTrue);
    expect(harness.map!.location, _cstLocation);
    expect(harness.map!.stations, const [_cstStation]);
    expect(harness.map!.showLocationPrompt, isTrue);
    expect(harness.map!.locationPromptActionLabel, 'Try my location');
    await _unmount(tester);
  });

  testWidgets('CST map stays visible and asks for location permission', (
    tester,
  ) async {
    final harness = _Harness(
      location: _FakeLocationService()..failure = LocationFailureKind.denied,
      fallbackLocation: _cstLocation,
      fallbackStations: const [_cstStation],
    );
    await _pumpPage(tester, harness, useRealMap: true);

    expect(
      find.byKey(const ValueKey('cst-offline-fallback-map')),
      findsOneWidget,
    );
    expect(
      find.text('Grant location permission to show stations near you.'),
      findsOneWidget,
    );
    expect(find.text('Grant location access'), findsOneWidget);
    expect(find.text('Map unavailable'), findsNothing);

    harness.location.failure = null;
    await tester.tap(find.text('Grant location access'));
    await tester.pumpAndSettle();
    expect(harness.location.permissionRequests, [true, true]);
    expect(find.text('Current location'), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('CST permission fallback fits a narrow large-text screen', (
    tester,
  ) async {
    final harness = _Harness(
      location: _FakeLocationService()..failure = LocationFailureKind.denied,
      fallbackLocation: _cstLocation,
      fallbackStations: const [_cstStation],
    );
    await _pumpPage(
      tester,
      harness,
      size: const Size(240, 320),
      textScale: 3,
      useRealMap: true,
    );

    expect(
      find.byKey(const ValueKey('cst-offline-fallback-map')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('location-permission-prompt')), findsOne);
    final mapBounds = tester.getRect(
      find.byKey(const ValueKey('cst-offline-fallback-map')),
    );
    final centerLabelBounds = tester.getRect(
      find.byKey(const ValueKey('cst-map-center-label')),
    );
    expect(centerLabelBounds.left, greaterThanOrEqualTo(mapBounds.left));
    expect(centerLabelBounds.right, lessThanOrEqualTo(mapBounds.right));
    expect(tester.takeException(), isNull);
    await _unmount(tester);
  });

  testWidgets('top navigation search moves the map away from CST', (
    tester,
  ) async {
    const searchedLocation = GeoPoint(latitude: 27.4287, longitude: 89.4164);
    final locationSearch = _FakeLocationSearchService(
      results: const [
        LocationSearchResult(label: 'Paro, Bhutan', location: searchedLocation),
      ],
    );
    final harness = _Harness(
      location: _FakeLocationService()..failure = LocationFailureKind.denied,
      fallbackLocation: _cstLocation,
      fallbackStations: const [_cstStation],
      locationSearchService: locationSearch,
    );
    await _pumpPage(tester, harness);
    expect(harness.map!.location, _cstLocation);

    await tester.tap(find.byTooltip('Search locations'));
    await tester.pumpAndSettle();
    expect(find.text('Search for another location'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Paro');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(locationSearch.queries, ['Paro']);
    await tester.tap(find.text('Paro, Bhutan'));
    await tester.pumpAndSettle();

    expect(harness.map!.location, searchedLocation);
    expect(harness.map!.isFallback, isFalse);
    expect(harness.map!.centerLabel, 'Paro, Bhutan');
    expect(harness.controller.searchedLocationLabel, 'Paro, Bhutan');
    expect(find.textContaining('Map center'), findsOneWidget);
    expect(harness.location.permissionRequests, [true]);
    await _unmount(tester);
  });

  testWidgets('Denied location shows a recoverable message and retry works', (
    tester,
  ) async {
    final harness = _Harness(
      location: _FakeLocationService()..failure = LocationFailureKind.denied,
    );
    await _pumpPage(tester, harness);

    expect(find.text('Location access is off'), findsOneWidget);
    expect(find.byKey(const ValueKey('map-preview')), findsNothing);
    expect(harness.repository.requests, isEmpty);
    expect(harness.location.permissionRequests, [true]);

    harness.location.failure = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Current location'), findsOneWidget);
    expect(harness.location.permissionRequests, [true, true]);
    expect(harness.map!.location, _userLocation);
    expect(find.text(_centralStation.name), findsOneWidget);
    await _unmount(tester);
  });

  for (final configuration in [
    (
      LocationFailureKind.deniedForever,
      'Location permission is blocked',
      'Open settings',
    ),
    (
      LocationFailureKind.serviceDisabled,
      'Location services are off',
      'Location settings',
    ),
  ]) {
    testWidgets('${configuration.$2} opens settings and rechecks on return', (
      tester,
    ) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      final harness = _Harness(
        location: _FakeLocationService()..failure = configuration.$1,
      );
      await _pumpPage(tester, harness);

      expect(find.text(configuration.$2), findsOneWidget);
      expect(harness.repository.requests, isEmpty);
      await tester.tap(find.text(configuration.$3));
      await tester.pumpAndSettle();
      expect(
        harness.location.appSettingsOpened,
        configuration.$1 == LocationFailureKind.deniedForever ? 1 : 0,
      );
      expect(
        harness.location.locationSettingsOpened,
        configuration.$1 == LocationFailureKind.serviceDisabled ? 1 : 0,
      );

      harness.location.failure = null;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(harness.location.permissionRequests, [true, false]);
      expect(find.text('Current location'), findsOneWidget);
      expect(harness.map!.location, _userLocation);
      await _unmount(tester);
    });
  }

  testWidgets('Settings failure gives an actionable device-settings fallback', (
    tester,
  ) async {
    final harness = _Harness(
      location: _FakeLocationService()
        ..failure = LocationFailureKind.deniedForever
        ..settingsAvailable = false,
    );
    await _pumpPage(tester, harness);
    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Open your device settings to enable location, then try again.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await _unmount(tester);
  });

  for (final configuration in [
    (LocationFailureKind.timedOut, 'Location took too long'),
    (LocationFailureKind.unavailable, 'Location unavailable'),
  ]) {
    testWidgets('${configuration.$2} offers retry without an unusable map', (
      tester,
    ) async {
      final harness = _Harness(
        location: _FakeLocationService()..failure = configuration.$1,
      );
      await _pumpPage(tester, harness);
      expect(find.text(configuration.$2), findsWidgets);
      expect(find.text('Try again').hitTestable(), findsOneWidget);
      expect(find.byKey(const ValueKey('map-preview')), findsNothing);
      expect(harness.repository.requests, isEmpty);
      await _unmount(tester);
    });
  }

  testWidgets(
    'Station selection updates the map without a local search field',
    (tester) async {
      final harness = _Harness();
      await _pumpPage(tester, harness);
      expect(harness.map!.stations.map((station) => station.id), [
        'central',
        'riverside',
      ]);
      expect(find.text(_centralStation.name), findsOneWidget);

      // The injected platform-free map calls the same selection callback as a pin.
      harness.map!.onSelected(_riversideStation);
      await tester.pumpAndSettle();
      expect(find.text(_riversideStation.name), findsOneWidget);
      expect(harness.map!.selectedStation!.id, 'riverside');
      expect(find.byType(TextField), findsNothing);
      expect(find.byTooltip('Search locations'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _unmount(tester);
    },
  );

  testWidgets('Change station opens a selectable list and updates details', (
    tester,
  ) async {
    final harness = _Harness();
    await _pumpPage(tester, harness);
    await tester.tap(find.textContaining('Change station'));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNWidgets(2));
    expect(harness.map!.interactionBlocked, isTrue);

    await tester.tap(find.widgetWithText(ListTile, _riversideStation.name));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNothing);
    expect(harness.map!.interactionBlocked, isFalse);
    expect(harness.map!.selectedStation!.id, 'riverside');
    expect(find.text(_riversideStation.name), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('Missing map configuration keeps the station list usable', (
    tester,
  ) async {
    final harness = _Harness();
    await _pumpPage(tester, harness, useRealMap: true);
    expect(
      find.byKey(const ValueKey('cst-offline-fallback-map')),
      findsOneWidget,
    );
    expect(find.text('CST fallback map'), findsOneWidget);
    expect(find.text('Map unavailable'), findsNothing);
    expect(find.text(_centralStation.name), findsOneWidget);
    expect(
      find.text('Location search © OpenStreetMap contributors').hitTestable(),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Ride in Station'));
    expect(find.text('Ride in Station').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _unmount(tester);
  });

  testWidgets('Station loading failure retries without another GPS request', (
    tester,
  ) async {
    final harness = _Harness(repository: _FakeStationRepository()..fail = true);
    await _pumpPage(tester, harness);
    expect(find.text('Stations could not load'), findsOneWidget);
    expect(find.byKey(const ValueKey('map-preview')), findsOneWidget);
    expect(harness.map!.stations, isEmpty);

    harness.repository.fail = false;
    await tester.tap(find.text('Retry stations'));
    await tester.pumpAndSettle();
    expect(find.text(_centralStation.name), findsOneWidget);
    expect(harness.location.permissionRequests, [true]);
    expect(harness.repository.requests, hasLength(2));
    await _unmount(tester);
  });

  testWidgets(
    'An empty station response explains coverage and allows refresh',
    (tester) async {
      final harness = _Harness(
        repository: _FakeStationRepository()..stations = [],
      );
      await _pumpPage(tester, harness);
      expect(find.text('No stations nearby'), findsOneWidget);
      expect(find.textContaining('within 5 km'), findsOneWidget);
      expect(find.byType(StationDetails), findsNothing);

      harness.repository.stations = [_centralStation];
      final refresh = find.text('Refresh stations');
      await tester.ensureVisible(refresh);
      await tester.pumpAndSettle();
      await tester.tap(refresh);
      await tester.pumpAndSettle();
      expect(find.text(_centralStation.name), findsOneWidget);
      expect(harness.location.permissionRequests, [true]);
      await _unmount(tester);
    },
  );

  for (final size in [
    const Size(240, 320),
    const Size(280, 640),
    const Size(390, 844),
    const Size(660, 900),
    const Size(844, 390),
    const Size(1440, 900),
  ]) {
    for (final textScale in [1.0, 2.0, 3.0]) {
      testWidgets('Station fits $size at text scale $textScale', (
        tester,
      ) async {
        final harness = _Harness();
        await _pumpPage(tester, harness, size: size, textScale: textScale);
        expect(tester.takeException(), isNull);
        expect(find.byType(BottomNav).hitTestable(), findsOneWidget);

        final rideInStation = find.text('Ride in Station');
        await tester.ensureVisible(rideInStation);
        await tester.pumpAndSettle();
        expect(rideInStation.hitTestable(), findsOneWidget);
        expect(
          find.text('Live availability is not provided for this station.'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await _unmount(tester);
      });

      testWidgets('Location retry fits $size at text scale $textScale', (
        tester,
      ) async {
        final harness = _Harness(
          location: _FakeLocationService()
            ..failure = LocationFailureKind.denied,
        );
        await _pumpPage(tester, harness, size: size, textScale: textScale);
        final retry = find.text('Try again');
        await tester.ensureVisible(retry);
        await tester.pumpAndSettle();
        expect(retry.hitTestable(), findsOneWidget);
        expect(find.byType(BottomNav).hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _unmount(tester);
      });
    }
  }

  testWidgets('Large-text station picker stays usable on a narrow screen', (
    tester,
  ) async {
    final harness = _Harness();
    await _pumpPage(tester, harness, size: const Size(240, 320), textScale: 3);
    final changeStation = find.textContaining('Change station');
    await tester.ensureVisible(changeStation);
    await tester.pumpAndSettle();
    await tester.tap(changeStation);
    await tester.pumpAndSettle();
    final riverside = find.widgetWithText(ListTile, _riversideStation.name);
    await tester.scrollUntilVisible(
      riverside,
      120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    if (riverside.hitTestable().evaluate().isEmpty) {
      await tester.drag(find.byType(ListView).last, const Offset(0, -200));
      await tester.pumpAndSettle();
    }
    expect(riverside.hitTestable(), findsOneWidget);
    await tester.tap(riverside.hitTestable());
    await tester.pumpAndSettle();
    expect(harness.map!.selectedStation!.id, _riversideStation.id);
    expect(harness.map!.interactionBlocked, isFalse);
    await tester.ensureVisible(find.text('Ride in Station'));
    await tester.pumpAndSettle();
    expect(find.text('Ride in Station').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _unmount(tester);
  });

  testWidgets('Orientation changes preserve station selection', (tester) async {
    final harness = _Harness();
    await _pumpPage(tester, harness);
    harness.map!.onSelected(_riversideStation);
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(844, 390);
    await tester.pumpAndSettle();
    expect(harness.map!.selectedStation!.id, _riversideStation.id);
    expect(harness.location.permissionRequests, [true]);
    await tester.ensureVisible(find.text('Ride in Station'));
    await tester.pumpAndSettle();
    expect(find.text('Ride in Station').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _unmount(tester);
  });

  for (final textScale in [1.0, 2.0, 3.0]) {
    testWidgets('Live counts and long names fit narrow details at $textScale', (
      tester,
    ) async {
      const longStation = BicycleStation(
        id: 'long-name',
        name: 'University and Botanical Garden Bicycle Station',
        latitude: 40.781,
        longitude: -73.97,
        operatorName: 'City Bicycle Sharing Network',
        bikesAvailable: 128,
        docksAvailable: 0,
      );
      tester.view.physicalSize = const Size(240, 320);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var rideRequests = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppStyle.theme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: StationDetails(
                station: longStation,
                userLocation: _userLocation,
                onRideInStation: () => rideRequests++,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('128'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.textContaining('Live availability'), findsNothing);
      final rideInStation = find.ancestor(
        of: find.text('Ride in Station'),
        matching: find.byWidgetPredicate((widget) => widget is FilledButton),
      );
      await tester.ensureVisible(rideInStation);
      await tester.pumpAndSettle();
      expect(tester.getSize(rideInStation).height, greaterThanOrEqualTo(48));
      await tester.tap(rideInStation);
      expect(rideRequests, 1);
      expect(tester.takeException(), isNull);
      await _unmount(tester);
    });
  }
}

class _Harness {
  _Harness({
    _FakeLocationService? location,
    _FakeStationRepository? repository,
    this.locationSearchService,
    this.fallbackLocation,
    this.fallbackStations = const [],
  }) : location = location ?? _FakeLocationService(),
       repository = repository ?? _FakeStationRepository();

  final _FakeLocationService location;
  final _FakeStationRepository repository;
  final LocationSearchService? locationSearchService;
  final GeoPoint? fallbackLocation;
  final List<BicycleStation> fallbackStations;
  late final controller = StationController(
    locationService: location,
    repository: repository,
    fallbackLocation: fallbackLocation,
    fallbackStations: fallbackStations,
  );
  StationMap? map;
}

Future<void> _pumpPage(
  WidgetTester tester,
  _Harness harness, {
  Size size = const Size(390, 844),
  double textScale = 1,
  bool settle = true,
  bool useRealMap = false,
  ValueChanged<BicycleStation>? onRideInStation,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  addTearDown(harness.controller.dispose);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppStyle.theme,
      home: Scaffold(
        body: StationPage(
          controller: harness.controller,
          onRideInStation: onRideInStation,
          locationSearchService: harness.locationSearchService,
          mapBuilder: useRealMap
              ? null
              : (context, map) {
                  harness.map = map;
                  return const ColoredBox(
                    key: ValueKey('map-preview'),
                    color: AppStyle.paleGreen,
                  );
                },
        ),
        bottomNavigationBar: BottomNav(selectedIndex: 1, onSelected: (_) {}),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

class _FakeLocationService implements LocationService {
  LocationFailureKind? failure;
  Completer<GeoPoint>? pendingPosition;
  final permissionRequests = <bool>[];
  int appSettingsOpened = 0;
  int locationSettingsOpened = 0;
  bool settingsAvailable = true;

  @override
  Future<GeoPoint> currentPosition({bool requestPermission = true}) async {
    permissionRequests.add(requestPermission);
    if (failure case final kind?) throw LocationFailure(kind);
    return pendingPosition == null
        ? _userLocation
        : await pendingPosition!.future;
  }

  @override
  Future<bool> openAppSettings() async {
    appSettingsOpened++;
    return settingsAvailable;
  }

  @override
  Future<bool> openLocationSettings() async {
    locationSettingsOpened++;
    return settingsAvailable;
  }
}

class _FakeLocationSearchService implements LocationSearchService {
  _FakeLocationSearchService({this.results = const []});

  final List<LocationSearchResult> results;
  final queries = <String>[];

  @override
  Future<List<LocationSearchResult>> search(String query) async {
    queries.add(query);
    return results;
  }
}

class _FakeStationRepository implements StationRepository {
  List<BicycleStation> stations = [_riversideStation, _centralStation];
  final requests = <GeoPoint>[];
  bool fail = false;

  @override
  Future<List<BicycleStation>> nearby(GeoPoint location) async {
    requests.add(location);
    if (fail) throw const StationRepositoryException('Offline');
    return stations;
  }
}
