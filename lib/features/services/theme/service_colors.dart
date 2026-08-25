import 'package:flutter/material.dart';

/// Services sector palette — structurally mirrors
/// `lib/core/constants/app_colors.dart` (Daily Essentials' own palette)
/// field-for-field, with brand/accent colors swapped to blue per the
/// Services sector's own theme. Neutral tokens (text, divider, card
/// backgrounds) are intentionally IDENTICAL to AppColors — only the brand
/// color changes between sectors, not the whole visual language. This is
/// the one place Services blue values live; no widget should hardcode a
/// blue hex value directly.
class ServiceColors {
  ServiceColors._();

  // Base
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color headerBackground = Color(0xFFDCEBFD);

  // Brand
  static const Color primaryBlue = Color(0xFF1E6FE0);
  static const Color primaryBlueDark = Color(0xFF1552A8);
  static const Color primaryBlueLight = Color(0xFFDCEAFE);

  // Text — identical to AppColors on purpose (neutral, not brand-specific).
  static const Color textPrimary = Color(0xFF1C1C1C);
  static const Color textSecondary = Color(0xFF757575);

  // UI — identical to AppColors on purpose.
  static const Color divider = Color(0xFFE7E7E7);
  static const Color cardGrey = Color(0xFFF3F3F3);
  static const Color chipGrey = Color(0xFFEDEDED);

  // Accent — identical to AppColors; these are cross-sector semantic
  // colors (success/warning/rating), not brand colors.
  static const Color accentRed = Color(0xFFE53935);
  static const Color accentGreen = Color(0xFF43A047);
  static const Color accentTeal = Color(0xFF00897B);
  static const Color accentPurple = Color(0xFF8E44AD);

  static const Color ratingStar = Color(0xFFFBC02D);

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF64A6F5), Color(0xFF1E6FE0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
