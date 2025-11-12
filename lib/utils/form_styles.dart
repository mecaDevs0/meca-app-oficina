import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../services/theme_service.dart';

class FormStyles {
  const FormStyles._();

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static TextStyle inputTextStyle(BuildContext context) {
    final isDark = _isDark(context);
    return TextStyle(
      color: ThemeService.getTextColor(isDark),
      fontSize: 14,
    );
  }

  static InputDecoration decorate(
    BuildContext context,
    InputDecoration decoration,
  ) {
    final isDark = _isDark(context);

    final fillColor =
        decoration.fillColor ?? ThemeService.getInputColor(isDark);
    final labelStyle = decoration.labelStyle ??
        TextStyle(
          color: isDark
              ? Colors.white.withOpacity(0.7)
              : const Color(0xFF4B5563),
        );
    final hintStyle = decoration.hintStyle ??
        TextStyle(
          color: isDark
              ? Colors.white.withOpacity(0.5)
              : const Color(0xFF9CA3AF),
        );
    final enabledBorder = decoration.enabledBorder ??
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: ThemeService.getBorderColor(isDark),
            width: 1.2,
          ),
        );
    final focusedBorder = decoration.focusedBorder ??
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: AppColors.primaryColor,
            width: 2,
          ),
        );

    return decoration.copyWith(
      filled: decoration.filled ?? true,
      fillColor: fillColor,
      labelStyle: labelStyle,
      hintStyle: hintStyle,
      enabledBorder: enabledBorder,
      border: decoration.border ?? enabledBorder,
      focusedBorder: focusedBorder,
      contentPadding: decoration.contentPadding ??
          const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
    );
  }
}

