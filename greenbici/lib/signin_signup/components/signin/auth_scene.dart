import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Fluid form layout with a readable width and scrollable intrinsic height.
class AuthScene extends StatelessWidget {
  const AuthScene({super.key, required this.child, this.topSpacing = 72});
  final Widget child;
  final double topSpacing;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF101212),
    resizeToAvoidBottomInset: false,
    body: Stack(
      children: [
        const Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(painter: _CyclingScenePainter()),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding = (constraints.maxWidth * .07).clamp(
                  16.0,
                  28.0,
                );
                final verticalScale = (constraints.maxHeight / 900).clamp(
                  .3,
                  1.0,
                );
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            topSpacing * verticalScale,
                            horizontalPadding,
                            150,
                          ),
                          child: DefaultTextStyle(
                            style: const TextStyle(
                              fontFamily: 'Arial',
                              fontSize: 16,
                              height: 1.15,
                              color: Color(0xFFE6E6E6),
                            ),
                            child: child,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    ),
  );
}

/// Self-contained approximation of the supplied sunset photograph.
class _CyclingScenePainter extends CustomPainter {
  const _CyclingScenePainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 306, size.height / 676);
    const bounds = Rect.fromLTWH(0, 0, 306, 676);
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF081F30),
            Color(0xFF102330),
            Color(0xFF333332),
            Color(0xFF674420),
          ],
          stops: [0, .35, .72, 1],
        ).createShader(bounds),
    );
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, .85),
          radius: .72,
          colors: [Color(0x224E321A), Color(0x00CDB76B)],
        ).createShader(bounds),
    );
    canvas.save();
    canvas.translate(0, 112);
    final ink = Paint()..color = const Color(0xFF080909);
    final ground = Path()..moveTo(0, 482);
    final random = math.Random(19);
    for (double x = 0; x <= 306; x += 6) {
      ground.lineTo(x, 481 + random.nextDouble() * 15);
    }
    ground
      ..lineTo(306, 676)
      ..lineTo(0, 676)
      ..close();
    canvas.drawPath(ground, ink);
    // Uneven, increasingly large foreground stones.
    for (var i = 0; i < 780; i++) {
      final y = 491 + random.nextDouble() * 185;
      final x = random.nextDouble() * 306;
      final depth = (y - 480) / 196;
      final w = 3 + random.nextDouble() * (7 + depth * 23);
      final h = 2 + random.nextDouble() * (3 + depth * 6);
      final stone = Path()
        ..moveTo(x - w / 2, y)
        ..lineTo(x - w / 3, y - h / 2)
        ..lineTo(x + w / 4, y - h)
        ..lineTo(x + w / 2, y)
        ..lineTo(x + w / 4, y + h / 2)
        ..lineTo(x - w / 3, y + h / 2)
        ..close();
      canvas.drawPath(
        stone,
        Paint()
          ..color = Color.lerp(
            const Color(0xFF11171B),
            const Color(0xFF32312A),
            random.nextDouble() * .65,
          )!,
      );
    }
    // Bicycle and rider silhouette, at the horizon behind the action button.
    canvas.save();
    // Keep the cyclist proportional even on wide or tall viewports.
    final aspect = (size.width / 306) / (size.height / 676);
    canvas.translate(153, 474);
    canvas.scale(math.min(1.0, 1 / aspect), math.min(1.0, aspect));
    canvas.translate(-153, -474);
    final line = Paint()
      ..color = const Color(0xFF030505)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawCircle(const Offset(120, 474), 17, line);
    canvas.drawCircle(const Offset(182, 474), 17, line);
    canvas.drawPath(
      Path()
        ..moveTo(120, 474)
        ..lineTo(140, 445)
        ..lineTo(157, 474)
        ..lineTo(120, 474)
        ..moveTo(140, 445)
        ..lineTo(170, 445)
        ..lineTo(157, 474)
        ..moveTo(182, 474)
        ..lineTo(169, 439)
        ..lineTo(177, 435)
        ..moveTo(133, 443)
        ..lineTo(145, 443),
      line,
    );
    canvas.drawCircle(const Offset(137, 410), 7, ink);
    canvas.drawOval(const Rect.fromLTWH(129, 402, 17, 8), ink);
    canvas.drawPath(
      Path()
        ..moveTo(137, 420)
        ..lineTo(130, 437)
        ..lineTo(150, 450)
        ..lineTo(140, 467)
        ..moveTo(134, 438)
        ..lineTo(127, 454)
        ..lineTo(116, 469)
        ..moveTo(140, 421)
        ..lineTo(156, 436)
        ..lineTo(170, 439),
      line..strokeWidth = 7,
    );
    canvas.restore();
    canvas.restore();
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Color(0x66000000)],
          stops: [.72, 1],
        ).createShader(bounds),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CyclingScenePainter oldDelegate) => false;
}
