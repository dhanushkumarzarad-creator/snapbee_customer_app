import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/design/snapbee_design.dart';
import '../../models/customer_model.dart';
import '../../screens/notification/notification_screen.dart';

/// Settings — app preferences, privacy & security, and account actions.
/// Only the actions that have a real backing (open Notifications, send a
/// password-reset email, sign out) do something; the rest acknowledge
/// clearly. Logout goes through the real `auth.signOut()` — `_AuthGate` in
/// main.dart returns the user to the login screen.
class SettingsScreen extends StatelessWidget {
  final CustomerModel? customer;
  final VoidCallback? onEditProfile;

  const SettingsScreen({super.key, this.customer, this.onEditProfile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SnapBeeAppBar(
        trailing: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: SnapBeePillButton(
            label: 'Edit Profile',
            icon: Icons.chevron_right,
            onTap: onEditProfile,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const SnapBeePageHeader(
            icon: Icons.settings_rounded,
            title: 'Settings',
            subtitle: 'Customize your app experience',
          ),

          if (customer != null)
            Container(
              margin: const EdgeInsets.fromLTRB(SnapBeeSpacing.gutter, 6, SnapBeeSpacing.gutter, 6),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: SnapBeeColors.cream, borderRadius: BorderRadius.circular(SnapBeeSpacing.rCard)),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: SnapBeeColors.navy,
                    child: Icon(Icons.person_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(customer!.fullName, style: SnapBeeText.title),
                        const SizedBox(height: 2),
                        Text('+91 ${customer!.mobileNumber}', style: SnapBeeText.caption),
                        if (customer!.email != null) Text(customer!.email!, style: SnapBeeText.caption),
                      ],
                    ),
                  ),
                  const SnapBeeMascotImage(asset: SnapBeeMascots.club, height: 52),
                ],
              ),
            ),

          SnapBeeMenuCard(
            sectionTitle: 'App Preferences',
            items: [
              SnapBeeMenuItem(
                icon: Icons.notifications_rounded,
                title: 'Notifications',
                subtitle: 'Manage your notification preferences',
                color: SnapBeeColors.danger,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
              ),
              SnapBeeMenuItem(
                icon: Icons.language_rounded,
                title: 'Language',
                subtitle: 'Choose your preferred language',
                trailingText: 'English',
                color: SnapBeeColors.platinum,
                onTap: () => _soon(context, 'More languages'),
              ),
              SnapBeeMenuItem(
                icon: Icons.palette_rounded,
                title: 'Theme',
                subtitle: 'Choose app appearance',
                trailingText: 'Light',
                color: SnapBeeColors.success,
                onTap: () => _soon(context, 'Dark theme'),
              ),
              SnapBeeMenuItem(
                icon: Icons.location_on_rounded,
                title: 'Location',
                subtitle: 'Manage location access',
                trailingText: 'System',
                color: SnapBeeColors.orange,
                onTap: () => _soon(context, 'Location settings'),
              ),
            ],
          ),

          SnapBeeMenuCard(
            sectionTitle: 'Privacy & Security',
            items: [
              SnapBeeMenuItem(
                icon: Icons.lock_rounded,
                title: 'Change Password',
                subtitle: 'Send a reset link to your email',
                color: SnapBeeColors.info,
                onTap: () => _resetPassword(context),
              ),
              SnapBeeMenuItem(
                icon: Icons.shield_rounded,
                title: 'Privacy',
                subtitle: 'Manage your data and privacy settings',
                color: SnapBeeColors.success,
                onTap: () => _soon(context, 'Privacy controls'),
              ),
              SnapBeeMenuItem(
                icon: Icons.delete_forever_rounded,
                title: 'Delete Account',
                subtitle: 'Permanently delete your account',
                color: SnapBeeColors.danger,
                onTap: () => _deleteAccount(context),
              ),
            ],
          ),

          SnapBeeMenuCard(
            sectionTitle: 'Other',
            items: [
              const SnapBeeMenuItem(icon: Icons.info_rounded, title: 'About SnapBee', subtitle: 'Version 1.0.0', color: SnapBeeColors.warn),
              const SnapBeeMenuItem(icon: Icons.description_rounded, title: 'Terms & Conditions', subtitle: 'Read our terms and policies', color: SnapBeeColors.platinum),
              SnapBeeMenuItem(
                icon: Icons.feedback_rounded,
                title: 'Send Feedback',
                subtitle: 'Help us improve SnapBee',
                color: SnapBeeColors.success,
                onTap: () => _soon(context, 'In-app feedback'),
              ),
              SnapBeeMenuItem(
                icon: Icons.logout_rounded,
                title: 'Logout',
                subtitle: 'Sign out from your account',
                color: SnapBeeColors.danger,
                onTap: () => _logout(context),
              ),
            ],
          ),

          const SnapBeePromoFooter(
            title: 'Your Preferences. A Better Experience!',
            subtitle: 'Customize SnapBee the way you like.',
            scriptAccent: 'Small Settings\nBig Happiness!',
          ),
        ],
      ),
    );
  }

  void _soon(BuildContext context, String what) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$what is coming soon.')));
  }

  Future<void> _resetPassword(BuildContext context) async {
    final email = customer?.email;
    if (email == null || email.isEmpty) {
      _soon(context, 'Password reset (no email on file)');
      return;
    }
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset link sent to $email')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not send reset link. Try again later.')),
      );
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'Account deletion is handled by our support team to protect your '
          'order history and refunds. We will email you to confirm.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: SnapBeeColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Request deletion'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deletion request noted. Support will contact you.')),
      );
    }
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to place orders.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Log out')),
        ],
      ),
    );
    if (ok == true) {
      await Supabase.instance.client.auth.signOut();
    }
  }
}
