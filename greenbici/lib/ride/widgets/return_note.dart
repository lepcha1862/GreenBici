import 'package:flutter/material.dart';

import '../../theme/app_style.dart';

class RideReturnNote extends StatelessWidget {
  const RideReturnNote({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppStyle.paleGreen,
      borderRadius: BorderRadius.circular(18),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.swap_horiz_rounded, size: 27, color: AppStyle.darkGreen),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Ride one way—return your bike to any eligible docking station.',
            style: TextStyle(
              color: AppStyle.darkGreen,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  );
}
