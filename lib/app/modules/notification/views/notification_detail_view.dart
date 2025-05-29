import 'package:flutter/material.dart';
import 'package:mega_commons/shared/extensions/int_extension.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../core/core.dart';
import '../controllers/notification_controller.dart';

class NotificationDetailView extends GetView<AppNotificationController> {
  const NotificationDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BaseAppBar(
        title: 'Detalhes da notificação',
      ),
      body: Obx(
        () => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.notificationDetail?.title ?? '',
                style: const TextStyle(
                  color: AppColors.mineShaft,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                controller.notificationDetail?.created.toddMMyyyyasHHmm() ?? '',
              ),
              const SizedBox(height: 16),
              Text(
                controller.notificationDetail?.content ?? '',
                style: const TextStyle(
                  color: AppColors.mineShaft,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
