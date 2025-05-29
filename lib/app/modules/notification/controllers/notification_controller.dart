import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../data/data.dart';
import '../../../data/providers/notification_provider.dart';

class AppNotificationController extends GetxController {
  AppNotificationController({
    required NotificationProvider notificationProvider,
  }) : _notificationProvider = notificationProvider;

  final NotificationProvider _notificationProvider;

  final _isLoading = RxBool(false);
  final _isLoadingDelete = RxBool(false);
  final _notificationDetail = Rxn<NotificationModel>();

  bool get isLoading => _isLoading.value;
  bool get isLoadingDelete => _isLoadingDelete.value;
  NotificationModel? get notificationDetail => _notificationDetail.value;

  set notificationDetail(NotificationModel? value) =>
      _notificationDetail.value = value;

  final PagingController<int, NotificationModel> pagingController =
      PagingController(firstPageKey: 1);
  final _limit = 30;

  @override
  void onInit() {
    pagingController.addPageRequestListener(_requestNotifications);
    super.onInit();
  }

  Future<void> _requestNotifications(int pageKey) async {
    await MegaRequestUtils.load(
      action: () async {
        final workshop = WorkshopModel.fromCache();
        final response = await _notificationProvider.listNotification(
          page: pageKey,
          limit: _limit,
          workshopId: workshop.id!,
        );
        final isLastPage = response.length < _limit;
        if (isLastPage) {
          pagingController.appendLastPage(response);
        } else {
          final nextPageKey = pageKey + 1;
          pagingController.appendPage(response, nextPageKey);
        }
      },
      onError: (megaResponse) => pagingController.error = megaResponse.errors,
    );
  }

  Future<void> removeNotification(String id) async {
    _isLoadingDelete.value = true;
    await MegaRequestUtils.load(
      action: () async {
        final response = await _notificationProvider.removeNotification(
          notificationId: id,
        );
        MegaSnackbar.showSuccessSnackBar(response.message ?? 'Success Message');
        pagingController.itemList!
            .removeWhere((notification) => notification.id == id);
      },
      onFinally: () => _isLoadingDelete.value = false,
    );
  }
}
