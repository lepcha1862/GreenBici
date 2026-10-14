import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenbici/navbar/bottom_nav.dart';
import 'package:greenbici/ride/ride_page.dart';
import 'package:greenbici/theme/app_style.dart';

const _bikeIds = ['GB-204', 'GB-217', 'GB-231', 'GB-248'];

void main() {
  testWidgets('Inventory is marked as a sample before any unlock action', (
    tester,
  ) async {
    await _pumpRide(tester);

    expect(find.text('Sample station & bikes').hitTestable(), findsOneWidget);
    expect(find.text('Riverside Greenway Dock'), findsOneWidget);
    expect(find.text('0.2 mi from you'), findsOneWidget);
    expect(find.byTooltip('Search locations'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Each unlock action explains operator access without starting a ride',
    (tester) async {
      await _pumpRide(tester);

      for (final id in _bikeIds) {
        final action = find.byKey(ValueKey('unlock-$id'));
        await tester.ensureVisible(action);
        await tester.pumpAndSettle();
        await tester.tap(action);
        await tester.pumpAndSettle();

        expect(find.text('Unlock unavailable'), findsOneWidget);
        expect(
          find.text(
            'Bike #$id is a sample bike. Unlocking requires a connected bike operator.',
          ),
          findsOneWidget,
        );
        await tester.tap(find.text('Got it'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.text('Bike #$id'), findsOneWidget);
        expect(find.text('Available'), findsNWidgets(4));
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('Unlock actions identify their bikes for screen readers', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pumpRide(tester);

      for (final id in _bikeIds) {
        await tester.ensureVisible(find.byKey(ValueKey('unlock-$id')));
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('Unlock bike $id'), findsOneWidget);
      }
    } finally {
      semantics.dispose();
    }
  });

  const sizes = [
    Size(320, 640),
    Size(390, 844),
    Size(768, 1024),
    Size(1440, 900),
  ];
  for (final size in sizes) {
    for (final scale in [1.0, 2.0, 3.0]) {
      testWidgets(
        'Ride actions stay reachable at $size with text scale $scale',
        (tester) async {
          await _pumpRide(tester, size: size, textScale: scale);
          expect(tester.takeException(), isNull);

          for (final id in _bikeIds) {
            final action = find.byKey(ValueKey('unlock-$id'));
            await tester.ensureVisible(action);
            await tester.pumpAndSettle();
            expect(action.hitTestable(), findsOneWidget);
            final actionBounds = tester.getRect(action);
            final navigationTop = tester.getTopLeft(find.byType(BottomNav)).dy;
            expect(actionBounds.left, greaterThanOrEqualTo(0));
            expect(actionBounds.right, lessThanOrEqualTo(size.width));
            expect(actionBounds.bottom, lessThanOrEqualTo(navigationTop));
            expect(tester.takeException(), isNull);
          }

          final returnNote = find.text(
            'Ride one way—return your bike to any eligible docking station.',
          );
          await tester.ensureVisible(returnNote);
          await tester.pumpAndSettle();
          expect(
            tester
                .getRect(returnNote)
                .overlaps(Rect.fromLTWH(0, 0, size.width, size.height)),
            isTrue,
          );
          expect(find.byType(BottomNav).hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'Unlock feedback stays usable on a narrow screen with large text',
    (tester) async {
      await _pumpRide(tester, size: const Size(320, 640), textScale: 3);
      final action = find.byKey(const ValueKey('unlock-GB-204'));
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      await tester.tap(action);
      await tester.pumpAndSettle();

      final dismiss = find.text('Got it');
      await tester.ensureVisible(dismiss);
      await tester.pumpAndSettle();
      expect(dismiss.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(dismiss);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    },
  );
}

Future<void> _pumpRide(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppStyle.theme,
      home: Scaffold(
        body: const RidePage(),
        bottomNavigationBar: BottomNav(selectedIndex: 2, onSelected: (_) {}),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
