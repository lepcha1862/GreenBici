import 'package:flutter/material.dart';

import '../home/home_page.dart';
import '../notifications/notification_page.dart';
import '../profile/profile_page.dart';
import '../ride/ride_page.dart';
import '../station/station_page.dart';
import '../theme/app_style.dart';
import 'bottom_nav.dart';

/// Owns navigation and the common light theme for all signed-in screens.
class AppShell extends StatefulWidget {
  const AppShell({super.key, this.displayName = 'Alex', this.stationBuilder});

  final String displayName;

  /// Allows an alternate Station implementation, including platform-free tests.
  final WidgetBuilder? stationBuilder;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  int _homeScrollToTopRevision = 0;
  bool _stationVisited = false;

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
            ),
          ),
          TickerMode(
            enabled: _selectedIndex == 1,
            // Keep GPS permission prompts deferred until Stations is opened.
            // Once visited, keep the map, selected station, and search intact.
            child: _stationVisited
                ? widget.stationBuilder?.call(context) ?? const StationPage()
                : const SizedBox.shrink(),
          ),
          TickerMode(enabled: _selectedIndex == 2, child: const RidePage()),
          TickerMode(
            enabled: _selectedIndex == 3,
            child: const KeyedSubtree(
              key: ValueKey('notifications-placeholder'),
              child: NotificationPage(),
            ),
          ),
          TickerMode(
            enabled: _selectedIndex == 4,
            child: ProfilePage(displayName: widget.displayName),
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
