// ============================================================================
// app_theme.dart
// ----------------------------------------------------------------------------
// Single source of truth for SnapBee's design tokens (color, radius, spacing)
// and the Material 3 ThemeData built from them. Every screen should read
// colors/spacing from here rather than hard-coding hex values, so a future
// re-brand or dark-mode pass touches one file.
// ============================================================================

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primaryGreen = Color(0xFF00C853);
  static const Color primaryGreenDark = Color(0xFF00A344);
  static const Color backgroundLightTop = Color(0xFFF3FBF4);
  static const Color backgroundLightBottom = Color(0xFFE3F6E7);
  static const Color textDark = Color(0xFF1B1F1C);
  static const Color textMuted = Color(0xFF6B7570);
  static const Color fieldFill = Color(0xFFFFFFFF);
  static const Color fieldBorder = Color(0xFFDCEAE0);

  // Membership tier accent colors — reused across dashboard, cards, badges.
  static const Color bronze = Color(0xFFCD7F32);
  static const Color silver = Color(0xFF9AA3AB);
  static const Color gold = Color(0xFFDBA800);
  static const Color platinum = Color(0xFF6C63FF);
}

class AppSpacing {
  AppSpacing._();

  static const double screenPadding = 24.0;
  static const double borderRadius = 18.0;
  static const double fieldGap = 18.0;
  static const double sectionGap = 32.0;
}

class AppBreakpoints {
  AppBreakpoints._();

  static const double tablet = 600;
  static const double desktop = 1024;

  static bool isTablet(double width) => width >= tablet && width < desktop;
  static bool isDesktop(double width) => width >= desktop;

  static double maxContentWidth(double width) {
    if (isDesktop(width)) return 460;
    if (isTablet(width)) return 420;
    return double.infinity;
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryGreen,
      primary: AppColors.primaryGreen,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundLightTop,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.fieldFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          borderSide: const BorderSide(color: AppColors.fieldBorder),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          ),
        ),
      ),
    );
  }
}
