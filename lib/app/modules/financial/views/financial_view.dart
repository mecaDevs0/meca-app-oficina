import 'package:flutter/material.dart';
import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../core/core.dart';
import '../../../data/data.dart';
import '../controllers/financial_controller.dart';
import 'widgets/financial_item.dart';

class FinancialView extends StatefulWidget {
  const FinancialView({super.key});

  @override
  State<FinancialView> createState() => _FinancialViewState();
}

class _FinancialViewState
    extends MegaState<FinancialView, FinancialController> {
  final dateController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Obx(
              () => AppDataPicker(
                label: 'Buscar por data',
                hintText: 'Selecione a data',
                selectedStartDate: controller.filterStartDate,
                selectedEndDate: controller.filterEndDate,
                onApplyClick: (startDate, endDate) {
                  controller.startDate = startDate;
                  if (endDate != null) {
                    controller.endDate = endDate;
                  } else {
                    controller.endDate = startDate;
                  }
                  controller.pagingController.refresh();
                },
                onCancelClick: () {
                  controller.startDate = null;
                  controller.endDate = null;
                  controller.pagingController.refresh();
                },
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => Future.sync(
                  () => controller.pagingController.refresh(),
                ),
                child: PagedListView<int, FinancialModel>(
                  pagingController: controller.pagingController,
                  builderDelegate: PagedChildBuilderDelegate<FinancialModel>(
                    animateTransitions: true,
                    transitionDuration: const Duration(milliseconds: 500),
                    itemBuilder: (context, item, index) => FinancialItem(
                      financial: item,
                    ),
                    firstPageErrorIndicatorBuilder: (context) => ErrorIndicator(
                      error: controller.pagingController.error,
                      onTryAgain: () => controller.pagingController.refresh(),
                    ),
                    noItemsFoundIndicatorBuilder: (context) =>
                        const EmptyListIndicator(
                      iconColor: AppColors.primaryColor,
                      message: 'Sem histórico financeiro para exibir',
                    ),
                    firstPageProgressIndicatorBuilder: (context) =>
                        const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Carregando histórico financeiro...',
                          style: TextStyle(
                            color: AppColors.abbey,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
