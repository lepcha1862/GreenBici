import 'package:flutter/material.dart';

import '../theme/app_style.dart';

class BottomNav extends StatelessWidget {
  const BottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    (Icons.home_rounded, 'Home'),
    (Icons.location_on_rounded, 'Stations'),
    (Icons.pedal_bike_rounded, 'Rides'),
    (Icons.notifications_rounded, 'Notifications'),
    (Icons.account_circle_outlined, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: AppStyle.border)),
    ),
    child: SafeArea(
      top: false,
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const labelStyle = TextStyle(fontFamily: 'Arial', fontSize: 11);
              final labelMeasure = TextPainter(
                text: const TextSpan(text: 'Notifications', style: labelStyle),
                textScaler: MediaQuery.textScalerOf(context),
                textDirection: Directionality.of(context),
              )..layout();
              final iconsOnly =
                  constraints.maxWidth < 340 ||
                  labelMeasure.width > (constraints.maxWidth - 16) / 5 - 4;
              labelMeasure.dispose();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: List.generate(_items.length, (index) {
                    final selected = index == selectedIndex;
                    final item = _items[index];
                    final color = selected
                        ? AppStyle.darkGreen
                        : AppStyle.muted;
                    return Expanded(
                      child: Semantics(
                        selected: selected,
                        button: true,
                        label: item.$2,
                        excludeSemantics: true,
                        onTap: () => onSelected(index),
                        child: Tooltip(
                          message: item.$2,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => onSelected(index),
                              child: AnimatedContainer(
                                constraints: const BoxConstraints(
                                  minHeight: 48,
                                ),
                                duration:
                                    MediaQuery.disableAnimationsOf(context)
                                    ? Duration.zero
                                    : const Duration(milliseconds: 220),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppStyle.paleGreen
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(item.$1, color: color, size: 28),
                                    if (!iconsOnly) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        item.$2,
                                        maxLines: 1,
                                        style: labelStyle.copyWith(
                                          color: color,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}
