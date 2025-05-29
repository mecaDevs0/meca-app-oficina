import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../core/core.dart';
import '../../../data/data.dart';
import '../../../data/providers/service_details_provider.dart';

class ServiceDetailsController extends GetxController {
  ServiceDetailsController({
    required ServiceDetailsProvider serviceDetailsProvider,
  }) : _serviceDetailsProvider = serviceDetailsProvider;

  final ServiceDetailsProvider _serviceDetailsProvider;

  final _isLoading = RxBool(false);
  final _scheduleService =
      Rx<ScheduleServiceModel>(ScheduleServiceModel.empty());
  final _scheduleHistory = RxList<ScheduleHistoryModel>.empty();
  final _isLoadingConfirm = RxBool(false);
  final _isLoadingCancel = RxBool(false);
  final _isLoadingConfirmArrival = RxBool(false);
  final _isLoadingClientDidNotShowUp = RxBool(false);
  final _isLoadingInitService = RxBool(false);
  final _isLoadingWaitingParts = RxBool(false);

  bool get isLoading => _isLoading.value;
  ScheduleServiceModel get scheduleService => _scheduleService.value;
  List<ScheduleHistoryModel> get scheduleHistory => _scheduleHistory.toList();
  Map<int, Map<String, dynamic>> groupedData = {};
  bool get isLoadingConfirm => _isLoadingConfirm.value;
  bool get isLoadingCancel => _isLoadingCancel.value;
  bool get isLoadingConfirmArrival => _isLoadingConfirmArrival.value;
  bool get isLoadingClientDidNotShowUp => _isLoadingClientDidNotShowUp.value;
  bool get isLoadingInitService => _isLoadingInitService.value;
  bool get isLoadingWaitingParts => _isLoadingWaitingParts.value;

  late String schedulingId;

  final _expandedServiceType = RxList<ServiceHistoryType>([
    ServiceHistoryType.orderPlaced,
    ServiceHistoryType.scheduling,
    ServiceHistoryType.budget,
    ServiceHistoryType.payment,
    ServiceHistoryType.service,
    ServiceHistoryType.approval,
    ServiceHistoryType.completed,
  ]);

  List<ServiceHistoryType> get expandedServiceType =>
      _expandedServiceType.toList();

  @override
  Future<void> onInit() async {
    final args = Get.arguments as ServiceArgs;
    schedulingId = args.serviceId;
    await getServiceDetails(args.serviceId);
    super.onInit();
  }

  Future<void> getServiceDetails(String id) async {
    _isLoading.value = true;
    await MegaRequestUtils.load(
      action: () async {
        final serviceDetails =
            await _serviceDetailsProvider.onScheduleDetail(id);
        final scheduleHistory =
            await _serviceDetailsProvider.onScheduleHistory(id);
        _scheduleService.value = serviceDetails;
        _scheduleHistory.assignAll(scheduleHistory);
        groupedData.clear();
        _groupScheduleHistory();
      },
      onFinally: () => _isLoading.value = false,
    );
  }

  void _groupScheduleHistory() {
    for (final item in scheduleHistory) {
      if (!groupedData.containsKey(item.statusTitle)) {
        groupedData[item.statusTitle] = {
          'count': 0,
          'items': <ScheduleHistoryModel>[],
        };
      }

      groupedData[item.statusTitle]!['count'] =
          (groupedData[item.statusTitle]!['count'] as int) + 1;
      (groupedData[item.statusTitle]!['items'] as List<ScheduleHistoryModel>)
          .add(item);
    }
  }

  void toggleServiceType(ServiceHistoryType serviceType) {
    _expandedServiceType.contains(serviceType)
        ? _expandedServiceType.remove(serviceType)
        : _expandedServiceType.add(serviceType);
  }

  bool isExpanded(ServiceHistoryType serviceType) =>
      _expandedServiceType.contains(serviceType);

  List<String> getItem(ServiceHistoryType value) {
    return scheduleHistory
        .where((element) => element.statusTitle == value.index)
        .map((e) => e.statusTitle.toString())
        .toList();
  }

  Future<bool> confirmSchedule() async {
    _isLoadingConfirm.value = true;
    bool isSuccess = false;
    await MegaRequestUtils.load(
      action: () async {
        await _serviceDetailsProvider.confirmSchedule(schedulingId, 0);
        isSuccess = true;
      },
      onFinally: () {
        getServiceDetails(schedulingId);
        _isLoadingConfirm.value = false;
      },
    );

    return isSuccess;
  }

  Future<void> cancelSchedule() async {
    _isLoadingCancel.value = true;
    await MegaRequestUtils.load(
      action: () async {
        await _serviceDetailsProvider.confirmSchedule(schedulingId, 1);
      },
      onFinally: () {
        _isLoadingCancel.value = false;
        getServiceDetails(schedulingId);
      },
    );
  }

  Future<bool> changeScheduleStatus(int status) async {
    bool isSuccess = false;
    switch (status) {
      case 5:
        _isLoadingConfirmArrival.value = true;
        break;
      case 16:
        _isLoadingInitService.value = true;
      case 17:
        _isLoadingWaitingParts.value = true;
      default:
        _isLoadingClientDidNotShowUp.value = true;
        break;
    }
    await MegaRequestUtils.load(
      action: () async {
        await _serviceDetailsProvider.changeScheduleStatus(
          schedulingId,
          status,
        );
        await getServiceDetails(schedulingId);
        isSuccess = true;
      },
      onFinally: () {
        switch (status) {
          case 5:
            _isLoadingConfirmArrival.value = false;
            break;
          case 16:
            _isLoadingInitService.value = false;
          case 17:
            _isLoadingWaitingParts.value = false;
          default:
            _isLoadingClientDidNotShowUp.value = false;
            break;
        }
      },
    );

    return isSuccess;
  }

  Future<void> suggestNewTime(DateTime date) async {
    await MegaRequestUtils.load(
      action: () async {
        final newTime = date.millisecondsSinceEpoch ~/ 1000;
        await _serviceDetailsProvider.suggestNewScheduleTime(
          schedulingId,
          newTime,
        );
      },
      onFinally: () {
        getServiceDetails(schedulingId);
      },
    );
  }
}
