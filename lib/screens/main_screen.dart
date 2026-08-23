import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'category/category_screen.dart';
import 'offers/offers_screen.dart';
import 'orders/orders_screen.dart';
import 'profile/profile_screen.dart';
import 'home/widgets/bottom_navigation_widget.dart';

/// MainScreen is the SINGLE root screen for the entire app's tab navigation.
///
/// It owns:
///  - the currently selected tab index (single source of truth)
///  - the IndexedStack that preserves each tab's state
///  - the one and only BottomNavigationWidget instance
///
/// No other screen should ever create a Scaffold + BottomNav combo again.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Index 1 = Home, since Home is the default landing tab even though
  // Profile is visually first in the bar (matches the reference design).
  int _selectedIndex = 1;

  // Tab pages. Order here MUST match the order of items in
  // BottomNavigationWidget so index references line up correctly:
  // Profile, Home, Category, Offers, Orders.
  final List<Widget> _pages = const [
    ProfileScreen(),
    HomeScreen(),
    CategoryScreen(),
    OfferZoneScreen(),
    OrdersScreen(),
  ];

  void _onTabSelected(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack keeps all 5 pages mounted simultaneously, only toggling
      // visibility. This preserves scroll position, form state, and
      // animation state per tab instead of rebuilding from scratch.
      body: IndexedStack(index: _selectedIndex, children: _pages),
      // The ONE and ONLY bottom navigation widget in the entire app.
      bottomNavigationBar: BottomNavigationWidget(
        selectedIndex: _selectedIndex,
        onTabSelected: _onTabSelected,
      ),
    );
  }
}
