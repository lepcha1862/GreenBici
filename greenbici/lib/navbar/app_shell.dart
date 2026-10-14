import 'package:flutter/material.dart';

import '../home/home_page.dart';
import '../notifications/notification_page.dart';
import '../profile/profile_page.dart';
import '../ride/ride_page.dart';
import '../station/models/bicycle_station.dart';
import '../station/station_page.dart';
import '../theme/app_style.dart';
import 'bottom_nav.dart';

/// Owns navigation and the common light theme for all signed-in screens.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    this.displayName = 'Alex',
    this.profileImage,
    this.stationBuilder,
  });

  final String displayName;
  final ImageProvider<Object>? profileImage;

  /// Allows an alternate Station implementation, including platform-free tests.
  final WidgetBuilder? stationBuilder;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  int _homeScrollToTopRevision = 0;
  int _stationSearchRevision = 0;
  bool _stationVisited = false;
  String? _rideStationName;

  void _selectNavigation(int index) {
    if (index == _selectedIndex) {
      if (index == 0) setState(() => _homeScrollToTopRevision++);
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() {
      _selectedIndex = index;
      _stationVisited = _stationVisited || index == 1;
    });
  }

  void _searchLocations() {
    FocusManager.instance.primaryFocus?.unfocus();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() {
      _selectedIndex = 1;
      _stationVisited = true;
      _stationSearchRevision++;
    });
  }

  void _rideInStation(BicycleStation station) {
    FocusManager.instance.primaryFocus?.unfocus();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() {
      _rideStationName = station.name;
      _selectedIndex = 2;
    });
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: AppStyle.theme,
    child: Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          TickerMode(
            enabled: _selectedIndex == 0,
            child: HomePage(
              displayName: widget.displayName,
              scrollToTopRevision: _homeScrollToTopRevision,
              onNavigate: _selectNavigation,
              onSearch: _searchLocations,
            ),
          ),
          TickerMode(
            enabled: _selectedIndex == 1,
            // Keep GPS permission prompts deferred until Stations is opened.
            // Once visited, keep the map and selected station intact.
            child: _stationVisited
                ? widget.stationBuilder?.call(context) ??
                      StationPage(
                        searchRevision: _stationSearchRevision,
                        onRideInStation: _rideInStation,
                      )
                : const SizedBox.shrink(),
          ),
          TickerMode(
            enabled: _selectedIndex == 2,
            child: RidePage(
              onSearch: _searchLocations,
              stationName: _rideStationName,
            ),
          ),
          TickerMode(
            enabled: _selectedIndex == 3,
            child: KeyedSubtree(
              key: const ValueKey('notifications-placeholder'),
              child: NotificationPage(onSearch: _searchLocations),
            ),
          ),
          TickerMode(
            enabled: _selectedIndex == 4,
            child: KeyedSubtree(
              key: const ValueKey('profile-placeholder'),
              child: ProfilePage(
                displayName: widget.displayName,
                profileImage: widget.profileImage,
                onSearch: _searchLocations,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNav(
        selectedIndex: _selectedIndex,
        onSelected: _selectNavigation,
      ),
    ),
  );
}
