import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../../theme/app_style.dart';
import '../../demo/demo_data.dart';
import '../models/bicycle_station.dart';
import '../models/geo_point.dart';
import '../services/mapbox_configuration.dart';
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
    this.centerLabel,
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
  final String? centerLabel;

  @override
  State<StationMap> createState() => _StationMapState();
}

class _StationMapState extends State<StationMap> {
  final ViewportController _viewportController = ViewportController();
  MapboxMap? _map;
  PointAnnotationManager? _pointAnnotations;
  Cancelable? _annotationTaps;
  late Future<void> _ready;
  Uint8List? _pin;
  Uint8List? _selectedPin;
  Timer? _mapLoadTimeout;
  final Map<String, BicycleStation> _stationByAnnotationId = {};
  int _annotationRevision = 0;
  bool _liveMapFailed = false;

  @override
  void initState() {
    super.initState();
    _ready = _prepare();
  }

  Future<void> _prepare() async {
    if (!MapboxConfiguration.isSupported || !MapboxConfiguration.isConfigured) {
      return;
    }
    MapboxConfiguration.prepare();
    final pins = await Future.wait([
      createStationMarker(selected: false),
      createStationMarker(selected: true),
    ]);
    if (!mounted) return;
    _pin = pins[0];
    _selectedPin = pins[1];
  }

