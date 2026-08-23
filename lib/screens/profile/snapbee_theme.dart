import 'package:flutter/material.dart';

/// Design tokens shared across the Categories screen and its widgets.
///
/// Centralising these means a future theming pass (e.g. dark mode, or
/// pulling values from `ThemeData` instead) only touches this one file.
class SnapBeeColors {
  SnapBeeColors._();

  static const Color primary = Color(0xFFFF9800); // SnapBee Orange
  static const Color primaryDark = Color(0xFFF57C00);
  static const Color scaffoldBackground = Color(0xFFF8F8F8);
  static const Color cardBackground = Colors.white;
  static const Color unselectedChip = Color(0xFFF0F0F0);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color rating = Color(0xFFFFA000);
  static const Color discountBadge = Color(0xFFE53935);
  static const Color shadow = Color(0x1A000000); // 10% black
}

class SnapBeeRadii {
  SnapBeeRadii._();

  static const double card = 16;
  static const double searchBar = 16;
  static const double sidebarItem = 14;
  static const double badge = 8;
}

class SnapBeeSpacing {
  SnapBeeSpacing._();

  static const double screenPadding = 16;
  static const double cardGap = 16;
  static const double small = 8;
  static const double tiny = 4;
}

/// Breakpoints used to adapt the split-screen layout across
/// mobile / tablet / web, per the responsive requirement.
class SnapBeeBreakpoints {
  SnapBeeBreakpoints._();

  static const double tablet = 700;
  static const double desktop = 1100;

  /// Left column (category rail) width as a fraction of total width.
  /// Mobile keeps the requested 25%; wider layouts cap it so the rail
  /// doesn't get absurdly wide on desktop.
  static double sidebarFraction(double width) {
    if (width >= desktop) return 0.18;
    if (width >= tablet) return 0.22;
    return 0.25;
  }
}
