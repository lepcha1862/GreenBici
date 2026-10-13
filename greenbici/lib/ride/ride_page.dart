import 'package:flutter/material.dart';

import '../navbar/top_nav.dart';
import '../theme/app_style.dart';
import 'data/sample_inventory.dart';
import 'models/ride_bike.dart';
import 'widgets/bike_card.dart';
import 'widgets/return_note.dart';
import 'widgets/station_summary.dart';

/// Ride inventory content. The application shell supplies the navigation.
class RidePage extends StatelessWidget {
  const RidePage({super.key, this.onSearch});

  final VoidCallback? onSearch;

  Future<void> _showUnlockPreview(BuildContext context, RideBike bike) =>
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          scrollable: true,
          title: const Text('Unlock unavailable'),
          content: Text(
            'Bike #${bike.id} is a sample bike. Unlocking requires a connected '
            'bike operator.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: ColoredBox(
      color: AppStyle.canvas,
      child: LayoutBuilder(
        builder: (context, bounds) => SingleChildScrollView(
          key: const PageStorageKey('ride-scroll'),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: bounds.maxWidth < 360 ? 16 : 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TopNav(title: 'Available Bikes', onSearch: onSearch),
                    LayoutBuilder(
                      builder: (context, contentBounds) {
                        final summary = RideStationSummary(
                          stationName: SampleInventory.stationName,
                          distance: SampleInventory.distance,
                          bikeCount: SampleInventory.bikes.length,
                        );
                        final bikes = Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final bike in SampleInventory.bikes) ...[
                              RideBikeCard(
                                bike: bike,
                                onUnlock: () =>
                                    _showUnlockPreview(context, bike),
                              ),
                              const SizedBox(height: 14),
                            ],
                            const RideReturnNote(),
                          ],
                        );
                        final wide =
                            contentBounds.maxWidth >= 850 &&
                            MediaQuery.textScalerOf(context).scale(14) <= 21;
                        if (wide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 2, child: summary),
                              const SizedBox(width: 28),
                              Expanded(flex: 3, child: bikes),
                            ],
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            summary,
                            const SizedBox(height: 22),
                            bikes,
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
