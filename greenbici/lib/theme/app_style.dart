import 'package:flutter/material.dart';

/// Shared visual tokens for GreenBici's signed-in screens.
abstract final class AppStyle {
  static const ink = Color(0xFF202820);
  static const muted = Color(0xFF626D61);
  static const green = Color(0xFF72AD43);
  static const darkGreen = Color(0xFF347C3D);
  static const paleGreen = Color(0xFFF1F7EE);
  static const blue = Color(0xFF249EBD);
  static const border = Color(0xFFEEF1EB);
  static const canvas = Color(0xFFF8FAF7);

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Arial',
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(
      seedColor: green,
      brightness: Brightness.light,
      surface: Colors.white,
      onSurface: ink,
      primary: darkGreen,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: ink, fontSize: 14, height: 1.3),
      bodySmall: TextStyle(color: muted, fontSize: 12, height: 1.3),
      titleMedium: TextStyle(
        color: ink,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
    ),
    iconTheme: const IconThemeData(color: ink),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: darkGreen),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(
          fontFamily: 'Arial',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: ink,
    ),
  );
}
