import 'package:flutter/material.dart';

import '../navbar/top_nav.dart';
import 'widgets/about_banner.dart';
import 'widgets/hero_slider.dart';
import 'widgets/offers_section.dart';
import 'widgets/pass_banner.dart';
import 'widgets/quick_actions.dart';
import 'widgets/recent_rides_section.dart';
import 'widgets/scroll_reveal.dart';
import 'widgets/stations_section.dart';

/// Dashboard content hosted by the shared application shell.
/// The reference cards use local sample data until services are connected.
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.displayName = 'Alex',
    this.scrollToTopRevision = 0,
    required this.onNavigate,
    this.onSearch,
  });

  final String displayName;
  final int scrollToTopRevision;
  final ValueChanged<int> onNavigate;
  final VoidCallback? onSearch;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollToTopRevision == widget.scrollToTopRevision ||
        !_scrollController.hasClients) {
      return;
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _scrollController.jumpTo(0);
    } else {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _previewMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _startRide() => widget.onNavigate(2);

  Widget _section(Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: ScrollReveal(controller: _scrollController, child: child),
  );

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        key: const PageStorageKey('home-scroll'),
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
                  TopNav(
                    displayName: widget.displayName,
                    onSearch: widget.onSearch ?? () => widget.onNavigate(1),
                  ),
                  _section(HeroSlider(onStartRide: _startRide)),
                  _section(
                    QuickActions(
                      onFindStation: () => widget.onNavigate(1),
                      onStartRide: _startRide,
                      onMyRides: () => widget.onNavigate(2),
                    ),
                  ),
                  _section(const AboutBanner()),
                  _section(
                    StationsSection(
                      onViewAll: () => widget.onNavigate(1),
                      onStationTap: (name) => _previewMessage(
                        '$name: live availability is not connected yet.',
                      ),
                    ),
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
                      onViewAll: () =>
                          _previewMessage('All sample offers are shown below.'),
                      onOfferTap: (name) =>
                          _previewMessage('$name is a sample offer.'),
                    ),
                  ),
                  _section(
                    RecentRidesSection(
                      onViewAll: () => widget.onNavigate(2),
                      onRideTap: (name) =>
                          _previewMessage('$name is a sample ride.'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
