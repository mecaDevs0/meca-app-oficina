import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../core/core.dart';
import '../../../data/data.dart';
import '../../../data/providers/schedule_provider.dart';

class ScheduleController extends GetxController {
  ScheduleController({required ScheduleProvider scheduleProvider})
      : _scheduleProvider = scheduleProvider;

  final ScheduleProvider _scheduleProvider;

  final _selectedMonth = Rx<DateTime>(DateTime.now());
  final _selectedDate = Rx<DateTime>(DateTime.now());
  final _dateList = RxList<DateTime>.empty();
  final _expandedDays = RxList<DaysOfWeek>.empty();
  final _isSelectedDays = RxList<DaysOfWeek>.empty();
  final _isLoading = RxBool(false);
  final _schedule = Rx<ScheduleModel?>(null);
  final _isLoadingConfig = RxBool(false);
  final _agendaModel = Rx<AgendaModel?>(null);

  DateTime get selectedMonth => _selectedMonth.value;
  DateTime get selectedDate => _selectedDate.value;
  List<DateTime> get dateList => _dateList;
  List<DaysOfWeek> get expandedDays => _expandedDays;
  List<DaysOfWeek> get isSelectedDays => _isSelectedDays;
  bool get isLoading => _isLoading.value;
  ScheduleModel? get schedule => _schedule.value;
  bool get isLoadingConfig => _isLoadingConfig.value;
  AgendaModel? get agendaModel => _agendaModel.value;

  final minimumDate = DateTime.now();
  final maximumDate = DateTime.now().add(const Duration(days: 30));
  final workshop = WorkshopModel.fromCache();

  @override
  Future<void> onInit() async {
    setListOfDate(selectedMonth);
    await _onGetSchedule();
    await onGetConfigSchedule();
    ever(_selectedDate, (_) => _onGetSchedule());
    super.onInit();
  }

  Future<void> _onGetSchedule() async {
    final workshop = WorkshopModel.fromCache();
    if (workshop.id.isNullOrEmpty) {
      return;
    }

    _isLoading.value = true;
    await MegaRequestUtils.load(
      action: () async {
        final response = await _scheduleProvider.getSchedule(
          selectedDate.formatFirstHour(),
          workshop.id!,
        );
        _schedule.value = response;
      },
      onFinally: () => _isLoading.value = false,
    );
  }

