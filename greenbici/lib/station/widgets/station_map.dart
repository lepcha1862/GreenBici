import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../../theme/app_style.dart';
import '../../demo/demo_data.dart';
import '../models/bicycle_station.dart';
import '../models/geo_point.dart';
import '../services/maps_configuration.dart';
import 'station_marker.dart';

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
    this.showLocationPrompt = false,
    this.locationPromptMessage =
        'Grant location permission to show stations near you.',
    this.locationPromptActionLabel = 'Grant location access',
    this.onLocationPrompt,
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
  final bool showLocationPrompt;
  final String locationPromptMessage;
  final String locationPromptActionLabel;
  final VoidCallback? onLocationPrompt;

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
      return _offlineFallbackMap();
    }
    return FutureBuilder<void>(
      future: _ready,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _offlineFallbackMap();
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return _offlineFallbackMap(loadingLiveMap: true);
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
                myLocationEnabled: !kIsWeb && !widget.showLocationPrompt,
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
            if (widget.showLocationPrompt && widget.onLocationPrompt != null)
              _LocationPermissionPrompt(
                bottomPadding: widget.bottomPadding,
                message: widget.locationPromptMessage,
                actionLabel: widget.locationPromptActionLabel,
                onAction: widget.onLocationPrompt!,
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

  Widget _offlineFallbackMap({bool loadingLiveMap = false}) {
    return _CstOfflineMap(
      bottomPadding: widget.bottomPadding,
      locating: widget.locating,
      interactionBlocked: widget.interactionBlocked,
      loadingLiveMap: loadingLiveMap,
      stations: widget.isFallback && widget.stations.isNotEmpty
          ? widget.stations
          : DemoData.stations,
      selectedStation: widget.selectedStation,
      onSelected: widget.onSelected,
      onLocate: widget.onLocate,
      showLocationPrompt: widget.showLocationPrompt,
      locationPromptMessage: widget.locationPromptMessage,
      locationPromptActionLabel: widget.locationPromptActionLabel,
      onLocationPrompt: widget.onLocationPrompt,
    );
  }
}

class _CstOfflineMap extends StatelessWidget {
  const _CstOfflineMap({
    required this.bottomPadding,
    required this.locating,
    required this.interactionBlocked,
    required this.loadingLiveMap,
    required this.stations,
    required this.selectedStation,
    required this.onSelected,
    required this.onLocate,
    required this.showLocationPrompt,
    required this.locationPromptMessage,
    required this.locationPromptActionLabel,
    required this.onLocationPrompt,
  });

  final double bottomPadding;
  final bool locating;
  final bool interactionBlocked;
  final bool loadingLiveMap;
  final List<BicycleStation> stations;
  final BicycleStation? selectedStation;
  final ValueChanged<BicycleStation> onSelected;
  final VoidCallback onLocate;
  final bool showLocationPrompt;
  final String locationPromptMessage;
  final String locationPromptActionLabel;
  final VoidCallback? onLocationPrompt;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        return Stack(
          key: const ValueKey('cst-offline-fallback-map'),
          children: [
            const Positioned.fill(
              child: CustomPaint(painter: _CstMapPainter()),
            ),
            Positioned(
              left: math.max(14, width * .5 - 122),
              top: math.max(88, height * .48 + 24),
              child: IgnorePointer(
                child: Material(
                  color: Colors.white.withValues(alpha: .92),
                  borderRadius: BorderRadius.circular(10),
                  elevation: 1,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                    child: SizedBox(
                      width: 226,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'College of Science and Technology',
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppStyle.ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Rinchending, Phuentsholing, Bhutan',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppStyle.muted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            for (final station in stations)
              _stationMarker(station, width, height),
            const Positioned(left: 14, top: 14, child: _CstFallbackBadge()),
            if (loadingLiveMap)
              Positioned(
                left: 14,
                top: 68,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: math.max(100, width - 28),
                  ),
                  child: Material(
                    color: Colors.white.withValues(alpha: .92),
                    borderRadius: BorderRadius.circular(14),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox.square(
                            dimension: 13,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppStyle.green,
                            ),
                          ),
                          SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              'Connecting to live map…',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppStyle.ink,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              right: 14,
              top: 14,
              child: Material(
                color: Colors.white,
                elevation: 3,
                borderRadius: BorderRadius.circular(16),
                child: IconButton(
                  tooltip: 'Center on my location',
                  color: AppStyle.green,
                  onPressed: locating ? null : onLocate,
                  icon: const Icon(Icons.my_location),
                ),
              ),
            ),
            if (showLocationPrompt && onLocationPrompt != null)
              _LocationPermissionPrompt(
                bottomPadding: bottomPadding,
                message: locationPromptMessage,
                actionLabel: locationPromptActionLabel,
                onAction: onLocationPrompt!,
              ),
            if (interactionBlocked)
              Positioned.fill(
                child: PointerInterceptor(child: const SizedBox.expand()),
              ),
          ],
        );
      },
    );
  }

  Widget _stationMarker(BicycleStation station, double width, double height) {
    const scale = 48000.0;
    final rawLeft =
        width * .5 +
        (station.location.longitude - DemoData.focus.longitude) * scale -
        20;
    final rawTop =
        height * .48 -
        (station.location.latitude - DemoData.focus.latitude) * scale -
        42;
    final left = rawLeft.clamp(4.0, math.max(4.0, width - 44)).toDouble();
    final top = rawTop
        .clamp(58.0, math.max(58.0, height - bottomPadding - 52))
        .toDouble();
    final selected = station.id == selectedStation?.id;
    return Positioned(
      left: left,
      top: top,
      child: Semantics(
        button: true,
        label: '${station.name}, ${station.bikesAvailable} bikes available',
        child: Tooltip(
          message: station.name,
          child: InkResponse(
            onTap: () => onSelected(station),
            radius: 24,
            child: Icon(
              Icons.location_on_rounded,
              size: selected ? 44 : 40,
              color: selected ? AppStyle.blue : AppStyle.darkGreen,
              shadows: const [Shadow(color: Color(0x66000000), blurRadius: 4)],
            ),
          ),
        ),
      ),
    );
  }
}

class _CstFallbackBadge extends StatelessWidget {
  const _CstFallbackBadge();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'CST fallback map',
      child: Material(
        key: const ValueKey('cst-fallback-map-badge'),
        color: Colors.white.withValues(alpha: .94),
        elevation: 3,
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 150),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.school_rounded, size: 19, color: AppStyle.darkGreen),
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
    );
  }
}

