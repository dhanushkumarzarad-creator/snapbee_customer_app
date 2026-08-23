import 'package:flutter/material.dart';
import '../app_colors.dart';

/// Placeholder bottom navigation bar.
///
/// This is ONLY here so OfferZoneScreen is runnable standalone.
/// In the real SnapBee app, delete this file's usage in offer_zone_screen.dart
/// and drop in your existing shared bottom-nav widget instead — the
/// Offer Zone screen doesn't own or manage nav state itself.
class SnapBeeBottomNavPlaceholder extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const SnapBeeBottomNavPlaceholder({
    super.key,
    this.currentIndex = 1,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: AppColors.primaryOrange,
      unselectedItemColor: AppColors.textGrey,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.local_offer), label: 'Offers'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long),
          label: 'Orders',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
