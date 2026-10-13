import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenbici/notifications/notification_page.dart';
import 'package:greenbici/profile/profile_page.dart';
import 'package:greenbici/theme/app_style.dart';

void main() {
  testWidgets('Profile uses first and last initials when no image is set', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppStyle.theme,
        home: const Scaffold(
          body: ProfilePage(displayName: 'Alex Jordan Morgan'),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('profile-avatar')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-initials')), findsOneWidget);
    expect(find.text('AM'), findsOneWidget);
    expect(find.text('alex.jordan.morgan@email.com'), findsOneWidget);
    expect(find.byTooltip('Edit profile'), findsOneWidget);
  });

  testWidgets('Profile displays a supplied image inside the avatar', (
    tester,
  ) async {
    const image = AssetImage('assets/branding/greenbici_app_icon.png');
    await tester.pumpWidget(
      MaterialApp(
        theme: AppStyle.theme,
        home: const Scaffold(
          body: ProfilePage(displayName: 'Alex Morgan', profileImage: image),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final avatar = tester.widget<CircleAvatar>(
      find.byKey(const ValueKey('profile-avatar')),
    );
    expect(avatar.foregroundImage, same(image));
    expect(tester.takeException(), isNull);
  });

  const sizes = [
    Size(240, 320),
    Size(320, 568),
    Size(390, 844),
    Size(844, 390),
    Size(1440, 900),
  ];

  for (final size in sizes) {
    for (final textScale in [1.0, 3.0]) {
      testWidgets('Notifications fit $size at text scale $textScale', (
        tester,
      ) async {
        _configureView(tester, size, textScale);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppStyle.theme,
            home: const Scaffold(body: NotificationPage()),
          ),
        );
        await tester.pumpAndSettle();

        final search = find.byTooltip('Search stations');
        expect(search, findsOneWidget);
        if (size.width <= 390) {
          final pagePadding = size.width < 360 ? 14.0 : 20.0;
          expect(
            tester.getRect(search).right,
            moreOrLessEquals(size.width - pagePadding, epsilon: 1),
          );
        }
        final lastCard = find.text('Refer & earn');
        await tester.ensureVisible(lastCard);
        await tester.pumpAndSettle();
        expect(lastCard, findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('Profile fits $size at text scale $textScale', (
        tester,
      ) async {
        _configureView(tester, size, textScale);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppStyle.theme,
            home: const Scaffold(
              body: ProfilePage(displayName: 'Alexandria Morgan-Rinchen'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byTooltip('Search stations'), findsOneWidget);
        final signOut = find.text('Sign out');
        await tester.ensureVisible(signOut);
        await tester.pumpAndSettle();
        expect(signOut, findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}

void _configureView(WidgetTester tester, Size size, double textScale) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}
