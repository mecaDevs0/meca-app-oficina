import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';

class AppTheme {
  AppTheme._();
  
  static final theme = ThemeData.light().copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.backgroundColor,
      foregroundColor: AppColors.fontDarkGray,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.fontDarkGray,
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: AppColors.backgroundColor,
        statusBarIconBrightness: Brightness.dark,
      ),
    ),
    colorScheme: ThemeData.light().colorScheme.copyWith(
      primary: AppColors.primaryColor,
      secondary: AppColors.secondaryColor,
      error: AppColors.errorColor,
      surface: AppColors.backgroundColor,
      onSurface: AppColors.fontDarkGray,
      onPrimary: AppColors.backgroundColor,
      onSecondary: AppColors.backgroundColor,
      onError: AppColors.backgroundColor,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.grayBorderColor, width: 1),
      ),
      surfaceTintColor: AppColors.backgroundColor,
      color: AppColors.backgroundColor,
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: AppColors.backgroundColor,
      surfaceTintColor: AppColors.backgroundColor,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.backgroundColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryColor,
        side: const BorderSide(color: AppColors.primaryColor, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    primaryColor: AppColors.primaryColor,
    scaffoldBackgroundColor: AppColors.surfaceColor,
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: GoogleFonts.inter(
        color: AppColors.hintTextColor,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.grayBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.grayBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.errorColor, width: 2),
      ),
      errorStyle: GoogleFonts.inter(
        color: AppColors.errorColor,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    ),
    textTheme: GoogleFonts.interTextTheme().copyWith(
      headlineLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.fontDarkGray,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: AppColors.fontDarkGray,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.fontDarkGray,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.fontDarkGray,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.fontDarkGray,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.fontDarkGray,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.fontDarkGray,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.grayMedium,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.silver,
      ),
    ),
  );
}
