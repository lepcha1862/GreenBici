import 'package:flutter/material.dart';

import '../home_style.dart';

class OffersSection extends StatelessWidget {
  const OffersSection({
    super.key,
    required this.onViewAll,
    required this.onOfferTap,
  });

  final VoidCallback onViewAll;
  final ValueChanged<String> onOfferTap;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SectionHeading(title: 'Offers for You', onViewAll: onViewAll),
      LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
          final stacked = constraints.maxWidth < 480 || textScale > 1.4;
          final compact = !stacked && constraints.maxWidth < 600;
          final cards = [
            _OfferCard(
              title: 'Weekend Ride',
              description: '20% off on all rides',
              detail: 'Valid till May 18',
              icon: Icons.local_offer_outlined,
              compact: compact,
              onTap: () => onOfferTap('Weekend Ride'),
            ),
            _OfferCard(
              title: 'Monthly Saver',
              description: 'Save up to 15%',
              detail: 'Valid till May 31',
              icon: Icons.percent_rounded,
              blue: true,
              compact: compact,
              onTap: () => onOfferTap('Monthly Saver'),
            ),
            _OfferCard(
              title: 'Refer & Ride',
              description: 'Get 1 free ride',
              detail: 'Know more',
              icon: Icons.card_giftcard_outlined,
              compact: compact,
              onTap: () => onOfferTap('Refer & Ride'),
            ),
          ];
          if (stacked) {
            return Column(
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  cards[i],
                ],
              ],
            );
          }
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(width: 14),
                  Expanded(child: cards[i]),
                ],
              ],
            ),
          );
        },
      ),
    ],
  );
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.title,
    required this.description,
    required this.detail,
    required this.icon,
    required this.compact,
    required this.onTap,
    this.blue = false,
  });

  final String title;
  final String description;
  final String detail;
  final IconData icon;
  final bool compact;
  final bool blue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final symbol = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: blue ? HomeStyle.blue : HomeStyle.green,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 27),
    );
    final label = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: HomeStyle.ink,
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          description,
          style: const TextStyle(
            color: Color(0xFF6F776B),
            fontSize: 11.5,
            height: 1.25,
          ),
        ),
        Text(
          detail,
          style: const TextStyle(
            color: HomeStyle.muted,
            fontSize: 11.5,
            height: 1.25,
          ),
        ),
      ],
    );
    return HomeCard(
      color: blue ? const Color(0xFFEDF8FC) : const Color(0xFFF2F8F0),
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [symbol, const SizedBox(height: 10), label],
            )
          : Row(
              children: [
                symbol,
                const SizedBox(width: 10),
                Expanded(child: label),
              ],
            ),
    );
  }
}
