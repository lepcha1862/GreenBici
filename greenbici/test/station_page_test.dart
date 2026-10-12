import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenbici/navbar/bottom_nav.dart';
import 'package:greenbici/station/models/bicycle_station.dart';
import 'package:greenbici/station/models/geo_point.dart';
import 'package:greenbici/station/services/location_service.dart';
import 'package:greenbici/station/services/station_repository.dart';
import 'package:greenbici/station/station_controller.dart';
import 'package:greenbici/station/station_page.dart';
import 'package:greenbici/station/widgets/station_details.dart';
import 'package:greenbici/station/widgets/station_map.dart';
import 'package:greenbici/theme/app_style.dart';

const _userLocation = GeoPoint(latitude: 40.78, longitude: -73.97);
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

  testWidgets('Station selection and search update the map and details', (
    tester,
  ) async {
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

    await tester.tap(find.byTooltip('Search stations'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), ' central ');
    await tester.pumpAndSettle();
    expect(harness.map!.stations.single.id, 'central');
    expect(find.text(_centralStation.name), findsOneWidget);
    expect(find.text(_riversideStation.name), findsNothing);

    await tester.enterText(find.byType(TextField), 'no such station');
    await tester.pumpAndSettle();
    expect(find.text('No matching stations'), findsOneWidget);
    expect(harness.map!.stations, isEmpty);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(harness.map!.stations, hasLength(2));
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );
    expect(tester.takeException(), isNull);
    await _unmount(tester);
  });

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
    expect(find.text('Map unavailable'), findsOneWidget);
    expect(find.text(_centralStation.name), findsOneWidget);
    expect(
      find.text('Station data © OpenStreetMap contributors').hitTestable(),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Get Directions'));
    expect(find.text('Get Directions').hitTestable(), findsOneWidget);
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
      await tester.tap(find.text('Refresh stations'));
      await tester.pumpAndSettle();
      expect(find.text(_centralStation.name), findsOneWidget);
      expect(harness.location.permissionRequests, [true]);
      await _unmount(tester);
    },
  );

  for (final size in [
    const Size(240, 320),
    const Size(390, 844),
    const Size(844, 390),
    const Size(1440, 900),
  ]) {
    for (final textScale in [1.0, 3.0]) {
      testWidgets('Station fits $size at text scale $textScale', (
        tester,
      ) async {
        final harness = _Harness();
        await _pumpPage(tester, harness, size: size, textScale: textScale);
        expect(tester.takeException(), isNull);
        expect(find.byType(BottomNav).hitTestable(), findsOneWidget);

        final directions = find.text('Get Directions');
        await tester.ensureVisible(directions);
        await tester.pumpAndSettle();
        expect(directions.hitTestable(), findsOneWidget);
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
}

class _Harness {
  _Harness({_FakeLocationService? location, _FakeStationRepository? repository})
    : location = location ?? _FakeLocationService(),
      repository = repository ?? _FakeStationRepository();

  final _FakeLocationService location;
  final _FakeStationRepository repository;
  late final controller = StationController(
    locationService: location,
    repository: repository,
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
