import 'package:flutter/material.dart';

import '../navbar/top_nav.dart';
import '../theme/app_card.dart';
import '../theme/app_style.dart';

enum NotificationFilter { all, rides, updates, offers }

class NotificationItem {
  const NotificationItem({
    required this.title,
    required this.message,
    required this.time,
    required this.filter,
    required this.icon,
    required this.tint,
    this.unread = false,
  });
  final String title;
  final String message;
  final String time;
  final NotificationFilter filter;
  final IconData icon;
  final Color tint;
  final bool unread;
}

/// Demo notification feed. Replace this list with the API response mapper.
const demoNotifications = <NotificationItem>[
  NotificationItem(
    title: 'Scheduled maintenance',
    message: 'Stations will be unavailable Sunday, 2:00–3:00 AM.',
    time: '10 min ago',
    filter: NotificationFilter.updates,
    icon: Icons.settings,
    tint: Color(0xFFFFA128),
    unread: true,
  ),
  NotificationItem(
    title: 'Ride completed',
    message: '28 min · 4.2 km · Nu. 45 charged.',
    time: '1 hour ago',
    filter: NotificationFilter.rides,
    icon: Icons.pedal_bike,
    tint: AppStyle.green,
    unread: true,
  ),
  NotificationItem(
    title: 'App improvements',
    message: 'Station availability now refreshes faster.',
    time: 'Yesterday',
    filter: NotificationFilter.updates,
    icon: Icons.bar_chart_rounded,
    tint: Color(0xFF4B99D0),
  ),
  NotificationItem(
    title: 'Weekend ride offer',
    message: 'Save 20% on your next ride through Sunday.',
    time: 'Yesterday',
    filter: NotificationFilter.offers,
    icon: Icons.local_offer_outlined,
    tint: AppStyle.green,
  ),
  NotificationItem(
    title: 'Happy Paro Tsechu!',
    message: 'Celebrate with 15% off rides this week.',
    time: '2 days ago',
    filter: NotificationFilter.offers,
    icon: Icons.local_florist_outlined,
    tint: Color(0xFF7851B8),
  ),
  NotificationItem(
    title: 'Diwali rides',
    message: 'Enjoy 20% off all rides this Diwali week.',
    time: '3 days ago',
    filter: NotificationFilter.offers,
    icon: Icons.wb_sunny_outlined,
    tint: Color(0xFFE4A255),
  ),
  NotificationItem(
    title: 'Refer & earn',
    message: 'Invite a friend and get Nu. 50.',
    time: '4 days ago',
    filter: NotificationFilter.offers,
    icon: Icons.card_giftcard_outlined,
    tint: AppStyle.green,
  ),
];

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key, this.onSearch});

  final VoidCallback? onSearch;

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  NotificationFilter _filter = NotificationFilter.all;

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final items = demoNotifications
            .where(
              (item) =>
                  _filter == NotificationFilter.all || item.filter == _filter,
            )
            .toList();
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: constraints.maxWidth < 360 ? 14 : 20,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(),
                  _filters(),
                  const SizedBox(height: 16),
                  for (final item in items) ...[
                    _NotificationCard(item: item),
                    const SizedBox(height: 14),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );

  Widget _header() => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: TopNav(title: 'Notifications', onSearch: widget.onSearch),
      ),
      Container(
        margin: const EdgeInsets.only(bottom: 28, right: 12),
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppStyle.green,
          shape: BoxShape.circle,
        ),
        child: Text(
          '${demoNotifications.where((item) => item.unread).length}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    ],
  );

  Widget _filters() => LayoutBuilder(
    builder: (context, constraints) {
      final compact =
          constraints.maxWidth < 440 ||
          MediaQuery.textScalerOf(context).scale(14) > 21;
      final columns = compact ? 2 : 4;
      final spacing = constraints.maxWidth < 360 ? 6.0 : 10.0;
      final itemWidth =
          (constraints.maxWidth - spacing * (columns - 1)) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: 8,
        children: NotificationFilter.values.map((filter) {
          final selected = filter == _filter;
          return SizedBox(
            width: itemWidth,
            child: Semantics(
              button: true,
              selected: selected,
              label: _filterLabel(filter),
              child: GestureDetector(
                onTap: () => setState(() => _filter = filter),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  constraints: const BoxConstraints(minHeight: 52),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppStyle.green : Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x080E2E0A),
                        blurRadius: 12,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    _filterLabel(filter),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? Colors.white : AppStyle.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );
    },
  );

  String _filterLabel(NotificationFilter filter) => switch (filter) {
    NotificationFilter.all => 'All',
    NotificationFilter.rides => 'Rides',
    NotificationFilter.updates => 'Updates',
    NotificationFilter.offers => 'Offers',
  };
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item});
  final NotificationItem item;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(16),
    color: item.unread ? const Color(0xFFFFFCF1) : Colors.white,
    radius: 20,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 280 ||
            MediaQuery.textScalerOf(context).scale(14) > 21;
        final avatar = CircleAvatar(
          radius: compact ? 25 : 31,
          backgroundColor: item.tint.withValues(alpha: .12),
          child: Icon(item.icon, color: item.tint, size: compact ? 25 : 30),
        );
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              item.message,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: AppStyle.ink,
              ),
            ),
          ],
        );
        final status = Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              item.time,
              style: const TextStyle(color: AppStyle.muted, fontSize: 12),
            ),
            const SizedBox(height: 18),
            if (item.unread)
              const Icon(Icons.circle, color: AppStyle.green, size: 12),
          ],
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  avatar,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.message,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: AppStyle.ink,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.time,
                      style: const TextStyle(
                        color: AppStyle.muted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (item.unread)
                    const Icon(Icons.circle, color: AppStyle.green, size: 12),
                ],
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            avatar,
            const SizedBox(width: 16),
            Expanded(child: content),
            const SizedBox(width: 12),
            status,
          ],
        );
      },
    ),
  );
}
