import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Base
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color creamBackground = Color(0xFFFDECC8);

  // Brand
  static const Color primaryOrange = Color(0xFFF7941D);
  static const Color primaryOrangeDark = Color(0xFFE8790A);
  static const Color primaryOrangeLight = Color(0xFFFDEBD3);

  // Text
  static const Color textPrimary = Color(0xFF1C1C1C);
  static const Color textSecondary = Color(0xFF757575);

  // UI
  static const Color divider = Color(0xFFE7E7E7);
  static const Color cardGrey = Color(0xFFF3F3F3);
  static const Color chipGrey = Color(0xFFEDEDED);

  // Accent
  static const Color accentRed = Color(0xFFE53935);
  static const Color accentGreen = Color(0xFF43A047);
  static const Color accentBlue = Color(0xFF1E88E5);
  static const Color accentPurple = Color(0xFF8E44AD);
  static const Color accentTeal = Color(0xFF00897B);

  // Rating / Offers
  static const Color ratingStar = Color(0xFFFBC02D);
  static const Color discountBadge = Color(0xFF43A047);
  static const Color strikePrice = Color(0xFF9E9E9E);

  // Gradient
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFFFFC15E), Color(0xFFF7941D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
