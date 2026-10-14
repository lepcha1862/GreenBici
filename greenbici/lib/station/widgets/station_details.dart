import 'package:flutter/material.dart';

import '../../theme/app_style.dart';
import '../models/bicycle_station.dart';
import '../models/geo_point.dart';

String stationDistance(double meters) => meters < 1000
    ? '${meters.round()} m away'
    : '${(meters / 1000).toStringAsFixed(1)} km away';

class StationDetails extends StatelessWidget {
  const StationDetails({
    super.key,
    required this.station,
    required this.userLocation,
    required this.onRideInStation,
  });

  final BicycleStation station;
  final GeoPoint userLocation;
  final VoidCallback onRideInStation;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      LayoutBuilder(
        builder: (context, constraints) {
          final stacked =
              constraints.maxWidth < 250 ||
              (constraints.maxWidth < 420 &&
                  MediaQuery.textScalerOf(context).scale(14) > 21);
          const icon = CircleAvatar(
            radius: 25,
            backgroundColor: AppStyle.paleGreen,
            child: Icon(Icons.pedal_bike, size: 30, color: AppStyle.darkGreen),
          );
          final summary = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  station.name,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                stationDistance(userLocation.distanceTo(station.location)),
                style: const TextStyle(color: AppStyle.muted),
              ),
              if (station.operatorName != null)
                Text(
                  station.operatorName!,
                  style: const TextStyle(color: AppStyle.muted),
                ),
            ],
          );
          return stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [icon, const SizedBox(height: 12), summary],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    icon,
                    const SizedBox(width: 12),
                    Expanded(child: summary),
                  ],
                );
        },
      ),
      const SizedBox(height: 18),
      if (station.bikesAvailable != null || station.docksAvailable != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _Availability(
                icon: Icons.pedal_bike,
                value: station.bikesAvailable,
                label: 'bikes available',
              ),
              _Availability(
                icon: Icons.local_parking,
                value: station.docksAvailable,
                label: 'docks available',
              ),
            ],
          ),
        ),
      if (station.bikesAvailable == null || station.docksAvailable == null) ...[
        const Text(
          'Live availability is not provided for this station.',
          style: TextStyle(fontSize: 12, color: AppStyle.muted),
        ),
      ],
      const SizedBox(height: 16),
      FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: AppStyle.darkGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onRideInStation,
        icon: const Icon(Icons.pedal_bike_rounded),
        label: const Text('Ride in Station', textAlign: TextAlign.center),
      ),
    ],
  );
}

class _Availability extends StatelessWidget {
  const _Availability({
    required this.icon,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final int? value;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: AppStyle.green, size: 25),
      const SizedBox(width: 8),
      Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value?.toString() ?? '—',
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppStyle.muted),
            ),
          ],
        ),
      ),
    ],
  );
}
