import 'package:flutter/material.dart';

import '../../data/data.dart';
import '../core.dart';

class AppServiceStatus extends StatelessWidget {
  const AppServiceStatus({
    super.key,
    required this.status,
  });

  final ScheduleStatus status;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status do serviço',
          style: TextStyle(
            color: AppColors.abbey,
            fontSize: 14,
            height: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        AppStatusChip(
          status: status,
        ),
      ],
    );
  }
}
