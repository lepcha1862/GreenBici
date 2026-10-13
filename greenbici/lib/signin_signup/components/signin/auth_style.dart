import 'package:flutter/material.dart';

import '../../../theme/app_style.dart';

/// The authentication screens keep a dark cycling scene with the shared brand.
abstract final class AuthStyle {
  static const primary = AppStyle.darkGreen;
  static const accent = Color(0xFFB6DFA0);
  static const foreground = Color(0xFFF4F7F3);
  static const secondary = Color(0xFFC8D4CF);
  static const surface = Color(0xE612252A);
  static const field = Color(0xD9102229);
  static const border = Color(0xFF82978D);
  static const radius = 16.0;
}
