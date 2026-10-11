import 'package:flutter/material.dart';

import 'home_style.dart';
import 'widgets/about_banner.dart';
import 'widgets/hero_slider.dart';
import 'widgets/home_header.dart';
import 'widgets/home_navigation.dart';
import 'widgets/offers_section.dart';
import 'widgets/pass_banner.dart';
import 'widgets/quick_actions.dart';
import 'widgets/recent_rides_section.dart';
import 'widgets/scroll_reveal.dart';
import 'widgets/stations_section.dart';

/// The reference dashboard uses local sample data until services are connected.
class HomePage extends StatefulWidget {
  const HomePage({super.key, this.displayName = 'Alex'});

  final String displayName;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scrollController = ScrollController();
  final _stationsKey = GlobalKey();
  final _ridesKey = GlobalKey();
  int _selectedIndex = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Duration get _scrollDuration => MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : const Duration(milliseconds: 650);

  void _scrollTo(GlobalKey key, int navigationIndex) {
    setState(() => _selectedIndex = navigationIndex);
    final sectionContext = key.currentContext;
    if (sectionContext != null) {
      Scrollable.ensureVisible(
        sectionContext,
        duration: _scrollDuration,
        curve: Curves.easeInOutCubic,
        alignment: .04,
      );
    }
  }

  void _previewMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _startRide() => _previewMessage('Bike unlocking is not connected yet.');

  void _selectNavigation(int index) {
    switch (index) {
      case 0:
        setState(() => _selectedIndex = 0);
        if (_scrollDuration == Duration.zero) {
          _scrollController.jumpTo(0);
        } else {
          _scrollController.animateTo(
            0,
            duration: _scrollDuration,
            curve: Curves.easeInOutCubic,
          );
        }
      case 1:
        _scrollTo(_stationsKey, 1);
      case 2:
        _scrollTo(_ridesKey, 2);
      case 3:
        _previewMessage('Notifications are not connected yet.');
      case 4:
        _previewMessage('Profile is not connected yet.');
    }
  }

  Widget _section(Widget child, {Key? key}) => Padding(
    key: key,
    padding: const EdgeInsets.only(bottom: 24),
    child: ScrollReveal(controller: _scrollController, child: child),
  );

  @override
  Widget build(BuildContext context) => Theme(
    data: HomeStyle.theme,
    child: Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            controller: _scrollController,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth < 360 ? 14 : 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      HomeHeader(
                        displayName: widget.displayName,
                        onSearch: () => _previewMessage(
                          'Station search is not connected yet.',
                        ),
                      ),
                      _section(HeroSlider(onStartRide: _startRide)),
                      _section(
                        QuickActions(
                          onFindStation: () => _scrollTo(_stationsKey, 1),
                          onStartRide: _startRide,
                          onMyRides: () => _scrollTo(_ridesKey, 2),
                        ),
                      ),
                      _section(const AboutBanner()),
                      _section(
                        StationsSection(
                          onViewAll: () => _previewMessage(
                            'All sample stations are shown below.',
                          ),
                          onStationTap: (name) => _previewMessage(
                            '$name: live availability is not connected yet.',
                          ),
                        ),
                        key: _stationsKey,
                      ),
                      _section(
                        PassBanner(
                          onManagePlan: () => _previewMessage(
                            'Plan management is not connected yet.',
                          ),
                        ),
                      ),
                      _section(
                        OffersSection(
                          onViewAll: () => _previewMessage(
                            'All sample offers are shown below.',
                          ),
                          onOfferTap: (name) =>
                              _previewMessage('$name is a sample offer.'),
                        ),
                      ),
                      _section(
                        RecentRidesSection(
                          onViewAll: () => _previewMessage(
                            'Your five sample rides are shown below.',
                          ),
                          onRideTap: (name) =>
                              _previewMessage('$name is a sample ride.'),
                        ),
                        key: _ridesKey,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: HomeNavigation(
        selectedIndex: _selectedIndex,
        onSelected: _selectNavigation,
      ),
    ),
  );
}
