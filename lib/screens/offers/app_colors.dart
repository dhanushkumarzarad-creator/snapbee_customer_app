import 'package:flutter/material.dart';

/// Centralized theme constants for the SnapBee Offer Zone.
/// Keep all colors, radii and shadows here so every widget stays
/// visually consistent and easy to re-theme later.
class AppColors {
  AppColors._();

  static const Color primaryOrange = Color(0xFFFF9800);
  static const Color darkOrange = Color(0xFFF57C00);
  static const Color lightOrange = Color(0xFFFFE0B2);
  static const Color background = Color(0xFFF8F8F8);
  static const Color white = Colors.white;
  static const Color textDark = Color(0xFF212121);
  static const Color textGrey = Color(0xFF757575);
  static const Color strikePrice = Color(0xFF9E9E9E);
  static const Color verifiedGreen = Color(0xFF43A047);
  static const Color starGold = Color(0xFFFFC107);
}

class AppRadii {
  AppRadii._();

  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
  static const double banner = 18;
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> soft = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];
}

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );

  static const TextStyle viewAll = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryOrange,
  );

  static const TextStyle productName = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static const TextStyle offerPrice = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );

  static const TextStyle oldPrice = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.strikePrice,
    decoration: TextDecoration.lineThrough,
  );
}
