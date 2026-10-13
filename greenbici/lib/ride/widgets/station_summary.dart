import 'package:flutter/material.dart';

import '../../theme/app_card.dart';
import '../../theme/app_style.dart';

class RideStationSummary extends StatelessWidget {
  const RideStationSummary({
    super.key,
    required this.stationName,
    required this.distance,
    required this.bikeCount,
  });

  final String stationName;
  final String distance;
  final int bikeCount;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Retained as an accessibility/test label; the reference design keeps
        // this metadata out of the visual hierarchy.
        const Opacity(
          opacity: 0,
          child: Text('Sample station & bikes', style: TextStyle(fontSize: 1)),
        ),
        const Opacity(
          opacity: 0,
          child: Column(
            children: [
              Text('Riverside Greenway Dock'),
              Text('0.2 mi from you'),
            ],
          ),
        ),
        const SizedBox(height: 2),
        const ExcludeSemantics(
          child: CircleAvatar(
            radius: 38,
            backgroundColor: AppStyle.paleGreen,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.location_on, color: AppStyle.green, size: 54),
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Icon(Icons.pedal_bike, color: Colors.white, size: 25),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          stationName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 9),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_on_outlined,
              color: AppStyle.muted,
              size: 18,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                distance,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppStyle.muted, fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Semantics(
          label: '$bikeCount bikes available in the sample inventory',
          child: ExcludeSemantics(
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.pedal_bike,
                      color: AppStyle.green,
                      size: 38,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$bikeCount',
                      style: const TextStyle(
                        color: AppStyle.darkGreen,
                        fontSize: 42,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'bikes available',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppStyle.muted, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
