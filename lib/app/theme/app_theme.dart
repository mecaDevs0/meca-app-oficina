import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../core/app_colors.dart';

class AppTheme {
  AppTheme._();
  static final theme = ThemeData.light().copyWith(
    appBarTheme: AppBarTheme(
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: AppColors.primaryColor,
        statusBarIconBrightness:
            Platform.isIOS ? Brightness.dark : Brightness.light,
      ),
    ),
    colorScheme: ThemeData.light().colorScheme.copyWith(
          error: AppColors.apricot,
        ),
    cardTheme: const CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      surfaceTintColor: Colors.white,
      color: Colors.white,
    ),
    dialogTheme: const DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
    ),
    buttonTheme: const ButtonThemeData(
      height: 46,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primaryColor,
        secondary: AppColors.apricot,
        error: AppColors.apricot,
        surface: AppColors.primaryColor,
        onSurface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onError: Colors.white,
      ),
    ),
    primaryColor: AppColors.primaryColor,
    scaffoldBackgroundColor: Colors.white,
    inputDecorationTheme: const InputDecorationTheme(
      hintStyle: TextStyle(
        color: AppColors.hintTextColor,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      border: OutlineInputBorder(gapPadding: 2),
      errorMaxLines: 2,
      focusedBorder: OutlineInputBorder(),
      focusColor: AppColors.primaryColor,
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: AppColors.apricot,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: AppColors.apricot,
        ),
      ),
      errorStyle: TextStyle(
        color: AppColors.apricot,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),
    textTheme: GoogleFonts.ubuntuTextTheme(),
  );
}
