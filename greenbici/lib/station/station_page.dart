import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:url_launcher/url_launcher.dart';

import '../navbar/top_nav.dart';
import '../demo/demo_data.dart';
import '../theme/app_style.dart';
import 'models/bicycle_station.dart';
import 'services/location_service.dart';
import 'services/station_repository.dart';
import 'station_controller.dart';
import 'widgets/station_details.dart';
import 'widgets/station_map.dart';
import 'widgets/station_message.dart';

typedef StationMapBuilder = Widget Function(
  BuildContext context,
  StationMap map,
);

/// Tab content; AppShell supplies the shared bottom navigation and scaffold.
class StationPage extends StatefulWidget {
  const StationPage({super.key, this.controller, this.mapBuilder});

  final StationController? controller;
  final StationMapBuilder? mapBuilder;

  @override
  State<StationPage> createState() => _StationPageState();
}

class _StationPageState extends State<StationPage> with WidgetsBindingObserver {
  late final StationController _controller;
  OverpassStationRepository? _ownedRepository;
  final _search = TextEditingController();
  bool _searchOpen = false;
  bool _choosingStation = false;
  bool _returningFromSettings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller =
        widget.controller ??
        StationController(
          locationService: DeviceLocationService(),
          repository: _ownedRepository = OverpassStationRepository(),
          fallbackLocation: DemoData.focus,
          fallbackStations: DemoData.stations,
        );
    _search.text = _controller.query;
    unawaited(_controller.locate());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        TickerMode.valuesOf(context).enabled) {
      // Recheck permission after settings/foregrounding without prompting again.
      if (_returningFromSettings || _controller.location != null) {
        _returningFromSettings = false;
        unawaited(_controller.locate(requestPermission: false));
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _search.dispose();
    if (widget.controller == null) _controller.dispose();
    _ownedRepository?.dispose();
    super.dispose();
  }

  Future<void> _openSettings({bool location = false}) async {
    _returningFromSettings = true;
    try {
      final opened = location
          ? await _controller.locationService.openLocationSettings()
          : await _controller.locationService.openAppSettings();
      if (!opened && mounted) {
        _showMessage(
          'Open your device settings to enable location, then try again.',
        );
      }
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Open your device settings to enable location, then try again.',
        );
      }
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _openLink(Uri uri) async {
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
          mounted) {
        _showMessage('Could not open the link. Please try again.');
      }
    } catch (_) {
      if (mounted) _showMessage('Could not open the link. Please try again.');
    }
  }

  void _directions(BicycleStation station) => unawaited(
    _openLink(
      Uri.https('www.google.com', '/maps/dir/', {
        'api': '1',
        'destination': '${station.latitude},${station.longitude}',
        'travelmode': 'walking',
        if (_controller.location case final location?)
          'origin': '${location.latitude},${location.longitude}',
      }),
    ),
  );

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => LayoutBuilder(
        builder: (context, bounds) {
          final accessible = MediaQuery.textScalerOf(context).scale(14) > 21;
          final scrollLayout = bounds.maxHeight < 540 || accessible;
          final header = Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: bounds.maxWidth < 360 ? 14 : 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TopNav(
                      title: 'Nearby Stations',
                      subtitle: _controller.location != null
                          ? (_controller.usingFallback
                                ? 'Fallback map · ${DemoData.focusLabel}'
                                : 'Current location')
                          : _controller.locating
                          ? 'Finding your location'
                          : 'Location unavailable',
                      subtitleIcon: Icons.location_on,
                      statusColor: _controller.location == null
                          ? AppStyle.muted
                          : AppStyle.green,
                      onSearch: () =>
                          setState(() => _searchOpen = !_searchOpen),
                      searchController: _searchOpen ? _search : null,
                      onSearchChanged: _controller.search,
                    ),
                  ],
                ),
              ),
            ),
          );
          if (scrollLayout) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  header,
                  SizedBox(height: 300, child: _mapOrLocationMessage(0)),
                  if (_controller.location != null)
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: _results(),
                      ),
                    ),
                  if (_controller.location != null) _attribution(),
                ],
              ),
            );
          }
          return Column(
            children: [
              header,
              Expanded(
                child: _controller.location == null
                    ? _mapOrLocationMessage(0)
                    : LayoutBuilder(
                        builder: (context, contentBounds) {
                          if (contentBounds.maxWidth >= 850) {
                            return Row(
                              children: [
                                Expanded(child: _mapOrLocationMessage(0)),
                                SizedBox(
                                  width: 350,
                                  child: SingleChildScrollView(
                                    child: _results(),
                                  ),
                                ),
                              ],
                            );
                          }
                          final panelHeight = math.min(
                            310.0,
                            contentBounds.maxHeight * .48,
                          );
                          return Stack(
                            children: [
                              Positioned.fill(
                                child: _mapOrLocationMessage(panelHeight + 20),
                              ),
                              Positioned(
                                left: 14,
                                right: 14,
                                bottom: 12,
                                height: panelHeight,
                                child: PointerInterceptor(
                                  child: Material(
                                    elevation: 6,
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    clipBehavior: Clip.antiAlias,
                                    child: SingleChildScrollView(
                                      child: _results(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
              if (_controller.location != null) _attribution(),
            ],
          );
        },
      ),
    ),
  );

  Widget _mapOrLocationMessage(double bottomPadding) {
    final location = _controller.location;
    if (location != null) {
      final map = StationMap(
        location: location,
        stations: _controller.stations,
        selectedStation: _controller.selectedStation,
        onSelected: _controller.select,
        onLocate: () => _controller.locate(),
        locating: _controller.busy,
        cameraRevision: _controller.cameraRevision,
        bottomPadding: bottomPadding,
        interactionBlocked: _choosingStation,
      );
      return widget.mapBuilder?.call(context, map) ?? map;
    }
    if (_controller.locating) {
      return const StationMessage(
        title: 'Finding your location',
        message: 'Allow location access to find bicycle stations nearby.',
        loading: true,
      );
    }
    final failure = _controller.locationFailure?.kind;
    final (title, message, label) = switch (failure) {
      LocationFailureKind.denied => (
        'Location access is off',
        'Allow location access to find stations near you.',
        'Try again',
      ),
      LocationFailureKind.deniedForever => (
        'Location permission is blocked',
        kIsWeb
            ? 'Enable location in your browser site settings, then try again.'
            : 'Enable location access for GreenBici in your device settings.',
        kIsWeb ? 'Try again' : 'Open settings',
      ),
      LocationFailureKind.serviceDisabled => (
        'Location services are off',
        'Turn on your device location services to find nearby stations.',
        kIsWeb ? 'Try again' : 'Location settings',
      ),
      LocationFailureKind.timedOut => (
        'Location took too long',
        'Move to a place with a clearer GPS signal and try again.',
        'Try again',
      ),
      _ => (
        'Location unavailable',
        'Check your device or browser location settings and try again.',
        'Try again',
      ),
    };
    return StationMessage(
      title: title,
      message: message,
      actionLabel: label,
      onAction: () {
        if (!kIsWeb && failure == LocationFailureKind.deniedForever) {
          unawaited(_openSettings());
        } else if (!kIsWeb && failure == LocationFailureKind.serviceDisabled) {
          unawaited(_openSettings(location: true));
        } else {
          unawaited(_controller.locate());
        }
      },
    );
  }

  Widget _results() {
    final station = _controller.selectedStation;
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_controller.busy)
            const StationMessage(
              title: 'Finding nearby stations',
              message: '',
              loading: true,
            )
          else if (_controller.stationLoadFailed)
            StationMessage(
              title: 'Stations could not load',
              message: 'Check your connection and try again.',
              actionLabel: 'Retry stations',
              onAction: _controller.refreshStations,
            )
          else if (station == null)
            StationMessage(
              title: _controller.query.trim().isEmpty
                  ? 'No stations nearby'
                  : 'No matching stations',
              message: _controller.query.trim().isEmpty
                  ? 'No bicycle-rental stations were found within 5 km. Coverage varies by area.'
                  : 'Try another name or clear your search.',
              actionLabel: _controller.query.trim().isEmpty
                  ? 'Refresh stations'
                  : 'Clear search',
              onAction: () {
                if (_controller.query.trim().isEmpty) {
                  unawaited(_controller.refreshStations());
                } else {
                  _search.clear();
                  _controller.search('');
                }
              },
            )
          else ...[
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton(
                  onPressed: _chooseStation,
                  child: Text(
                    '${_controller.stations.length} nearby · Change station',
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh stations',
                  onPressed: _controller.refreshStations,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            StationDetails(
              station: station,
              userLocation: _controller.location!,
              onDirections: () => _directions(station),
            ),
          ],
        ],
      ),
    );
  }

  Widget _attribution() => TextButton(
    onPressed: () =>
        _openLink(Uri.https('www.openstreetmap.org', '/copyright')),
    child: const Text(
      'Station data © OpenStreetMap contributors',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 11),
    ),
  );

  Future<void> _chooseStation() async {
    final stations = _controller.stations;
    final location = _controller.location!;
    setState(() => _choosingStation = true);
    final station = await showModalBottomSheet<BicycleStation>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxWidth: 680,
        maxHeight: MediaQuery.sizeOf(context).height * .8,
      ),
      builder: (context) => PointerInterceptor(
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 20),
          itemCount: stations.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final station = stations[index];
            return ListTile(
              leading: const Icon(Icons.pedal_bike, color: AppStyle.green),
              title: Text(station.name),
              subtitle: Text(
                stationDistance(location.distanceTo(station.location)),
              ),
              selected: station.id == _controller.selectedStation?.id,
              onTap: () => Navigator.pop(context, station),
            );
          },
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _choosingStation = false);
    if (station != null) _controller.select(station);
  }
}
