import 'package:flutter/material.dart';

import '../home_style.dart';

class StationsSection extends StatelessWidget {
  const StationsSection({
    super.key,
    required this.onViewAll,
    required this.onStationTap,
  });

  final VoidCallback onViewAll;
  final ValueChanged<String> onStationTap;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SectionHeading(title: 'Nearby Docking Stations', onViewAll: onViewAll),
      LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
          final stacked = constraints.maxWidth < 540 || textScale > 1.4;
          final cards = [
            _StationCard(
              name: 'Central Park Station',
              distance: '0.4 km away',
              bikes: '12 / 18 bikes',
              image: 'assets/images/home/central_park.jpg',
              limited: false,
              onTap: () => onStationTap('Central Park Station'),
            ),
            _StationCard(
              name: 'Riverside Station',
              distance: '0.8 km away',
              bikes: '3 / 15 bikes',
              image: 'assets/images/home/riverside.jpg',
              limited: true,
              onTap: () => onStationTap('Riverside Station'),
            ),
          ];
          if (stacked) {
            return Column(
              children: [cards[0], const SizedBox(height: 12), cards[1]],
            );
          }
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 16),
                Expanded(child: cards[1]),
              ],
            ),
          );
        },
      ),
    ],
  );
}

class _StationCard extends StatelessWidget {
  const _StationCard({
    required this.name,
    required this.distance,
    required this.bikes,
    required this.image,
    required this.limited,
    required this.onTap,
  });

  final String name;
  final String distance;
  final String bikes;
  final String image;
  final bool limited;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => HomeCard(
    padding: const EdgeInsets.all(11),
    onTap: onTap,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Image.asset(
            image,
            width: 76,
            height: 80,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 76,
              height: 80,
              color: HomeStyle.paleGreen,
              child: const Icon(
                Icons.park_outlined,
                color: HomeStyle.green,
                size: 32,
              ),
            ),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: HomeStyle.ink,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 15,
                    color: HomeStyle.muted,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      distance,
                      style: const TextStyle(
                        color: HomeStyle.muted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.pedal_bike_rounded,
                        color: Color(0xFF679B9B),
                        size: 19,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          bikes,
                          style: const TextStyle(
                            color: HomeStyle.ink,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: limited
                          ? const Color(0xFFFFF1CF)
                          : const Color(0xFFE9F5E5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      limited ? 'Limited' : 'Available',
                      style: TextStyle(
                        color: limited
                            ? const Color(0xFFB28A31)
                            : HomeStyle.darkGreen,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
