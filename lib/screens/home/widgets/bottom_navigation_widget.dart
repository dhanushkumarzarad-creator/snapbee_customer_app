import 'package:flutter/material.dart';

/// -----------------------------------------
/// Bottom Navigation Widget
/// Part 1
/// -----------------------------------------

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class BottomNavigationWidget extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const BottomNavigationWidget({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  // Order (Profile, Home, Categories, Offers, Orders) matches the approved
  // reference and the MainScreen page list. Home (index 1) is the default
  // landing tab.
  static const List<_NavItem> _items = [
    _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
    _NavItem(icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view, label: 'Categories'),
    _NavItem(icon: Icons.local_offer_outlined, activeIcon: Icons.local_offer, label: 'Offers'),
    _NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: 'Orders'),
  ];

  static const double _barHeight = 76;
  static const double _stackHeight = 96;
  static const double _squareSize = 60;

  static const Color _iconColor = Color(0xFF20243A);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double totalWidth = constraints.maxWidth;
        final double itemWidth = totalWidth / _items.length;

        return SizedBox(
          height: _stackHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              /// Navigation Bar
              Positioned(
                left: 12,
                right: 12,
                bottom: 14,
                height: _barHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(_barHeight / 2),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: .55),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: .35),
                        blurRadius: 22,
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: List.generate(_items.length, (index) {
                      final bool isSelected = index == selectedIndex;

                      return Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(50),
                          onTap: () => onTabSelected(index),
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            // The selected slot is covered by the floating
                            // orange button, so hide the plain icon + label
                            // underneath it.
                            opacity: isSelected ? 0 : 1,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_items[index].icon, color: _iconColor, size: 24),
                                const SizedBox(height: 3),
                                Text(
                                  _items[index].label,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _iconColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),

              /// Floating Bee Button
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                left: itemWidth * selectedIndex,
                top: 0,
                width: itemWidth,
                height: _stackHeight - 14,
                child: _FloatingBeeButton(
                  key: ValueKey(selectedIndex),
                  icon: _items[selectedIndex].activeIcon,
                  label: _items[selectedIndex].label,
                  squareSize: _squareSize,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// -----------------------------------------
/// Floating Bee Button
/// Part 2
/// -----------------------------------------

class _FloatingBeeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final double squareSize;

  const _FloatingBeeButton({
    super.key,
    required this.icon,
    required this.label,
    required this.squareSize,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.75, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          alignment: Alignment.bottomCenter,
          child: child,
        );
      },
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Orange floating button + label
          Positioned(
            bottom: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: squareSize,
                  height: squareSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFFB74D), Color(0xFFFF9100)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.45),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(child: Icon(icon, color: Colors.white, size: 26)),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE8790A),
                  ),
                ),
              ],
            ),
          ),

          // Bee mascot
          Positioned(
            bottom: squareSize + 6,
            child: Image.asset(
              'assets/images/mascot/snapbee_homeicon_bee.png',
              width: squareSize + 34,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.emoji_nature,
                  size: squareSize * 0.75,
                  color: Colors.amber.shade700,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
