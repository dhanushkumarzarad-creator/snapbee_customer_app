import 'package:flutter/material.dart';

import '../../../core/design/snapbee_design.dart';

/// The white quick-action card under the hero banner on Home:
/// Top Offers · Near Me · Free Delivery · SnapBee Club · Refer & Earn.
/// Pure navigation affordances — each callback routes to an existing
/// screen; this widget owns no data.
class HomeQuickActions extends StatelessWidget {
  final VoidCallback? onTopOffers;
  final VoidCallback? onNearMe;
  final VoidCallback? onFreeDelivery;
  final VoidCallback? onClub;
  final VoidCallback? onRefer;

  const HomeQuickActions({
    super.key,
    this.onTopOffers,
    this.onNearMe,
    this.onFreeDelivery,
    this.onClub,
    this.onRefer,
  });

  @override
  Widget build(BuildContext context) {
    return SnapBeeQuickActionRail(
      actions: [
        SnapBeeQuickAction(
          icon: Icons.percent_rounded,
          label: 'Top Offers',
          color: SnapBeeColors.orangeDeep,
          onTap: onTopOffers,
        ),
        SnapBeeQuickAction(
          icon: Icons.near_me_rounded,
          label: 'Near Me',
          color: SnapBeeColors.success,
          onTap: onNearMe,
        ),
        SnapBeeQuickAction(
          icon: Icons.delivery_dining_rounded,
          label: 'Free Delivery',
          color: SnapBeeColors.orange,
          onTap: onFreeDelivery,
        ),
        SnapBeeQuickAction(
          icon: Icons.workspace_premium_rounded,
          label: 'SnapBee Club',
          color: SnapBeeColors.platinum,
          onTap: onClub,
        ),
        SnapBeeQuickAction(
          icon: Icons.card_giftcard_rounded,
          label: 'Refer & Earn',
          color: SnapBeeColors.info,
          onTap: onRefer,
        ),
      ],
    );
  }
}
