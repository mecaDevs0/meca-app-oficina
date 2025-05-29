import 'package:flutter/material.dart';
import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../core/core.dart';
import '../../../data/data.dart';
import '../../../routes/app_pages.dart';
import '../controllers/service_controller.dart';
import 'widgets/item_service.dart';

class ServiceView extends GetView<ServiceController> {
  const ServiceView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BaseAppBar(title: 'Serviços'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            MegaBaseButton(
              'Cadastrar serviço',
              onButtonPress: () async {
                final result = await Get.toNamed(Routes.createService);
                if (result == true) {
                  controller.pagingController.refresh();
                }
              },
              textStyle: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => Future.sync(
                  () => controller.pagingController.refresh(),
                ),
                child: PagedListView<int, ServiceModel>(
                  pagingController: controller.pagingController,
                  builderDelegate: PagedChildBuilderDelegate(
                    animateTransitions: true,
                    transitionDuration: const Duration(milliseconds: 500),
                    itemBuilder: (context, item, index) => ItemService(
                      service: item,
                      onTap: () {
                        controller.getDetailedService(item.id!);
                        Get.toNamed(Routes.detailedService);
                      },
                    ),
                    firstPageErrorIndicatorBuilder: (context) => ErrorIndicator(
                      error: controller.pagingController.error,
                      onTryAgain: () => controller.pagingController.refresh(),
                    ),
                    noItemsFoundIndicatorBuilder: (context) =>
                        const EmptyListIndicator(
                      iconColor: AppColors.primaryColor,
                      message: 'Sem serviços para exibir',
                    ),
                    firstPageProgressIndicatorBuilder: (context) =>
                        const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Carregando serviços...',
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
