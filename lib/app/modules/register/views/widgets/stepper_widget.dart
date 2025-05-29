import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../../core/core.dart';
import '../../../../data/data.dart';
import '../../controllers/register_controller.dart';

class StepperWidget extends GetView<RegisterController> {
  const StepperWidget({super.key});

  Color iconColor(StepRegister step) {
    final currentIndex = StepRegister.values.indexOf(step);
    final currentStep = StepRegister.values.indexOf(controller.stepRegister);

    return switch (currentIndex.compareTo(currentStep)) {
      0 => AppColors.primaryColor,
      -1 => Colors.white,
      _ => AppColors.grayLineColor
    };
  }

  Color circleColor(StepRegister step) {
    final currentIndex = StepRegister.values.indexOf(step);
    final currentStep = StepRegister.values.indexOf(controller.stepRegister);

    return switch (currentIndex.compareTo(currentStep)) {
      -1 => AppColors.primaryColor,
      _ => Colors.white
    };
  }

  Color borderColor(StepRegister step) {
    final currentIndex = StepRegister.values.indexOf(step);
    final currentStep = StepRegister.values.indexOf(controller.stepRegister);

    return switch (currentIndex.compareTo(currentStep)) {
      0 || -1 => AppColors.primaryColor,
      _ => AppColors.grayLineColor
    };
  }

  AlignmentGeometry alignment(StepRegister step) {
    final currentIndex = StepRegister.values.indexOf(step);

    if (currentIndex == 0) {
      return Alignment.centerLeft;
    }
    if (currentIndex == StepRegister.values.length - 1) {
      return Alignment.centerRight;
    }
    return Alignment.center;
  }

  double get valueProgress {
    return switch (controller.stepRegister) {
      StepRegister.establishment => 0.0,
      StepRegister.address => 0.5,
      StepRegister.responsible => 1.0,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Stack(
        children: [
          Positioned(
            top: 24,
            left: 32,
            right: 32,
            child: LinearProgressIndicator(
              value: valueProgress,
              backgroundColor: AppColors.grayLineColor,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
          ),
          ...StepRegister.values.map(
            (step) {
              return Align(
                alignment: alignment(step),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: circleColor(step),
                        border: Border.all(
                          color: borderColor(step),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          step.icon,
                          colorFilter: ColorFilter.mode(
                            iconColor(step),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                    Text(step.description),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
