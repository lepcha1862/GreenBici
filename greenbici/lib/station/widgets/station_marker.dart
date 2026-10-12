import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../theme/app_style.dart';

/// Draws a reusable bike pin without relying on remote assets or fake counts.
Future<BitmapDescriptor> createStationMarker({required bool selected}) async {
  const ratio = 3.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(ratio);
  final path = Path()
    ..moveTo(26, 65)
    ..cubicTo(19, 55, 3, 39, 3, 26)
    ..arcToPoint(const Offset(49, 26), radius: const Radius.circular(23))
    ..cubicTo(49, 39, 33, 55, 26, 65)
    ..close();
  canvas.drawShadow(path, Colors.black.withValues(alpha: .3), 3, false);
  canvas.drawPath(
    path,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppStyle.green, AppStyle.darkGreen],
      ).createShader(const Rect.fromLTWH(0, 0, 52, 68)),
  );
  if (selected) {
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }
  final icon = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(Icons.pedal_bike.codePoint),
      style: TextStyle(
        fontFamily: Icons.pedal_bike.fontFamily,
        package: Icons.pedal_bike.fontPackage,
        fontSize: 29,
        color: Colors.white,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  icon.paint(canvas, Offset((52 - icon.width) / 2, 12));
  icon.dispose();
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    (52 * ratio).round(),
    (68 * ratio).round(),
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return BitmapDescriptor.bytes(
    bytes!.buffer.asUint8List(),
    width: 52,
    height: 68,
  );
}
