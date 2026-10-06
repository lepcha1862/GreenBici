import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'auth_action_button.dart';

class SocialSignInSection extends StatelessWidget {
  const SocialSignInSection({
    super.key,
    required this.accountPrompt,
    required this.linkLabel,
    required this.onNavigate,
    this.signUp = false,
  });
  final bool signUp;
  final String accountPrompt;
  final String linkLabel;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Expanded(child: Divider(color: Color(0xFF777974))),
          Flexible(
            flex: 3,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                signUp ? 'or sign up with' : 'or sign in with',
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(child: Divider(color: Color(0xFF777974))),
        ],
      ),
      const SizedBox(height: 26),
      ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 62,
          minWidth: double.infinity,
        ),
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            foregroundColor: const Color(0xFFE2E2E2),
            side: const BorderSide(color: Color(0xFFD5D7D3)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          onPressed: () =>
              showAuthMessage(context, 'Google sign-in is not connected yet.'),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomPaint(size: Size(28, 28), painter: _GoogleMarkPainter()),
              SizedBox(width: 9),
              Flexible(
                child: Text(
                  signUp ? 'Sign up with Google' : 'Sign in with Google',
                  style: TextStyle(fontFamily: 'Arial', fontSize: 19),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),
      Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            accountPrompt,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15),
          ),
          TextButton(
            onPressed: onNavigate,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF93BC58),
              padding: const EdgeInsets.only(left: 4),
              minimumSize: const Size(0, 48),
              textStyle: const TextStyle(fontFamily: 'Arial', fontSize: 15),
            ),
            child: Text(linkLabel),
          ),
        ],
      ),
    ],
  );
}

class _GoogleMarkPainter extends CustomPainter {
  const _GoogleMarkPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 28, size.height / 28);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.5;
    const rect = Rect.fromLTWH(3, 3, 22, 22);
    for (final segment in [
      (45.0, 90.0, const Color(0xFF34A853)),
      (135.0, 60.0, const Color(0xFFFBBC05)),
      (195.0, 120.0, const Color(0xFFEA4335)),
      (-4.0, 49.0, const Color(0xFF4285F4)),
    ]) {
      canvas.drawArc(
        rect,
        segment.$1 * math.pi / 180,
        segment.$2 * math.pi / 180,
        false,
        paint..color = segment.$3,
      );
    }
    canvas.drawLine(
      const Offset(14, 14),
      const Offset(27, 14),
      paint..color = const Color(0xFF4285F4),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GoogleMarkPainter oldDelegate) => false;
}
