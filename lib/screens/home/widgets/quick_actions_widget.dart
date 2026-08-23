import 'package:flutter/material.dart';
import 'package:snapbee_customer_app/core/constants/app_colors.dart';

/// A single quick-action shortcut, e.g. Top Offers, Near Me.
class QuickActionItem {
  final String label;
  final IconData icon;
  final Color iconColor;

  const QuickActionItem({
    required this.label,
    required this.icon,
    required this.iconColor,
  });
}

/// White card row of five quick-action shortcuts shown below the hero
/// banner: Top Offers, Near Me, Free Delivery, SnapBee Club, and
/// Refer & Earn. Each is an icon over a short label, evenly spaced.
class QuickActionsWidget extends StatelessWidget {
  final List<QuickActionItem> actions;
  final ValueChanged<int>? onActionTap;

  const QuickActionsWidget({
    super.key,
    this.actions = const [
      QuickActionItem(
        label: 'Top Offers',
        icon: Icons.local_offer_rounded,
        iconColor: AppColors.accentRed,
      ),
      QuickActionItem(
        label: 'Near Me',
        icon: Icons.location_on_rounded,
        iconColor: AppColors.accentGreen,
      ),
      QuickActionItem(
        label: 'Free Delivery',
        icon: Icons.two_wheeler_rounded,
        iconColor: AppColors.primaryOrangeDark,
      ),
      QuickActionItem(
        label: 'SnapBee Club',
        icon: Icons.workspace_premium_rounded,
        iconColor: AppColors.accentPurple,
      ),
      QuickActionItem(
        label: 'Refer & Earn',
        icon: Icons.group_rounded,
        iconColor: AppColors.accentTeal,
      ),
    ],
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(actions.length, (index) {
            final action = actions[index];
            return _QuickActionColumn(
              action: action,
              onTap: () => onActionTap?.call(index),
            );
          }),
        ),
      ),
    );
  }
}

class _QuickActionColumn extends StatelessWidget {
  final QuickActionItem action;
  final VoidCallback? onTap;

  const _QuickActionColumn({required this.action, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(action.icon, size: 26, color: action.iconColor),
            const SizedBox(height: 6),
            Text(
              action.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
