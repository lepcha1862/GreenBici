import 'package:flutter/material.dart';

/// Vector approximation; replace this widget with the original brand asset
/// when the production logo is available.
class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'GreenBici. Peddle the future.',
    image: true,
    child: ExcludeSemantics(
      child: SizedBox(
        height: 65,
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: 220,
            height: 65,
            child: Stack(
              children: [
                Positioned(
                  top: 8,
                  left: 0,
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontFamily: 'Arial',
                        fontSize: 45,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -2.7,
                        color: Color(0xFF006C3E),
                      ),
                      children: [
                        TextSpan(
                          text: 'Green',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                        TextSpan(
                          text: 'Bici',
                          style: TextStyle(color: Color(0xFF30AA00)),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 5,
                  top: 0,
                  child: CustomPaint(
                    size: const Size(31, 24),
                    painter: _LeavesPainter(),
                  ),
                ),
                const Positioned(
                  left: 1,
                  right: 4,
                  bottom: 1,
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(color: Color(0xFF389C28), thickness: 1),
                      ),
                      Flexible(
                        flex: 10,
                        child: FittedBox(
                          child: Text(
                            ' P E D D L E   T H E   F U T U R E ',
                            style: TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.w800,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF005F42),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: Color(0xFF389C28), thickness: 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _LeavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF38AF00);
    canvas.drawPath(
      Path()
        ..moveTo(11, 21)
        ..quadraticBezierTo(10, 1, 30, 0)
        ..quadraticBezierTo(29, 15, 11, 21),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(10, 23)
        ..quadraticBezierTo(-3, 19, 2, 9)
        ..quadraticBezierTo(12, 11, 10, 23),
      paint,
    );
    canvas.drawLine(
      const Offset(9, 24),
      const Offset(24, 6),
      Paint()
        ..color = const Color(0xFF16862E)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _LeavesPainter oldDelegate) => false;
}
