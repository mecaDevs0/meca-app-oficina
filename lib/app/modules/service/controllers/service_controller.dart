import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../data/data.dart';
import '../../../data/providers/service_provider.dart';

class ServiceController extends GetxController {
  ServiceController({required ServiceProvider serviceProvider})
      : _serviceProvider = serviceProvider;

  final ServiceProvider _serviceProvider;

  final _isLoading = RxBool(false);
  final _loadingMessage = RxString('');
  final _serviceDetail = Rx<ServiceModel?>(null);

  bool get isLoading => _isLoading.value;
  String get loadingMessage => _loadingMessage.value;
  ServiceModel? get serviceDetail => _serviceDetail.value;

  final PagingController<int, ServiceModel> pagingController =
      PagingController(firstPageKey: 1);
  final _limit = 30;

  @override
  void onInit() {
    pagingController.addPageRequestListener(listServices);
    super.onInit();
  }

  Future<void> listServices(int pageKey) async {
    final workshop = WorkshopModel.fromCache();
    await MegaRequestUtils.load(
      action: () async {
        final response = await _serviceProvider.onListServices(
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
    );
  }

  Future<void> getDetailedService(String id) async {
    _isLoading.value = true;
    _loadingMessage.value = 'Carregando detalhes do serviço...';
    await MegaRequestUtils.load(
      action: () async {
        final response = await _serviceProvider.onGetService(id);
        _serviceDetail.value = response;
      },
      onFinally: () => _isLoading.value = false,
    );
  }

  void clearServiceDetail() {
    _serviceDetail.value = null;
  }

  Future<(bool, String?)> removeService() async {
    _isLoading.value = true;
    _loadingMessage.value = 'Removendo serviço...';
    bool success = false;
    String? message;
    await MegaRequestUtils.load(
      action: () async {
        final response =
            await _serviceProvider.onRemoveService(serviceDetail!.id);
        pagingController.itemList
            ?.removeWhere((element) => element.id == serviceDetail!.id);
        // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
        pagingController.notifyListeners();
        success = true;
        message = response;
      },
      onFinally: () => _isLoading.value = false,
    );
    return (success, message);
  }
}
