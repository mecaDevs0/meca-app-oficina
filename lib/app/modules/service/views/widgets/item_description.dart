import 'package:flutter/material.dart';

import '../../../../core/core.dart';

class ItemDescription extends StatelessWidget {
  const ItemDescription({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.abbey,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.abbey,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
