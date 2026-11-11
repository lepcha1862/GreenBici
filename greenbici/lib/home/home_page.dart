import 'package:flutter/material.dart';

import '../navbar/top_nav.dart';
import '../plans/pricing_plans.dart';
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
    this.plansDismissRevision = 0,
    required this.onNavigate,
    this.onSearch,
  });

  final String displayName;
  final int scrollToTopRevision;

  /// Increments when shell navigation should leave the pricing list.
  final int plansDismissRevision;
  final ValueChanged<int> onNavigate;
  final VoidCallback? onSearch;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scrollController = ScrollController();
  bool _showingPlans = false;
  double _savedOffset = 0;
  int _plansGeneration = 0;

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final dismissPlans =
        widget.plansDismissRevision != oldWidget.plansDismissRevision;
    final scrollHomeToTop =
        widget.scrollToTopRevision != oldWidget.scrollToTopRevision;
    if (dismissPlans && _showingPlans) {
      _closePlans(restoreOffset: !scrollHomeToTop);
    }
    if (!scrollHomeToTop || !_scrollController.hasClients) return;
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

  void _openPlans() {
    final generation = ++_plansGeneration;
    if (_scrollController.hasClients) {
      _savedOffset = _scrollController.offset;
      if (_scrollController.offset != 0) _scrollController.jumpTo(0);
    }
    setState(() => _showingPlans = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _plansGeneration || !_showingPlans) return;
      if (!_scrollController.hasClients) return;
      if (_scrollController.offset != 0) _scrollController.jumpTo(0);
    });
  }

  void _closePlans({required bool restoreOffset}) {
    if (!_showingPlans) return;
    _plansGeneration++;
    _showingPlans = false;
    if (!restoreOffset) return;
    final offset = _savedOffset;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _showingPlans || !_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      _scrollController.jumpTo(offset.clamp(0, max));
    });
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
                  MainContentSwitch(
                    showPlans: _showingPlans,
                    plans: const PricingPlansBody(
                      key: ValueKey('home-plans'),
                      title: 'Manage Plan',
                    ),
                    child: Column(
                      key: const ValueKey('home-main'),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
                        _section(PassBanner(onManagePlan: _openPlans)),
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
                            onViewAll: () => widget.onNavigate(2),
                            onRideTap: (name) =>
                                _previewMessage('$name is a sample ride.'),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
