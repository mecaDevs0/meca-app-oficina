import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../../core/core.dart';
import '../../../../data/data.dart';
import '../../controllers/core_controller.dart';

class BottomBarItem extends GetView<CoreController> {
  const BottomBarItem({
    super.key,
    required this.bottomBarEnum,
    required this.onTap,
  });

  final NavigationTab bottomBarEnum;
  final void Function() onTap;

  String get icon {
    return switch (bottomBarEnum) {
      NavigationTab.home => AppImages.icHome,
      NavigationTab.schedule => AppImages.icSchedule,
      NavigationTab.financial => AppImages.icFinancial,
      NavigationTab.profile => AppImages.icProfile,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => InkWell(
        splashColor: Colors.transparent,
        onTap: onTap,
        child: SizedBox(
          width: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (controller.currentIndex == bottomBarEnum.index)
                Container(
                  width: 21,
                  height: 3,
                  decoration: ShapeDecoration(
                    color: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ).animate().moveY(
                      begin: -10,
                      end: 0,
                    ),
              const SizedBox(height: 8),
              SizedBox(
                height: 24,
                child: SvgPicture.asset(
                  icon,
                  colorFilter: ColorFilter.mode(
                    controller.currentIndex == bottomBarEnum.index
                        ? AppColors.primaryColor
                        : AppColors.grayLineColor,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                bottomBarEnum.description,
                style: TextStyle(
                  color: controller.currentIndex == bottomBarEnum.index
                      ? AppColors.primaryColor
                      : AppColors.grayLineColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
