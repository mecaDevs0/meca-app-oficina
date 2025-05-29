import 'package:flutter/material.dart';
import 'package:mega_commons/mega_commons.dart';

import '../../../../core/core.dart';
import '../../../../data/data.dart';

class WithTimeRich extends StatelessWidget {
  const WithTimeRich({
    super.key,
    required this.status,
    this.date,
  });

  final AlertStatus status;
  final int? date;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: RichText(
        maxLines: 2,
        text: TextSpan(
          children: [
            TextSpan(
              text: 'Aguardando veiculo dia ',
              style: TextStyle(
                color: status.color,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextSpan(
              text: date != null ? date!.toddMMyyyy() : '',
              style: const TextStyle(
                color: AppColors.abbey,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
            ),
            TextSpan(
              text: ' às ',
              style: TextStyle(
                color: status.color,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextSpan(
              text: date != null ? date!.toHHmm() : '',
              style: const TextStyle(
                color: AppColors.abbey,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
