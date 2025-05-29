import 'package:flutter/material.dart';
import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../core/core.dart';
import '../../../data/data.dart';
import '../controllers/home_controller.dart';
import 'widgets/item_service.dart';

class NextTabView extends GetView<HomeController> {
  const NextTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return PagedSliverList<int, ScheduleServiceModel>(
      pagingController: controller.nextPagingController,
      builderDelegate: PagedChildBuilderDelegate<ScheduleServiceModel>(
        itemBuilder: (context, item, index) {
          return ItemService(
            schedule: item,
          );
        },
        firstPageProgressIndicatorBuilder: (context) {
          return const AppLoading(
            message: 'Carregando serviços...',
          );
        },
        noItemsFoundIndicatorBuilder: (context) {
          return const EmptyListIndicator(
            iconColor: AppColors.primaryColor,
            message: 'Nenhum serviço encontrado',
            isShowIcon: false,
          );
        },
      ),
    );
  }
}