  Future<void> deleteHour(WorkshopAgendaModel workshopAgenda) async {
    _isLoading.value = true;
    await MegaRequestUtils.load(
      action: () async {
        final hour = workshopAgenda.hour.split(':').first;
        final date = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          int.parse(hour),
          0,
          0,
        );
        await MegaRequestUtils.load(
          action: () async {
            await _scheduleProvider.deleteHour(date.toTimestamp());
            _schedule.value = _schedule.value?.copyWith(
              workshopAgenda: _schedule.value?.workshopAgenda
                  .where((element) => element != workshopAgenda)
                  .toList(),
            );
          },
          onFinally: () => _isLoading.value = false,
        );
      },
    );
  }

  Future<void> onGetConfigSchedule() async {
    _isLoadingConfig.value = true;
    await MegaRequestUtils.load(
      action: () async {
        final workshop = WorkshopModel.fromCache();
        final response =
            await _scheduleProvider.getConfigSchedule(workshop.id!);
        _agendaModel.value = response;
        _getOpenDays(response);
      },
      onFinally: () => _isLoadingConfig.value = false,
    );
  }

  void _getOpenDays(AgendaModel agenda) {
    final Map<DaysOfWeek, WeekDayModel> daysMap = {
      DaysOfWeek.monday: agenda.monday,
      DaysOfWeek.tuesday: agenda.tuesday,
      DaysOfWeek.wednesday: agenda.wednesday,
      DaysOfWeek.thursday: agenda.thursday,
      DaysOfWeek.friday: agenda.friday,
      DaysOfWeek.saturday: agenda.saturday,
      DaysOfWeek.sunday: agenda.sunday,
    };

    final List<DaysOfWeek> openDays = daysMap.entries
        .where((element) => element.value.open)
        .map((e) => e.key)
        .toList();

    _isSelectedDays.value = openDays;
  }

  void nextMonth() {
    final isSameMonth = maximumDate.month == selectedMonth.month;
    final isSameYear = maximumDate.year == selectedMonth.year;
    if (isSameMonth && isSameYear) {
      return;
    }

    final nextMonthDate = DateTime(selectedMonth.year, selectedMonth.month + 1);
    setListOfDate(nextMonthDate);
    _selectedMonth.value = nextMonthDate;
  }

  void previousMonth() {
    final isSameMonth = minimumDate.month == selectedMonth.month;
    final isSameYear = minimumDate.year == selectedMonth.year;
    if (isSameMonth && isSameYear) {
      return;
    }

    final previousMonthDate =
        DateTime(selectedMonth.year, selectedMonth.month - 1);
    setListOfDate(previousMonthDate);
    _selectedMonth.value = previousMonthDate;
  }

  void setListOfDate(DateTime monthDate) {
    dateList.clear();
    final firstDayOfMonth = DateTime(monthDate.year, monthDate.month, 1);
    final daysInMonth = DateTime(monthDate.year, monthDate.month + 1, 0).day;
    final firstWeekday = firstDayOfMonth.weekday;

    for (int i = 0; i < firstWeekday; i++) {
      dateList.add(firstDayOfMonth.subtract(Duration(days: firstWeekday - i)));
    }

    for (int i = 0; i < daysInMonth; i++) {
      dateList.add(firstDayOfMonth.add(Duration(days: i)));
    }

    final int remainingDays = 42 - dateList.length;
    for (int i = 0; i < remainingDays; i++) {
      dateList.add(firstDayOfMonth.add(Duration(days: daysInMonth + i)));
    }
  }

  void onDateSelected(DateTime date) {
    _selectedDate.value = date;
  }

  void toggleDay(DaysOfWeek day) {
    _expandedDays.contains(day)
        ? _expandedDays.remove(day)
        : _expandedDays.add(day);
  }

  bool isExpanded(DaysOfWeek day) => _expandedDays.contains(day);

  void toggleSelectedDay(DaysOfWeek day) {
    _isSelectedDays.contains(day)
        ? _isSelectedDays.remove(day)
        : _isSelectedDays.add(day);
  }

  bool isSelected(DaysOfWeek day) => _isSelectedDays.contains(day);

  Future<bool> saveConfigSchedule() async {
    if (agendaModel == null) {
      return false;
    }
    bool isSuccess = false;
    _isLoading.value = true;
    await MegaRequestUtils.load(
      action: () async {
        final agenda = agendaModel!.toggleOpenStatus(isSelectedDays);
        final response = await _scheduleProvider.saveConfigSchedule(agenda);

        final workshop = WorkshopModel.fromCache();
        workshop.workshopAgendaValid = true;
        await workshop.save();

        await _onGetSchedule();
        _agendaModel.value = response;
        isSuccess = true;
      },
      onFinally: () => _isLoading.value = false,
    );
    return isSuccess;
  }

  Future<bool> saveConfigNewSchedule() async {
    bool isSuccess = false;
    _isLoading.value = true;
    await MegaRequestUtils.load(
      action: () async {
        final agenda = agendaModel!.toggleOpenStatus(isSelectedDays);
        final response = await _scheduleProvider.saveConfigSchedule(agenda);
        _agendaModel.value = response;
        isSuccess = true;
      },
      onFinally: () => _isLoading.value = false,
    );
    return isSuccess;
  }

  void setTime({
    required TypeTimeAgenda typeTime,
    required DaysOfWeek day,
    required String value,
  }) {
    final WeekDayModel weekDay = agendaModel!.getWeekDay(day);
    final changed = switch (typeTime) {
      TypeTimeAgenda.startTime => weekDay.copyWith(startTime: value),
      TypeTimeAgenda.closingTime => weekDay.copyWith(closingTime: value),
      TypeTimeAgenda.startOfBreak => weekDay.copyWith(startOfBreak: value),
      TypeTimeAgenda.endOfBreak => weekDay.copyWith(endOfBreak: value),
    };
    _agendaModel.value = agendaModel!.copyWith(day, changed);
  }

  void collapsedAllDays() {
    _expandedDays.clear();
  }
}
