import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The home page's swipeable introduction to riding with GreenBici.
class HeroSlider extends StatefulWidget {
  const HeroSlider({super.key, required this.onStartRide});

  final VoidCallback onStartRide;

  @override
  State<HeroSlider> createState() => _HeroSliderState();
}

class _HeroSliderState extends State<HeroSlider> with WidgetsBindingObserver {
  static const _autoplayDelay = Duration(seconds: 6);
  static const _slides = <_HeroSlide>[
    _HeroSlide(
      title:
          'Taking a bike is more\nthan just getting from\npoint A to point B.',
      description:
          'It’s a small action with a big impact—less traffic, cleaner air, '
          'and a greener city for all. Every ride brings us closer to a '
          'sustainable tomorrow.',
      imageAlignment: Alignment.centerRight,
    ),
    _HeroSlide(
      title: 'A small action.\nA big impact.',
      description:
          'Less traffic, cleaner air, and a greener city for all. '
          'Every ride brings us closer to a sustainable tomorrow.',
      imageAlignment: Alignment(0.6, 0),
    ),
    _HeroSlide(
      title: 'A cleaner, healthier\nfuture with every ride.',
      description:
          'Affordable, convenient, and eco-friendly mobility for everyone.',
      imageAlignment: Alignment(0.2, 0),
    ),
    _HeroSlide(
      title: 'Every ride brings us\ncloser to a sustainable\ntomorrow.',
      description:
          'Taking a bike is more than just getting from point A to point B. '
          'It’s a small action with a big impact.',
      imageAlignment: Alignment.centerRight,
    ),
  ];

  final PageController _pageController = PageController();
  final Set<int> _activePointers = <int>{};
  Timer? _autoplayTimer;
  AppLifecycleState? _lifecycleState;
  int _currentPage = 0;
  bool _reduceMotion = false;
  bool _tickerEnabled = true;
  bool _hovered = false;
  bool _focused = false;
  bool _dragging = false;

  bool get _canAutoplay =>
      mounted &&
      !_reduceMotion &&
      _tickerEnabled &&
      (_lifecycleState == null ||
          _lifecycleState == AppLifecycleState.resumed) &&
      !_hovered &&
      !_focused &&
      !_dragging &&
      _activePointers.isEmpty;

  @override
  void initState() {
    super.initState();
    _lifecycleState = WidgetsBinding.instance.lifecycleState;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _tickerEnabled = TickerMode.valuesOf(context).enabled;
    _scheduleAutoplay();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    _scheduleAutoplay();
  }

  void _scheduleAutoplay() {
    _autoplayTimer?.cancel();
    _autoplayTimer = null;
    if (!_canAutoplay) return;

    _autoplayTimer = Timer(_autoplayDelay, () {
      if (!_canAutoplay || !_pageController.hasClients) return;
      _goToPage((_currentPage + 1) % _slides.length);
    });
  }

  Future<void> _goToPage(int page) async {
    _autoplayTimer?.cancel();
    if (!_pageController.hasClients) return;

    if (_reduceMotion) {
      _pageController.jumpToPage(page);
    } else {
      await _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    }
    if (mounted) _scheduleAutoplay();
  }

  void _onPointerDown(PointerDownEvent event) {
    _activePointers.add(event.pointer);
    _scheduleAutoplay();
  }

