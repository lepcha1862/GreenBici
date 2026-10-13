// Optional visual review: flutter test tool/ui_review_test.dart
// --dart-define=UI_REVIEW_FONT_DIR=C:/Windows/Fonts
// Captures current viewports in build/ui-review; not golden baselines.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenbici/home/home_page.dart';
import 'package:greenbici/navbar/bottom_nav.dart';
import 'package:greenbici/ride/ride_page.dart';
import 'package:greenbici/signin_signup/signin_page.dart';
import 'package:greenbici/signin_signup/sign_up.dart';
import 'package:greenbici/station/models/bicycle_station.dart';
import 'package:greenbici/station/models/geo_point.dart';
import 'package:greenbici/station/services/location_service.dart';
import 'package:greenbici/station/services/station_repository.dart';
import 'package:greenbici/station/station_controller.dart';
import 'package:greenbici/station/station_page.dart';
import 'package:greenbici/theme/app_style.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final flutterRoot = Platform.environment['FLUTTER_ROOT'];
    if (flutterRoot != null) {
      final icons = FontLoader('MaterialIcons')
        ..addFont(
          File(
            '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
          ).readAsBytes().then(ByteData.sublistView),
        );
      await icons.load();
    }
    const fontDirectory = String.fromEnvironment('UI_REVIEW_FONT_DIR');
    if (fontDirectory.isNotEmpty) {
      final loader = FontLoader('Arial');
      for (final name in [
        'arial.ttf',
        'arialbd.ttf',
        'ariali.ttf',
        'arialbi.ttf',
      ]) {
        loader.addFont(
          File('$fontDirectory/$name').readAsBytes().then(ByteData.sublistView),
        );
      }
      await loader.load();
    }
  });

  for (final viewport in [
    ('mobile', const Size(390, 844), 1.0),
    ('small', const Size(320, 568), 1.0),
    ('tablet', const Size(768, 1024), 1.0),
    ('desktop', const Size(1440, 900), 1.0),
    ('large-text', const Size(390, 844), 2.0),
  ]) {
    for (final screen in ['home', 'station', 'ride', 'signin', 'signup']) {
      testWidgets('$screen visual review at ${viewport.$1}', (tester) async {
        tester.view.physicalSize = viewport.$2;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = viewport.$3;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final station = StationController(
          locationService: _ReviewLocation(),
          repository: _ReviewStations(),
        );
        final auth = screen == 'signin' || screen == 'signup';
        final page = switch (screen) {
          'home' => HomePage(onNavigate: (_) {}),
          'station' => StationPage(
            controller: station,
            mapBuilder: (_, _) => const ColoredBox(
              color: AppStyle.paleGreen,
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Map area · layout preview'),
                ),
              ),
            ),
          ),
          'ride' => const RidePage(),
          'signin' => const SignInPage(),
          _ => const SignUpPage(),
        };
        const boundaryKey = ValueKey('review-boundary');
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundaryKey,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: auth
                  ? ThemeData(brightness: Brightness.dark, fontFamily: 'Arial')
                  : AppStyle.theme,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              ),
              home: auth
                  ? page
                  : Scaffold(
                      body: page,
                      bottomNavigationBar: BottomNav(
                        selectedIndex: [
                          'home',
                          'station',
                          'ride',
                        ].indexOf(screen),
                        onSelected: (_) {},
                      ),
                    ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(boundaryKey),
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final directory = Directory('build/ui-review');
          await directory.create(recursive: true);
          await File('${directory.path}/$screen-${viewport.$1}.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        station.dispose();
      });
    }
  }
}

class _ReviewLocation implements LocationService {
  @override
  Future<GeoPoint> currentPosition({bool requestPermission = true}) async =>
      const GeoPoint(latitude: 40.78, longitude: -73.97);
  @override
  Future<bool> openAppSettings() async => false;
  @override
  Future<bool> openLocationSettings() async => false;
}

class _ReviewStations implements StationRepository {
  @override
  Future<List<BicycleStation>> nearby(GeoPoint location) async => const [
    BicycleStation(
      id: 'review-station',
      name: 'Central Park Dock',
      latitude: 40.781,
      longitude: -73.97,
      operatorName: 'GreenBici',
    ),
  ];
}
