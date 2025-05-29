import 'package:flutter/material.dart';
import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../core/core.dart';
import '../../../data/data.dart';
import '../../../data/models/budget_service_model.dart';
import '../controllers/service_details_controller.dart';

class BudgetDetailsView extends GetView<ServiceDetailsController> {
  const BudgetDetailsView({super.key});

  ScheduleStatus get _status {
    return ScheduleStatus.values[controller.scheduleService.status];
  }

  List<BudgetServiceModel> get _getServices {
    final budgetServices = controller.scheduleService.budgetServices ?? [];
    if (budgetServices.isNotEmpty) {
      return budgetServices;
    }
    return controller.scheduleService.budgetServices!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BaseAppBar(title: 'Detalhes do orçamento'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppClientInfo(
              name: controller.scheduleService.profile.fullName ?? '',
              email: controller.scheduleService.profile.email ?? '',
              phone: controller.scheduleService.profile.phone ?? '',
            ),
            const SizedBox(height: 12),
            AppServiceStatus(status: _status),
            const SizedBox(height: 12),
            AppCarDesc(
              vehicle: controller.scheduleService.vehicle,
            ),
            AppDescriptionTile(
              title: 'Data da ultima atualização',
              description: '${controller.scheduleService.date.toddMMyyyy()} '
                  'às ${controller.scheduleService.date.toHHmm()}',
            ),
            AppDescriptionTile(
              title: 'Valor do diagnóstico',
              description:
                  controller.scheduleService.diagnosticValue?.moneyFormat() ??
                      r'R$ 0,00',
            ),
            const SizedBox(height: 16),
            AppTablePrice(
              services: _getServices,
              style: TableStyle.icon,
            ),
            const SizedBox(height: 16),
            AppServiceImages(
              images: controller.scheduleService.budgetImages,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Valor total',
                  style: TextStyle(
                    color: AppColors.abbey,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  controller.scheduleService.totalValue?.moneyFormat() ??
                      'Sem valor',
                  style: const TextStyle(
                    color: AppColors.abbey,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
