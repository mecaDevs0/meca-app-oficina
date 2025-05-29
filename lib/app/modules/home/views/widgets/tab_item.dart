import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../../core/core.dart';
import '../../../../data/data.dart';
import '../../controllers/home_controller.dart';

class TabItem extends GetView<HomeController> {
  const TabItem({
    super.key,
    required this.onTap,
    required this.homeTab,
    required this.selectedTab,
  });

  final void Function() onTap;
  final HomeSection homeTab;
  final HomeSection selectedTab;

  Color get color {
    final isSelected = homeTab == selectedTab;
    return isSelected ? AppColors.primaryColor : AppColors.grayLineColor;
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: onTap,
        child: Column(
          children: [
            Container(
              height: 40,
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    homeTab.icon,
                    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    homeTab.description,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 3,
              color: color,
              margin: EdgeInsets.only(
                right: homeTab == HomeSection.history ? 0 : 8,
                left: homeTab == HomeSection.upcoming ? 0 : 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
