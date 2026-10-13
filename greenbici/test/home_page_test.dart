import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenbici/home/home_page.dart';
import 'package:greenbici/home/widgets/hero_slider.dart';
import 'package:greenbici/navbar/app_shell.dart';
import 'package:greenbici/navbar/bottom_nav.dart';
import 'package:greenbici/navbar/top_nav.dart';
import 'package:greenbici/ride/ride_page.dart';
import 'package:greenbici/main.dart';
import 'package:greenbici/signin_signup/signin_page.dart';

void main() {
  for (final name in ['', '   Sam Rivera   ']) {
    testWidgets('Sign in opens home without credentials and greets '
        '${name.isEmpty ? 'Alex' : 'the entered rider'}', (tester) async {
      _configureView(tester, const Size(390, 844));
      await tester.pumpWidget(const MyApp());
      if (name.isNotEmpty) {
        await tester.enterText(find.byType(TextField).first, name);
      }

      await tester.ensureVisible(find.text('Sign In'));
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(SignInPage), findsNothing);
      expect(
        find.text(
          'Good morning, ${name.isEmpty ? 'Alex' : name.trim()}',
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await _unmount(tester);
    });
  }

  const sizes = [
    Size(240, 320),
    Size(280, 640),
    Size(390, 844),
    Size(660, 1600),
    Size(844, 390),
    Size(1440, 900),
  ];
  for (final size in sizes) {
    for (final textScale in [1.0, 2.0, 3.0]) {
      testWidgets('Home fits $size with text scale $textScale', (tester) async {
        _configureView(tester, size, textScale: textScale);
        await tester.pumpWidget(_homeApp(reducedMotion: true));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        for (final title in [
          'Quick Actions',
          'Nearby Docking Stations',
          'Offers for You',
          'Top 5 Recent Rides',
        ]) {
          final heading = find.text(title);
          await tester.ensureVisible(heading);
          await tester.pumpAndSettle();
          expect(
            tester
                .getRect(heading)
                .overlaps(Rect.fromLTWH(0, 0, size.width, size.height)),
            isTrue,
            reason: '$title must remain reachable at $size / $textScale',
          );
          expect(tester.takeException(), isNull);
        }

        await tester.ensureVisible(find.text('27 min'));
        await tester.pumpAndSettle();
        expect(find.text(r'$2.70'), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(find.byType(BottomNav).hitTestable(), findsOneWidget);
        await _unmount(tester);
      });
    }
  }

  testWidgets('Quick actions open destinations and preserve Home scroll', (
    tester,
  ) async {
    _configureView(tester, const Size(390, 844));
    await tester.pumpWidget(_homeApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Find Station'));
    await tester.pumpAndSettle();
    final homeScroll = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byKey(const PageStorageKey('home-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    final homeOffset = homeScroll.position.pixels;
    await tester.tap(find.text('Find Station'));
    await tester.pumpAndSettle();
    _expectHeadingInBody(tester, 'Nearby Stations');
    expect(find.byType(HomePage), findsNothing);
    expect(tester.widget<BottomNav>(find.byType(BottomNav)).selectedIndex, 1);

    await tester.tap(find.byTooltip('Home'));
    await tester.pumpAndSettle();
    expect(homeScroll.position.pixels, homeOffset);

    await tester.ensureVisible(find.text('My Rides'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My Rides'));
    await tester.pumpAndSettle();
    expect(find.byType(RidePage), findsOneWidget);
    _expectHeadingInBody(tester, 'Available Bikes');
    expect(find.byType(HomePage), findsNothing);
    expect(tester.widget<BottomNav>(find.byType(BottomNav)).selectedIndex, 2);

    await tester.tap(find.byTooltip('Stations'));
    await tester.pumpAndSettle();
    _expectHeadingInBody(tester, 'Nearby Stations');
    for (final destination in ['Notifications', 'Profile']) {
      await tester.tap(find.byTooltip(destination));
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('${destination.toLowerCase()}-placeholder')),
        findsOneWidget,
      );
      expect(find.byType(HomePage), findsNothing);
      expect(find.byType(TopNav), findsNothing);
      expect(find.byType(BottomNav).hitTestable(), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
    await _unmount(tester);
  });

  testWidgets('Start Ride opens bikes and the shared navigation stays active', (
    tester,
  ) async {
    _configureView(tester, const Size(390, 844));
    await tester.pumpWidget(_homeApp(reducedMotion: true));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Start Ride'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Ride'));
    await tester.pumpAndSettle();
    expect(find.byType(RidePage), findsOneWidget);
    expect(tester.widget<BottomNav>(find.byType(BottomNav)).selectedIndex, 2);
    expect(find.byTooltip('Search stations'), findsNothing);
    await tester.tap(find.byTooltip('Home'));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _unmount(tester);
  });

  testWidgets(
    'Station is created on demand and its state survives tab changes',
    (tester) async {
      _configureView(tester, const Size(390, 844));
      await tester.pumpWidget(_homeApp(reducedMotion: true));
      await tester.pumpAndSettle();
      expect(find.byType(_StationStub, skipOffstage: false), findsNothing);

      await tester.tap(find.byTooltip('Search stations'));
      await tester.pumpAndSettle();
      _expectHeadingInBody(tester, 'Nearby Stations');
      await tester.tap(find.text('Select station 0'));
      await tester.pump();
      expect(find.text('Select station 1'), findsOneWidget);

      await tester.tap(find.byTooltip('Home'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Stations'));
      await tester.pumpAndSettle();
      expect(find.text('Select station 1'), findsOneWidget);
      expect(find.byType(TopNav), findsOneWidget);
      expect(find.byType(BottomNav), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _unmount(tester);
    },
  );

  testWidgets('Home station View all opens the Station destination', (
    tester,
  ) async {
    _configureView(tester, const Size(390, 844));
    await tester.pumpWidget(_homeApp(reducedMotion: true));
    await tester.pumpAndSettle();
    final stationViewAll = find.text('View all').first;
    await tester.ensureVisible(stationViewAll);
    await tester.pumpAndSettle();
    await tester.tap(stationViewAll);
    await tester.pumpAndSettle();
    _expectHeadingInBody(tester, 'Nearby Stations');
    await _unmount(tester);
  });

  testWidgets('Home autoplay pauses while another tab is selected', (
    tester,
  ) async {
    _configureView(tester, const Size(660, 700));
    await tester.pumpWidget(_homeApp());
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    _expectSlide(tester, 2);

    await tester.tap(find.byTooltip('Rides'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 18));
    await tester.tap(find.byTooltip('Home'));
    await tester.pumpAndSettle();
    _expectSlide(tester, 2);
    expect(tester.takeException(), isNull);
    await _unmount(tester);
  });

  for (final reducedMotion in [false, true]) {
    testWidgets(
      'Reselecting Home scrolls to top, reduced motion: $reducedMotion',
      (tester) async {
        _configureView(tester, const Size(390, 844));
        await tester.pumpWidget(_homeApp(reducedMotion: reducedMotion));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Nearby Docking Stations'));
        await tester.pumpAndSettle();
        final scroll = tester.state<ScrollableState>(
          find
              .descendant(
                of: find.byKey(const PageStorageKey('home-scroll')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(scroll.position.pixels, greaterThan(0));

        await tester.tap(find.byTooltip('Home'));
        await tester.pumpAndSettle();
        expect(scroll.position.pixels, 0);
        _expectHeadingInBody(tester, 'Good morning, Alex', richText: true);
        expect(tester.takeException(), isNull);
        await _unmount(tester);
      },
    );
  }

  testWidgets('Navigation remains readable at intermediate text scales', (
    tester,
  ) async {
    _configureView(tester, const Size(390, 844), textScale: 1.5);
    await tester.pumpWidget(_homeApp(reducedMotion: true));
    await tester.pumpAndSettle();
    final labels = find.descendant(
      of: find.byType(BottomNav),
      matching: find.byType(RichText),
    );
    for (final label in labels.evaluate()) {
      final paragraph = label.renderObject! as RenderParagraph;
      expect(paragraph.didExceedMaxLines, isFalse);
    }
    for (final label in [
      'Home',
      'Stations',
      'Rides',
      'Notifications',
      'Profile',
    ]) {
      expect(find.byTooltip(label).hitTestable(), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
    await _unmount(tester);
  });

  testWidgets('Hero supports swiping, pagination and its ride action', (
    tester,
  ) async {
    _configureView(tester, const Size(660, 700));
    var startedRides = 0;
    await tester.pumpWidget(_heroApp(onStartRide: () => startedRides++));
    await tester.pumpAndSettle();
    _expectSlide(tester, 1);

    await tester.drag(find.byType(PageView), const Offset(-450, 0));
    await tester.pumpAndSettle();
    _expectSlide(tester, 2);

    await tester.tap(_slideIndicator(4));
    await tester.pumpAndSettle();
    _expectSlide(tester, 4);

    await tester.tap(find.text('Start a ride').hitTestable());
    await tester.pumpAndSettle();
    expect(startedRides, 1);
    expect(tester.takeException(), isNull);
    await _unmount(tester);
  });

  testWidgets('Hero autoplay pauses during touch and app inactivity', (
    tester,
  ) async {
    _configureView(tester, const Size(660, 700));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    addTearDown(() {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    });
    await tester.pumpWidget(_heroApp());
    await tester.pumpAndSettle();

    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    _expectSlide(tester, 2);

    final pointer = await tester.startGesture(
      tester.getCenter(find.byType(PageView)),
    );
    await tester.pump(const Duration(seconds: 12));
    _expectSlide(tester, 2);
    await pointer.up();
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    _expectSlide(tester, 3);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump(const Duration(seconds: 12));
    _expectSlide(tester, 3);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    _expectSlide(tester, 4);

    await _unmount(tester);
    await tester.pump(const Duration(seconds: 12));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Reduced motion disables autoplay while pagination stays usable',
    (tester) async {
      _configureView(tester, const Size(660, 700));
      await tester.pumpWidget(_heroApp(reducedMotion: true));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 20));
      _expectSlide(tester, 1);

      await tester.tap(_slideIndicator(3));
      await tester.pump();
      _expectSlide(tester, 3);
      expect(
        tester.widget<PageView>(find.byType(PageView)).controller!.page,
        2,
      );

      await _unmount(tester);
      await tester.pump(const Duration(seconds: 12));
      expect(tester.takeException(), isNull);
    },
  );
}

void _configureView(WidgetTester tester, Size size, {double textScale = 1}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Widget _homeApp({bool reducedMotion = false}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
    child: child!,
  ),
  home: AppShell(stationBuilder: (_) => const _StationStub()),
);

Widget _heroApp({bool reducedMotion = false, VoidCallback? onStartRide}) =>
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: HeroSlider(onStartRide: onStartRide ?? () {}),
        ),
      ),
    );

Finder _slideIndicator(int slide) => find.byWidgetPredicate(
  (widget) =>
      widget is Semantics && widget.properties.label == 'Slide $slide of 4',
);

void _expectSlide(WidgetTester tester, int slide) {
  expect(
    tester.widget<Semantics>(_slideIndicator(slide)).properties.selected,
    isTrue,
  );
}

void _expectHeadingInBody(
  WidgetTester tester,
  String title, {
  bool richText = false,
}) {
  final bounds = tester.getRect(find.text(title, findRichText: richText));
  final navigationTop = tester.getTopLeft(find.byType(BottomNav)).dy;
  expect(bounds.top, greaterThanOrEqualTo(-1));
  expect(bounds.bottom, lessThan(navigationTop));
}

Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

class _StationStub extends StatefulWidget {
  const _StationStub();

  @override
  State<_StationStub> createState() => _StationStubState();
}

class _StationStubState extends State<_StationStub> {
  int _selectedStation = 0;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          TopNav(
            title: 'Nearby Stations',
            subtitle: 'Current location',
            onSearch: () {},
          ),
          TextButton(
            onPressed: () => setState(() => _selectedStation++),
            child: Text('Select station $_selectedStation'),
          ),
        ],
      ),
    ),
  );
}
