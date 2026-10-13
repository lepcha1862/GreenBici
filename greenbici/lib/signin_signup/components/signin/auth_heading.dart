import 'package:flutter/material.dart';

import 'auth_style.dart';
import 'brand_header.dart';

class AuthHeading extends StatelessWidget {
  const AuthHeading({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const BrandHeader(),
      const SizedBox(height: 20),
      Semantics(
        header: true,
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AuthStyle.foreground,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
      ),
    ],
  );
}
