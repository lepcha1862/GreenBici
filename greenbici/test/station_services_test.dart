import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:greenbici/station/models/bicycle_station.dart';
import 'package:greenbici/station/models/geo_point.dart';
import 'package:greenbici/station/services/location_service.dart';
import 'package:greenbici/station/services/location_search_service.dart';
import 'package:greenbici/station/services/station_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const origin = GeoPoint(latitude: 43.238, longitude: 76.945);

  group('Location search', () {
    test('submits a text query, parses results, and caches repeats', () async {
      var calls = 0;
      final service = NominatimLocationSearchService(
        minimumRequestInterval: Duration.zero,
        client: MockClient((request) async {
          calls++;
          expect(request.method, 'GET');
          expect(request.url.queryParameters['q'], 'Paro Bhutan');
          expect(request.url.queryParameters['format'], 'jsonv2');
          expect(request.url.queryParameters['limit'], '5');
          expect(request.headers['User-Agent'], startsWith('GreenBici/'));
          return http.Response(
            jsonEncode([
              {
                'display_name': 'Paro, Bhutan',
                'lat': '27.4287',
                'lon': '89.4164',
              },
              {'display_name': 'Malformed', 'lat': 'north', 'lon': 'east'},
            ]),
            200,
          );
        }),
      );

      final first = await service.search('  Paro   Bhutan ');
      final second = await service.search('paro bhutan');

      expect(first, same(second));
      expect(calls, 1);
      expect(first.single.label, 'Paro, Bhutan');
      expect(
        first.single.location,
        const GeoPoint(latitude: 27.4287, longitude: 89.4164),
      );
    });

    test('rejects short queries and failed responses', () async {
      final service = NominatimLocationSearchService(
        minimumRequestInterval: Duration.zero,
        client: MockClient((_) async => http.Response('Unavailable', 503)),
      );
      await expectLater(
        service.search('x'),
        throwsA(isA<LocationSearchException>()),
      );
      await expectLater(
        service.search('Paro'),
        throwsA(isA<LocationSearchException>()),
      );
    });
  });

  group('Station search', () {
    test('static repository returns bundled demo markers only', () async {
      const markers = [
        BicycleStation(
          id: 'demo',
          name: 'Demo Station',
          latitude: 26.8502,
          longitude: 89.394,
        ),
      ];
      const repository = StaticStationRepository(markers);

      final result = await repository.nearby(origin);

      expect(result, markers);
      expect(() => result.add(markers.single), throwsUnsupportedError);
    });

    test(
      'queries current coordinates, parses all OSM geometries and sorts',
      () async {
        final repository = OverpassStationRepository(
          client: MockClient((request) async {
            expect(request.method, 'POST');
            expect(request.url.scheme, 'https');
            final query = Uri.splitQueryString(request.body)['data']!;
            expect(query, contains('around:5000,43.238,76.945'));
            expect(query, contains('nwr["amenity"="bicycle_rental"]'));
            // The body output mode retains node coordinates as well as tags.
            expect(query, contains('out body center;'));
            return _response([
              _station(2, latitude: 43.250, type: 'way'),
              _station(
                1,
                latitude: 43.239,
                tags: {
                  'name': 'Garden station',
                  'capacity': '24',
                  'operator': 'City bikes',
                  'bikes_available': '12',
                },
              ),
              _station(3, latitude: 43.242, type: 'relation'),
            ]);
          }),
        );

        final stations = await repository.nearby(origin);
        expect(stations.map((s) => s.id), ['node/1', 'relation/3', 'way/2']);
        expect(stations.first.name, 'Garden station');
        expect(stations.first.operatorName, 'City bikes');
        expect(stations.first.capacity, 24);
        // Static OSM tags are never presented as live availability.
        expect(stations.every((s) => s.bikesAvailable == null), isTrue);
        expect(stations.every((s) => s.docksAvailable == null), isTrue);
      },
    );

    test('drops malformed, duplicate, distant and inactive stations', () async {
      final malformed = _station(7)..['lat'] = 200;
      final missingCenter = _station(8, type: 'way')..remove('center');
      final repository = OverpassStationRepository(
        client: MockClient(
          (_) async => _response([
            _station(1),
            _station(1),
            _station(2, latitude: 44),
            _station(3, tags: {'disused': 'yes'}),
            _station(4, tags: {'abandoned:amenity': 'bicycle_rental'}),
            _station(5, tags: {'access': 'private'}),
            _station(6, tags: {'amenity': 'bicycle_parking'}),
            malformed,
            missingCenter,
            {'type': 'node', 'id': 9},
            null,
            'invalid',
          ]),
        ),
      );

      expect((await repository.nearby(origin)).map((s) => s.id), ['node/1']);
    });

    test(
      'uses operator and station reference when the name is missing',
      () async {
        final repository = OverpassStationRepository(
          client: MockClient(
            (_) async => _response([
              _station(
                1,
                tags: {'network': 'City bikes', 'ref': 'A12', 'capacity': '-1'},
              ),
            ]),
          ),
        );
        final station = (await repository.nearby(origin)).single;
        expect(station.name, 'City bikes A12');
        expect(station.capacity, isNull);
      },
    );

    test(
      'returns an empty result when no stations are mapped nearby',
      () async {
        final repository = OverpassStationRepository(
          client: MockClient((_) async => _response([])),
        );
        expect(await repository.nearby(origin), isEmpty);
      },
    );

    for (final response in [
      http.Response('Service unavailable', 503),
      http.Response('<html>Error</html>', 200),
      http.Response('{"elements":{}}', 200),
      http.Response('{"elements":[],"remark":"runtime error: timed out"}', 200),
    ]) {
      test(
        'reports failed or incomplete responses: ${response.body}',
        () async {
          final repository = OverpassStationRepository(
            client: MockClient((_) async => response),
          );
          await expectLater(
            repository.nearby(origin),
            throwsA(isA<StationRepositoryException>()),
          );
        },
      );
    }

    test('bounds slow requests and reports network failure', () async {
      final slow = OverpassStationRepository(
        client: MockClient((_) => Completer<http.Response>().future),
        timeout: const Duration(milliseconds: 1),
      );
      await expectLater(
        slow.nearby(origin),
        throwsA(isA<StationRepositoryException>()),
      );
      final offline = OverpassStationRepository(
        client: MockClient((_) async => throw http.ClientException('Offline')),
      );
      await expectLater(
        offline.nearby(origin),
        throwsA(isA<StationRepositoryException>()),
      );
    });

    test('rejects invalid coordinates before making a request', () async {
      var calls = 0;
      final repository = OverpassStationRepository(
        client: MockClient((_) async {
          calls++;
          return _response([]);
        }),
      );
      await expectLater(
        repository.nearby(const GeoPoint(latitude: double.nan, longitude: 0)),
        throwsA(isA<StationRepositoryException>()),
      );
      expect(calls, 0);
    });

    test(
      'allows a deployment to provide its own HTTPS station endpoint',
      () async {
        final endpoint = Uri.parse('https://stations.example.com/overpass');
        final repository = OverpassStationRepository(
          endpoint: endpoint,
          client: MockClient((request) async {
            expect(request.url, endpoint);
            expect(request.headers['User-Agent'], startsWith('GreenBici/'));
            return _response([]);
          }),
        );
        expect(await repository.nearby(origin), isEmpty);
      },
    );
  });

  group('Location permission and fixes', () {
    test('requests permission then obtains one foreground fix', () async {
      final platform = _LocationPlatform()
        ..permission = LocationPermission.denied
        ..requestedPermission = LocationPermission.whileInUse;
      final point = await DeviceLocationService(platform: platform)
          .currentPosition();

      expect(point, origin);
      expect(platform.permissionRequests, 1);
      expect(platform.positionRequests, 1);
      expect(platform.settings?.timeLimit, const Duration(seconds: 15));
      expect(platform.settings?.accuracy, LocationAccuracy.high);
    });

    test('does not re-request permission that was already granted', () async {
      final platform = _LocationPlatform();
      await DeviceLocationService(platform: platform).currentPosition();
      expect(platform.permissionRequests, 0);
      expect(platform.positionRequests, 1);
    });

    test(
      'temporary denial remains recoverable without requesting a fix',
      () async {
        final platform = _LocationPlatform()
          ..permission = LocationPermission.denied
          ..requestedPermission = LocationPermission.denied;
        await expectLater(
          DeviceLocationService(platform: platform).currentPosition(),
          _failsWith(LocationFailureKind.denied),
        );
        expect(platform.permissionRequests, 1);
        expect(platform.positionRequests, 0);
      },
    );

    test('permanent denial avoids another system prompt', () async {
      final platform = _LocationPlatform()
        ..permission = LocationPermission.deniedForever;
      await expectLater(
        DeviceLocationService(platform: platform).currentPosition(),
        _failsWith(LocationFailureKind.deniedForever),
      );
      expect(platform.permissionRequests, 0);
      expect(platform.positionRequests, 0);
    });

    test(
      'detects permanent denial returned by the permission request',
      () async {
        final platform = _LocationPlatform()
          ..permission = LocationPermission.denied
          ..requestedPermission = LocationPermission.deniedForever;
        await expectLater(
          DeviceLocationService(platform: platform).currentPosition(),
          _failsWith(LocationFailureKind.deniedForever),
        );
        expect(platform.positionRequests, 0);
      },
    );

    test('disabled GPS does not ask for permission or acquire a fix', () async {
      final platform = _LocationPlatform()..serviceEnabled = false;
      await expectLater(
        DeviceLocationService(platform: platform).currentPosition(),
        _failsWith(LocationFailureKind.serviceDisabled),
      );
      expect(platform.permissionRequests, 0);
      expect(platform.positionRequests, 0);
    });

    test(
      'resume checks never prompt when permission is still denied',
      () async {
        final platform = _LocationPlatform()
          ..permission = LocationPermission.denied;
        await expectLater(
          DeviceLocationService(
            platform: platform,
            isWeb: true,
          ).currentPosition(requestPermission: false),
          _failsWith(LocationFailureKind.denied),
        );
        expect(platform.permissionRequests, 0);
        expect(platform.positionRequests, 0);
      },
    );

    for (final permission in [
      LocationPermission.denied,
      LocationPermission.unableToDetermine,
    ]) {
      test(
        'web acquires a fix when permission preflight returns $permission',
        () async {
          final platform = _LocationPlatform()..permission = permission;
          final service = DeviceLocationService(
            platform: platform,
            isWeb: true,
          );
          expect(await service.currentPosition(), origin);
          expect(platform.permissionRequests, 0);
          expect(platform.positionRequests, 1);
        },
      );
    }

    test(
      'unsupported browser Permissions API still permits location',
      () async {
        final platform = _LocationPlatform()
          ..permissionError = UnsupportedError(
            'Permissions API is unavailable',
          );
        final service = DeviceLocationService(platform: platform, isWeb: true);
        expect(await service.currentPosition(), origin);
        expect(platform.positionRequests, 1);
      },
    );

    test('browser refusal offers settings after the denied fix', () async {
      final platform = _LocationPlatform()
        ..permission = LocationPermission.denied
        ..positionError = const PermissionDeniedException('User denied');
      await expectLater(
        DeviceLocationService(
          platform: platform,
          isWeb: true,
        ).currentPosition(),
        _failsWith(LocationFailureKind.deniedForever),
      );
      expect(platform.permissionRequests, 0);
      expect(platform.positionRequests, 1);
    });

    test('classifies denied, timed-out and unavailable fixes', () async {
      final failures = <Object, LocationFailureKind>{
        const PermissionDeniedException('Denied'): LocationFailureKind.denied,
        TimeoutException('No GPS fix'): LocationFailureKind.timedOut,
        const LocationServiceDisabledException():
            LocationFailureKind.serviceDisabled,
        StateError('Position unavailable'): LocationFailureKind.unavailable,
      };
      for (final entry in failures.entries) {
        final platform = _LocationPlatform()..positionError = entry.key;
        await expectLater(
          DeviceLocationService(platform: platform).currentPosition(),
          _failsWith(entry.value),
        );
      }
    });

    test('bounds an unresponsive location fix', () async {
      final platform = _LocationPlatform()
        ..pendingPosition = Completer<Position>().future;
      await expectLater(
        DeviceLocationService(
          platform: platform,
          timeout: const Duration(milliseconds: 1),
        ).currentPosition(),
        _failsWith(LocationFailureKind.timedOut),
      );
    });

    test(
      'settings APIs return false when the platform cannot open them',
      () async {
        final platform = _LocationPlatform()..settingsSupported = false;
        final service = DeviceLocationService(platform: platform, isWeb: true);
        expect(await service.openAppSettings(), isFalse);
        expect(await service.openLocationSettings(), isFalse);
        platform.settingsSupported = true;
        expect(await service.openAppSettings(), isTrue);
        expect(await service.openLocationSettings(), isTrue);
      },
    );
  });

  test('distance is in meters and stays finite across the date line', () {
    const start = GeoPoint(latitude: 0, longitude: 179.999);
    const end = GeoPoint(latitude: 0, longitude: -179.999);
    expect(origin.distanceTo(origin), 0);
    expect(start.distanceTo(end), closeTo(222.39, 0.1));
  });
}

