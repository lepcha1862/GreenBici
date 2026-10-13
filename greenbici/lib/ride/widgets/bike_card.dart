import 'package:flutter/material.dart';

import '../../theme/app_card.dart';
import '../../theme/app_style.dart';
import '../models/ride_bike.dart';

class RideBikeCard extends StatelessWidget {
  const RideBikeCard({super.key, required this.bike, required this.onUnlock});

  final RideBike bike;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(16),
    child: LayoutBuilder(
      builder: (context, bounds) {
        final stacked =
            bounds.maxWidth < 280 ||
            MediaQuery.textScalerOf(context).scale(14) > 21;
        final description = Row(
          children: [
            const ExcludeSemantics(
              child: CircleAvatar(
                radius: 25,
                backgroundColor: AppStyle.paleGreen,
                child: Icon(Icons.pedal_bike, size: 31, color: AppStyle.green),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bike #${bike.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Row(
                    children: [
                      Icon(Icons.circle, color: AppStyle.green, size: 7),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Available',
                          style: TextStyle(
                            color: AppStyle.darkGreen,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
        final unlock = FilledButton.icon(
          key: ValueKey('unlock-${bike.id}'),
          onPressed: onUnlock,
          style: FilledButton.styleFrom(
            backgroundColor: AppStyle.darkGreen,
            foregroundColor: Colors.white,
            minimumSize: const Size(100, 48),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: const Icon(Icons.lock_outline_rounded, size: 18),
          label: Text('Unlock', semanticsLabel: 'Unlock bike ${bike.id}'),
        );
        if (stacked) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [description, const SizedBox(height: 16), unlock],
          );
        }
        return Row(
          children: [
            Expanded(child: description),
            const SizedBox(width: 12),
            unlock,
          ],
        );
      },
    ),
  );
}
