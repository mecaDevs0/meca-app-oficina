import 'package:flutter/material.dart';
import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../../core/core.dart';
import '../../../../data/data.dart';
import '../../../../routes/app_pages.dart';
import '../../controllers/service_details_controller.dart';
import 'status_alert.dart';

class ServiceInfo extends GetView<ServiceDetailsController> {
  const ServiceInfo({
    super.key,
  });

  ScheduleStatus get _status {
    return ScheduleStatus.values[controller.scheduleService.status];
  }

  bool isOrderDateClose(
    int? orderDate, {
    Duration threshold = const Duration(hours: 1),
  }) {
    if (orderDate == null) {
      return false;
    }

    final DateTime now = DateTime.now();
    final Duration difference = orderDate.toDateTime().difference(now);

    return difference.abs() <= threshold;
  }

  List<WorkshopServiceModel> get _getServices {
    return controller.scheduleService.workshopServices;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.scheduleService.status == 20) ...[
            StatusAlert(
              status: AlertStatus.reproved,
              id: controller.scheduleService.id,
              date: controller.scheduleService.date,
            ),
          ],
          if (isOrderDateClose(controller.scheduleService.date) &&
              controller.scheduleService.freeRepair == false) ...[
            const StatusAlert(status: AlertStatus.info),
          ] else if (controller.scheduleService.status == 3) ...[
            StatusAlert(
              status: AlertStatus.withTime,
              date: controller.scheduleService.date,
            ),
          ],
          AppServiceStatus(status: _status),
          const SizedBox(height: 12),
          AppCarDesc(vehicle: controller.scheduleService.vehicle),
          Visibility(
            visible: controller.scheduleService.lastUpdate != null,
            child: AppDescriptionTile(
              title: 'Data da ultima atualização',
              description:
                  controller.scheduleService.lastUpdate?.toddMMyyyyHHmm() ??
                      'Sem data',
            ),
          ),
          if (controller.scheduleService.paymentDate != null) ...[
            AppDescriptionTile(
              title: 'Data do pagamento',
              description:
                  controller.scheduleService.paymentDate?.toddMMyyyyHHmm() ??
                      'Sem data',
            ),
          ],
          Visibility(
            visible: controller.scheduleService.suggestedDate != null &&
                (controller.scheduleService.status == 1 ||
                    controller.scheduleService.status == 2),
            child: AppDescriptionTile(
              title: 'Novo horário sugerido pela oficina',
              description:
                  controller.scheduleService.suggestedDate?.toddMMyyyyHHmm() ??
                      'Sem data',
            ),
          ),
          const SizedBox(height: 12),
          AppDescriptionTile(
            title: 'Data do agendamento',
            description: controller.scheduleService.date.toddMMyyyyHHmm(),
          ),
          const SizedBox(height: 12),
          const Text(
            'Serviços solicitados',
            style: TextStyle(
              color: AppColors.abbey,
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _getServices
                .map(
                  (service) =>
                      AppStatusChip(label: service.service?.name ?? 'Sem nome'),
                )
                .toList(),
          ),
          Visibility(
            visible: controller.scheduleService.diagnosticValue != null,
            child: AppDescriptionTile(
              title: 'Valor do diagnóstico',
              description:
                  controller.scheduleService.diagnosticValue?.moneyFormat() ??
                      r'R$ 0,00',
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: ShapeDecoration(
              shape: RoundedRectangleBorder(
                side: const BorderSide(
                  width: 1,
                  color: AppColors.grayLineColor,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Observações',
                  style: TextStyle(
                    color: AppColors.abbey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  controller.scheduleService.observations ?? 'Sem observações',
                  style: const TextStyle(
                    color: AppColors.boulder,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Visibility(
            visible: controller.scheduleService.status >= 7,
            child: Center(
              child: TextButton(
                onPressed: () => Get.toNamed(Routes.budgetDetails),
                child: const Text(
                  'ver detalhes do orçamento',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ),
          Visibility(
            visible: controller.scheduleService.totalValue != null,
            child: Column(
              children: [
                const SizedBox(height: 24),
                Row(
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
          const SizedBox(height: 8),
          const Divider(),
        ],
      ),
    );
  }
}
