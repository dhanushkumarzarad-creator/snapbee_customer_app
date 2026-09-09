import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/design/snapbee_design.dart';
import '../../models/customer_model.dart';

/// Profile Details — the customer's real personal information from the
/// `customers` row. Fields the schema doesn't carry (date of birth, gender)
/// show an honest "Not added" rather than an invented value. "Change
/// Password" sends a real Supabase reset email.
class ProfileDetailsScreen extends StatelessWidget {
  final CustomerModel? customer;

  const ProfileDetailsScreen({super.key, this.customer});

  @override
  Widget build(BuildContext context) {
    final c = customer;
    return Scaffold(
      appBar: const SnapBeeAppBar(),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(SnapBeeSpacing.gutter, 4, SnapBeeSpacing.gutter, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Avatar(url: c?.profilePhotoUrl),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Profile Details', style: SnapBeeText.h1),
                      const SizedBox(height: 2),
                      Text('Keep your information up to date', style: SnapBeeText.body),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: SnapBeeSpacing.gutter, top: 8),
                  child: Text('Personal Information', style: SnapBeeText.h2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: SnapBeeSpacing.gutter),
                child: SnapBeePillButton(
                  label: 'Edit',
                  icon: Icons.edit_rounded,
                  color: SnapBeeColors.info,
                  onTap: () => _soon(context, 'Editing personal details'),
                ),
              ),
            ],
          ),
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
                _InfoRow(Icons.person_outline_rounded, 'Full Name', c?.fullName ?? '—'),
                const Divider(height: 1, color: SnapBeeColors.hairline, indent: 52),
                _InfoRow(Icons.phone_outlined, 'Mobile Number', c != null ? '+91 ${c.mobileNumber}' : '—', verified: c != null),
                const Divider(height: 1, color: SnapBeeColors.hairline, indent: 52),
                _InfoRow(Icons.mail_outline_rounded, 'Email Address', c?.email ?? 'Not added', verified: (c?.email ?? '').isNotEmpty),
                const Divider(height: 1, color: SnapBeeColors.hairline, indent: 52),
                _InfoRow(Icons.cake_outlined, 'Date of Birth', 'Not added'),
                const Divider(height: 1, color: SnapBeeColors.hairline, indent: 52),
                _InfoRow(Icons.wc_outlined, 'Gender', 'Not added'),
                const Divider(height: 1, color: SnapBeeColors.hairline, indent: 52),
                _InfoRow(Icons.badge_outlined, 'Member ID', c?.customerCode ?? '—'),
              ],
            ),
          ),

          SnapBeeMenuCard(
            sectionTitle: 'Manage Account',
            items: [
              SnapBeeMenuItem(
                icon: Icons.lock_outline_rounded,
                title: 'Change Password',
                subtitle: 'Send a reset link to your email',
                color: SnapBeeColors.info,
                onTap: () => _resetPassword(context),
              ),
              SnapBeeMenuItem(
                icon: Icons.link_rounded,
                title: 'Linked Accounts',
                subtitle: 'Google, Apple, etc.',
                color: SnapBeeColors.platinum,
                onTap: () => _soon(context, 'Linked accounts'),
              ),
            ],
          ),

          const SnapBeePromoFooter(scriptAccent: 'A Better You for a\nSmarter Tomorrow!'),
        ],
      ),
    );
  }

  void _soon(BuildContext context, String what) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$what is coming soon.')));

  Future<void> _resetPassword(BuildContext context) async {
    final email = customer?.email;
    if (email == null || email.isEmpty) {
      _soon(context, 'Password reset (no email on file)');
      return;
    }
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password reset link sent to $email')));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not send reset link. Try again later.')),
      );
    }
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  const _Avatar({this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: SnapBeeColors.navy),
      clipBehavior: Clip.antiAlias,
      child: (url != null && url!.isNotEmpty)
          ? Image.network(url!, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.person_rounded, color: Colors.white, size: 34))
          : const Icon(Icons.person_rounded, color: Colors.white, size: 34),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool verified;
  const _InfoRow(this.icon, this.label, this.value, {this.verified = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: SnapBeeColors.inkSoft),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(label, style: SnapBeeText.caption),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: SnapBeeText.bodyStrong, textAlign: TextAlign.right),
          ),
          if (verified) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: SnapBeeColors.successFill, borderRadius: BorderRadius.circular(SnapBeeSpacing.rPill)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF1F7A3D)),
                  SizedBox(width: 3),
                  Text('Verified', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF1F7A3D))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
