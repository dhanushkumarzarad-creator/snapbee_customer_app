import 'package:flutter/material.dart';

import '../../core/constants/membership_constants.dart';
import '../../core/design/snapbee_design.dart';
import '../../models/customer_model.dart';

/// SnapBee Club — the approved order-based membership ladder
/// (Bronze 0–9 · Silver 10–49 · Gold 50–199 · Platinum 200+). Tier and
/// progress are computed from the customer's real `completed_orders`; this
/// screen only presents that data, it never writes it.
class SnapBeeClubScreen extends StatelessWidget {
  final CustomerModel? customer;

  const SnapBeeClubScreen({super.key, this.customer});

  int get _completed => customer?.completedOrders ?? 0;
  MembershipTier get _tier => MembershipThresholds.tierForCompletedOrders(_completed);

  @override
  Widget build(BuildContext context) {
    final tier = _tier;
    final next = MembershipThresholds.nextTier(tier);
    final toNext = MembershipThresholds.ordersToNextTier(_completed);
    final progress = MembershipThresholds.progressWithinTier(_completed);

    return Scaffold(
      appBar: const SnapBeeAppBar(
        trailing: Padding(
          padding: EdgeInsets.only(right: 8),
          child: SnapBeePillButton(label: 'How it works?', icon: Icons.help_outline),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const SnapBeePageHeader(
            icon: Icons.workspace_premium_rounded,
            title: 'SnapBee Club',
            subtitle: 'The more you order, the more you unlock!',
            tint: SnapBeeColors.gold,
          ),

          // ---- Current tier card -------------------------------------------
          Container(
            margin: const EdgeInsets.fromLTRB(SnapBeeSpacing.gutter, 6, SnapBeeSpacing.gutter, 6),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: SnapBeeColors.cream,
              borderRadius: BorderRadius.circular(SnapBeeSpacing.rCard),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _TierCrest(tier: tier, size: 58),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your Current Tier', style: SnapBeeText.caption),
                          const SizedBox(height: 2),
                          Text(tier.label, style: SnapBeeText.h1),
                          const SizedBox(height: 2),
                          Text('$_completed orders completed', style: SnapBeeText.body.copyWith(fontSize: 13)),
                        ],
                      ),
                    ),
                    SnapBeeMascotImage(asset: SnapBeeMascots.club, height: 66),
                  ],
                ),
                const SizedBox(height: 16),
                if (next != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: SnapBeeColors.successFill,
                      borderRadius: BorderRadius.circular(SnapBeeSpacing.rPill),
                    ),
                    child: Text(
                      toNext > 0
                          ? "You're $toNext ${toNext == 1 ? 'order' : 'orders'} away from ${next.label}!"
                          : 'Reaching ${next.label} soon!',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F7A3D),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SnapBeeProgressBar(value: progress),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$_completed', style: SnapBeeText.caption),
                      Text('${_bandEnd(tier)}', style: SnapBeeText.caption),
                    ],
                  ),
                ] else
                  Text(
                    "You've reached the top tier — enjoy every SnapBee Club benefit.",
                    style: SnapBeeText.body.copyWith(fontSize: 13),
                  ),
              ],
            ),
          ),

          const SnapBeeSectionHeader(title: 'Club Tiers', actionLabel: null),
          Padding(
            padding: const EdgeInsets.fromLTRB(SnapBeeSpacing.gutter, 0, SnapBeeSpacing.gutter, 4),
            child: Text(
              'Automatically upgraded based on your completed orders.',
              style: SnapBeeText.caption,
            ),
          ),
          SizedBox(
            height: 232,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: SnapBeeSpacing.screenH,
              children: [
                for (final t in MembershipTier.values)
                  _TierColumn(tier: t, current: t == tier),
              ],
            ),
          ),

          const SnapBeeSectionHeader(title: 'Club Benefits for You', actionLabel: null),
          Container(
            margin: SnapBeeSpacing.screenH,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: SnapBeeColors.surface,
              borderRadius: BorderRadius.circular(SnapBeeSpacing.rTile),
              boxShadow: SnapBeeShadows.soft,
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceEvenly,
              runSpacing: 16,
              children: const [
                _Benefit(Icons.local_offer_rounded, 'Exclusive\nOffers', SnapBeeColors.orange),
                _Benefit(Icons.local_shipping_rounded, 'Special\nDelivery Deals', SnapBeeColors.success),
                _Benefit(Icons.card_giftcard_rounded, 'Member\nRewards', SnapBeeColors.danger),
                _Benefit(Icons.flash_on_rounded, 'Early Access\nto Sales', SnapBeeColors.star),
                _Benefit(Icons.support_agent_rounded, 'Priority\nSupport', SnapBeeColors.info),
                _Benefit(Icons.savings_rounded, 'Higher\nSavings', SnapBeeColors.platinum),
              ],
            ),
          ),

          const SizedBox(height: 4),
          SnapBeeInfoBanner(
            icon: Icons.info_outline_rounded,
            color: SnapBeeColors.info,
            fill: SnapBeeColors.infoFill,
            text: 'Only completed orders count. Cancelled, refunded or failed '
                'orders are not counted. Once you reach a higher tier you keep '
                'its benefits.',
          ),
          const SnapBeePromoFooter(
            title: 'Your Progress Matters!',
            subtitle: 'Every completed order brings you closer to the next tier.',
            scriptAccent: 'Shop More\nUnlock More!',
          ),
        ],
      ),
    );
  }

  static int _bandEnd(MembershipTier t) {
    switch (t) {
      case MembershipTier.bronze:
        return MembershipThresholds.silverMin;
      case MembershipTier.silver:
        return MembershipThresholds.goldMin;
      case MembershipTier.gold:
        return MembershipThresholds.platinumMin;
      case MembershipTier.platinum:
        return MembershipThresholds.platinumMin;
    }
  }
}

