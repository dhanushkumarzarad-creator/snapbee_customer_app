import 'package:flutter/material.dart';

import '../../core/design/snapbee_design.dart';
import '../../models/customer_model.dart';

/// My Wallet — shows the customer's real `wallet_balance`. Money-movement
/// actions (add / send / withdraw) are surfaced but route to a clear
/// "coming soon" acknowledgement rather than a fake flow, because no wallet
/// top-up backend is wired yet. The transaction list shows an honest empty
/// state instead of fabricated history.
class WalletScreen extends StatelessWidget {
  final CustomerModel? customer;

  const WalletScreen({super.key, this.customer});

  @override
  Widget build(BuildContext context) {
    final balance = customer?.walletBalance ?? 0;

    return Scaffold(
      appBar: const SnapBeeAppBar(
        trailing: Padding(
          padding: EdgeInsets.only(right: 8),
          child: SnapBeePillButton(label: 'Help', icon: Icons.support_agent_rounded),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const SnapBeePageHeader(
            icon: Icons.account_balance_wallet_rounded,
            title: 'My Wallet',
            subtitle: 'Fast. Safe. Convenient.',
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
                      Text('Wallet Balance', style: SnapBeeText.body.copyWith(fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(
                        '₹${balance.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: SnapBeeColors.navy),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: SnapBeeColors.successFill,
                          borderRadius: BorderRadius.circular(SnapBeeSpacing.rPill),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_user_rounded, size: 13, color: Color(0xFF1F7A3D)),
                            SizedBox(width: 5),
                            Text('100% Safe & Secure', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF1F7A3D))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SnapBeeMascotImage(asset: SnapBeeMascots.earnings, height: 92),
              ],
            ),
          ),

          SnapBeeQuickActionRail(
            actions: [
              SnapBeeQuickAction(icon: Icons.add_rounded, label: 'Add Money', color: SnapBeeColors.orange, onTap: () => _soon(context, 'Adding money to your wallet')),
              SnapBeeQuickAction(icon: Icons.north_east_rounded, label: 'Send Money', color: SnapBeeColors.info, onTap: () => _soon(context, 'Sending wallet money')),
              SnapBeeQuickAction(icon: Icons.history_rounded, label: 'History', color: SnapBeeColors.success, onTap: () => _soon(context, 'Transaction history')),
              SnapBeeQuickAction(icon: Icons.account_balance_rounded, label: 'Withdraw', color: SnapBeeColors.danger, onTap: () => _soon(context, 'Withdrawing to bank')),
            ],
          ),

          SnapBeeInfoBanner(
            icon: Icons.card_giftcard_rounded,
            text: 'Add money to your wallet to check out faster on every SnapBee vertical.',
          ),

          const SnapBeeSectionHeader(title: 'Recent Transactions', actionLabel: null),
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
                Icon(Icons.receipt_long_rounded, size: 34, color: SnapBeeColors.inkFaint),
                const SizedBox(height: 10),
                Text('No wallet transactions yet', style: SnapBeeText.title),
                const SizedBox(height: 4),
                Text(
                  'Your wallet top-ups, refunds and payments will appear here.',
                  textAlign: TextAlign.center,
                  style: SnapBeeText.caption,
                ),
              ],
            ),
          ),

          const SnapBeePromoFooter(
            title: 'Smart Shopping. Smarter Savings!',
            subtitle: 'Use your SnapBee Wallet for a better experience.',
            scriptAccent: 'Good Food\nHappier You!',
          ),
        ],
      ),
    );
  }

  void _soon(BuildContext context, String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$what is coming soon.')),
    );
  }
}
