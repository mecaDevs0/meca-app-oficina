import 'package:flutter/material.dart';
import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../core/core.dart';
import '../../../data/data.dart';
import '../../../routes/app_pages.dart';
import '../controllers/notification_controller.dart';
import 'widgets/item_notification.dart';

class NotificationView extends GetView<AppNotificationController> {
  const NotificationView({super.key});

  (bool, bool) validNotification({
    required NotificationModel notification,
    required int index,
  }) {
    final isToday = notification.created.isSameDate();
    final isFirstItem = index == 0;
    final previousItem = getPreviousItem(isFirstItem, index);
    final isNewGroup =
        isFirstItem || (isToday != previousItem!.created.isSameDate());

    return (isNewGroup, isToday);
  }

  NotificationModel? getPreviousItem(bool isFirstItem, int index) {
    return isFirstItem
        ? null
        : controller.pagingController.itemList![index - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BaseAppBar(
        title: 'Notificações',
      ),
      body: Obx(
        () => MegaContainerLoading(
          isLoading: controller.isLoadingDelete,
          textLoading: 'removendo notificação',
          backgroundColor: Colors.black.withValues(alpha: 0.6),
          child: Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: RefreshIndicator(
                        onRefresh: () => Future.sync(
                          () => controller.pagingController.refresh(),
                        ),
                        child: PagedListView<int, NotificationModel>(
                          pagingController: controller.pagingController,
                          builderDelegate:
                              PagedChildBuilderDelegate<NotificationModel>(
                            animateTransitions: true,
                            transitionDuration:
                                const Duration(milliseconds: 500),
                            itemBuilder: (context, item, index) {
                              final (isNewGroup, isToday) = validNotification(
                                notification: item,
                                index: index,
                              );
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isNewGroup)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8.0,
                                      ),
                                      child: Text(
                                        isToday
                                            ? 'Hoje'
                                            : 'Notificações passadas',
                                        style: const TextStyle(
                                          color: AppColors.tundora,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ItemNotification(
                                    notification: item,
                                    removeNotification: () async {
                                      await controller
                                          .removeNotification(item.id);
                                    },
                                    onTap: () {
                                      controller.notificationDetail = item;
                                      Get.toNamed(Routes.notificationDetail);
                                    },
                                  ),
                                ],
                              );
                            },
                            firstPageErrorIndicatorBuilder: (context) =>
                                ErrorIndicator(
                              error: controller.pagingController.error,
                              onTryAgain: () =>
                                  controller.pagingController.refresh(),
                            ),
                            noItemsFoundIndicatorBuilder: (context) =>
                                const EmptyListIndicator(
                              iconColor: AppColors.primaryColor,
                              message: 'Sem notificações para exibir',
                            ),
                            firstPageProgressIndicatorBuilder: (context) =>
                                const AppLoading(
                              message: 'Carregando Notificações...',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
