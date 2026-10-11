import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../home_style.dart';

class AboutBanner extends StatelessWidget {
  const AboutBanner({super.key});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: ColoredBox(
      color: HomeStyle.paleGreen,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 520;
          return Stack(
            children: [
              Positioned(
                right: -15,
                bottom: -16,
                child: Opacity(
                  opacity: wide ? 1 : 0.45,
                  child: const CustomPaint(
                    size: Size(140, 140),
                    painter: _LeavesPainter(),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 19, wide ? 130 : 20, 19),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: wide ? 66 : 48,
                      height: wide ? 66 : 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDDEFCB),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.spa_outlined,
                        color: HomeStyle.green,
                        size: wide ? 42 : 31,
                      ),
                    ),
                    const SizedBox(width: 20),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              text: 'About ',
                              children: [
                                TextSpan(
                                  text: 'GreenBici',
                                  style: TextStyle(color: HomeStyle.darkGreen),
                                ),
                              ],
                            ),
                            style: TextStyle(
                              color: HomeStyle.ink,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "We're building a cleaner, healthier future with every ride. "
                            'Affordable, convenient, and eco-friendly mobility for everyone.',
                            style: TextStyle(
                              color: HomeStyle.muted,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _LeavesPainter extends CustomPainter {
  const _LeavesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 140, size.height / 140);
    for (var stem = 0; stem < 3; stem++) {
      canvas.save();
      canvas.translate(109, 138);
      canvas.rotate((stem - 1) * 0.5);
      final stemPaint = Paint()
        ..color = const Color(0xFF8DBE68).withValues(alpha: 0.55)
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke;
      canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(-7, -50, 2, -126),
        stemPaint,
      );
      for (var leaf = 0; leaf < 5; leaf++) {
        final y = -23.0 - leaf * 21;
        for (final side in [-1.0, 1.0]) {
          canvas.save();
          canvas.translate(-2, y);
          canvas.rotate(side * math.pi / 3.7);
          final path = Path()
            ..moveTo(0, 0)
            ..quadraticBezierTo(-16, -17, 0, -35)
            ..quadraticBezierTo(15, -17, 0, 0);
          canvas.drawPath(
            path,
            Paint()
              ..color =
                  (leaf.isEven
                          ? const Color(0xFFAAD579)
                          : const Color(0xFF75B952))
                      .withValues(alpha: stem == 0 ? 0.27 : 0.48),
          );
          canvas.restore();
        }
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _LeavesPainter oldDelegate) => false;
}
