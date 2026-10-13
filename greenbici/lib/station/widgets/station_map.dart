import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../../theme/app_style.dart';
import '../models/bicycle_station.dart';
import '../models/geo_point.dart';
import '../services/maps_configuration.dart';
import 'station_marker.dart';
import 'station_message.dart';

class StationMap extends StatefulWidget {
  const StationMap({
    super.key,
    required this.location,
    required this.stations,
    required this.selectedStation,
    required this.onSelected,
    required this.onLocate,
    required this.cameraRevision,
    this.bottomPadding = 0,
    this.locating = false,
    this.interactionBlocked = false,
    this.isFallback = false,
  });

  final GeoPoint location;
  final List<BicycleStation> stations;
  final BicycleStation? selectedStation;
  final ValueChanged<BicycleStation> onSelected;
  final VoidCallback onLocate;
  final int cameraRevision;
  final double bottomPadding;
  final bool locating;
  final bool interactionBlocked;
  final bool isFallback;

  @override
  State<StationMap> createState() => _StationMapState();
}

class _StationMapState extends State<StationMap> {
  GoogleMapController? _map;
  late Future<void> _ready;
  BitmapDescriptor? _pin;
  BitmapDescriptor? _selectedPin;

  @override
  void initState() {
    super.initState();
    _ready = _prepare();
  }

  Future<void> _prepare() async {
    if (!MapsConfiguration.isSupported || !MapsConfiguration.isConfigured) {
      return;
    }
    await MapsConfiguration.prepare();
    List<BitmapDescriptor> pins;
    try {
      pins = await Future.wait([
        createStationMarker(selected: false),
        createStationMarker(selected: true),
      ]);
    } catch (_) {
      // A marker-rendering failure should not prevent the map from appearing.
      pins = [
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ];
    }
    if (!mounted) return;
    _pin = pins[0];
    _selectedPin = pins[1];
  }

