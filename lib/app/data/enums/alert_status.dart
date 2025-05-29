import 'package:flutter/material.dart';

import '../../core/core.dart';

enum AlertStatus {
  reproved,
  withTime,
  info,
  waitingApproveBudget,
  waitingCarParts;

  Color get color {
    return switch (this) {
      AlertStatus.reproved => AppColors.apricot,
      _ => AppColors.halfBaked,
    };
  }
}
