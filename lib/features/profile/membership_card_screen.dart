import 'package:flutter/material.dart';

import '../../core/constants/membership_constants.dart';
import '../../core/design/snapbee_design.dart';
import '../../models/customer_model.dart';
import '../../screens/profile/widgets/membership_card.dart';

/// Membership Club Card — the premium metallic tier card (reuses the existing
/// [MembershipCard] widget) plus the tier ladder and the benefits grid, per
/// reference screen 24. All figures come from the customer's real
/// `completed_orders` / `membership_tier`.
class MembershipCardScreen extends StatelessWidget {
  final CustomerModel? customer;

  const MembershipCardScreen({super.key, this.customer});

  @override
  Widget build(BuildContext context) {
    final completed = customer?.completedOrders ?? 0;
    final tier = MembershipThresholds.tierForCompletedOrders(completed);
    final next = MembershipThresholds.nextTier(tier);
    final toNext = MembershipThresholds.ordersToNextTier(completed);
    final joined = customer?.registrationDate;

    return Scaffold(
      appBar: const SnapBeeAppBar(
        trailing: Padding(
          padding: EdgeInsets.only(right: 8),
          child: SnapBeePillButton(label: 'How It Works?', icon: Icons.help_outline),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const SnapBeePageHeader(
            icon: Icons.workspace_premium_rounded,
            title: 'SnapBee Club',
            subtitle: 'More Orders. More Rewards. A Better You!',
            tint: SnapBeeColors.gold,
          ),
          const SizedBox(height: 6),

          MembershipCard(
            tier: tier,
            totalOrders: completed,
            benefitsCount: 4,
            ordersToNextTier: toNext,
            progress: MembershipThresholds.progressWithinTier(completed),
          ),
          if (joined != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(SnapBeeSpacing.gutter, 8, SnapBeeSpacing.gutter, 0),
              child: Text(
                'Member since ${_fmtDate(joined)}',
                style: SnapBeeText.caption,
              ),
            ),

          const SizedBox(height: 10),
          // Ladder strip
          Padding(
            padding: SnapBeeSpacing.screenH,
            child: Row(
              children: [
                for (int i = 0; i < MembershipTier.values.length; i++) ...[
                  if (i != 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: SnapBeeColors.hairline,
                      ),
                    ),
                  _LadderNode(
                    tier: MembershipTier.values[i],
                    reached: MembershipTier.values[i].index <= tier.index,
                  ),
                ],
              ],
            ),
          ),

          const SnapBeeSectionHeader(title: 'Club Benefits', actionLabel: null),
          Container(
            margin: SnapBeeSpacing.screenH,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: SnapBeeColors.cream,
              borderRadius: BorderRadius.circular(SnapBeeSpacing.rTile),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceEvenly,
              runSpacing: 16,
              children: const [
                _MiniBenefit(Icons.local_offer_rounded, 'Exclusive Offers', SnapBeeColors.orange),
                _MiniBenefit(Icons.card_giftcard_rounded, 'Extra Rewards', SnapBeeColors.gold),
                _MiniBenefit(Icons.local_shipping_rounded, 'Priority Delivery', SnapBeeColors.info),
                _MiniBenefit(Icons.workspace_premium_rounded, 'Special Deals', SnapBeeColors.danger),
                _MiniBenefit(Icons.support_agent_rounded, 'Priority Support', SnapBeeColors.platinum),
                _MiniBenefit(Icons.star_rounded, 'Early Access', SnapBeeColors.star),
              ],
            ),
          ),

          if (next != null)
            SnapBeeInfoBanner(
              icon: Icons.trending_up_rounded,
              color: SnapBeeColors.success,
              fill: SnapBeeColors.successFill,
              text: toNext > 0
                  ? 'Complete $toNext more ${toNext == 1 ? 'order' : 'orders'} to unlock ${next.label} tier benefits.'
                  : 'Your ${next.label} upgrade is almost here!',
            ),

          const SnapBeePromoFooter(
            scriptAccent: 'Together for a\nBetter Tomorrow!',
          ),
        ],
      ),
    );
  }

  static String _fmtDate(DateTime d) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day.toString().padLeft(2, '0')} ${m[d.month - 1]} ${d.year}';
  }
}

class _LadderNode extends StatelessWidget {
  final MembershipTier tier;
  final bool reached;
  const _LadderNode({required this.tier, required this.reached});

  Color get _c {
    switch (tier) {
      case MembershipTier.bronze:
        return SnapBeeColors.bronze;
      case MembershipTier.silver:
        return SnapBeeColors.silver;
      case MembershipTier.gold:
        return SnapBeeColors.gold;
      case MembershipTier.platinum:
        return SnapBeeColors.platinum;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: reached ? _c.withValues(alpha: 0.18) : SnapBeeColors.chipFill,
            border: Border.all(color: reached ? _c : SnapBeeColors.hairline, width: 1.6),
          ),
          child: Icon(Icons.workspace_premium_rounded, size: 18, color: reached ? _c : SnapBeeColors.inkFaint),
        ),
        const SizedBox(height: 4),
        Text(tier.label, style: SnapBeeText.caption.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _MiniBenefit extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MiniBenefit(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.16), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: SnapBeeColors.ink, height: 1.2)),
        ],
      ),
    );
  }
}
