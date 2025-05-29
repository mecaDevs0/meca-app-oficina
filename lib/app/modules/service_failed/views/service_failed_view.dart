import 'package:flutter/material.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../core/core.dart';
import '../../../data/models/models.dart';
import '../controllers/service_failed_controller.dart';
import 'widgets/bottom_actions.dart';

class ServiceFailedView extends GetView<ServiceFailedController> {
  const ServiceFailedView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BaseAppBar(title: 'Serviço reprovado'),
      body: Obx(
        () {
          if (controller.isLoadingService) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryColor,
              ),
            );
          }
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppClientInfo(
                        name: controller.serviceFailed?.profile.fullName ?? '',
                        email: controller.serviceFailed?.profile.email ?? '',
                        phone: controller
                                .serviceFailed?.profile.phone?.formattedPhone ??
                            '',
                      ),
                      const SizedBox(height: 12),
                      AppCarDesc(
                        vehicle: controller.serviceFailed?.vehicle ??
                            VehicleModel.empty(),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Motivo da reprovação',
                        style: TextStyle(
                          color: AppColors.apricot,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        controller.serviceFailed?.reasonDisapproval ??
                            'Sem motivo',
                        style: const TextStyle(
                          color: AppColors.boulder,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 32),
                      AppServiceImages(
                        images:
                            controller.serviceFailed?.imagesDisapproval ?? [],
                      ),
                    ],
                  ),
                ),
              ),
              const BottomActions(),
            ],
          );
        },
      ),
    );
  }
}
