import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../../core/core.dart';
import '../../../../routes/app_pages.dart';

class CoreAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CoreAppBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: SvgPicture.asset(AppImages.icMenu),
      ),
      actions: [
        GestureDetector(
          onTap: () {
            Get.toNamed(Routes.notifications);
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Stack(
              children: [
                SvgPicture.asset(AppImages.icNotification),
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    height: 10,
                    width: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.ceriseRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      backgroundColor: AppColors.primaryColor,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
