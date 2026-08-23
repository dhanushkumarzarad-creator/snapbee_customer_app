import 'package:flutter/material.dart';
import '../snapbee_theme.dart';

/// Existing SnapBee bottom navigation, kept visually identical to the
/// current app: Home / Categories (active, raised octagon) / Offers /
/// Chat / Profile.
class SnapBeeBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const SnapBeeBottomNav({
    super.key,
    this.currentIndex = 1,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFCE0B4),
      padding: const EdgeInsets.only(top: 14),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _navIcon(Icons.home_outlined, 0),
                  const SizedBox(width: 56), // space for the raised button
                  _navIcon(Icons.percent, 2),
                  _navIcon(Icons.chat_bubble_outline, 3),
                  _navIcon(Icons.person_outline, 4),
                ],
              ),
              Positioned(
                top: -22,
                child: GestureDetector(
                  onTap: () => onTap?.call(1),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: SnapBeeColors.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: SnapBeeColors.primary.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.grid_view_rounded,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navIcon(IconData icon, int index) {
    final selected = index == currentIndex;
    return IconButton(
      onPressed: () => onTap?.call(index),
      icon: Icon(
        icon,
        color: selected ? SnapBeeColors.primary : Colors.black87,
      ),
    );
  }
}
