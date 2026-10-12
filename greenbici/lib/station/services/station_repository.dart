import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/bicycle_station.dart';
import '../models/geo_point.dart';

abstract interface class StationRepository {
  Future<List<BicycleStation>> nearby(GeoPoint location);
}

class StationRepositoryException implements Exception {
  const StationRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Finds real, mapped bicycle rental stations via OpenStreetMap's Overpass API.
/// OSM does not supply live bike counts; an operator feed can later implement
/// [StationRepository] without changing the screen or inventing availability.
class OverpassStationRepository implements StationRepository {
  OverpassStationRepository({
    http.Client? client,
    Uri? endpoint,
    this.timeout = const Duration(seconds: 20),
    this.radiusMeters = 5000,
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null,
       _endpoint = endpoint ?? Uri.parse(defaultEndpoint);

  final http.Client _client;
  final bool _ownsClient;
  final Duration timeout;
  final double radiusMeters;

  final Uri _endpoint;

  static const defaultEndpoint = String.fromEnvironment(
    'OVERPASS_API_URL',
    defaultValue: 'https://overpass.private.coffee/api/interpreter',
  );

  @override
  Future<List<BicycleStation>> nearby(GeoPoint location) async {
    if (!location.isValid || !radiusMeters.isFinite || radiusMeters <= 0) {
      throw const StationRepositoryException('The search location is invalid.');
    }
    if (_endpoint.scheme != 'https' || _endpoint.host.isEmpty) {
      throw const StationRepositoryException(
        'Station search requires a valid HTTPS endpoint.',
      );
    }

    final query =
        '[out:json][timeout:15];'
        'nwr["amenity"="bicycle_rental"]'
        '(around:${radiusMeters.round()},${location.latitude},'
        '${location.longitude});out body center;';

    try {
      final response = await _client
          .post(
            _endpoint,
            headers: {
              'Accept': 'application/json',
              // Browsers supply their own User-Agent and Referer headers.
              if (!const bool.fromEnvironment('dart.library.js_interop'))
                'User-Agent': 'GreenBici/1.0 (nearby bicycle station search)',
            },
            body: {'data': query},
          )
          .timeout(timeout);
      if (response.statusCode != 200) {
        throw const StationRepositoryException(
          'Station search is temporarily unavailable. Please try again.',
        );
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic> || decoded['elements'] is! List) {
        throw const StationRepositoryException(
          'Station search returned an unexpected response. Please try again.',
        );
      }
      // Overpass can return HTTP 200 with a timeout remark and partial results.
      if (decoded['remark'] != null) {
        throw const StationRepositoryException(
          'Station search could not finish. Please try again.',
        );
      }

      final stations = <String, BicycleStation>{};
      for (final element in decoded['elements'] as List) {
        final station = _parseStation(element);
        if (station != null &&
            location.distanceTo(station.location) <= radiusMeters) {
          stations.putIfAbsent(station.id, () => station);
        }
      }
      final sorted = stations.values.toList()
        ..sort((a, b) {
          final distance = location
              .distanceTo(a.location)
              .compareTo(location.distanceTo(b.location));
          return distance == 0 ? a.id.compareTo(b.id) : distance;
        });
      return List.unmodifiable(sorted);
    } on StationRepositoryException {
      rethrow;
    } on TimeoutException {
      throw const StationRepositoryException(
        'Station search took too long. Please try again.',
      );
    } on FormatException {
      throw const StationRepositoryException(
        'Station search returned an unexpected response. Please try again.',
      );
    } on http.ClientException {
      throw const StationRepositoryException(
        'Could not connect to station search. Check your connection and retry.',
      );
    } on Exception {
      // Some HTTP backends expose TLS failures outside ClientException.
      throw const StationRepositoryException(
        'Could not securely connect to station search. Please try again.',
      );
    }
  }

  BicycleStation? _parseStation(dynamic element) {
    if (element is! Map<String, dynamic>) return null;
    final type = element['type'];
    final id = element['id'];
    final tags = element['tags'];
    if (!const ['node', 'way', 'relation'].contains(type) ||
        id is! int ||
        tags is! Map<String, dynamic> ||
        tags['amenity'] != 'bicycle_rental' ||
        _isInactive(tags)) {
      return null;
    }

    final coordinates = type == 'node' ? element : element['center'];
    if (coordinates is! Map<String, dynamic>) return null;
    final latitude = coordinates['lat'];
    final longitude = coordinates['lon'];
    if (latitude is! num || longitude is! num) return null;
    final location = GeoPoint(
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
    );
    if (!location.isValid) return null;

    final operatorName = _text(tags['operator']) ?? _text(tags['network']);
    final reference = _text(tags['ref']);
    final capacity = int.tryParse(tags['capacity']?.toString() ?? '');
    return BicycleStation(
      id: '$type/$id',
      name:
          _text(tags['name']) ??
          _text(tags['name:en']) ??
          (reference == null
              ? operatorName ?? 'Bicycle station'
              : '${operatorName ?? 'Bicycle station'} $reference'),
      latitude: location.latitude,
      longitude: location.longitude,
      capacity: capacity != null && capacity >= 0 ? capacity : null,
      operatorName: operatorName,
    );
  }

  bool _isInactive(Map<String, dynamic> tags) {
    if (tags['access'] == 'no' || tags['access'] == 'private') return true;
    for (final lifecycle in [
      'disused',
      'abandoned',
      'demolished',
      'removed',
      'construction',
      'proposed',
    ]) {
      if (tags[lifecycle] == 'yes' ||
          tags['$lifecycle:amenity'] == 'bicycle_rental') {
        return true;
      }
    }
    return false;
  }

  String? _text(dynamic value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;

  /// An injected client remains the responsibility of its owner.
  void dispose() {
    if (_ownsClient) _client.close();
  }
}
