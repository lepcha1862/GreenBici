import 'package:flutter/material.dart';

import 'signin_signup/signin_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'GreenBici',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'Arial',
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF00D900),
        brightness: Brightness.dark,
      ),
    ),
    home: const SignInPage(),
  );
}