class _LocationPermissionPrompt extends StatelessWidget {
  const _LocationPermissionPrompt({
    required this.bottomPadding,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final double bottomPadding;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 14,
      right: 14,
      bottom: bottomPadding + 14,
      child: PointerInterceptor(
        child: Material(
          key: const ValueKey('location-permission-prompt'),
          color: Colors.white.withValues(alpha: .97),
          elevation: 5,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_off_outlined,
                      color: AppStyle.darkGreen,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        message,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppStyle.ink,
                          fontSize: 12,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onAction,
                    child: Text(actionLabel),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CstMapPainter extends CustomPainter {
  const _CstMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFEAF3E5),
    );

    final river = Path()
      ..moveTo(-20, size.height * .78)
      ..cubicTo(
        size.width * .22,
        size.height * .64,
        size.width * .35,
        size.height * .92,
        size.width * .58,
        size.height * .8,
      )
      ..cubicTo(
        size.width * .78,
        size.height * .69,
        size.width * .87,
        size.height * .84,
        size.width + 20,
        size.height * .7,
      );
    canvas.drawPath(
      river,
      Paint()
        ..color = const Color(0xFFB9DFE8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(26, size.shortestSide * .1)
        ..strokeCap = StrokeCap.round,
    );

    final roadPaint = Paint()
      ..color = const Color(0xFFFDFDFB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round;
    final roadEdgePaint = Paint()
      ..color = const Color(0xFFD8DDD2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;
    final mainRoad = Path()
      ..moveTo(-10, size.height * .55)
      ..cubicTo(
        size.width * .24,
        size.height * .36,
        size.width * .52,
        size.height * .58,
        size.width + 10,
        size.height * .3,
      );
    final crossRoad = Path()
      ..moveTo(size.width * .35, -10)
      ..cubicTo(
        size.width * .47,
        size.height * .27,
        size.width * .4,
        size.height * .55,
        size.width * .63,
        size.height + 10,
      );
    for (final road in [mainRoad, crossRoad]) {
      canvas
        ..drawPath(road, roadEdgePaint)
        ..drawPath(road, roadPaint);
    }

    final buildingPaint = Paint()..color = const Color(0xFFD9D5C8);
    final buildingRoofPaint = Paint()..color = const Color(0xFFC7BCA8);
    final buildings = <Rect>[
      Rect.fromLTWH(size.width * .12, size.height * .17, 62, 32),
      Rect.fromLTWH(size.width * .57, size.height * .16, 76, 36),
      Rect.fromLTWH(size.width * .62, size.height * .5, 58, 30),
      Rect.fromLTWH(size.width * .2, size.height * .59, 72, 34),
    ];
    for (final building in buildings) {
      final radius = Radius.circular(math.min(7, building.shortestSide * .2));
      canvas.drawRRect(
        RRect.fromRectAndRadius(building.shift(const Offset(3, 4)), radius),
        buildingPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(building, radius),
        buildingRoofPaint,
      );
    }

    final campus = Rect.fromCenter(
      center: Offset(size.width * .5, size.height * .48),
      width: math.min(190, size.width * .5),
      height: math.min(110, size.height * .28),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(campus, const Radius.circular(20)),
      Paint()
        ..color = AppStyle.green.withValues(alpha: .12)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(campus, const Radius.circular(20)),
      Paint()
        ..color = AppStyle.darkGreen.withValues(alpha: .45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _CstMapPainter oldDelegate) => false;
}

const _mapStyle = '''[
  {"featureType":"poi","elementType":"labels","stylers":[{"visibility":"off"}]},
  {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#f4f6ef"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#dfeecf"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#c7e3e7"}]}
]''';
