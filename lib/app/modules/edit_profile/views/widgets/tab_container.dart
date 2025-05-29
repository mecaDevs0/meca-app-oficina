import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../../core/core.dart';
import '../../../../data/data.dart';
import '../../controllers/edit_profile_controller.dart';

class TabContainer extends GetView<EditProfileController> {
  const TabContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: StepRegister.values
            .map(
              (step) => Expanded(
                child: _TabItem(
                  step: step,
                  isSelected: step == controller.stepRegister,
                  onTap: () => controller.stepRegister = step,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.step,
    required this.isSelected,
    required this.onTap,
  });

  final StepRegister step;
  final bool isSelected;
  final Function() onTap;

  Color get color {
    if (isSelected) {
      return AppColors.primaryColor;
    }
    return AppColors.grayLineColor;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: color,
              width: 3,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                step.icon,
                colorFilter: ColorFilter.mode(
                  color,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    step.description,
                    key: ValueKey(step.description),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
