import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mega_commons/mega_commons.dart';

import '../../theme/app_calendar_theme.dart';
import '../core.dart';

class AppDataPicker extends StatefulWidget {
  const AppDataPicker({
    super.key,
    required this.label,
    required this.hintText,
    required this.onApplyClick,
    required this.onCancelClick,
    this.minimumDate,
    this.maximumDate,
    this.selectedStartDate,
    this.selectedEndDate,
  });

  @override
  State<AppDataPicker> createState() => _AppDataPickerState();

  final String label;
  final String hintText;
  final void Function(DateTime, DateTime?) onApplyClick;
  final void Function() onCancelClick;
  final DateTime? minimumDate;
  final DateTime? maximumDate;
  final DateTime? selectedStartDate;
  final DateTime? selectedEndDate;
}

class _AppDataPickerState extends State<AppDataPicker> {
  final dateController = TextEditingController();

  String _validDate(DateTime startDate, DateTime? endDate) {
    if (startDate == null && endDate == null) {
      return '';
    }
    if (endDate == null) {
      return startDate.toddMMyy();
    }
    return '${startDate.toddMMyy()} - ${endDate.toddMMyy()}';
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: dateController,
      label: widget.label,
      hintText: widget.hintText,
      onTap: () {
        showMegaDateRangePicker(
          context,
          dismissible: true,
          minimumDate: widget.minimumDate ??
              DateTime.now().subtract(const Duration(days: 365)),
          maximumDate: widget.minimumDate ??
              DateTime.now().add(const Duration(days: 365)),
          onApplyClick: (startDate, endDate) {
            dateController.text = _validDate(startDate, endDate);
            widget.onApplyClick(startDate, endDate);
          },
          onCancelClick: () {
            dateController.clear();
            widget.onCancelClick();
          },
          theme: const AppCalendarTheme(),
          startDate: widget.selectedStartDate,
          endDate: widget.selectedEndDate,
          radiusConfirmButton: 6,
        );
      },
      suffixIcon: SvgPicture.asset(
        AppImages.icSchedule,
        colorFilter: const ColorFilter.mode(
          AppColors.abbey,
          BlendMode.srcIn,
        ),
        height: 24,
      ),
    );
  }
}
