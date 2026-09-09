// ============================================================================
// snapbee_ui.dart
// ----------------------------------------------------------------------------
// The single source of truth for SnapBee's premium customer-app design
// language, distilled directly from the approved Daily Essentials UI
// reference screens (X:\SnapBee\01_Design\UI_References\Daily_Essentials).
//
// Everything visual — colour, spacing, radius, shadow, typography — lives
// here so every vertical (Daily Essentials, Services, Travel, Entertainment,
// E-Commerce) renders as ONE cohesive product. Screens must read tokens from
// here instead of hard-coding hex values.
//
// This file adds NO behaviour and touches NO business/backend logic. It is
// pure presentation.
// ============================================================================

import 'package:flutter/material.dart';

/// Brand + surface palette. Orange + dark-blue identity on premium
/// white/light surfaces, exactly as the reference screens.
class SnapBeeColors {
  SnapBeeColors._();

  // ---- Brand ---------------------------------------------------------------
  static const Color orange = Color(0xFFF7941D); // primary brand
  static const Color orangeDark = Color(0xFFE8790A);
  static const Color orangeDeep = Color(0xFFEA5B0C); // "Delivered Fast!" red-orange
  static const Color orangeTint = Color(0xFFFDEBD3); // light pill fill
  static const Color navy = Color(0xFF20243A); // dark-blue brand ink
  static const Color brandBlue = Color(0xFF1D4ED8); // "Daily Essentials" sub-wordmark

  // ---- Surfaces ----------------------------------------------------------
  static const Color scaffold = Color(0xFFFAFAFB); // page background
  static const Color surface = Color(0xFFFFFFFF); // cards
  static const Color cream = Color(0xFFFDEEDD); // hero card top
  static const Color creamDeep = Color(0xFFF9E2C8); // hero card bottom
  static const Color mint = Color(0xFFE8F6EC); // green promo / "fresh" banner
  static const Color mintDeep = Color(0xFFDDEFE1);
  static const Color skyCard = Color(0xFFEAF2FF); // "Join SnapBee Club" banner

  // ---- Ink -------------------------------------------------------------
  static const Color ink = Color(0xFF1C1C21); // headings
  static const Color inkSoft = Color(0xFF5A6472); // body / secondary
  static const Color inkFaint = Color(0xFF95A0AD); // captions / hints

  // ---- Lines / fills -------------------------------------------------
  static const Color hairline = Color(0xFFEDEEF1);
  static const Color chipFill = Color(0xFFF3F4F6);

  // ---- Status ---------------------------------------------------------
  static const Color success = Color(0xFF2E9E4F);
  static const Color successFill = Color(0xFFE7F6EC);
  static const Color danger = Color(0xFFE23D3D);
  static const Color dangerFill = Color(0xFFFCEBEB);
  static const Color info = Color(0xFF2E7DD1);
  static const Color infoFill = Color(0xFFE9F2FB);
  static const Color warn = Color(0xFFEEA200);
  static const Color warnFill = Color(0xFFFDF3E0);
  static const Color star = Color(0xFFFBB01B);
  static const Color strike = Color(0xFF9AA3AF); // struck-through MRP

  // ---- Pastel accents (category tiles, tinted icon chips) -------------
  static const Color pastelPeach = Color(0xFFFDEEDD);
  static const Color pastelMint = Color(0xFFE7F6EC);
  static const Color pastelPink = Color(0xFFFCE9EE);
  static const Color pastelLavender = Color(0xFFEFEAFB);
  static const Color pastelBlue = Color(0xFFE8F1FE);
  static const Color pastelLemon = Color(0xFFFDF4DA);

  static const List<Color> pastelCycle = [
    pastelPeach,
    pastelMint,
    pastelPink,
    pastelLavender,
    pastelBlue,
    pastelLemon,
  ];

  static Color pastelFor(int i) => pastelCycle[i % pastelCycle.length];

  // ---- Membership tiers (Bronze / Silver / Gold / Platinum) ----------
  static const Color bronze = Color(0xFFC1783C);
  static const Color silver = Color(0xFF98A0A9);
  static const Color gold = Color(0xFFE0A422);
  static const Color platinum = Color(0xFF7C6CF0);

