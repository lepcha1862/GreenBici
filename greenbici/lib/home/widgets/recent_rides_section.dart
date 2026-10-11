import 'package:flutter/material.dart';

import '../home_style.dart';

class RecentRidesSection extends StatelessWidget {
  const RecentRidesSection({
    super.key,
    required this.onViewAll,
    required this.onRideTap,
  });

  final VoidCallback onViewAll;
  final ValueChanged<String> onRideTap;

  static const _rides = [
    _Ride(
      from: 'Central Park',
      to: 'Downtown Hub',
      date: 'May 16, 2025',
      time: '8:32 AM',
      duration: '24 min',
      price: '\$2.40',
      color: HomeStyle.green,
    ),
    _Ride(
      from: 'Riverside Station',
      to: 'Central Park',
      date: 'May 15, 2025',
      time: '6:45 PM',
      duration: '18 min',
      price: '\$1.80',
      color: Color(0xFF5EBAAA),
    ),
    _Ride(
      from: 'Lakeside Dock',
      to: 'Tech Park',
      date: 'May 14, 2025',
      time: '12:20 PM',
      duration: '32 min',
      price: '\$3.20',
      color: HomeStyle.blue,
    ),
    _Ride(
      from: 'University Station',
      to: 'Central Park',
      date: 'May 13, 2025',
      time: '5:10 PM',
      duration: '21 min',
      price: '\$2.10',
      color: HomeStyle.blue,
    ),
    _Ride(
      from: 'Downtown Hub',
      to: 'Riverside Station',
      date: 'May 12, 2025',
      time: '9:05 AM',
      duration: '27 min',
      price: '\$2.70',
      color: Color(0xFF76A15C),
    ),
  ];

  @override
  Widget build(BuildContext context) => HomeCard(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 5),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading(title: 'Top 5 Recent Rides', onViewAll: onViewAll),
        for (var i = 0; i < _rides.length; i++) ...[
          if (i > 0)
            const Divider(height: 1, color: HomeStyle.border, indent: 38),
          _RideRow(
            ride: _rides[i],
            onTap: () => onRideTap('${_rides[i].from} → ${_rides[i].to}'),
          ),
        ],
      ],
    ),
  );
}

class _Ride {
  const _Ride({
    required this.from,
    required this.to,
    required this.date,
    required this.time,
    required this.duration,
    required this.price,
    required this.color,
  });

  final String from;
  final String to;
  final String date;
  final String time;
  final String duration;
  final String price;
  final Color color;
}

class _RideRow extends StatelessWidget {
  const _RideRow({required this.ride, required this.onTap});

  final _Ride ride;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
      final compact = constraints.maxWidth < 510 || textScale > 1.3;
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 3),
          child: Row(
            children: [
              SizedBox(
                width: 13,
                height: 29,
                child: CustomPaint(painter: _RoutePainter(ride.color)),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        text: '${ride.from} → ',
                        children: [
                          TextSpan(
                            text: ride.to,
                            style: const TextStyle(color: Color(0xFF747C72)),
                          ),
                        ],
                      ),
                      style: const TextStyle(
                        color: HomeStyle.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${ride.date} • ${ride.time}',
                      style: const TextStyle(
                        color: HomeStyle.muted,
                        fontSize: 11.5,
                        height: 1.3,
                      ),
                    ),
                    if (compact) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 20,
                        runSpacing: 4,
                        children: [
                          _RideMetric(ride.duration),
                          _RideMetric(ride.price),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: 18),
                SizedBox(width: 90, child: _RideMetric(ride.duration)),
                SizedBox(width: 61, child: _RideMetric(ride.price)),
              ],
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                size: 21,
                color: HomeStyle.ink,
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _RideMetric extends StatelessWidget {
  const _RideMetric(this.value);

  final String value;

  @override
  Widget build(BuildContext context) => Text(
    value,
    style: const TextStyle(
      color: HomeStyle.ink,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
  );
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final top = Offset(size.width / 2, 5);
    final bottom = Offset(size.width / 2, size.height - 5);
    canvas.drawLine(top, bottom, paint);
    canvas.drawCircle(top, 4.5, paint);
    canvas.drawCircle(bottom, 4.5, paint);
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) =>
      oldDelegate.color != color;
}
