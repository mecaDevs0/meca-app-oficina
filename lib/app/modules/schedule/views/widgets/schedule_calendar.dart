import 'package:flutter/material.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../../core/core.dart';
import '../../controllers/schedule_controller.dart';
import 'header_calendar.dart';
import 'week_widget.dart';

class ScheduleCalendar extends GetView<ScheduleController> {
  const ScheduleCalendar({super.key});

  Color _getColor(DateTime date) {
    final minDate = controller.minimumDate.subtract(const Duration(days: 1));
    final maximumDate = controller.maximumDate;
    const disabledColor = AppColors.hintTextColor;
    if (minDate != null && date.isBefore(minDate)) {
      return disabledColor;
    }
    if (maximumDate != null && date.isAfter(maximumDate)) {
      return disabledColor;
    }
    if (getIsSelectedDate(date)) {
      return Colors.white;
    }
    if (controller.selectedMonth.month == date.month) {
      return AppColors.abbey;
    }

    return disabledColor;
  }

  FontWeight _getFontWeight(DateTime date) {
    if (getIsSelectedDate(date)) {
      return FontWeight.bold;
    }
    if (controller.selectedMonth.month == date.month) {
      return FontWeight.w700;
    }

    return FontWeight.normal;
  }

  bool getIsSelectedDate(DateTime date) {
    if (controller.selectedDate != null &&
        controller.selectedDate.day == date.day &&
        controller.selectedDate.month == date.month &&
        controller.selectedDate.year == date.year) {
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        children: <Widget>[
          const HeaderCalendar(),
          WeekWidget(dateList: controller.dateList),
          Padding(
            padding: const EdgeInsets.only(right: 8, left: 8),
            child: Column(
              children: [
                for (int i = 0; i < controller.dateList.length / 7; i++)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int j = 0; j < 7; j++)
                        Expanded(
                          child: AspectRatio(
                            aspectRatio: 1.0,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(4)),
                                onTap: () {
                                  final date = controller.dateList[i * 7 + j];
                                  if (controller.selectedMonth.month <=
                                      date.month) {
                                    final minimumDate = controller.minimumDate;
                                    final maximumDate = controller.maximumDate;
                                    if (minimumDate != null &&
                                        maximumDate != null) {
                                      final DateTime newMinimumDate = DateTime(
                                        minimumDate.year,
                                        minimumDate.month,
                                        minimumDate.day - 1,
                                      );
                                      final DateTime newMaximumDate = DateTime(
                                        maximumDate.year,
                                        maximumDate.month,
                                        maximumDate.day + 1,
                                      );
                                      if (date.isAfter(newMinimumDate) &&
                                          date.isBefore(newMaximumDate)) {
                                        controller.onDateSelected(date);
                                      }
                                    } else if (minimumDate != null) {
                                      final DateTime newMinimumDate = DateTime(
                                        minimumDate.year,
                                        minimumDate.month,
                                        minimumDate.day - 1,
                                      );
                                      if (date.isAfter(newMinimumDate)) {
                                        controller.onDateSelected(date);
                                      }
                                    } else if (maximumDate != null) {
                                      final DateTime newMaximumDate = DateTime(
                                        maximumDate.year,
                                        maximumDate.month,
                                        maximumDate.day + 1,
                                      );
                                      if (date.isBefore(newMaximumDate)) {
                                        controller.onDateSelected(date);
                                      }
                                    } else {
                                      controller.onDateSelected(date);
                                    }
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: getIsSelectedDate(
                                        controller.dateList[i * 7 + j],
                                      )
                                          ? AppColors.primaryColor
                                          : Colors.transparent,
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(4),
                                      ),
                                      boxShadow: getIsSelectedDate(
                                        controller.dateList[i * 7 + j],
                                      )
                                          ? [
                                              const BoxShadow(
                                                color: AppColors.hintTextColor,
                                                blurRadius: 4,
                                                offset: Offset.zero,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${controller.dateList[i * 7 + j].day}',
                                        style: TextStyle(
                                          color: _getColor(
                                            controller.dateList[i * 7 + j],
                                          ),
                                          fontSize: 16,
                                          fontWeight: _getFontWeight(
                                            controller.dateList[i * 7 + j],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 26,
            height: 4,
            decoration: const BoxDecoration(
              color: AppColors.hintTextColor,
              borderRadius: BorderRadius.all(
                Radius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
