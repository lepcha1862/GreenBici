import 'package:flutter/material.dart';

import 'signin_signup/signin_page.dart';
import 'splash/splash_screen.dart';
import 'station/services/mapbox_configuration.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MapboxConfiguration.prepare();
  runApp(const MyApp(showSplash: true));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.showSplash = false, this.startupLoader});

  final bool showSplash;
  final StartupLoader? startupLoader;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'GreenBici',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'Arial',
      scaffoldBackgroundColor: const Color(0xFF091F30),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF76A936),
        brightness: Brightness.dark,
      ),
    ),
    home: showSplash
        ? StartupGate(
            loader: startupLoader ?? loadStartupAssets,
            child: const SignInPage(),
          )
        : const SignInPage(),
  );
}
