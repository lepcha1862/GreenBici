import 'package:flutter/material.dart';

import '../home_style.dart';

class PassBanner extends StatelessWidget {
  const PassBanner({super.key, required this.onManagePlan});

  final VoidCallback onManagePlan;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
      final compact = constraints.maxWidth < 540 || textScale > 1.4;
      final manageButton = FilledButton(
        onPressed: onManagePlan,
        style: FilledButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: const Color(0xFF278EA7),
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 11),
          minimumSize: const Size(48, 40),
          tapTargetSize: MaterialTapTargetSize.padded,
          textStyle: const TextStyle(
            fontFamily: 'Arial',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: const Text('Manage Plan', textAlign: TextAlign.center),
      );
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFFEBF7FD), Color(0xFFEAF8FA)],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(18, 15, 18, 15),
        child: Row(
          children: [
            SizedBox(
              width: compact ? 49 : 65,
              height: compact ? 60 : 72,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.shield_rounded,
                    size: compact ? 57 : 72,
                    color: const Color(0xFF22A6E5),
                  ),
                  Icon(
                    Icons.star_border_rounded,
                    size: compact ? 30 : 36,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 17),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 9,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'GreenBici Pass',
                        style: TextStyle(
                          color: HomeStyle.ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF20A4E8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Active',
                          style: TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Monthly Plan',
                    style: TextStyle(color: HomeStyle.ink, fontSize: 12),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Renews on May 25, 2025',
                    style: TextStyle(color: Color(0xFF64727A), fontSize: 11.5),
                  ),
                  if (compact) ...[const SizedBox(height: 8), manageButton],
                ],
              ),
            ),
            if (!compact) ...[
              const SizedBox(width: 12),
              SizedBox(
                width: 134,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Icon(
                        Icons.pedal_bike_rounded,
                        color: Color(0xFF52A7A7),
                        size: 72,
                      ),
                    ),
                    manageButton,
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}
