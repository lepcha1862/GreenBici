import 'package:flutter/material.dart';

import '../home_style.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.displayName,
    required this.onSearch,
  });

  final String displayName;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact =
          constraints.maxWidth < 420 ||
          MediaQuery.textScalerOf(context).scale(14) > 21;
      final greeting = Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: 'Good morning, '),
            TextSpan(
              text: displayName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        style: const TextStyle(fontSize: 17, height: 1.4),
      );
      return Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(width: 126, child: _HomeWordmark()),
                if (!compact) ...[
                  const SizedBox(width: 26),
                  Expanded(flex: 2, child: greeting),
                ] else
                  const Spacer(),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Search stations',
                  onPressed: onSearch,
                  icon: const Icon(Icons.search_rounded, size: 31),
                ),
              ],
            ),
            if (compact) ...[const SizedBox(height: 6), greeting],
          ],
        ),
      );
    },
  );
}

class _HomeWordmark extends StatelessWidget {
  const _HomeWordmark();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'GreenBici',
    image: true,
    child: ExcludeSemantics(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Green',
                      style: TextStyle(
                        color: HomeStyle.darkGreen,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    TextSpan(
                      text: 'Bici',
                      style: TextStyle(color: HomeStyle.green),
                    ),
                  ],
                ),
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.4,
                ),
              ),
            ),
            Positioned(
              right: -1,
              top: -1,
              child: Transform.rotate(
                angle: -.5,
                child: const Icon(Icons.eco, size: 14, color: HomeStyle.green),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
