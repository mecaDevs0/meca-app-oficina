import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mega_commons/shared/extensions/extensions.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/app_images.dart';
import '../../../../data/models/budget_service_model.dart';
import '../../controllers/send_quote_controller.dart';

enum TableStyle { icon, checkBox }

class AppTablePriceBudget extends GetView<SendQuoteController> {
  const AppTablePriceBudget({
    super.key,
    this.style = TableStyle.icon,
    required this.onEditService,
  });

  final TableStyle style;
  final Function(BudgetServiceModel) onEditService;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        if (controller.budgetServices.isEmpty) {
          return Center(
            child: SizedBox(
              child: Column(
                children: [
                  SvgPicture.asset(
                    AppImages.budgetServicesEmpty,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  const Text(
                    'Ainda não adicionou nenhum orçamento para adicionar seu primeiro orçamento clique no botão abaixo',
                    style: TextStyle(
                      color: AppColors.grayMedium,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        final services = controller.budgetServices;
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(
            shape: RoundedRectangleBorder(
              side: const BorderSide(width: 1, color: AppColors.grayLineColor),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      width: 1,
                      color: AppColors.grayLineColor,
                    ),
                  ),
                ),
                child: const Row(
                  children: [
                    Text(
                      'Serviços orçados',
                      style: TextStyle(
                        color: AppColors.abbey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              ListView.builder(
                itemCount: services.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) {
                  final service = services[index];
                  final isLast = index == services.length - 1;
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: !isLast
                          ? const Border(
                              bottom: BorderSide(
                                width: 1,
                                color: AppColors.grayLineColor,
                              ),
                            )
                          : null,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              service.title ?? '',
                              style: const TextStyle(
                                color: AppColors.boulder,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              service.value?.moneyFormat() ?? r'R$ 0,00',
                              style: const TextStyle(
                                color: AppColors.boulder,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              service.description ?? '',
                              style: const TextStyle(
                                color: AppColors.boulder,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    onEditService(service);
                                  },
                                  icon: SvgPicture.asset(
                                    AppImages.icEdit,
                                    width: 18,
                                    height: 18,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    controller.removeBudgetService(service);
                                  },
                                  icon: SvgPicture.asset(
                                    AppImages.icTrashSmall,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