  // ---- Gradients -----------------------------------------------------
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFFFDEEDD), Color(0xFFF7E0C6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFFFB74D), Color(0xFFF7941D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient mintGradient = LinearGradient(
    colors: [Color(0xFFEBF8EF), Color(0xFFDDF0E2)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

/// 4-pt spacing scale + shared radii.
class SnapBeeSpacing {
  SnapBeeSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16; // default screen gutter
  static const double xl = 20;
  static const double xxl = 28;

  static const double gutter = 16;

  static const double rCard = 20; // cards / hero
  static const double rTile = 16; // small tiles / list rows
  static const double rChip = 12; // filter chips
  static const double rField = 14; // inputs / search
  static const double rPill = 100; // fully-rounded

  static const EdgeInsets screenH = EdgeInsets.symmetric(horizontal: gutter);
  static const EdgeInsets card = EdgeInsets.all(lg);
}

/// Soft, layered shadows — the reference cards float on a barely-there
/// shadow, never a hard drop.
class SnapBeeShadows {
  SnapBeeShadows._();

  static List<BoxShadow> get card => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get soft => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.035),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get lifted => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];
}

/// Typography. System font (no custom font ships in this repo); weights and
/// sizes match the reference hierarchy. `script` approximates the reference
/// hand-lettered accent lines with a heavy italic.
class SnapBeeText {
  SnapBeeText._();

  static const TextStyle display = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: SnapBeeColors.ink,
    height: 1.15,
    letterSpacing: -0.3,
  );

  static const TextStyle h1 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: SnapBeeColors.ink,
    height: 1.2,
    letterSpacing: -0.2,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: SnapBeeColors.ink,
    height: 1.25,
  );

  static const TextStyle title = TextStyle(
    fontSize: 15.5,
    fontWeight: FontWeight.w700,
    color: SnapBeeColors.ink,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: SnapBeeColors.inkSoft,
    height: 1.4,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: SnapBeeColors.ink,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: SnapBeeColors.inkFaint,
  );

  static const TextStyle label = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    color: SnapBeeColors.inkSoft,
  );

  static const TextStyle price = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w800,
    color: SnapBeeColors.ink,
  );

  static const TextStyle script = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    fontStyle: FontStyle.italic,
    color: SnapBeeColors.navy,
    height: 1.25,
  );
}

/// Per-vertical accent so each vertical keeps a recognisable hue while
/// sharing the one design system. Daily Essentials == the brand orange.
enum SnapBeeVertical { dailyEssentials, services, travel, entertainment, ecommerce }

extension SnapBeeVerticalX on SnapBeeVertical {
  String get label {
    switch (this) {
      case SnapBeeVertical.dailyEssentials:
        return 'Daily Essentials';
      case SnapBeeVertical.services:
        return 'Services';
      case SnapBeeVertical.travel:
        return 'Travel';
      case SnapBeeVertical.entertainment:
        return 'Entertainment';
      case SnapBeeVertical.ecommerce:
        return 'E-Commerce';
    }
  }

  /// The accent used for active states / links inside the vertical.
  Color get accent {
    switch (this) {
      case SnapBeeVertical.dailyEssentials:
        return SnapBeeColors.orange;
      case SnapBeeVertical.services:
        return const Color(0xFF0E9F6E);
      case SnapBeeVertical.travel:
        return const Color(0xFF2563EB);
      case SnapBeeVertical.entertainment:
        return const Color(0xFFD6336C);
      case SnapBeeVertical.ecommerce:
        return const Color(0xFF7C3AED);
    }
  }

  Color get accentSoft {
    switch (this) {
      case SnapBeeVertical.dailyEssentials:
        return SnapBeeColors.orangeTint;
      case SnapBeeVertical.services:
        return const Color(0xFFE3F6EE);
      case SnapBeeVertical.travel:
        return const Color(0xFFE6EEFF);
      case SnapBeeVertical.entertainment:
        return const Color(0xFFFCE7EF);
      case SnapBeeVertical.ecommerce:
        return const Color(0xFFF0E9FE);
    }
  }
}

/// Central place for the mascot art shipped in `assets/images/mascot/`, with
/// a graceful fallback so a missing asset never breaks a layout.
class SnapBeeMascots {
  SnapBeeMascots._();

  static const String welcome = 'assets/images/mascot/snapbee_mascot_welcome.png';
  static const String home = 'assets/images/mascot/snapbee_mascot_home.png';
  static const String shopping = 'assets/images/mascot/snapbee_mascot_shopping.png';
  static const String scooter = 'assets/images/mascot/snapbee_mascot_scooter.png';
  static const String orders = 'assets/images/mascot/snapbee_mascot_orders.png';
  static const String club = 'assets/images/mascot/snapbee_mascot_club.png';
  static const String earnings = 'assets/images/mascot/snapbee_mascot_earnings.png';
  static const String refer = 'assets/images/mascot/snapbee_mascot_refer.png';
  static const String location = 'assets/images/mascot/snapbee_mascot_location.png';
  static const String notification = 'assets/images/mascot/snapbee_mascot_notification.png';
  static const String search = 'assets/images/mascot/snapbee_mascot_search.png';
  static const String wishlist = 'assets/images/mascot/snapbee_mascot_wishlist.png';
  static const String success = 'assets/images/mascot/snapbee_mascot_success.png';
  static const String error = 'assets/images/mascot/snapbee_mascot_error.png';
  static const String emptyCart = 'assets/images/mascot/snapbee_mascot_empty_cart.png';
}
