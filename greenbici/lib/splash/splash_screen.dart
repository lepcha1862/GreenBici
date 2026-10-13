import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_style.dart';

typedef StartupLoader = Future<void> Function(
  BuildContext context,
  ValueChanged<double> reportProgress,
);

const _startupAssets = <String>[
  'assets/branding/greenbici_splash_logo.png',
  'assets/branding/greenbici_app_icon.png',
  'assets/images/home/ride_hero.jpg',
  'assets/images/home/central_park.jpg',
  'assets/images/home/riverside.jpg',
];

/// Warms the images used immediately after startup and reports completed work.
Future<void> loadStartupAssets(
  BuildContext context,
  ValueChanged<double> reportProgress,
) async {
  reportProgress(0);
  for (var index = 0; index < _startupAssets.length; index++) {
    await precacheImage(AssetImage(_startupAssets[index]), context);
    reportProgress((index + 1) / _startupAssets.length);
  }
}

class StartupGate extends StatefulWidget {
  const StartupGate({
    super.key,
    required this.child,
    this.loader = loadStartupAssets,
  });

  final Widget child;
  final StartupLoader loader;

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  double _progress = 0;
  Object? _error;
  var _attempt = 0;
  var _isLoading = false;
  var _loadComplete = false;
  var _showSplash = true;
  var _isFinishing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startLoading());
  }

  Future<void> _startLoading() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _loadComplete = false;
      _error = null;
      _progress = 0;
    });

    try {
      await widget.loader(context, _reportProgress);
      if (!mounted) return;
      setState(() {
        _progress = 1;
        _loadComplete = true;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  void _reportProgress(double value) {
    if (!mounted) return;
    final nextProgress = value.clamp(0.0, 1.0).toDouble();
    if (nextProgress <= _progress) return;
    setState(() => _progress = nextProgress);
  }

  void _retry() {
    setState(() => _attempt++);
    _startLoading();
  }

  Future<void> _finishSplash() async {
    if (!_showSplash || !_loadComplete || _isFinishing) return;
    _isFinishing = true;
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    setState(() => _showSplash = false);
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 420),
    switchInCurve: Curves.easeOut,
    switchOutCurve: Curves.easeIn,
    child: _showSplash
        ? SplashScreen(
            key: ValueKey(_attempt),
            progress: _progress,
            startupComplete: _loadComplete,
            error: _error,
            onRetry: _retry,
            onProgressComplete: _finishSplash,
          )
        : KeyedSubtree(key: const ValueKey('app'), child: widget.child),
  );
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({
    super.key,
    required this.progress,
    required this.startupComplete,
    required this.onRetry,
    required this.onProgressComplete,
    this.error,
  });

  final double progress;
  final bool startupComplete;
  final Object? error;
  final VoidCallback onRetry;
  final VoidCallback onProgressComplete;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF1F7EE),
      body: Stack(
        children: [
          const Positioned.fill(child: _SplashBackdrop()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = math.max(0.0, constraints.maxWidth - 48);
                final logoWidth = math.min(360.0, availableWidth);
                final progressWidth = math.min(320.0, availableWidth);
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TweenAnimationBuilder<double>(
                          duration: reduceMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 620),
                          curve: Curves.easeOutBack,
                          tween: Tween(begin: 0.92, end: 1),
                          builder: (context, value, child) => Opacity(
                            opacity: ((value - 0.92) / 0.08).clamp(0, 1),
                            alwaysIncludeSemantics: true,
                            child: Transform.scale(scale: value, child: child),
                          ),
                          child: Semantics(
                            image: true,
                            label: 'GreenBici',
                            child: Image.asset(
                              'assets/branding/greenbici_splash_logo.png',
                              width: logoWidth,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                              excludeFromSemantics: true,
                            ),
                          ),
                        ),
                        const SizedBox(height: 44),
                        SizedBox(
                          width: progressWidth,
                          child: _AnimatedLoadingBar(
                            progress: progress,
                            startupComplete: startupComplete,
                            error: error,
                            reduceMotion: reduceMotion,
                            onProgressComplete: onProgressComplete,
                          ),
                        ),
                        if (error != null) ...[
                          const SizedBox(height: 24),
                          const Text(
                            'We could not finish preparing the app.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF36513C),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: onRetry,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF347C3D),
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Try again'),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedLoadingBar extends StatelessWidget {
  const _AnimatedLoadingBar({
    required this.progress,
    required this.startupComplete,
    required this.error,
    required this.reduceMotion,
    required this.onProgressComplete,
  });

  final double progress;
  final bool startupComplete;
  final Object? error;
  final bool reduceMotion;
  final VoidCallback onProgressComplete;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 680),
    curve: Curves.easeOutCubic,
    tween: Tween(begin: 0, end: progress),
    onEnd: () {
      if (startupComplete && progress >= 1 && error == null) {
        onProgressComplete();
      }
    },
    builder: (context, value, _) {
      final safeValue = value.clamp(0.0, 1.0).toDouble();
      final percentage = (safeValue * 100).round();
      return Semantics(
        label: 'Loading GreenBici',
        value: '$percentage percent',
        liveRegion: true,
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0x3372AD43), Color(0x33249EBD)],
                  ),
                  border: Border.all(
                    color: AppStyle.darkGreen.withValues(alpha: .28),
                  ),
                ),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: safeValue,
                  child: const DecoratedBox(
                    key: ValueKey('splash-progress-fill'),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppStyle.darkGreen,
                          AppStyle.green,
                          AppStyle.blue,
                        ],
                        stops: [0, .55, 1],
                      ),
                      boxShadow: [
                        BoxShadow(color: Color(0x8072AD43), blurRadius: 12),
                        BoxShadow(color: Color(0x66249EBD), blurRadius: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '$percentage%',
              key: const ValueKey('splash-percentage'),
              style: const TextStyle(
                color: Color(0xFF194B34),
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              error != null
                  ? 'Startup paused'
                  : percentage == 100
                  ? 'Ready to ride'
                  : 'Preparing your ride',
              style: const TextStyle(
                color: Color(0xFF617666),
                fontSize: 13,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _SplashBackdrop extends StatelessWidget {
  const _SplashBackdrop();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFAFCF8), Color(0xFFE9F5E4)],
      ),
    ),
    child: Stack(
      children: const [
        Positioned(
          top: -110,
          right: -90,
          child: _Glow(size: 280, color: Color(0x2979B841)),
        ),
        Positioned(
          bottom: -130,
          left: -100,
          child: _Glow(size: 310, color: Color(0x24176B4C)),
        ),
      ],
    ),
  );
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}
