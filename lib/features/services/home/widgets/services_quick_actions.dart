import 'package:flutter/material.dart';

import '../../theme/service_colors.dart';

class ServiceQuickActionItem {
  final String label;
  final IconData icon;
  final Color iconColor;

  const ServiceQuickActionItem({required this.label, required this.icon, required this.iconColor});
}

/// Structurally identical to Daily Essentials' `QuickActionsWidget` (white
/// card, evenly-spaced icon-over-label shortcuts), populated with
/// Services-relevant destinations instead.
class ServicesQuickActions extends StatelessWidget {
  final List<ServiceQuickActionItem> actions;
  final ValueChanged<int>? onActionTap;

  const ServicesQuickActions({
    super.key,
    this.actions = const [
      ServiceQuickActionItem(label: 'Categories', icon: Icons.grid_view_rounded, iconColor: ServiceColors.primaryBlueDark),
      ServiceQuickActionItem(label: 'Offers', icon: Icons.local_offer_rounded, iconColor: ServiceColors.accentRed),
      ServiceQuickActionItem(label: 'My Bookings', icon: Icons.receipt_long_rounded, iconColor: ServiceColors.accentTeal),
      ServiceQuickActionItem(label: 'Emergency', icon: Icons.warning_amber_rounded, iconColor: Colors.deepOrange),
      ServiceQuickActionItem(label: 'Refer & Earn', icon: Icons.group_rounded, iconColor: ServiceColors.accentPurple),
    ],
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: ServiceColors.divider)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(actions.length, (index) {
            final action = actions[index];
            return _QuickActionColumn(action: action, onTap: () => onActionTap?.call(index));
          }),
        ),
      ),
    );
  }
}

class _QuickActionColumn extends StatelessWidget {
  final ServiceQuickActionItem action;
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
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ServiceColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
