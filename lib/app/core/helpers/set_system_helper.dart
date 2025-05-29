import 'dart:io'; // Add this import to check for platform

import 'package:flutter/services.dart';

class SetSystemHelper {
  SetSystemHelper._();

  static void setSystemUIOverlayStyle({
    required Brightness statusBarIconBrightness,
    required Color statusBarColor,
  }) {
    if (Platform.isIOS) {
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: statusBarColor,
          statusBarBrightness: statusBarIconBrightness,
        ),
      );
    } else {
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: statusBarColor,
          statusBarIconBrightness: statusBarIconBrightness,
        ),
      );
    }
  }
}
