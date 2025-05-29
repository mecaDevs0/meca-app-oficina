import 'package:flutter/material.dart';

import '../core.dart';

class AppRequirementItem extends StatelessWidget {
  const AppRequirementItem({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: const ShapeDecoration(
            color: AppColors.alto,
            shape: OvalBorder(),
          ),
        ),
        const SizedBox(width: 8),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$title:',
                style: const TextStyle(
                  color: AppColors.black,
                ),
              ),
              TextSpan(
                text: ' $subtitle',
                style: const TextStyle(
                  color: AppColors.abbey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
