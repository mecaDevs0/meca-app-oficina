import 'package:flutter/material.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../../core/core.dart';

class WeekWidget extends StatelessWidget {
  const WeekWidget({super.key, required this.dateList});

  final List<DateTime> dateList;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, left: 8, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: dateList.take(7).map((date) => ItemWeek(date: date)).toList(),
      ),
    );
  }
}

class ItemWeek extends StatelessWidget {
  const ItemWeek({
    super.key,
    required this.date,
  });

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          DateFormat('EEE', 'pt-BR').format(date).substring(0, 3).capitalize!,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.baliHai,
          ),
        ),
      ),
    );
  }
}
