import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenbici/splash/splash_screen.dart';

void main() {
  testWidgets('splash reports loading progress before revealing the app', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final loader = _ControlledLoader();
    await tester.pumpWidget(
      MaterialApp(
        home: StartupGate(
          loader: loader.call,
          child: const Text('App ready', textDirection: TextDirection.ltr),
        ),
      ),
    );

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);

    loader.reportProgress(0.5);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('50%'), findsOneWidget);

    loader.complete();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('Ready to ride'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 180));
    await tester.pumpAndSettle();
    expect(find.text('App ready'), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _ControlledLoader {
  final _completion = Completer<void>();
  late ValueChanged<double> reportProgress;

  Future<void> call(BuildContext context, ValueChanged<double> onProgress) {
    reportProgress = onProgress;
    return _completion.future;
  }

  void complete() => _completion.complete();
}
