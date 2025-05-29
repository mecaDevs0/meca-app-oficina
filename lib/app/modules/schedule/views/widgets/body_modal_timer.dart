import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mega_commons/mega_commons.dart';

import '../../../../core/core.dart';

class BodyModalTimer extends StatelessWidget {
  const BodyModalTimer({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String? value;
  final void Function(String) onChanged;

  DateTime getInitialDateTime(String? value) {
    if (value.isNullOrEmpty) {
      final now = DateTime.now();
      final minute = now.minute < 30 ? 0 : 30;
      return now.copyWith(
        minute: minute,
        second: 0,
        millisecond: 0,
        microsecond: 0,
      );
    } else {
      final timeParts = value!.split(':');
      if (timeParts.length == 2) {
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        final adjustedMinute = minute < 30 ? 0 : 30;
        return DateTime(2021, 1, 1, hour, adjustedMinute);
      } else {
        final now = DateTime.now();
        final minute = now.minute < 30 ? 0 : 30;
        return now.copyWith(
          minute: minute,
          second: 0,
          millisecond: 0,
          microsecond: 0,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String time = value.isNullOrEmpty ? '00:00' : value!;
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Escolha o horário',
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                width: 300,
                child: CupertinoDatePicker(
                  use24hFormat: true,
                  initialDateTime: getInitialDateTime(value),
                  mode: CupertinoDatePickerMode.time,
                  minuteInterval: 30,
                  onDateTimeChanged: (value) {
                    time = value.toHHmm();
                  },
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: MegaBaseButton(
                      'Cancelar',
                      onButtonPress: () {
                        Navigator.pop(context);
                      },
                      borderRadius: 4,
                      buttonColor: Colors.transparent,
                      border: Border.all(
                        color: AppColors.abbey,
                        width: 1,
                      ),
                      textStyle: const TextStyle(
                        color: AppColors.abbey,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MegaBaseButton(
                      'Confirmar',
                      onButtonPress: () {
                        onChanged(time);
                        Navigator.pop(context);
                      },
                      borderRadius: 4,
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
