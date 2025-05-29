import 'package:flutter/material.dart';

import '../../data/data.dart';
import '../core.dart';

class AppCarDesc extends StatelessWidget {
  const AppCarDesc({
    super.key,
    this.isVisibleTitle = true,
    required this.vehicle,
  });

  final bool isVisibleTitle;
  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isVisibleTitle)
          const Text(
            'Veículo',
            style: TextStyle(
              color: AppColors.abbey,
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        Row(
          children: [
            Text(
              vehicle.model,
              style: const TextStyle(
                color: AppColors.abbey,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 2,
              height: 2,
              decoration: const ShapeDecoration(
                color: AppColors.alto,
                shape: OvalBorder(),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              vehicle.plate ?? '-',
              style: const TextStyle(
                color: AppColors.abbey,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
