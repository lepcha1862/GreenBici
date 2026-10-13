import 'package:flutter/material.dart';

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'GreenBici. Peddle the future.',
    image: true,
    child: ExcludeSemantics(
      child: Image.asset(
        'assets/branding/greenbici_logo.png',
        fit: BoxFit.contain,
      ),
    ),
  );
}
