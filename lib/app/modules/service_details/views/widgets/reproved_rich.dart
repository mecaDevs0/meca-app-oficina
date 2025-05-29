import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../../core/core.dart';
import '../../../../data/data.dart';
import '../../../../routes/app_pages.dart';
import '../../controllers/service_details_controller.dart';

class ReprovedRich extends GetView<ServiceDetailsController> {
  const ReprovedRich({
    super.key,
    required this.status,
    required this.id,
  });

  final AlertStatus status;
  final String id;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Serviço reprovado ',
            style: TextStyle(
              color: status.color,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(
            text: 'Veja os motivos',
            style: const TextStyle(
              color: AppColors.abbey,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                final isResult = await Get.toNamed(
                  Routes.serviceFailed,
                  arguments: ServiceArgs(id),
                );
                if (isResult) {
                  controller.getServiceDetails(id);
                }
              },
          ),
        ],
      ),
    );
  }
}
