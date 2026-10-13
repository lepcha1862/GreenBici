import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenbici/main.dart';
import 'package:greenbici/navbar/app_shell.dart';
import 'package:greenbici/signin_signup/sign_up.dart';

void main() {
  testWidgets('Auth dividers are centered between primary and Google actions', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    final signInDivider = find.text('— or sign in with —');
    expect(signInDivider, findsOneWidget);
    expect(
      tester.getCenter(signInDivider).dx,
      moreOrLessEquals(
        tester.view.physicalSize.width / tester.view.devicePixelRatio / 2,
        epsilon: 1,
      ),
    );

    final signUp = find.widgetWithText(TextButton, 'Sign Up');
    await tester.ensureVisible(signUp);
    await tester.pumpAndSettle();
    await tester.tap(signUp);
    await tester.pumpAndSettle();
    final signUpDivider = find.text('— or sign up with —');
    expect(signUpDivider, findsOneWidget);
    expect(
      tester.getCenter(signUpDivider).dx,
      moreOrLessEquals(
        tester.view.physicalSize.width / tester.view.devicePixelRatio / 2,
        epsilon: 1,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sign-in opens signup and returns without losing input', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(306, 676);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
    expect(find.byType(TextField), findsNWidgets(2));
    await tester.enterText(find.byType(TextField).first, 'rider');
    expect(
      tester.widget<TextField>(find.byType(TextField).last).obscureText,
      isTrue,
    );
    await tester.ensureVisible(find.text('Sign Up'));
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
    expect(find.byType(SignUpPage), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(4));
    await tester.enterText(find.byType(TextField).at(0), 'rider');
    await tester.enterText(find.byType(TextField).at(1), 'rider@example.com');
    await tester.enterText(find.byType(TextField).at(2), 'password123');
    await tester.enterText(find.byType(TextField).at(3), 'different');
    await tester.ensureVisible(find.text('Sign Up'));
    await tester.tap(find.text('Sign Up'));
    await tester.pump();
    expect(find.text('Your passwords do not match.'), findsOneWidget);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sign In'));
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
    expect(find.byType(SignUpPage), findsNothing);
    expect(find.text('rider'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Password visibility can be toggled without losing input', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    final password = find.byType(TextField).last;
    await tester.enterText(password, 'my-secret');
    await tester.ensureVisible(find.byTooltip('Show password'));
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(tester.widget<TextField>(password).obscureText, isFalse);
    expect(tester.widget<TextField>(password).controller!.text, 'my-secret');
    await tester.tap(find.byTooltip('Hide password'));
    await tester.pump();
    expect(tester.widget<TextField>(password).obscureText, isTrue);
  });

  testWidgets('Small screens and keyboard keep navigation reachable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(280, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(const MyApp());
    await tester.ensureVisible(find.text('Sign Up'));
    await tester.ensureVisible(find.text('Sign Up'));
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(TextField).last);
    await tester.enterText(find.byType(TextField).last, 'confirmation');
    await tester.pumpAndSettle();
    expect(
      tester.getBottomRight(find.byType(TextField).last).dy,
      lessThanOrEqualTo(480 - 240),
    );
    await tester.ensureVisible(find.text('Sign In'));
    await tester.ensureVisible(find.text('Sign In'));
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Keyboard Next moves focus and Done signs in', (tester) async {
    await tester.pumpWidget(const MyApp());
    final fields = find.byType(TextField);
    await tester.enterText(fields.first, 'Sam Rivera');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).last)
          .focusNode
          .hasFocus,
      isTrue,
    );
    await tester.enterText(fields.last, 'secret');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.byType(AppShell), findsOneWidget);
    expect(
      tester.widget<AppShell>(find.byType(AppShell)).displayName,
      'Sam Rivera',
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Signup validates missing, invalid, and matching field values', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SignUpPage()));
    await tester.ensureVisible(find.text('Sign Up'));
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
    expect(find.text('Complete all four fields.'), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Sam Rivera');
    await tester.enterText(fields.at(1), 'invalid-email');
    await tester.enterText(fields.at(2), 'password123');
    await tester.enterText(fields.at(3), 'password123');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address.'), findsOneWidget);

    await tester.enterText(fields.at(1), 'sam@example.com');
    await tester.enterText(fields.at(3), 'different');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Your passwords do not match.'), findsOneWidget);

    await tester.enterText(fields.at(3), 'password123');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(
      find.text('Sign-up is not connected to an authentication service yet.'),
      findsOneWidget,
    );
    expect(find.byType(SignUpPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Auth actions have accessible touch sizes', (tester) async {
    await tester.pumpWidget(const MyApp());
    for (final control in [
      find.byTooltip('Show password'),
      find.widgetWithText(TextButton, 'Forgot Password?'),
      find.widgetWithText(FilledButton, 'Sign In'),
      find.widgetWithText(OutlinedButton, 'Sign in with Google'),
      find.widgetWithText(TextButton, 'Sign Up'),
    ]) {
      final size = tester.getSize(control);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('Large-text validation stays within a small keyboard viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const MaterialApp(home: SignUpPage()));
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(TextField).last);
    await tester.enterText(find.byType(TextField).last, 'secret');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Complete all four fields.'), findsOneWidget);
    expect(tester.getSize(find.byType(SnackBar)).height, lessThan(240));
    expect(tester.takeException(), isNull);
  });
  for (final size in [
    const Size(240, 320),
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390),
    const Size(768, 1024),
    const Size(1440, 900),
  ]) {
    for (final textScale in [1.0, 2.0, 3.0]) {
      testWidgets('Both pages at $size and text scale $textScale', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = textScale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(const MyApp());
        await tester.enterText(find.byType(TextField).first, 'rider');
        final fieldWidth = tester.getSize(find.byType(TextField).first).width;
        expect(fieldWidth, lessThanOrEqualTo(460));
        expect(fieldWidth, lessThanOrEqualTo(size.width));
        await tester.ensureVisible(find.text('Sign Up'));
        await tester.tap(find.text('Sign Up'));
        await tester.pumpAndSettle();
        expect(find.byType(SignUpPage), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.byType(TextField).last);
        await tester.enterText(find.byType(TextField).last, 'secret');
        final label = tester.renderObject<RenderParagraph>(
          find.text('Confirm Password'),
        );
        expect(label.didExceedMaxLines, isFalse);
        expect(label.size.width, lessThanOrEqualTo(fieldWidth));
        await tester.ensureVisible(find.text('Sign In'));
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();
        expect(find.byType(SignUpPage), findsNothing);
        expect(find.text('rider'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
