import 'package:flutter/material.dart';

import '../../screens/profile/profile_screen.dart';
import 'categories/service_categories_page.dart';
import 'home/services_home_screen.dart';
import 'home/widgets/services_bottom_navigation_widget.dart';
import 'offers/services_offers_screen.dart';
import 'service_records/my_bookings_screen.dart';

/// The Services sector's own root tab shell — structurally identical to
/// Daily Essentials' `MainScreen` (single Scaffold + IndexedStack + one
/// bottom nav instance), reached by pushing on top of Daily Essentials'
/// Home when the customer taps "Services" in the sector selector. A
/// deliberate, scoped exception to `MainScreen`'s own "no other screen
/// should ever create a Scaffold + BottomNav combo again" rule: that rule
/// is about not fragmenting Daily Essentials' OWN navigation, not about
/// forbidding a sibling sector from having its own equivalent shell — the
/// Services spec explicitly calls for "its own sector-specific app
/// navigation while preserving the common Customer App shell" (Profile,
/// below, is the literal same shared widget, not a copy).
///
/// Tab order MUST match ServicesBottomNavigationWidget's item order:
/// Profile, Home, Categories, Offers, Service Orders.
class ServicesMainScreen extends StatefulWidget {
  const ServicesMainScreen({super.key});

  @override
  State<ServicesMainScreen> createState() => _ServicesMainScreenState();
}

class _ServicesMainScreenState extends State<ServicesMainScreen> {
  // Index 1 = Home, mirroring MainScreen's own landing-tab convention.
  int _selectedIndex = 1;

  void _onTabSelected(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const ProfileScreen(),
      ServicesHomeScreen(onNavigateToTab: _onTabSelected),
      const ServiceCategoriesPage(),
      const ServicesOffersScreen(),
      const MyBookingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: ServicesBottomNavigationWidget(selectedIndex: _selectedIndex, onTabSelected: _onTabSelected),
    );
  }
}
