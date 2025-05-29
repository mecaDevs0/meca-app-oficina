import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mega_commons/mega_commons.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../core/core.dart';
import '../../../routes/app_pages.dart';
import '../controllers/service_controller.dart';
import 'widgets/item_description.dart';

class DetailedServiceView extends GetView<ServiceController> {
  const DetailedServiceView({super.key});

  String formatHours(double hours) {
    if (hours == 1.0) {
      return '1 hora';
    }
    if (hours % 1 != 0) {
      final int hoursInt = hours.toInt();
      final int minutes = ((hours - hoursInt) * 60).toInt();
      return '$hoursInt horas e $minutes minutos';
    }

    final int hoursInt = hours.toInt();
    return '$hoursInt horas';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BaseAppBar(title: 'Detalhes do serviço'),
      body: Obx(
        () => Skeletonizer(
          enabled: controller.isLoading,
          child: Column(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MegaCachedNetworkImage(
                      imageUrl: controller.serviceDetail?.photo,
                      width: double.infinity,
                      height: 120,
                      radius: 4,
                    ),
                    const SizedBox(height: 24),
                    ItemDescription(
                      title: 'Nome do serviço',
                      description:
                          controller.serviceDetail?.service?.name ?? '',
                    ),
                    ItemDescription(
                      title: 'Tempo estimado',
                      description: formatHours(
                        controller.serviceDetail?.estimatedTime ?? 0,
                      ),
                    ),
                    ItemDescription(
                      title: 'Antecedência mínima para o agendamento',
                      description: formatHours(
                        controller.serviceDetail?.minTimeScheduling ?? 0,
                      ),
                    ),
                    ItemDescription(
                      title: 'Descrição',
                      description: controller.serviceDetail?.description ?? '',
                    ),
                    ItemDescription(
                      title: 'Serviço rápido',
                      description:
                          controller.serviceDetail?.quickService == true
                              ? 'Sim'
                              : 'Não',
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: const ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            width: 1,
                            strokeAlign: BorderSide.strokeAlignCenter,
                            color: AppColors.grayBorderColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    MegaBaseButton(
                      'Editar serviço',
                      borderRadius: 4,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      onButtonPress: () async {
                        if (controller.serviceDetail?.id == null) {
                          MegaSnackbar.showErroSnackBar(
                            'Não foi possível editar o serviço',
                          );
                          return;
                        }
                        final result = await Get.toNamed(
                          Routes.createService,
                          arguments: ServiceArgs(
                            controller.serviceDetail!.id!,
                          ),
                        );
                        if (controller.serviceDetail?.id == null) {
                          Get.back();
                          return;
                        }
                        if (result == true) {
                          final serviceId = controller.serviceDetail!.id!;
                          await controller.getDetailedService(serviceId);
                        }
                      },
                    ).shade,
                    const SizedBox(height: 8),
                    MegaBaseButton(
                      'Excluir serviço',
                      borderRadius: 4,
                      buttonColor: AppColors.apricot,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      onButtonPress: () async {
                        AppBottomSheet.showDeleteBottomSheet(
                          context,
                          onButtonPress: _onDeleteService,
                        );
                      },
                    ).shade,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onDeleteService() async {
    final result = await controller.removeService();
    if (result.$1) {
      Get.back();
      MegaSnackbar.showSuccessSnackBar(
        result.$2 ?? 'Serviço removido com sucesso',
      );
      controller.clearServiceDetail();
    }
  }
}
