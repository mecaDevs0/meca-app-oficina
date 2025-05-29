import 'dart:io';

import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../core/core.dart';
import '../../../data/models/schedule_service_model.dart';
import '../../../data/providers/service_failed_provider.dart';

class ServiceFailedController extends GetxController {
  ServiceFailedController({
    required ServiceFailedProvider serviceFailedProvider,
  }) : _serviceFailedProvider = serviceFailedProvider;

  final ServiceFailedProvider _serviceFailedProvider;

  final _isLoadingService = RxBool(false);
  final _isLoading = RxBool(false);
  final _isLoadingDisputeFailedService = RxBool(false);
  final _serviceFailed = Rx<ScheduleServiceModel?>(null);
  final _selectedImages = RxList<File>.empty();

  List<File> get selectedImages => _selectedImages;
  bool get isLoadingService => _isLoadingService.value;
  bool get isLoadingDisputeFailedService =>
      _isLoadingDisputeFailedService.value;
  ScheduleServiceModel? get serviceFailed => _serviceFailed.value;
  bool get isLoading => _isLoading.value;

  int maxImages = 5;

  late String serviceId;

  @override
  void onInit() {
    final args = Get.arguments as ServiceArgs;
    serviceId = args.serviceId;
    getServiceInfo();
    super.onInit();
  }

  Future<void> getServiceInfo() async {
    _isLoadingService.value = true;
    await MegaRequestUtils.load(
      action: () async {
        final response =
            await _serviceFailedProvider.onScheduleDetail(serviceId);
        _serviceFailed.value = response;
      },
      onFinally: () => _isLoadingService.value = false,
    );
  }

  Future<bool> suggestFreeRepair() async {
    bool isSuccess = false;
    _isLoading.value = true;
    await MegaRequestUtils.load(
      action: () async {
        await _serviceFailedProvider.onSuggestFreeRepair(serviceId);
        isSuccess = true;
      },
      onFinally: () => _isLoading.value = false,
    );
    return isSuccess;
  }

  Future<bool> disputeFailedService(String dispute) async {
    bool isSuccess = false;
    _isLoadingDisputeFailedService.value = true;
    await MegaRequestUtils.load(
      action: () async {
        final provider = _serviceFailedProvider;
        final uploadedImages = await provider.uploadFiles(selectedImages);
        await provider.onDisputeFailedService(
          schedulingId: serviceId,
          dispute: dispute,
          imagesDispute: uploadedImages,
        );
        isSuccess = true;
      },
      onFinally: () => _isLoadingDisputeFailedService.value = false,
    );
    return isSuccess;
  }

  void addImages(List<File>? file) {
    if (_selectedImages.length >= maxImages) {
      return;
    }
    if (file == null) {
      return;
    }
    for (final element in file) {
      if (_selectedImages.length >= maxImages) {
        break;
      }
      _selectedImages.add(element);
    }
  }

  void removeImage(File file) {
    _selectedImages.remove(file);
  }
}
