import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mega_commons/mega_commons.dart';

import '../core.dart';

class AppBodyTimerModal extends StatefulWidget {
  const AppBodyTimerModal({super.key, required this.onConfirm});

  final Function(String) onConfirm;

  @override
  State<AppBodyTimerModal> createState() => _AppBodyTimerModalState();
}

class _AppBodyTimerModalState extends State<AppBodyTimerModal> {
  String _openingHours = '08:00';
  String _closingHours = '18:00';
  final now = DateTime.now();

  void _onOpeningHoursChanged(DateTime value) {
    _openingHours = value.toHHmm();
  }

  void _onClosingHoursChanged(DateTime value) {
    _closingHours = value.toHHmm();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Selecione o horário de funcionamento',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _TimerWidget(
                title: 'Abertura',
                onDateTimeChanged: _onOpeningHoursChanged,
                initialDateTime: DateTime(now.year, now.month, now.day, 8, 0),
              ),
              _TimerWidget(
                title: 'Fechamento',
                onDateTimeChanged: _onClosingHoursChanged,
                initialDateTime: DateTime(now.year, now.month, now.day, 18, 0),
              ),
            ],
          ),
          const SizedBox(height: 24),
          MegaBaseButton(
            'Confirmar',
            onButtonPress: () {
              widget.onConfirm('$_openingHours às $_closingHours');
              Navigator.pop(context);
            },
            borderRadius: 4,
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerWidget extends StatelessWidget {
  const _TimerWidget({
    required this.title,
    required this.onDateTimeChanged,
    required this.initialDateTime,
  });

  final String title;
  final Function(DateTime) onDateTimeChanged;
  final DateTime initialDateTime;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title:',
            style: const TextStyle(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: CupertinoDatePicker(
              use24hFormat: true,
              initialDateTime: initialDateTime,
              mode: CupertinoDatePickerMode.time,
              minuteInterval: 5,
              onDateTimeChanged: onDateTimeChanged,
            ),
          ),
        ],
      ),
    );
  }
}
