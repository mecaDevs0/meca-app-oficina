import 'package:flutter/material.dart';
import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../../core/core.dart';
import '../../../../routes/app_pages.dart';
import '../../controllers/service_failed_controller.dart';

class BottomActions extends GetView<ServiceFailedController> {
  const BottomActions({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final double bottomPadding = bottom == 0 ? 8 : 22;
    return Obx(
      () => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x3F000000),
              blurRadius: 4,
              offset: Offset.zero,
              spreadRadius: 0,
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MegaBaseButton(
              'Sugerir reparo gratuito',
              textStyle: AppTextStyle.buttonTextStyle,
              borderRadius: 4,
              isLoading: controller.isLoading,
              onButtonPress: () async {
                final isSuccess = await controller.suggestFreeRepair();
                if (isSuccess) {
                  Get.back(result: true);
                }
              },
            ),
            const SizedBox(height: 16),
            MegaBaseButton(
              'Contestar',
              buttonColor: AppColors.apricot,
              textStyle: AppTextStyle.buttonTextStyle,
              borderRadius: 4,
              onButtonPress: () async {
                final isResult = await Get.toNamed(Routes.disputeFailedService);
                if (isResult == true) {
                  Get.back(result: true);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
