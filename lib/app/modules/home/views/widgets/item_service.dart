import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mega_commons/shared/extensions/extensions.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../../core/core.dart';
import '../../../../data/data.dart';
import '../../../../routes/app_pages.dart';

class ItemService extends StatelessWidget {
  const ItemService({
    super.key,
    required this.schedule,
  });

  final ScheduleServiceModel schedule;

  String get _formatPhone {
    if (schedule.profile.phone.isNullOrEmpty) {
      return '';
    }
    final phone = schedule.profile.phone;
    return UtilBrasilFields.obterTelefone(phone!);
  }

  String get newMethod {
    if (schedule.workshopServices.isEmpty) {
      return 'Nenhum serviço';
    }
    if (schedule.workshopServices.length == 1) {
      return '1 serviço';
    }
    return '${schedule.workshopServices.length} serviços';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(
        Routes.serviceDetails,
        arguments: ServiceArgs(schedule.id),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 1, color: AppColors.mercury),
            borderRadius: BorderRadius.circular(8),
          ),
          shadows: const [
            BoxShadow(
              color: Color(0x0C000000),
              blurRadius: 1,
              offset: Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        schedule.date.toddMMyyyyasHHmm(),
                        style: const TextStyle(
                          color: AppColors.silver,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      AppStatusChip(
                        status: ScheduleStatus.values[schedule.status],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(
                    color: AppColors.grayBorderColor,
                    height: 1,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          schedule.workshop.companyName ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.abbey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatPhone,
                        style: const TextStyle(
                          color: AppColors.abbey,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  AppCarDesc(vehicle: schedule.vehicle),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SvgPicture.asset(
                        AppImages.icTools,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        newMethod,
                        style: const TextStyle(
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
            ),
          ],
        ),
      ),
    );
  }
}
