import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design/snapbee_design.dart';

/// Help & Support — support categories, an FAQ list, and contact options.
/// Contact rows copy the relevant detail to the clipboard (no url_launcher
/// ships in this app) so the customer can act on it in their dialler / mail
/// app.
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const _faqs = <String>[
    'How can I track my order?',
    'How do I cancel my order?',
    'When will I get my refund?',
    'How to use a coupon code?',
    'How does SnapBee Club work?',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SnapBeeAppBar(
        trailing: Padding(
          padding: EdgeInsets.only(right: 8),
          child: SnapBeePillButton(label: 'FAQs', icon: Icons.help_outline, color: SnapBeeColors.info),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const SnapBeePageHeader(
            icon: Icons.support_agent_rounded,
            title: 'Help & Support',
            subtitle: "We're here to help you, always!",
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
                      Text("Got a Question? We've Got You!", style: SnapBeeText.h2),
                      const SizedBox(height: 6),
                      Text('Quick support for a smoother shopping experience.', style: SnapBeeText.body.copyWith(fontSize: 12.5)),
                    ],
                  ),
                ),
                const SnapBeeMascotImage(asset: SnapBeeMascots.notification, height: 78),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(SnapBeeSpacing.gutter, 8, SnapBeeSpacing.gutter, 4),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: const [
                _HelpCat(Icons.shopping_bag_rounded, 'My Orders', 'Track, cancel, refunds', SnapBeeColors.orange),
                _HelpCat(Icons.account_balance_wallet_rounded, 'Payments', 'UPI, cards, wallet', SnapBeeColors.success),
                _HelpCat(Icons.storefront_rounded, 'Vendors', 'Product & store support', SnapBeeColors.danger),
                _HelpCat(Icons.local_shipping_rounded, 'Delivery', 'Track, delay or issues', SnapBeeColors.info),
                _HelpCat(Icons.person_rounded, 'Account', 'Profile, login & security', SnapBeeColors.platinum),
                _HelpCat(Icons.local_offer_rounded, 'Offers', 'Rewards & promo codes', SnapBeeColors.star),
              ],
            ),
          ),

          const SnapBeeSectionHeader(title: 'Frequently Asked Questions', actionLabel: null),
          Container(
            margin: SnapBeeSpacing.screenH,
            decoration: BoxDecoration(
              color: SnapBeeColors.surface,
              borderRadius: BorderRadius.circular(SnapBeeSpacing.rTile),
              boxShadow: SnapBeeShadows.card,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (int i = 0; i < _faqs.length; i++) ...[
                  ListTile(
                    leading: const Icon(Icons.article_outlined, color: SnapBeeColors.info, size: 20),
                    title: Text(_faqs[i], style: SnapBeeText.title),
                    trailing: const Icon(Icons.chevron_right, color: SnapBeeColors.inkFaint),
                    onTap: () {},
                  ),
                  if (i != _faqs.length - 1) const Divider(height: 1, color: SnapBeeColors.hairline, indent: 56),
                ],
              ],
            ),
          ),

          const SnapBeeSectionHeader(title: 'Contact Us', actionLabel: null),
          _ContactRow(
            icon: Icons.chat_bubble_rounded,
            color: SnapBeeColors.success,
            title: 'WhatsApp',
            detail: '+91 98765 43210',
            context: context,
          ),
          _ContactRow(
            icon: Icons.call_rounded,
            color: SnapBeeColors.info,
            title: 'Call Us',
            detail: '+91 98765 43210 (9 AM – 10 PM)',
            copyValue: '+919876543210',
            context: context,
          ),
          _ContactRow(
            icon: Icons.mail_rounded,
            color: SnapBeeColors.danger,
            title: 'Email Us',
            detail: 'support@snapbee.in',
            context: context,
          ),

          const SnapBeePromoFooter(
            title: 'Your Feedback Helps Us Grow!',
            subtitle: 'Share your suggestions and make SnapBee better.',
            scriptAccent: 'Together For a\nBetter Tomorrow!',
          ),
        ],
      ),
    );
  }
}

class _HelpCat extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color color;
  const _HelpCat(this.icon, this.title, this.body, this.color);

  @override
  Widget build(BuildContext context) {
    final w = (MediaQuery.of(context).size.width - SnapBeeSpacing.gutter * 2 - 10) / 2;
    return Container(
      width: w,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(SnapBeeSpacing.rTile)),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.18), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: SnapBeeColors.ink)),
                Text(body, maxLines: 2, style: const TextStyle(fontSize: 10, color: SnapBeeColors.inkFaint, height: 1.15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String detail;
  final String? copyValue;
  final BuildContext context;
  const _ContactRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
    required this.context,
    this.copyValue,
  });

  @override
  Widget build(BuildContext context) {
    return SnapBeeCard(
      margin: const EdgeInsets.symmetric(horizontal: SnapBeeSpacing.gutter, vertical: 5),
      onTap: () {
        Clipboard.setData(ClipboardData(text: copyValue ?? detail));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title detail copied')),
        );
      },
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.16), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: SnapBeeText.title),
                const SizedBox(height: 2),
                Text(detail, style: SnapBeeText.caption),
              ],
            ),
          ),
          const Icon(Icons.copy_rounded, size: 16, color: SnapBeeColors.inkFaint),
        ],
      ),
    );
  }
}
