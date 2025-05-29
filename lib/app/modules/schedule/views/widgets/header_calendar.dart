import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../../core/core.dart';
import '../../controllers/schedule_controller.dart';

class HeaderCalendar extends GetView<ScheduleController> {
  const HeaderCalendar({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.only(left: 8, right: 8, bottom: 12),
        child: Row(
          children: [
            ToggleButton(
              icon: AppImages.icLeft,
              onTap: controller.previousMonth,
            ),
            Expanded(
              child: Center(
                child: Column(
                  children: [
                    Text(
                      DateFormat('MMMM', 'pt-BR')
                          .format(controller.selectedMonth)
                          .capitalize!,
                      style: const TextStyle(
                        fontSize: 20,
                        color: AppColors.cloudBurst,
                      ),
                    ),
                    Text(
                      DateFormat('yyyy', 'pt-BR')
                          .format(controller.selectedMonth),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.baliHai,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ToggleButton(
              onTap: controller.nextMonth,
              icon: AppImages.icRight,
            ),
          ],
        ),
      ),
    );
  }
}

class ToggleButton extends StatelessWidget {
  const ToggleButton({
    super.key,
    required this.onTap,
    required this.icon,
  });

  final VoidCallback onTap;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 1, color: AppColors.grayLineColor),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        child: SvgPicture.asset(icon),
      ),
    );
  }
}
