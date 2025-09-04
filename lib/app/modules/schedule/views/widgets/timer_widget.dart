import 'package:flutter/material.dart';

import '../../../../core/core.dart';

class TimerWidget extends StatelessWidget {
  const TimerWidget({
    super.key,
    required this.title,
    required this.hint,
    required this.value,
    required this.onChanged,
    this.isOptional = false,
  });

  final String title;
  final String hint;
  final String value;
  final Function(String) onChanged;
  final bool isOptional;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título com tag opcional
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.abbey,
              ),
            ),
            if (isOptional) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'OPCIONAL',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        
        // Campo de seleção de horário
        GestureDetector(
          onTap: () async {
            final TimeOfDay? time = await showTimePicker(
              context: context,
              initialTime: _parseTime(value),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppColors.primaryColor,
                      onPrimary: Colors.white,
                      surface: Colors.white,
                    ),
                    timePickerTheme: TimePickerThemeData(
                      backgroundColor: Colors.white,
                      hourMinuteTextColor: AppColors.primaryColor,
                      hourMinuteColor: AppColors.primaryColor.withOpacity(0.1),
                      dialHandColor: AppColors.primaryColor,
                      dialBackgroundColor: Colors.grey[100],
                      dialTextColor: AppColors.abbey,
                      entryModeIconColor: AppColors.primaryColor,
                    ),
                  ),
                  child: child!,
                );
              },
            );

            if (time != null) {
              final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
              onChanged(timeString);
            }
          },
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: value.isNotEmpty
                    ? AppColors.primaryColor
                    : Colors.grey[300]!,
                width: value.isNotEmpty ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: value.isNotEmpty
                        ? AppColors.primaryColor.withOpacity(0.1)
                        : Colors.grey[100],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(7),
                      bottomLeft: Radius.circular(7),
                    ),
                  ),
                  child: Icon(
                    Icons.access_time,
                    color: value.isNotEmpty
                        ? AppColors.primaryColor
                        : Colors.grey[400],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value.isNotEmpty ? value : hint,
                    style: TextStyle(
                      color: value.isNotEmpty
                          ? AppColors.abbey
                          : Colors.grey[400],
                      fontSize: 16,
                      fontWeight: value.isNotEmpty
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: Colors.grey[400],
                  size: 24,
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
        
        // Texto de ajuda
        if (value.isEmpty) ...[
          const SizedBox(height: 4),
          Text(
            hint,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  TimeOfDay _parseTime(String timeString) {
    if (timeString.isEmpty) return const TimeOfDay(hour: 8, minute: 0);
    try {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      print('❌ Erro ao fazer parse do horário: $e');
    }
    return const TimeOfDay(hour: 8, minute: 0);
  }
}
