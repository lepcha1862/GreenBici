import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'auth_action_button.dart';
import 'auth_style.dart';

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
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: LayoutBuilder(
          builder: (context, constraints) => Row(
            key: const ValueKey('auth-method-divider'),
            children: [
              const Expanded(
                child: Divider(color: AuthStyle.border, thickness: 1.2),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * .72,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    signUp ? '— or sign up with —' : '— or sign in with —',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AuthStyle.secondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const Expanded(
                child: Divider(color: AuthStyle.border, thickness: 1.2),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
      ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 56,
          minWidth: double.infinity,
        ),
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            foregroundColor: AuthStyle.foreground,
            backgroundColor: AuthStyle.field,
            side: const BorderSide(color: AuthStyle.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AuthStyle.radius),
            ),
          ),
          onPressed: () =>
              showAuthMessage(context, 'Google sign-in is not connected yet.'),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomPaint(
                size: const Size(24, 24),
                painter: const _GoogleMarkPainter(),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  signUp ? 'Sign up with Google' : 'Sign in with Google',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Arial',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            accountPrompt,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AuthStyle.secondary),
          ),
          TextButton(
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              onNavigate();
            },
            style: TextButton.styleFrom(
              foregroundColor: AuthStyle.accent,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              minimumSize: const Size(48, 48),
              textStyle: const TextStyle(
                fontFamily: 'Arial',
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
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
