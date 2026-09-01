import 'package:flutter/material.dart';

/// Travel sector palette — structurally mirrors AppColors/ServiceColors
/// field-for-field, brand swapped to teal-green (matches snapbee_travel /
/// snapbee_travel_admin's own AppColors so the sector reads as one brand
/// across customer + provider + admin surfaces). Neutral tokens stay
/// identical to AppColors on purpose.
class TravelColors {
  TravelColors._();

  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color headerBackground = Color(0xFFDDEFE6);

  static const Color primary = Color(0xFF0B6E4F);
  static const Color primaryDark = Color(0xFF07472F);
  static const Color primaryLight = Color(0xFFDDEFE6);

  static const Color textPrimary = Color(0xFF1C1C1C);
  static const Color textSecondary = Color(0xFF757575);

  static const Color divider = Color(0xFFE7E7E7);
  static const Color cardGrey = Color(0xFFF3F3F3);
  static const Color chipGrey = Color(0xFFEDEDED);

  static const Color accentRed = Color(0xFFE53935);
  static const Color accentGreen = Color(0xFF43A047);
  static const Color ratingStar = Color(0xFFFBC02D);
}
