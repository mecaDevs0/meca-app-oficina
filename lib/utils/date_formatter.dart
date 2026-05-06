import 'package:flutter/services.dart';

class DateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');

    final buffer = StringBuffer();
    for (var i = 0; i < digitsOnly.length && i < 8; i++) {
      if (i == 2 || i == 4) {
        buffer.write('/');
      }
      buffer.write(digitsOnly[i]);
    }

    final formatted = buffer.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Retorna label humanizado para exibição nos cards de agendamento.
String humanizeBookingDate(DateTime date) {
  final d = DateTime(date.year, date.month, date.day, date.hour, date.minute);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(d.year, d.month, d.day);
  final diffDays = target.difference(today).inDays;

  final timeStr =
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  if (diffDays == -1) return 'Ontem às $timeStr';
  if (diffDays == 0) return 'Hoje às $timeStr';
  if (diffDays == 1) return 'Amanhã às $timeStr';

  final dayStr = d.day.toString().padLeft(2, '0');
  final monthStr = d.month.toString().padLeft(2, '0');
  return '$dayStr/$monthStr/${d.year} às $timeStr';
}
