import 'package:flutter/material.dart';

import '../../theme/service_colors.dart';

/// Services sector's header — structurally identical to Daily Essentials'
/// `HomeHeader` (location + notification), blue-themed. No cart icon: the
/// Services sector has no shopping-cart concept, and a dedicated "Service
/// Orders" bottom-nav destination already covers what a shortcut icon here
/// would have duplicated.
class ServicesHeader extends StatelessWidget {
  final String cityLabel;
  final String addressLabel;
  final int notificationCount;
  final VoidCallback? onLocationTap;
  final VoidCallback? onNotificationTap;

  const ServicesHeader({
    super.key,
    this.cityLabel = 'Dharmapuri',
    this.addressLabel = 'Near Bus Stand, Dharmapuri',
    this.notificationCount = 0,
    this.onLocationTap,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ServiceColors.headerBackground,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: InkWell(
              onTap: onLocationTap,
              borderRadius: BorderRadius.circular(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: ServiceColors.textPrimary, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        cityLabel,
                        style: const TextStyle(color: ServiceColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down, color: ServiceColors.textPrimary, size: 20),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Text(
                      addressLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: ServiceColors.textSecondary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          _HeaderIconButton(icon: Icons.notifications_none_rounded, badgeCount: notificationCount, onTap: onNotificationTap),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final int badgeCount;
  final VoidCallback? onTap;

  const _HeaderIconButton({required this.icon, this.badgeCount = 0, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Icon(icon, color: ServiceColors.primaryBlueDark, size: 24),
          ),
          if (badgeCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    badgeCount > 9 ? '9+' : '$badgeCount',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
