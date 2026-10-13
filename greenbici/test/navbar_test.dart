import 'dart:ui' show SemanticsAction, SemanticsFlag;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenbici/navbar/bottom_nav.dart';
import 'package:greenbici/theme/app_style.dart';

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(768, 1024),
    const Size(1440, 900),
  ]) {
    testWidgets('Navigation is labeled and operable at $size with large text', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final semantics = tester.ensureSemantics();
      try {
        var destination = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppStyle.theme,
            home: Scaffold(
              bottomNavigationBar: BottomNav(
                selectedIndex: 2,
                onSelected: (index) => destination = index,
              ),
            ),
          ),
        );
        final labels = [
          'Home',
          'Stations',
          'Rides',
          'Notifications',
          'Profile',
        ];
        for (var index = 0; index < labels.length; index++) {
          final target = find.bySemanticsLabel(labels[index]);
          final node = tester.getSemantics(target);
          final data = node.getSemanticsData();
          expect(data.hasFlag(SemanticsFlag.isButton), isTrue);
          expect(data.hasAction(SemanticsAction.tap), isTrue);
          expect(data.hasFlag(SemanticsFlag.isSelected), index == 2);
          expect(node.rect.width, greaterThanOrEqualTo(48));
          expect(node.rect.height, greaterThanOrEqualTo(48));
          await tester.tap(find.byTooltip(labels[index]));
          expect(destination, index);
        }
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }
}