http.Response _response(List<Object?> stations) => http.Response(
  jsonEncode({'elements': stations}),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, dynamic> _station(
  int id, {
  String type = 'node',
  double latitude = 43.239,
  Map<String, String> tags = const {},
}) => {
  'id': id,
  'type': type,
  if (type == 'node') ...{'lat': latitude, 'lon': 76.945},
  if (type != 'node') 'center': {'lat': latitude, 'lon': 76.945},
  'tags': {'amenity': 'bicycle_rental', ...tags},
};

Matcher _failsWith(LocationFailureKind kind) => throwsA(
  isA<LocationFailure>().having((failure) => failure.kind, 'kind', kind),
);

class _LocationPlatform extends GeolocatorPlatform {
  bool serviceEnabled = true;
  LocationPermission permission = LocationPermission.whileInUse;
  LocationPermission requestedPermission = LocationPermission.whileInUse;
  Object? permissionError;
  Object? positionError;
  Future<Position>? pendingPosition;
  bool settingsSupported = true;
  int permissionRequests = 0;
  int positionRequests = 0;
  LocationSettings? settings;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async {
    if (permissionError != null) throw permissionError!;
    return permission;
  }

  @override
  Future<LocationPermission> requestPermission() async {
    permissionRequests++;
    return requestedPermission;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    positionRequests++;
    settings = locationSettings;
    if (positionError != null) throw positionError!;
    if (pendingPosition != null) return pendingPosition!;
    return Position(
      latitude: 43.238,
      longitude: 76.945,
      timestamp: DateTime(2026),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  @override
  Future<bool> openAppSettings() async {
    if (!settingsSupported) throw UnsupportedError('Browser settings');
    return true;
  }

  @override
  Future<bool> openLocationSettings() => openAppSettings();
}
