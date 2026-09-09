import 'package:flutter/material.dart';

import '../../core/design/snapbee_design.dart';
import 'order_details_screen.dart';

/// Order Placed Successfully — the full-screen confirmation from reference
/// 12, shown right after `place_customer_order` returns. Every value is
/// real (the RPC result + the read-back order); the two CTAs go to real
/// destinations. Replaces the old modal dialog.
class OrderSuccessScreen extends StatelessWidget {
  final String orderId;
  final double amount;
  final String paymentLabel;
  final String storeName;
  final DateTime placedAt;

  /// The order re-loaded from Supabase, used to open the details/tracking
  /// screen. When null (a transient read-back failure) the buttons fall
  /// back to a minimal details view.
  final OrderDetailsData detailsData;

  const OrderSuccessScreen({
    super.key,
    required this.orderId,
    required this.amount,
    required this.paymentLabel,
    required this.storeName,
    required this.placedAt,
    required this.detailsData,
  });

  void _openDetails(BuildContext context) {
    Navigator.of(context).popUntil((r) => r.isFirst);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: detailsData)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shortId = orderId.length > 10 ? orderId.substring(0, 8).toUpperCase() : orderId.toUpperCase();

    return Scaffold(
      backgroundColor: SnapBeeColors.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  const SizedBox(height: 12),
                  const Center(child: SnapBeeWordmark(subtitle: 'Daily Essentials')),
                  const SizedBox(height: 12),

                  Center(child: SnapBeeMascotImage(asset: SnapBeeMascots.success, height: 130)),
                  const SizedBox(height: 4),
                  Center(
                    child: Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(color: SnapBeeColors.successFill, shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded, color: SnapBeeColors.success, size: 38),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(child: Text('Order Placed Successfully!', style: SnapBeeText.h1)),
                  const SizedBox(height: 6),
                  Center(child: Text('Thank you for shopping with SnapBee', style: SnapBeeText.body)),
                  const SizedBox(height: 4),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Good Food Brighter Days!', style: SnapBeeText.script.copyWith(fontSize: 12)),
                        const SizedBox(width: 4),
                        const Text('❤️', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ---- Order summary card --------------------------------
                  Container(
                    margin: SnapBeeSpacing.screenH,
                    padding: const EdgeInsets.all(16),
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
                              Text('Order Number', style: SnapBeeText.caption),
                              const SizedBox(height: 2),
                              Text('#$shortId', style: SnapBeeText.bodyStrong),
                              const SizedBox(height: 10),
                              Text('Placed on', style: SnapBeeText.caption),
                              const SizedBox(height: 2),
                              Text(_fmt(placedAt), style: SnapBeeText.caption.copyWith(color: SnapBeeColors.inkSoft)),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 60, color: Colors.white),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total Amount', style: SnapBeeText.caption),
                              const SizedBox(height: 2),
                              Text('₹${amount.toStringAsFixed(0)}', style: SnapBeeText.price.copyWith(color: SnapBeeColors.orangeDeep, fontSize: 18)),
                              const SizedBox(height: 10),
                              Text('Payment Method', style: SnapBeeText.caption),
                              const SizedBox(height: 2),
                              Text(paymentLabel, style: SnapBeeText.caption.copyWith(color: SnapBeeColors.inkSoft)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SnapBeeInfoBanner(
                    icon: Icons.eco_rounded,
                    color: SnapBeeColors.success,
                    fill: SnapBeeColors.successFill,
                    text: 'Fresh items, safely to your doorstep — quality products, safe packaging, on-time delivery.',
                  ),

                  _linkRow(context, Icons.local_shipping_outlined, 'Order Tracking', 'Track your order in real time', () => _openDetails(context)),
                  _linkRow(context, Icons.receipt_long_rounded, 'Order Details', 'View items, bill and more', () => _openDetails(context)),
                  _linkRow(context, Icons.storefront_rounded, 'View Store', storeName, () => _openDetails(context)),

                  const SnapBeePromoFooter(
                    title: 'Spread the Buzz!',
                    subtitle: 'Refer your friends and earn rewards.',
                    scriptAccent: 'Good Food\nHappier You!',
                  ),
                ],
              ),
            ),
            SnapBeeBottomBar(
              actions: [
                SnapBeeOutlineButton(
                  label: 'Continue Shopping',
                  icon: Icons.shopping_bag_outlined,
                  onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                ),
                SnapBeePrimaryButton(
                  label: 'View My Orders',
                  onPressed: () => _openDetails(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _linkRow(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return SnapBeeCard(
      margin: const EdgeInsets.symmetric(horizontal: SnapBeeSpacing.gutter, vertical: 5),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: SnapBeeColors.chipFill, shape: BoxShape.circle),
            child: Icon(icon, size: 19, color: SnapBeeColors.ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: SnapBeeText.title),
                const SizedBox(height: 2),
                Text(subtitle, style: SnapBeeText.caption),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: SnapBeeColors.inkFaint),
        ],
      ),
    );
  }

  static String _fmt(DateTime d) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ap = d.hour < 12 ? 'AM' : 'PM';
    return '${d.day.toString().padLeft(2, '0')} ${m[d.month - 1]} ${d.year}, $h:${d.minute.toString().padLeft(2, '0')} $ap';
  }
}
