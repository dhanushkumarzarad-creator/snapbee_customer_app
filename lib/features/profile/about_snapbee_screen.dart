import 'package:flutter/material.dart';

import '../../core/design/snapbee_design.dart';

/// About SnapBee — static brand/company content plus the standard legal
/// links. "Licenses" opens Flutter's built-in [showLicensePage].
class AboutSnapBeeScreen extends StatelessWidget {
  const AboutSnapBeeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SnapBeeAppBar(),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const SnapBeePageHeader(
            icon: Icons.info_rounded,
            title: 'About SnapBee',
            subtitle: 'Your everyday companion',
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
                      Text('Good Food. Happier You!', style: SnapBeeText.h2),
                      const SizedBox(height: 6),
                      Text(
                        'SnapBee brings daily essentials, services, travel, entertainment '
                        'and e-commerce closer to you. Local. Reliable. Always.',
                        style: SnapBeeText.body.copyWith(fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                const SnapBeeMascotImage(asset: SnapBeeMascots.welcome, height: 84),
              ],
            ),
          ),

          Container(
            margin: SnapBeeSpacing.screenH,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: SnapBeeColors.surface,
              borderRadius: BorderRadius.circular(SnapBeeSpacing.rTile),
              boxShadow: SnapBeeShadows.soft,
            ),
            child: const Wrap(
              alignment: WrapAlignment.spaceEvenly,
              runSpacing: 16,
              children: [
                _Value(Icons.storefront_rounded, 'Wide Range', 'Everything you need', SnapBeeColors.orange),
                _Value(Icons.location_on_rounded, 'Local Stores', 'Support nearby businesses', SnapBeeColors.success),
                _Value(Icons.flash_on_rounded, 'Fast Delivery', 'Right to your doorstep', SnapBeeColors.platinum),
                _Value(Icons.favorite_rounded, 'Better Community', 'For a stronger tomorrow', SnapBeeColors.danger),
              ],
            ),
          ),

          _MissionCard(
            icon: Icons.track_changes_rounded,
            title: 'Our Mission',
            body: 'To make everyday essentials easily accessible for everyone, by '
                'connecting local businesses with the community through technology.',
            fill: SnapBeeColors.orangeTint,
            color: SnapBeeColors.orange,
          ),
          _MissionCard(
            icon: Icons.visibility_rounded,
            title: 'Our Vision',
            body: 'To become the most trusted and loved local marketplace, empowering '
                'local businesses and making life more convenient for every home.',
            fill: SnapBeeColors.pastelLavender,
            color: SnapBeeColors.platinum,
          ),

          SnapBeeMenuCard(
            items: [
              const SnapBeeMenuItem(icon: Icons.layers_rounded, title: 'App Version', subtitle: '1.0.0 (Build 1)', trailingText: 'Up to date', color: SnapBeeColors.success),
              const SnapBeeMenuItem(icon: Icons.description_rounded, title: 'Terms & Conditions', subtitle: 'Read our terms and policies', color: SnapBeeColors.info),
              const SnapBeeMenuItem(icon: Icons.shield_rounded, title: 'Privacy Policy', subtitle: 'How we protect your data', color: SnapBeeColors.danger),
              SnapBeeMenuItem(
                icon: Icons.code_rounded,
                title: 'Licenses',
                subtitle: 'Open source licenses',
                color: SnapBeeColors.platinum,
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'SnapBee',
                  applicationVersion: '1.0.0',
                ),
              ),
            ],
          ),

          const SnapBeePromoFooter(
            title: 'Thank You for Being a Part of SnapBee!',
            subtitle: 'Together, we make local stronger.',
            scriptAccent: 'Good Food\nHappier You!',
          ),
        ],
      ),
    );
  }
}

class _Value extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color color;
  const _Value(this.icon, this.title, this.body, this.color);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.16), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 6),
          Text(title, style: SnapBeeText.title),
          const SizedBox(height: 2),
          Text(body, textAlign: TextAlign.center, style: SnapBeeText.caption),
        ],
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color fill;
  final Color color;
  const _MissionCard({required this.icon, required this.title, required this.body, required this.fill, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: SnapBeeSpacing.gutter, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(SnapBeeSpacing.rTile)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.18), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: SnapBeeText.title),
                const SizedBox(height: 4),
                Text(body, style: SnapBeeText.body.copyWith(fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
