import 'package:flutter/material.dart';

import 'auth_style.dart';

class AuthActionButton extends StatelessWidget {
  const AuthActionButton({
    super.key,
    required this.label,
    required this.onPressed,
  });
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
    style: FilledButton.styleFrom(
      backgroundColor: AuthStyle.primary,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 56),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AuthStyle.radius),
      ),
      textStyle: const TextStyle(
        fontFamily: 'Arial',
        fontSize: 17,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
    ),
    onPressed: onPressed,
    child: Text(label, textAlign: TextAlign.center),
  );
}

void showAuthMessage(BuildContext context, String message) {
  final media = MediaQuery.of(context);
  final visibleHeight =
      (media.size.height - media.viewInsets.bottom - media.padding.vertical)
          .clamp(0.0, double.infinity);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF23362D),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: visibleHeight * .4),
          child: SingleChildScrollView(
            child: Text(message, style: const TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
}
