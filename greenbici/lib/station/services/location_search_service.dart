import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/geo_point.dart';

class LocationSearchResult {
  const LocationSearchResult({required this.label, required this.location});

  final String label;
  final GeoPoint location;
}

class LocationSearchException implements Exception {
  const LocationSearchException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class LocationSearchService {
  Future<List<LocationSearchResult>> search(String query);
}

/// User-submitted location lookup backed by Nominatim's search endpoint.
///
/// Requests are never sent while typing. Results are cached and network calls
/// are spaced at least one second apart to respect the public service policy.
class NominatimLocationSearchService implements LocationSearchService {
  NominatimLocationSearchService({
    http.Client? client,
    Uri? endpoint,
    this.timeout = const Duration(seconds: 15),
    this.minimumRequestInterval = const Duration(seconds: 1),
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null,
       _endpoint = endpoint ?? Uri.parse(defaultEndpoint);

  static const defaultEndpoint = String.fromEnvironment(
    'LOCATION_SEARCH_API_URL',
    defaultValue: 'https://nominatim.openstreetmap.org/search',
  );

  final http.Client _client;
  final bool _ownsClient;
  final Uri _endpoint;
  final Duration timeout;
  final Duration minimumRequestInterval;
  final Map<String, List<LocationSearchResult>> _cache = {};
  DateTime? _lastRequestAt;

  @override
  Future<List<LocationSearchResult>> search(String query) async {
    final normalized = query.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length < 2) {
      throw const LocationSearchException(
        'Enter at least two characters to search for a location.',
      );
    }
    if (_endpoint.scheme != 'https' || _endpoint.host.isEmpty) {
      throw const LocationSearchException(
        'Location search requires a valid HTTPS endpoint.',
      );
    }
    final cacheKey = normalized.toLowerCase();
    if (_cache[cacheKey] case final cached?) return cached;

    final lastRequestAt = _lastRequestAt;
    if (lastRequestAt != null) {
      final remaining =
          minimumRequestInterval - DateTime.now().difference(lastRequestAt);
      if (remaining > Duration.zero) await Future<void>.delayed(remaining);
    }
    _lastRequestAt = DateTime.now();

    final uri = _endpoint.replace(
      queryParameters: {
        ..._endpoint.queryParameters,
        'q': normalized,
        'format': 'jsonv2',
        'limit': '5',
        'addressdetails': '1',
      },
    );
    try {
      final response = await _client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Accept-Language': 'en',
              if (!kIsWeb)
                'User-Agent': 'GreenBici/1.0 (Flutter bicycle-sharing app)',
            },
          )
          .timeout(timeout);
      if (response.statusCode != 200) {
        throw const LocationSearchException(
          'Location search is temporarily unavailable. Please try again.',
        );
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! List) {
        throw const LocationSearchException(
          'Location search returned an unexpected response.',
        );
      }
      final seen = <GeoPoint>{};
      final results = <LocationSearchResult>[];
      for (final item in decoded) {
        if (item is! Map<String, dynamic>) continue;
        final latitude = double.tryParse(item['lat']?.toString() ?? '');
        final longitude = double.tryParse(item['lon']?.toString() ?? '');
        final label = item['display_name'];
        if (latitude == null || longitude == null || label is! String) continue;
        final location = GeoPoint(latitude: latitude, longitude: longitude);
        if (!location.isValid || label.trim().isEmpty || !seen.add(location)) {
          continue;
        }
        results.add(
          LocationSearchResult(label: label.trim(), location: location),
        );
      }
      final value = List<LocationSearchResult>.unmodifiable(results);
      _cache[cacheKey] = value;
      return value;
    } on LocationSearchException {
      rethrow;
    } on TimeoutException {
      throw const LocationSearchException(
        'Location search took too long. Please try again.',
      );
    } on FormatException {
      throw const LocationSearchException(
        'Location search returned an unexpected response.',
      );
    } on http.ClientException {
      throw const LocationSearchException(
        'Could not connect to location search. Check your connection.',
      );
    } on Exception {
      throw const LocationSearchException(
        'Could not search for that location. Please try again.',
      );
    }
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }
}
