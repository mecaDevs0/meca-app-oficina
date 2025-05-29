import 'dart:io';

import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../core/core.dart';
import '../../../data/data.dart';
import '../../../data/providers/create_service_provider.dart';

class CreateServiceController extends GetxController {
  CreateServiceController({
    required CreateServiceProvider createServiceProvider,
  }) : _createServiceProvider = createServiceProvider;

  final CreateServiceProvider _createServiceProvider;

  final _isFastService = RxBool(false);
  final _isLoading = RxBool(false);
  final _isLoadingDetail = RxBool(false);
  final _selectedFile = Rx<String?>(null);
  final _defaultServices = RxList<DefaultServiceModel>.empty();
  final serviceDetail = Rx<ServiceModel?>(null);
  final _isLoadingService = RxBool(false);
  final _selectedService = Rx<DefaultServiceModel?>(null);

  bool get isFastService => _isFastService.value;
  bool get isLoading => _isLoading.value;
  bool get isLoadingDetail => _isLoadingDetail.value;
  String? get selectedImage => _selectedFile.value;
  List<DefaultServiceModel> get defaultServices => _defaultServices.toList();
  bool get isLoadingService => _isLoadingService.value;
  DefaultServiceModel? get selectedService => _selectedService.value;

  set selectedImage(String? value) => _selectedFile.value = value;
  set isFastService(bool value) => _isFastService.value = value;
  set selectedService(DefaultServiceModel? value) =>
      _selectedService.value = value;

  @override
  Future<void> onInit() async {
    await _fetchDefaultServices();
    if (Get.arguments != null) {
      final args = Get.arguments as ServiceArgs;
      await onGetServiceDetail(args.serviceId);
    }
    super.onInit();
  }

  Future<void> _fetchDefaultServices() async {
    _isLoadingService.value = true;
    await MegaRequestUtils.load(
      action: () async {
        final response = await _createServiceProvider.getDefaultServices();
        _defaultServices.assignAll(response);
      },
      onFinally: () => _isLoadingService.value = false,
    );
  }

  void toggleFastService() {
    _isFastService.toggle();
  }

  Future<(bool, String?)> onCreateService(ServiceModel service) async {
    _isLoading.value = true;
    bool isSuccess = false;
    String? successMessage;
    ServiceModel createdService = service;
    createdService = createdService.copyWith(quickService: isFastService);
    await MegaRequestUtils.load(
      action: () async {
        if (selectedImage?.isFile == true) {
          final filePath = await onUploadImage(selectedImage!);
          createdService = createdService.copyWith(photo: filePath);
        }
        final response =
            await _createServiceProvider.onCreateService(createdService);
        final workshopCache = WorkshopModel.fromCache();
        workshopCache.workshopServicesValid = true;
        workshopCache.save();
        isSuccess = true;
        successMessage = response;
      },
      onFinally: () => _isLoading.value = false,
    );
    return (isSuccess, successMessage!);
  }

  Future<(bool, String?)> onEditService(ServiceModel service) async {
    _isLoading.value = true;
    bool isSuccess = false;
    String? successMessage;
    ServiceModel editedService = service;
    editedService = editedService.copyWith(id: serviceDetail.value?.id);
    editedService = editedService.copyWith(quickService: isFastService);
    await MegaRequestUtils.load(
      action: () async {
        if (selectedImage?.isFile == true) {
          final filePath = await onUploadImage(selectedImage!);
          editedService = editedService.copyWith(photo: filePath);
        } else {
          editedService =
              editedService.copyWith(photo: serviceDetail.value?.photo);
        }
        final response =
            await _createServiceProvider.onEditService(editedService);
        isSuccess = true;
        successMessage = response;
      },
      onFinally: () => _isLoading.value = false,
    );
    return (isSuccess, successMessage!);
  }

  Future<String?> onUploadImage(String path) async {
    final fileImage = File(path);
    final response = await _createServiceProvider.onUploadImage(fileImage);
    return response.fileName;
  }

  Future<void> onGetServiceDetail(String id) async {
    _isLoadingDetail.value = true;
    await MegaRequestUtils.load(
      action: () async {
        final response = await _createServiceProvider.getServiceDetail(id);
        serviceDetail.value = response;
      },
      onFinally: () => _isLoadingDetail.value = false,
    );
  }
}