Color _tierColor(MembershipTier t) {
  switch (t) {
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

String _tierRange(MembershipTier t) {
  switch (t) {
    case MembershipTier.bronze:
      return '0 – 9 orders';
    case MembershipTier.silver:
      return '10 – 49 orders';
    case MembershipTier.gold:
      return '50 – 199 orders';
    case MembershipTier.platinum:
      return '200+ orders';
  }
}

List<String> _tierPerks(MembershipTier t) {
  switch (t) {
    case MembershipTier.bronze:
      return ['Basic Offers', 'Member Deals', 'Special Discounts'];
    case MembershipTier.silver:
      return ['Better Discounts', 'Exclusive Offers', 'Priority Support'];
    case MembershipTier.gold:
      return ['Higher Discounts', 'Early Access', 'Special Deals', 'Priority Support'];
    case MembershipTier.platinum:
      return ['Best Discounts', 'Exclusive Rewards', 'VIP Support', 'Early Feature Access'];
  }
}

class _TierCrest extends StatelessWidget {
  final MembershipTier tier;
  final double size;
  const _TierCrest({required this.tier, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final c = _tierColor(tier);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.withValues(alpha: 0.9), c.withValues(alpha: 0.55)],
        ),
        boxShadow: [BoxShadow(color: c.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 24),
    );
  }
}

class _TierColumn extends StatelessWidget {
  final MembershipTier tier;
  final bool current;
  const _TierColumn({required this.tier, required this.current});

  @override
  Widget build(BuildContext context) {
    final c = _tierColor(tier);
    return Container(
      width: 156,
      margin: const EdgeInsets.only(right: 10, top: 4, bottom: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(SnapBeeSpacing.rTile),
        border: Border.all(color: current ? c : Colors.transparent, width: 1.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TierCrest(tier: tier, size: 40),
          const SizedBox(height: 10),
          Text(tier.label, style: SnapBeeText.title),
          Text(_tierRange(tier), style: SnapBeeText.caption),
          const SizedBox(height: 10),
          for (final p in _tierPerks(tier))
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_rounded, size: 13, color: c),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(p, style: const TextStyle(fontSize: 11, color: SnapBeeColors.inkSoft, height: 1.2)),
                  ),
                ],
              ),
            ),
          if (current) ...[
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: c.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(8)),
              child: Text('Your Tier', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c)),
            ),
          ],
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Benefit(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SnapBeeColors.ink, height: 1.2),
          ),
        ],
      ),
    );
  }
}