  @override
  void didUpdateWidget(covariant StationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cameraRevision != widget.cameraRevision ||
        oldWidget.isFallback != widget.isFallback) {
      _move(widget.location, zoom: _locationZoom);
    } else if (oldWidget.selectedStation?.id != widget.selectedStation?.id &&
        widget.selectedStation != null) {
      _move(widget.selectedStation!.location);
    }
    if (oldWidget.stations != widget.stations ||
        oldWidget.selectedStation?.id != widget.selectedStation?.id ||
        oldWidget.isFallback != widget.isFallback) {
      unawaited(_syncMarkers());
    }
  }

  Point _coordinates(GeoPoint point) =>
      Point(coordinates: Position(point.longitude, point.latitude));

  double get _locationZoom => widget.isFallback ? 17 : 15;

  void _move(GeoPoint location, {double? zoom}) {
    if (!mounted) return;
    _viewportController.moveTo(
      CameraViewportState(
        center: _coordinates(location),
        zoom: zoom,
        padding: EdgeInsets.only(bottom: widget.bottomPadding, right: 8),
      ),
      transition: MediaQuery.disableAnimationsOf(context)
          ? null
          : const DefaultViewportTransition(),
    );
  }

  Future<void> _zoomBy(double change) async {
    final map = _map;
    if (map == null) return;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    try {
      final camera = await map.getCameraState();
      await map.easeTo(
        CameraOptions(
          center: camera.center,
          zoom: (camera.zoom + change).clamp(2, 20).toDouble(),
          bearing: camera.bearing,
          pitch: camera.pitch,
        ),
        MapAnimationOptions(duration: disableAnimations ? 0 : 250),
      );
    } catch (_) {
      // The platform map may finish disposal while a camera command is active.
    }
  }

  Future<void> _onMapCreated(MapboxMap map) async {
    if (!mounted) return;
    _map = map;
    _mapLoadTimeout?.cancel();
    _mapLoadTimeout = Timer(
      const Duration(seconds: 20),
      () => _useOfflineFallback('Mapbox timed out while loading.'),
    );
    _move(widget.location, zoom: _locationZoom);

    // Annotation managers are currently a native-only Mapbox API.
    if (kIsWeb) return;
    try {
      final manager = await map.annotations.createPointAnnotationManager();
      if (!mounted || !identical(_map, map)) return;
      _pointAnnotations = manager;
      await manager.setIconAllowOverlap(true);
      _annotationTaps = manager.tapEvents(
        onTap: (annotation) {
          final station = _stationByAnnotationId[annotation.id];
          if (station != null) widget.onSelected(station);
        },
      );
      await _syncMarkers();
    } catch (error) {
      debugPrint('Mapbox station markers could not be created: $error');
    }
  }

  Future<void> _syncMarkers() async {
    final manager = _pointAnnotations;
    final pin = _pin;
    final selectedPin = _selectedPin;
    if (manager == null || pin == null || selectedPin == null) return;

    final revision = ++_annotationRevision;
    try {
      await manager.deleteAll();
      if (!mounted || revision != _annotationRevision) return;
      _stationByAnnotationId.clear();

      for (final station in widget.stations) {
        if (!mounted || revision != _annotationRevision) return;
        final selected = station.id == widget.selectedStation?.id;
        final annotation = await manager.create(
          PointAnnotationOptions(
            geometry: _coordinates(station.location),
            image: selected ? selectedPin : pin,
            iconAnchor: IconAnchor.BOTTOM,
            iconSize: .34,
            symbolSortKey: selected ? 2 : 1,
          ),
        );
        _stationByAnnotationId[annotation.id] = station;
      }

      if (widget.isFallback &&
          !widget.stations.any(
            (station) => station.location == widget.location,
          )) {
        await manager.create(
          PointAnnotationOptions(
            geometry: _coordinates(widget.location),
            image: selectedPin,
            iconAnchor: IconAnchor.BOTTOM,
            iconSize: .34,
            symbolSortKey: 3,
          ),
        );
      }
    } catch (error) {
      debugPrint('Mapbox station markers could not be updated: $error');
    }
  }

  void _mapLoaded() {
    _mapLoadTimeout?.cancel();
    _mapLoadTimeout = null;
  }

  void _useOfflineFallback(String reason) {
    if (!mounted || _liveMapFailed) return;
    debugPrint('$reason Showing the CST fallback map.');
    _mapLoadTimeout?.cancel();
    _annotationTaps?.cancel();
    setState(() {
      _map = null;
      _pointAnnotations = null;
      _annotationTaps = null;
      _liveMapFailed = true;
    });
  }

  @override
  void dispose() {
    _mapLoadTimeout?.cancel();
    _annotationTaps?.cancel();
    _viewportController.dispose();
    _map = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!MapboxConfiguration.isSupported ||
        !MapboxConfiguration.isConfigured ||
        _liveMapFailed) {
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
              child: MapWidget(
                styleUri: MapboxStyles.MAPBOX_STREETS,
                viewport: CameraViewportState(
                  center: _coordinates(widget.location),
                  zoom: _locationZoom,
                  padding: EdgeInsets.only(
                    bottom: widget.bottomPadding,
                    right: 8,
                  ),
                ),
                viewportController: _viewportController,
                onMapCreated: _onMapCreated,
                onMapLoadedListener: (_) => _mapLoaded(),
                onMapLoadErrorListener: (_) =>
                    _useOfflineFallback('Mapbox reported a loading error.'),
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
                        onPressed: () => unawaited(_zoomBy(1)),
                        icon: const Icon(Icons.add),
                      ),
                      IconButton(
                        tooltip: 'Zoom out',
                        color: AppStyle.green,
                        onPressed: () => unawaited(_zoomBy(-1)),
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
      center: widget.centerLabel == null ? DemoData.focus : widget.location,
      centerLabel: widget.centerLabel,
      stations: widget.centerLabel != null
          ? widget.stations
          : widget.isFallback && widget.stations.isNotEmpty
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
    required this.center,
    required this.centerLabel,
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
  final GeoPoint center;
  final String? centerLabel;
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    child: SizedBox(
                      width: 226,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            centerLabel ?? 'College of Science and Technology',
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppStyle.ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (centerLabel == null)
                            const Text(
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
            Positioned(
              left: 14,
              top: 14,
              child: _CstFallbackBadge(
                label: centerLabel == null
                    ? 'CST fallback map'
                    : 'Searched location',
              ),
            ),
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
        (station.location.longitude - center.longitude) * scale -
        20;
    final rawTop =
        height * .48 -
        (station.location.latitude - center.latitude) * scale -
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
  const _CstFallbackBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Material(
        key: const ValueKey('cst-fallback-map-badge'),
        color: Colors.white.withValues(alpha: .94),
        elevation: 3,
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 150),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.school_rounded,
                  size: 19,
                  color: AppStyle.darkGreen,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
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