  @override
  void didUpdateWidget(covariant StationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cameraRevision != widget.cameraRevision ||
        oldWidget.isFallback != widget.isFallback) {
      unawaited(
        _move(
          CameraUpdate.newLatLngZoom(
            _coordinates(widget.location),
            _locationZoom,
          ),
        ),
      );
    } else if (oldWidget.selectedStation != null &&
        widget.selectedStation != null &&
        oldWidget.selectedStation!.id != widget.selectedStation!.id) {
      unawaited(
        _move(
          CameraUpdate.newLatLng(
            _coordinates(widget.selectedStation!.location),
          ),
        ),
      );
    }
  }

  LatLng _coordinates(GeoPoint point) =>
      LatLng(point.latitude, point.longitude);

  double get _locationZoom => widget.isFallback ? 17 : 15;

  Future<void> _move(CameraUpdate update) async {
    final map = _map;
    if (map == null || !mounted) return;
    try {
      if (MediaQuery.disableAnimationsOf(context)) {
        await map.moveCamera(update);
      } else {
        await map.animateCamera(update);
      }
    } catch (_) {
      // A platform view can finish disposal while a camera command is in flight.
    }
  }

  @override
  void dispose() {
    // GoogleMap owns and disposes its controller with the platform view.
    _map = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!MapsConfiguration.isSupported || !MapsConfiguration.isConfigured) {
      return ColoredBox(
        color: AppStyle.paleGreen,
        child: Padding(
          padding: EdgeInsets.only(bottom: widget.bottomPadding),
          child: StationMessage(
            icon: Icons.map_outlined,
            title: 'Map unavailable',
            message: MapsConfiguration.isSupported
                ? 'The map is not configured yet. Nearby stations are listed below.'
                : 'Use Android, iOS, or a web browser to view the map. Nearby stations are listed below.',
          ),
        ),
      );
    }
    return FutureBuilder<void>(
      future: _ready,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: EdgeInsets.only(bottom: widget.bottomPadding),
            child: StationMessage(
              title: 'Map could not load',
              message: 'Check your connection and try again.',
              actionLabel: 'Retry map',
              onAction: () => setState(() => _ready = _prepare()),
            ),
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return Padding(
            padding: EdgeInsets.only(bottom: widget.bottomPadding),
            child: const StationMessage(
              title: 'Loading map',
              message: '',
              loading: true,
            ),
          );
        }
        return Stack(
          children: [
            Positioned.fill(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _coordinates(widget.location),
                  zoom: _locationZoom,
                ),
                onMapCreated: (controller) {
                  if (!mounted) return;
                  _map = controller;
                  // Use the latest location even if GPS finished during map creation.
                  unawaited(
                    _move(
                      CameraUpdate.newLatLngZoom(
                        _coordinates(widget.location),
                        _locationZoom,
                      ),
                    ),
                  );
                },
                style: _mapStyle,
                padding: EdgeInsets.only(
                  bottom: widget.bottomPadding,
                  right: 8,
                ),
                myLocationEnabled: !kIsWeb,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
                webCameraControlEnabled: false,
                circles: kIsWeb
                    ? {
                        Circle(
                          circleId: const CircleId('location-halo'),
                          center: _coordinates(widget.location),
                          radius: 60,
                          fillColor: Colors.blue.withValues(alpha: .16),
                          strokeWidth: 0,
                        ),
                        Circle(
                          circleId: const CircleId('location'),
                          center: _coordinates(widget.location),
                          radius: 8,
                          fillColor: Colors.blue,
                          strokeColor: Colors.white,
                          strokeWidth: 3,
                        ),
                      }
                    : {},
                markers: {
                  for (final station in widget.stations)
                    Marker(
                      markerId: MarkerId(station.id),
                      position: _coordinates(station.location),
                      icon: station.id == widget.selectedStation?.id
                          ? _selectedPin!
                          : _pin!,
                      zIndexInt: station.id == widget.selectedStation?.id
                          ? 1
                          : 0,
                      infoWindow: InfoWindow(title: station.name),
                      onTap: () => widget.onSelected(station),
                    ),
                  if (widget.isFallback &&
                      !widget.stations.any(
                        (station) => station.location == widget.location,
                      ))
                    Marker(
                      markerId: const MarkerId('cst-fallback'),
                      position: _coordinates(widget.location),
                      icon: _selectedPin!,
                      zIndexInt: 2,
                      infoWindow: const InfoWindow(
                        title: 'College of Science and Technology',
                        snippet: 'Rinchending, Phuentsholing, Bhutan',
                      ),
                    ),
                },
              ),
            ),
            if (widget.isFallback)
              Positioned(
                left: 14,
                top: 14,
                child: PointerInterceptor(
                  child: Semantics(
                    label: 'CST fallback map',
                    child: Material(
                      key: const ValueKey('cst-fallback-map-badge'),
                      color: Colors.white.withValues(alpha: .94),
                      elevation: 3,
                      borderRadius: BorderRadius.circular(16),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.school_rounded,
                                size: 19,
                                color: AppStyle.darkGreen,
                              ),
                              SizedBox(width: 7),
                              Flexible(
                                child: Text(
                                  'CST fallback map',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppStyle.ink,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              right: 14,
              top: 14,
              child: PointerInterceptor(
                child: Material(
                  color: Colors.white,
                  elevation: 3,
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Center on my location',
                        color: AppStyle.green,
                        onPressed: widget.locating ? null : widget.onLocate,
                        icon: const Icon(Icons.my_location),
                      ),
                      IconButton(
                        tooltip: 'Zoom in',
                        color: AppStyle.green,
                        onPressed: () => _move(CameraUpdate.zoomIn()),
                        icon: const Icon(Icons.add),
                      ),
                      IconButton(
                        tooltip: 'Zoom out',
                        color: AppStyle.green,
                        onPressed: () => _move(CameraUpdate.zoomOut()),
                        icon: const Icon(Icons.remove),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Keep browser platform views from swallowing modal barrier taps.
            if (widget.interactionBlocked)
              Positioned.fill(
                child: PointerInterceptor(child: const SizedBox.expand()),
              ),
          ],
        );
      },
    );
  }
}

const _mapStyle = '''[
  {"featureType":"poi","elementType":"labels","stylers":[{"visibility":"off"}]},
  {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#f4f6ef"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#dfeecf"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#c7e3e7"}]}
]''';
