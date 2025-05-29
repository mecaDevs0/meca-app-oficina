import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../core/core.dart';
import '../../../../data/enums/alert_status.dart';
import 'budget_info_rich.dart';
import 'info_rich.dart';
import 'reproved_rich.dart';
import 'with_time_rich.dart';

class StatusAlert extends StatelessWidget {
  const StatusAlert({
    super.key,
    required this.status,
    this.id,
    this.date,
  }) : assert(status != AlertStatus.reproved || id != null);

  final AlertStatus status;
  final String? id;
  final int? date;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: ShapeDecoration(
        color: status.color.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: status.color),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            AppImages.icInfoAlert,
            colorFilter: ColorFilter.mode(status.color, BlendMode.srcIn),
          ),
          const SizedBox(width: 10),
          switch (status) {
            AlertStatus.reproved => ReprovedRich(
                status: status,
                id: id ?? '',
              ),
            AlertStatus.withTime => WithTimeRich(
                status: status,
                date: date,
              ),
            AlertStatus.info => InfoRich(status: status),
            AlertStatus.waitingApproveBudget => BudgetInfoRich(status: status),
            AlertStatus.waitingCarParts => InfoRich(status: status),
          },
        ],
      ),
    );
  }
}
