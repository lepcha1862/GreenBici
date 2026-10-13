import 'package:flutter/foundation.dart';

import 'models/bicycle_station.dart';
import 'models/geo_point.dart';
import 'services/location_service.dart';
import 'services/station_repository.dart';

/// Owns location and station state independently of the map platform view.
class StationController extends ChangeNotifier {
  StationController({
    required this.locationService,
    required this.repository,
    this.fallbackLocation,
    this.fallbackStations = const [],
  });

  final LocationService locationService;
  final StationRepository repository;
  final GeoPoint? fallbackLocation;
  final List<BicycleStation> fallbackStations;
  GeoPoint? location;
  LocationFailure? locationFailure;
  bool locating = false;
  bool loadingStations = false;
  bool stationLoadFailed = false;
  bool usingFallback = false;
  List<BicycleStation> _stations = const [];
  String _query = '';
  String? _selectedId;
  bool _disposed = false;
  int _generation = 0;
  int cameraRevision = 0;

  bool get busy => locating || loadingStations;
  String get query => _query;
  List<BicycleStation> get stations => List.unmodifiable(
    _stations.where(
      (station) => '${station.name} ${station.operatorName ?? ''}'
          .toLowerCase()
          .contains(_query.toLowerCase().trim()),
    ),
  );

  BicycleStation? get selectedStation {
    final visible = stations;
    if (visible.isEmpty) return null;
    return visible.firstWhere(
      (station) => station.id == _selectedId,
      orElse: () => visible.first,
    );
  }

  void search(String query) {
    _query = query;
    _notify();
  }

  void select(BicycleStation station) {
    _selectedId = station.id;
    _notify();
  }

  Future<void> locate({bool requestPermission = true}) async {
    if (busy || _disposed) return;
    final generation = ++_generation;
    locating = true;
    locationFailure = null;
    if (location == null && fallbackLocation != null) {
      location = fallbackLocation;
      _stations = [...fallbackStations];
      usingFallback = true;
      cameraRevision++;
    }
    _notify();
    try {
      final position = await locationService.currentPosition(
        requestPermission: requestPermission,
      );
      if (!_isCurrent(generation)) return;
      if (!position.isValid) {
        throw const LocationFailure(LocationFailureKind.unavailable);
      }
      location = position;
      usingFallback = false;
      cameraRevision++;
      locating = false;
      await _loadStations(generation);
    } on LocationFailure catch (failure) {
      if (!_isCurrent(generation)) return;
      if (fallbackLocation != null) {
        _applyFallback(locationFailure: failure);
        return;
      }
      locationFailure = failure;
      location = null;
      _stations = const [];
    } catch (_) {
      if (!_isCurrent(generation)) return;
      if (fallbackLocation != null) {
        _applyFallback(
          locationFailure: const LocationFailure(
            LocationFailureKind.unavailable,
          ),
        );
        return;
      }
      locationFailure = const LocationFailure(LocationFailureKind.unavailable);
      location = null;
      _stations = const [];
    } finally {
      if (_isCurrent(generation)) {
        locating = false;
        _notify();
      }
    }
  }

  void _applyFallback({LocationFailure? locationFailure}) {
    location = fallbackLocation;
    _stations = [...fallbackStations];
    usingFallback = true;
    this.locationFailure = locationFailure;
    stationLoadFailed = false;
    cameraRevision++;
  }

  Future<void> refreshStations() async {
    if (busy || _disposed) return;
    if (location == null) return locate();
    await _loadStations(++_generation);
  }

  Future<void> _loadStations(int generation) async {
    loadingStations = true;
    stationLoadFailed = false;
    // Never show old-area stations as results for a fresh GPS position.
    _stations = const [];
    _notify();
    try {
      final results = await repository.nearby(location!);
      if (!_isCurrent(generation)) return;
      if (results.isEmpty && fallbackLocation != null && !usingFallback) {
        _applyFallback();
        return;
      }
      _stations = [...results]
        ..sort(
          (a, b) => location!
              .distanceTo(a.location)
              .compareTo(location!.distanceTo(b.location)),
        );
    } catch (_) {
      if (!_isCurrent(generation)) return;
      if (fallbackLocation != null) {
        _applyFallback();
      } else {
        stationLoadFailed = true;
      }
    } finally {
      if (_isCurrent(generation)) {
        loadingStations = false;
        _notify();
      }
    }
  }

  bool _isCurrent(int generation) => !_disposed && generation == _generation;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
