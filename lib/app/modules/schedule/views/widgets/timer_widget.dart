import 'package:flutter/material.dart';
import 'package:mega_commons/mega_commons.dart';

import '../../../../core/core.dart';
import 'body_modal_timer.dart';

class TimerWidget extends StatelessWidget {
  const TimerWidget({
    super.key,
    required this.title,
    required this.hint,
    this.value,
    required this.onChanged,
  });

  final String title;
  final String hint;
  final String? value;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        InkWell(
          splashColor: Colors.transparent,
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => Material(
                color: Colors.transparent,
                child: BodyModalTimer(
                  value: value,
                  onChanged: onChanged,
                ),
              ),
            );
          },
          child: Container(
            width: 146,
            padding: const EdgeInsets.all(16),
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                side: const BorderSide(
                  width: 1,
                  color: AppColors.grayBorderColor,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Text(
              value ?? hint,
              style: TextStyle(
                color: value.isNullOrEmpty
                    ? AppColors.hintTextColor
                    : AppColors.abbey,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
