import 'dart:io';

import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../data/data.dart';
import '../../../data/models/budget_service_model.dart';
import '../../../data/providers/send_quote_provider.dart';
import '../../service_details/controllers/service_details_controller.dart';

class SendQuoteController extends GetxController {
  SendQuoteController({
    required SendQuoteProvider sendQuoteProvider,
    required ServiceDetailsController serviceDetailsController,
  })  : _sendQuoteProvider = sendQuoteProvider,
        _serviceDetailsController = serviceDetailsController;

  final SendQuoteProvider _sendQuoteProvider;
  final ServiceDetailsController _serviceDetailsController;

  final _scheduleService =
      Rx<ScheduleServiceModel>(ScheduleServiceModel.empty());
  final _budgetServices = RxList<BudgetServiceModel>.empty();
  final _isLoadingSendQuote = RxBool(false);
  final _isLoadingServiceDetail = RxBool(false);
  final _selectedImages = RxList<File>.empty();
  final _totalServicesValue = RxDouble(0.0);
  final _totalWithDiagnostic = RxDouble(0.0);
  final List<DateTime> dots = RxList<DateTime>.empty();

  ScheduleServiceModel get scheduleService => _scheduleService.value;
  bool get isLoadingSendQuote => _isLoadingSendQuote.value;
  bool get isLoadingServiceDetail => _isLoadingServiceDetail.value;
  List<File> get selectedImages => _selectedImages;
  List<BudgetServiceModel> get budgetServices => _budgetServices;
  double get totalServicesValue => _totalServicesValue.value;
  double get totalWithDiagnostic => _totalWithDiagnostic.value;

  late String scheduleId;

  int maxImages = 5;

  @override
  Future<void> onInit() async {
    scheduleId = Get.arguments['id'] as String;
    await _getServiceDetails(scheduleId);
    super.onInit();
  }

  Future<void> _getServiceDetails(String id) async {
    _isLoadingServiceDetail.value = true;
    await MegaRequestUtils.load(
      action: () async {
        final serviceDetails = await _sendQuoteProvider.onScheduleDetail(id);
        _scheduleService.value = serviceDetails;
      },
      onFinally: () => _isLoadingServiceDetail.value = false,
    );
  }

  void incrementBudgetService(BudgetServiceModel service) {
    if (service == null) {
      return;
    }
    _budgetServices.add(service);
  }

  void removeBudgetService(BudgetServiceModel service) {
    if (service == null) {
      return;
    }
    _budgetServices.remove(service);
  }

  void onDiagnosticValueChanged(String? value) {
    if (value == null || value.isEmpty) {
      calculateTotals(0.0);
      return;
    }

    final diagnosticValue = UtilBrasilFields.converterMoedaParaDouble(value);
    calculateTotals(diagnosticValue);
  }

  void editBudgetService(
    BudgetServiceModel oldService,
    BudgetServiceModel newService,
  ) {
    if (oldService == null || newService == null) {
      return;
    }

    final index = _budgetServices.indexOf(oldService);
    if (index != -1) {
      _budgetServices[index] = newService;
    }
  }

  void calculateTotals(double? diagnosticValue) {
    final servicesTotal = _budgetServices.fold<double>(
      0.0,
      (sum, service) => sum + (service.value ?? 0.0),
    );

    _totalServicesValue.value = servicesTotal;
    if (diagnosticValue != null) {
      _totalWithDiagnostic.value = servicesTotal + diagnosticValue;
    }
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

  Future<bool> sendQuote({
    required double diagnosticValue,
    required int estimatedTimeForCompletion,
  }) async {
    bool isSuccess = false;
    _isLoadingSendQuote.value = true;
    await MegaRequestUtils.load(
      action: () async {
        final provider = _sendQuoteProvider;
        final List<String> budgetImages = [];
        if (selectedImages.isNotEmpty) {
          budgetImages.addAll(await provider.uploadFiles(selectedImages));
        }

        await provider.onSendQuote(
          schedulingId: scheduleId,
          diagnosticValue: diagnosticValue,
          estimatedTimeForCompletion: estimatedTimeForCompletion,
          budgetImages: budgetImages,
          budgetServices: budgetServices,
        );
        _serviceDetailsController.getServiceDetails(scheduleId);
        isSuccess = true;
      },
      onFinally: () => _isLoadingSendQuote.value = false,
    );
    return isSuccess;
  }
}