  void _onPointerUp(PointerEvent event) {
    _activePointers.remove(event.pointer);
    _scheduleAutoplay();
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _dragging = true;
      _scheduleAutoplay();
    } else if (notification is ScrollEndNotification) {
      _dragging = false;
      _scheduleAutoplay();
    }
    return false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoplayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = _HeroMetrics.calculate(
          context,
          constraints.maxWidth,
          _slides,
        );

        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: MouseRegion(
            onEnter: (_) {
              _hovered = true;
              _scheduleAutoplay();
            },
            onExit: (_) {
              _hovered = false;
              _scheduleAutoplay();
            },
            child: Focus(
              onFocusChange: (focused) {
                _focused = focused;
                _scheduleAutoplay();
              },
              child: Listener(
                onPointerDown: _onPointerDown,
                onPointerUp: _onPointerUp,
                onPointerCancel: _onPointerUp,
                child: SizedBox(
                  height: metrics.height,
                  child: Stack(
                    children: [
                      NotificationListener<ScrollNotification>(
                        onNotification: _onScrollNotification,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _slides.length,
                          onPageChanged: (page) {
                            setState(() => _currentPage = page);
                          },
                          itemBuilder: (context, index) => _HeroPanel(
                            slide: _slides[index],
                            metrics: metrics,
                            onStartRide: widget.onStartRide,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 8,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_slides.length, (index) {
                            final selected = _currentPage == index;
                            return Semantics(
                              label: 'Slide ${index + 1} of ${_slides.length}',
                              button: true,
                              selected: selected,
                              child: Material(
                                color: Colors.transparent,
                                child: InkResponse(
                                  onTap: () => _goToPage(index),
                                  radius: 22,
                                  child: SizedBox(
                                    width: 40,
                                    height: 44,
                                    child: Center(
                                      child: AnimatedContainer(
                                        duration: _reduceMotion
                                            ? Duration.zero
                                            : const Duration(milliseconds: 250),
                                        curve: Curves.easeOut,
                                        width: selected ? 20 : 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: selected ? 1 : 0.55,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeroSlide {
  const _HeroSlide({
    required this.title,
    required this.description,
    required this.imageAlignment,
  });

  final String title;
  final String description;
  final Alignment imageAlignment;
}

/// Measures the same text styles used by the panels so large accessibility
/// text can grow the carousel naturally instead of clipping its content.
class _HeroMetrics {
  const _HeroMetrics({
    required this.height,
    required this.padding,
    required this.contentWidth,
    required this.buttonWidth,
    required this.buttonHeight,
    required this.compact,
    required this.titleStyle,
    required this.descriptionStyle,
    required this.buttonStyle,
  });

  final double height;
  final double padding;
  final double contentWidth;
  final double buttonWidth;
  final double buttonHeight;
  final bool compact;
  final TextStyle titleStyle;
  final TextStyle descriptionStyle;
  final TextStyle buttonStyle;

  static _HeroMetrics calculate(
    BuildContext context,
    double width,
    List<_HeroSlide> slides,
  ) {
    final compact = width < 560;
    final padding = compact ? (width < 340 ? 20.0 : 24.0) : 32.0;
    final availableWidth = math.max(1.0, width - padding * 2);
    final contentWidth = compact
        ? availableWidth
        : math.min(480.0, availableWidth * 0.55);
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    final titleStyle = TextStyle(
      fontFamily: fontFamily,
      color: Colors.white,
      fontSize: compact ? (width < 340 ? 20 : 23) : 25,
      fontWeight: FontWeight.w700,
      height: 1.12,
      letterSpacing: -0.45,
    );
    final descriptionStyle = TextStyle(
      fontFamily: fontFamily,
      color: const Color(0xFFEDF2E9),
      fontSize: compact ? 14.5 : 16,
      fontWeight: FontWeight.w400,
      height: 1.24,
      letterSpacing: 0,
    );
    final buttonStyle = TextStyle(
      fontFamily: fontFamily,
      fontSize: 15,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: 0,
    );

    Size measure(String text, TextStyle style, double maxWidth) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: maxWidth);
      final size = painter.size;
      painter.dispose();
      return size;
    }

    final labelWidth = measure(
      'Start a ride',
      buttonStyle,
      double.infinity,
    ).width;
    final buttonWidth = math.min(
      contentWidth,
      math.max(168.0, labelWidth + 72),
    );
    final buttonHeight = math.max(
      46.0,
      measure(
            'Start a ride',
            buttonStyle,
            math.max(1.0, buttonWidth - 72),
          ).height +
          24,
    );
    var tallestContent = 0.0;
    for (final slide in slides) {
      final contentHeight =
          measure(slide.title, titleStyle, contentWidth).height +
          12 +
          measure(slide.description, descriptionStyle, contentWidth).height +
          20 +
          buttonHeight;
      tallestContent = math.max(tallestContent, contentHeight);
    }

    return _HeroMetrics(
      height: math
          .max(
            compact ? 350.0 : math.min(430.0, width * 0.55),
            tallestContent + padding + 68,
          )
          .ceilToDouble(),
      padding: padding,
      contentWidth: contentWidth,
      buttonWidth: buttonWidth,
      buttonHeight: buttonHeight,
      compact: compact,
      titleStyle: titleStyle,
      descriptionStyle: descriptionStyle,
      buttonStyle: buttonStyle,
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.slide,
    required this.metrics,
    required this.onStartRide,
  });

  final _HeroSlide slide;
  final _HeroMetrics metrics;
  final VoidCallback onStartRide;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeSemantics(
          child: Image.asset(
            'assets/images/home/ride_hero.jpg',
            fit: BoxFit.cover,
            alignment: slide.imageAlignment,
            errorBuilder: (context, error, stackTrace) => const _HeroFallback(),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                const Color(0xFF061D18).withValues(alpha: 0.88),
                const Color(0xFF061D18)
                    .withValues(alpha: metrics.compact ? 0.72 : 0.6),
                const Color(0xFF061D18)
                    .withValues(alpha: metrics.compact ? 0.3 : 0.05),
              ],
              stops: const [0, 0.48, 1],
            ),
          ),
        ),
        Positioned(
          left: metrics.padding,
          top: metrics.padding,
          width: metrics.contentWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(slide.title, style: metrics.titleStyle),
              const SizedBox(height: 12),
              Text(slide.description, style: metrics.descriptionStyle),
              const SizedBox(height: 20),
              SizedBox(
                width: metrics.buttonWidth,
                height: metrics.buttonHeight,
                child: FilledButton(
                  onPressed: onStartRide,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF72AD43),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    textStyle: metrics.buttonStyle,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(child: Text('Start a ride')),
                      const SizedBox(width: 12),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroFallback extends StatelessWidget {
  const _HeroFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF325A43), Color(0xFF164C49), Color(0xFF81A864)],
        ),
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Icon(
            Icons.pedal_bike_rounded,
            size: 190,
            color: Color(0x5579B277),
          ),
        ),
      ),
    );
  }
}
