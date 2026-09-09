import 'package:flutter/material.dart';

import '../../core/design/snapbee_design.dart';

/// Coupons — no coupon backend is wired for the customer app yet, so this
/// screen presents an honest empty state within the premium SnapBee shell
/// rather than fabricating promo codes. Available coupons still surface at
/// checkout via the existing "Apply Offers & Coupons" flow.
class CouponsScreen extends StatelessWidget {
  const CouponsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SnapBeeAppBar(
        trailing: Padding(
          padding: EdgeInsets.only(right: 8),
          child: SnapBeePillButton(label: 'How to Use?', icon: Icons.help_outline, color: SnapBeeColors.info),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const SnapBeePageHeader(
            icon: Icons.local_offer_rounded,
            title: 'Coupons',
            subtitle: 'Save more on your everyday orders!',
            tint: SnapBeeColors.danger,
          ),

          Container(
            margin: const EdgeInsets.fromLTRB(SnapBeeSpacing.gutter, 6, SnapBeeSpacing.gutter, 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: SnapBeeColors.cream, borderRadius: BorderRadius.circular(SnapBeeSpacing.rCard)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Great Offers, Happier Shopping!', style: SnapBeeText.h2),
                      const SizedBox(height: 6),
                      Text('Apply coupons at checkout and save on every order.', style: SnapBeeText.body.copyWith(fontSize: 12.5)),
                    ],
                  ),
                ),
                const SnapBeeMascotImage(asset: SnapBeeMascots.shopping, height: 76),
              ],
            ),
          ),

          const SnapBeeSectionHeader(title: 'Available Coupons', actionLabel: null),
          Container(
            margin: SnapBeeSpacing.screenH,
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
            decoration: BoxDecoration(
              color: SnapBeeColors.surface,
              borderRadius: BorderRadius.circular(SnapBeeSpacing.rTile),
              boxShadow: SnapBeeShadows.soft,
            ),
            child: Column(
              children: [
                Icon(Icons.confirmation_number_outlined, size: 36, color: SnapBeeColors.inkFaint),
                const SizedBox(height: 12),
                Text('No coupons available right now', style: SnapBeeText.title),
                const SizedBox(height: 4),
                Text(
                  'New coupons appear here and at checkout. Keep ordering to unlock member coupons through SnapBee Club.',
                  textAlign: TextAlign.center,
                  style: SnapBeeText.caption,
                ),
              ],
            ),
          ),

          SnapBeeInfoBanner(
            icon: Icons.lightbulb_outline_rounded,
            text: 'Tip: SnapBee Club members earn coupons automatically as they '
                'complete more orders.',
          ),

          const SnapBeePromoFooter(
            title: 'Use Coupons. Save More.',
            subtitle: 'Shop smarter with SnapBee!',
            scriptAccent: 'Everyday Savings!',
          ),
        ],
      ),
    );
  }
}
