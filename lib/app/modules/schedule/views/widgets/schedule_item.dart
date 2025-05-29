import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../../core/core.dart';
import '../../../../data/data.dart';
import '../../controllers/schedule_controller.dart';

class ScheduleItem extends GetView<ScheduleController> {
  const ScheduleItem({
    super.key,
    required this.schedule,
  });

  final WorkshopAgendaModel schedule;

  bool get isNotSchedule {
    return schedule.available;
  }

  bool get isRemoved {
    final hasProfile = schedule.profile != null;
    final isAvailable = schedule.available;
    return !hasProfile && !isAvailable;
  }

  @override
  Widget build(BuildContext context) {
    if (isRemoved) {
      return const SizedBox.shrink();
    }
    return Container(
      height: 120,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: AppColors.mercury),
          borderRadius: BorderRadius.circular(8),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 4,
            offset: Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: ShapeDecoration(
                  color: isNotSchedule
                      ? AppColors.hintTextColor
                      : AppColors.primaryColor,
                  shape: const OvalBorder(),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                schedule.hour,
                style: const TextStyle(
                  color: AppColors.dustyGray,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (isNotSchedule)
                GestureDetector(
                  onTap: () => controller.deleteHour(schedule),
                  child: SvgPicture.asset(
                    AppImages.icClose,
                  ),
                ),
            ],
          ),
          const Divider(color: AppColors.grayBorderColor),
          if (isNotSchedule)
            const Text(
              'Horário disponivel',
              style: TextStyle(
                color: AppColors.abbey,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      schedule.profile?.fullName ?? '',
                      style: const TextStyle(
                        color: AppColors.abbey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      schedule.profile?.phone.formattedPhone ?? '',
                      style: const TextStyle(
                        color: AppColors.abbey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                AppCarDesc(
                  isVisibleTitle: false,
                  vehicle: VehicleModel.empty(),
                ),
                Row(
                  children: [
                    SvgPicture.asset(
                      AppImages.icTools,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '2 serviços',
                      style: TextStyle(
                        color: AppColors.hintTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Ver detalhes',
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(width: 4),
                    SvgPicture.asset(
                      AppImages.icArrow,
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    ).shade;
  }
}
