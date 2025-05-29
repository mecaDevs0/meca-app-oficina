import 'dart:io';

import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../core/core.dart';
import '../../../data/data.dart';
import '../../../data/providers/home_provider.dart';
import '../../core/controllers/core_controller.dart';

class HomeController extends GetxController with WorkshopMixin {
  HomeController({
    required HomeProvider homeProvider,
    required CoreController coreController,
  })  : _homeProvider = homeProvider,
        _coreController = coreController;

  final HomeProvider _homeProvider;
  final CoreController _coreController;

  final _selectedTab = Rx<HomeSection>(HomeSection.upcoming);
  final _filterStartDate = Rx<DateTime?>(null);
  final _filterEndDate = Rx<DateTime?>(null);
  final _workshop = Rx<WorkshopModel?>(null);
  final _cardMeiFile = Rx<File?>(null);
  final _userDocumentFile = Rx<File?>(null);
  final _isLoading = RxBool(false);

  final Set<String> _loggedNotificationIds = {};

  HomeSection get selectedTab => _selectedTab.value;
  DateTime? get filterStartDate => _filterStartDate.value;
  DateTime? get filterEndDate => _filterEndDate.value;
  WorkshopModel? get workshop => _workshop.value;
  File? get cardMeiFile => _cardMeiFile.value;
  File? get userDocumentFile => _userDocumentFile.value;
  bool get isLoading => _isLoading.value;

  set selectedTab(HomeSection tab) => _selectedTab.value = tab;
  set startDate(DateTime? value) => _filterStartDate.value = value;
  set endDate(DateTime? value) => _filterEndDate.value = value;
  set cardMeiFile(File? value) => _cardMeiFile.value = value;
  set userDocumentFile(File? value) => _userDocumentFile.value = value;

  final PagingController<int, ScheduleServiceModel> nextPagingController =
      PagingController(firstPageKey: 1);
  final PagingController<int, ScheduleServiceModel> historyPagingController =
      PagingController(firstPageKey: 1);
  final _limit = 30;
  List<int> get listIssues => _coreController.listIssues;

  @override
  void onInit() {
    nextPagingController.addPageRequestListener(getNextSchedule);
    historyPagingController.addPageRequestListener(getHistorySchedule);

    ever(_selectedTab, (tab) {
      if (tab == HomeSection.upcoming) {
        nextPagingController.refresh();
      } else {
        historyPagingController.refresh();
      }
    });

    WorkshopModel.cacheBox.listenable().addListener(() {
      _workshop.value = WorkshopModel.fromCache();
      _workshop.refresh();
    });

    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      final notificationId = event.notification.notificationId;
      if (!_loggedNotificationIds.contains(notificationId)) {
        _loggedNotificationIds.add(notificationId);
        nextPagingController.refresh();
        historyPagingController.refresh();
      }
    });

    super.onInit();
  }

  Future<void> onGetWorkshopInfo() async {
    await _coreController.getProfileInfo();
  }

  Future<void> getNextSchedule(int page) async {
    await MegaRequestUtils.load(
      action: () async {
        final response = await _homeProvider.getScheduleService(
          page: page,
          limit: _limit,
          status: ScheduleStatus.nextStatus,
          startDate: filterStartDate?.formatFirstHour(),
          endDate: filterEndDate?.formatLastHour(),
        );
        final isLastPage = response.length < _limit;
        if (isLastPage) {
          nextPagingController.appendLastPage(response);
        } else {
          final nextPageKey = page + 1;
          nextPagingController.appendPage(response, nextPageKey);
        }
      },
    );
  }

  Future<void> getHistorySchedule(int page) async {
    await MegaRequestUtils.load(
      action: () async {
        final response = await _homeProvider.getScheduleService(
          page: page,
          limit: _limit,
          status: selectedTab == HomeSection.upcoming
              ? ScheduleStatus.nextStatus
              : ScheduleStatus.historicStatus,
          startDate: filterStartDate?.formatFirstHour(),
          endDate: filterEndDate?.formatLastHour(),
        );
        final isLastPage = response.length < _limit;
        if (isLastPage) {
          historyPagingController.appendLastPage(response);
        } else {
          final nextPageKey = page + 1;
          historyPagingController.appendPage(response, nextPageKey);
        }
      },
    );
  }

  Future<bool> onCompleteRequirements(WorkshopModel workshop) async {
    bool isSuccess = false;
    final workshopSend = workshop.copyWith(id: _workshop.value?.id);
    _isLoading.value = true;
    await MegaRequestUtils.load(
      action: () async {
        if (userDocumentFile?.path.isFile == true) {
          final logo = await onUploadFile(userDocumentFile!.path);
          workshopSend.fileDocument = logo;
        }
        if (cardMeiFile?.path.isFile == true) {
          final meiCard = await onUploadFile(cardMeiFile!.path);
          workshopSend.meiCard = meiCard;
        }
        final response = await _homeProvider.onUpdateWorkshop(workshopSend);
        _coreController.listIssues = response.requirements;
        await response.save();
        isSuccess = true;
      },
      onFinally: () => _isLoading.value = false,
    );
    return isSuccess;
  }

  Future<String?> onUploadFile(String path) async {
    final fileImage = File(path);
    final response = await _homeProvider.onUploadImage(fileImage);
    return response.fileName;
  }
}
