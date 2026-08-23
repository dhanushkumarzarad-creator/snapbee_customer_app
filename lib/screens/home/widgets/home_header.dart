import 'package:flutter/material.dart';
import 'package:snapbee_customer_app/core/constants/app_colors.dart';

/// Cream-colored header shown at the very top of the Home screen.
/// Shows the customer's current delivery location + a short address
/// line underneath (tappable to change), a notification bell with an
/// unread-count badge, and a cart icon with an item-count badge.
class HomeHeader extends StatelessWidget {
  final String cityLabel;
  final String addressLabel;
  final int cartItemCount;
  final int notificationCount;
  final VoidCallback? onLocationTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onCartTap;

  const HomeHeader({
    super.key,
    this.cityLabel = 'Dharmapuri',
    this.addressLabel = 'Near Bus Stand, Dharmapuri',
    // No caller should rely on these defaults for real counts — they used
    // to be hardcoded to 2/3, showing fake numbers to every customer
    // regardless of actual cart contents or unread notifications. 0 hides
    // the badge entirely (see the `if (badgeCount > 0)` below), which is
    // the honest state when a caller doesn't pass a real value.
    this.cartItemCount = 0,
    this.notificationCount = 0,
    this.onLocationTap,
    this.onNotificationTap,
    this.onCartTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.creamBackground,
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
                      const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        cityLabel,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Text(
                      addressLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          _HeaderIconButton(
            icon: Icons.notifications_none_rounded,
            badgeCount: notificationCount,
            onTap: onNotificationTap,
          ),
          const SizedBox(width: 16),
          _HeaderIconButton(
            icon: Icons.shopping_cart_outlined,
            badgeCount: cartItemCount,
            onTap: onCartTap,
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final int badgeCount;
  final VoidCallback? onTap;

  const _HeaderIconButton({
    required this.icon,
    this.badgeCount = 0,
    this.onTap,
  });

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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: const Color.fromARGB(255, 219, 128, 0),
              size: 24,
            ),
          ),

          if (badgeCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    badgeCount > 9 ? '9+' : '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
