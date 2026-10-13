import 'package:flutter/material.dart';

import '../home_style.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({
    super.key,
    required this.onFindStation,
    required this.onStartRide,
    required this.onMyRides,
  });

  final VoidCallback onFindStation;
  final VoidCallback onStartRide;
  final VoidCallback onMyRides;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SectionHeading(title: 'Quick Actions'),
      LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
          final stacked = constraints.maxWidth < 340 || textScale > 1.5;
          final compact = constraints.maxWidth < 560 && !stacked;
          final actions = [
            _ActionCard(
              title: 'Find Station',
              description: 'Locate nearby stations',
              icon: Icons.location_on_outlined,
              compact: compact,
              onTap: onFindStation,
            ),
            _ActionCard(
              title: 'Start Ride',
              description: 'Scan to unlock a bike',
              icon: Icons.pedal_bike_rounded,
              compact: compact,
              onTap: onStartRide,
            ),
            _ActionCard(
              title: 'My Rides',
              description: 'View your ride history',
              icon: Icons.assignment_outlined,
              compact: compact,
              onTap: onMyRides,
            ),
          ];
          if (stacked) {
            return Column(
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  actions[i],
                ],
              ],
            );
          }
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(child: actions[i]),
                ],
              ],
            ),
          );
        },
      ),
    ],
  );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.compact,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final symbol = Container(
      width: 42,
      height: 44,
      decoration: BoxDecoration(
        color: HomeStyle.paleGreen,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(icon, color: HomeStyle.green, size: 28),
    );
    final label = Column(
      crossAxisAlignment: compact
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: const TextStyle(
            color: HomeStyle.ink,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          description,
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: const TextStyle(
            color: HomeStyle.muted,
            fontSize: 11.5,
            height: 1.3,
          ),
        ),
      ],
    );
    return HomeCard(
      padding: EdgeInsets.symmetric(horizontal: compact ? 9 : 14, vertical: 16),
      onTap: onTap,
      child: compact
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [symbol, const SizedBox(height: 10), label],
            )
          : Row(
              children: [
                symbol,
                const SizedBox(width: 10),
                Expanded(child: label),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: HomeStyle.muted,
                ),
              ],
            ),
    );
  }
}
