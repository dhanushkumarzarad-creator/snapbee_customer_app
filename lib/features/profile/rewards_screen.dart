import 'package:flutter/material.dart';

import '../../core/design/snapbee_design.dart';
import '../../models/customer_model.dart';

/// My Rewards — shows the customer's real `reward_points` balance and a
/// redeemable-rewards catalogue. Redemption isn't wired to a backend yet, so
/// the redeem actions acknowledge clearly instead of faking a transaction.
/// The activity list uses an honest empty state.
class RewardsScreen extends StatelessWidget {
  final CustomerModel? customer;

  const RewardsScreen({super.key, this.customer});

  @override
  Widget build(BuildContext context) {
    final points = customer?.rewardPoints ?? 0;

    return Scaffold(
      appBar: const SnapBeeAppBar(
        trailing: Padding(
          padding: EdgeInsets.only(right: 8),
          child: SnapBeePillButton(label: 'How It Works?', icon: Icons.help_outline, color: SnapBeeColors.info),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const SnapBeePageHeader(
            icon: Icons.star_rounded,
            title: 'My Rewards',
            subtitle: 'Shop More. Earn More. Get Rewarded!',
            tint: SnapBeeColors.star,
          ),

          Container(
            margin: const EdgeInsets.fromLTRB(SnapBeeSpacing.gutter, 6, SnapBeeSpacing.gutter, 6),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: SnapBeeColors.cream,
              borderRadius: BorderRadius.circular(SnapBeeSpacing.rCard),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your Points Balance', style: SnapBeeText.body.copyWith(fontSize: 13)),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('$points', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: SnapBeeColors.navy)),
                          const SizedBox(width: 6),
                          Text('SnapPoints', style: SnapBeeText.body.copyWith(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SnapBeeMascotImage(asset: SnapBeeMascots.club, height: 88),
              ],
            ),
          ),

          SnapBeeQuickActionRail(
            actions: [
              SnapBeeQuickAction(icon: Icons.shopping_bag_rounded, label: 'Earn Points', color: SnapBeeColors.orange, onTap: () {}),
              SnapBeeQuickAction(icon: Icons.redeem_rounded, label: 'Redeem', color: SnapBeeColors.danger, onTap: () => _soon(context)),
              SnapBeeQuickAction(icon: Icons.timeline_rounded, label: 'History', color: SnapBeeColors.success, onTap: () {}),
              SnapBeeQuickAction(icon: Icons.workspace_premium_rounded, label: 'Benefits', color: SnapBeeColors.platinum, onTap: () {}),
            ],
          ),

          const SnapBeeSectionHeader(title: 'Rewards You Can Get', actionLabel: null),
          SizedBox(
            height: 132,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: SnapBeeSpacing.screenH,
              children: const [
                _RewardTile('₹50 Discount Coupon', '500 Points', Icons.confirmation_number_rounded, SnapBeeColors.success),
                _RewardTile('Free Delivery (1 Order)', '750 Points', Icons.local_shipping_rounded, SnapBeeColors.info),
                _RewardTile('₹100 Discount Coupon', '1,000 Points', Icons.percent_rounded, SnapBeeColors.danger),
                _RewardTile('Exclusive Offers', '1,000 Points', Icons.shopping_bag_rounded, SnapBeeColors.orange),
                _RewardTile('Club Bonus Rewards', '2,000 Points', Icons.workspace_premium_rounded, SnapBeeColors.platinum),
              ],
            ),
          ),

          const SnapBeeSectionHeader(title: 'Recent Activity', actionLabel: null),
          Container(
            margin: SnapBeeSpacing.screenH,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            decoration: BoxDecoration(
              color: SnapBeeColors.surface,
              borderRadius: BorderRadius.circular(SnapBeeSpacing.rTile),
              boxShadow: SnapBeeShadows.soft,
            ),
            child: Column(
              children: [
                Icon(Icons.stars_rounded, size: 34, color: SnapBeeColors.inkFaint),
                const SizedBox(height: 10),
                Text('No rewards activity yet', style: SnapBeeText.title),
                const SizedBox(height: 4),
                Text('Points you earn and redeem will show up here.', textAlign: TextAlign.center, style: SnapBeeText.caption),
              ],
            ),
          ),

          const SnapBeePromoFooter(
            title: 'Every Order Brings You Closer to Bigger Rewards!',
            subtitle: 'Shop. Earn. Redeem. Be Happier!',
            scriptAccent: 'Good Food\nHappier You!',
          ),
        ],
      ),
    );
  }

  void _soon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reward redemption is coming soon.')),
    );
  }
}

class _RewardTile extends StatelessWidget {
  final String title;
  final String cost;
  final IconData icon;
  final Color color;
  const _RewardTile(this.title, this.cost, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 10, top: 4, bottom: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(SnapBeeSpacing.rTile),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.18), shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 10),
          Text(title, maxLines: 2, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: SnapBeeColors.ink, height: 1.2)),
          const Spacer(),
          Row(
            children: [
              Icon(Icons.monetization_on_rounded, size: 13, color: color),
              const SizedBox(width: 4),
              Text(cost, style: SnapBeeText.caption.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}
