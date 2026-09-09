import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/membership_constants.dart';
import '../../core/design/snapbee_design.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/wishlist_repository.dart';
import '../../models/customer_model.dart';
import '../notification/notification_screen.dart';
import '../orders/orders_screen.dart';
import '../wishlist/wishlist_screen.dart';
import '../order_history/order_history_screen.dart';
import '../order_history/models/order_history_model.dart';
import '../../features/booking_history/presentation/booking_history_screen.dart';
import '../../features/profile/about_snapbee_screen.dart';
import '../../features/profile/coupons_screen.dart';
import '../../features/profile/help_support_screen.dart';
import '../../features/profile/membership_card_screen.dart';
import '../../features/profile/profile_details_screen.dart';
import '../../features/profile/referrals_screen.dart';
import '../../features/profile/rewards_screen.dart';
import '../../features/profile/saved_addresses_screen.dart';
import '../../features/profile/settings_screen.dart';
import '../../features/profile/snapbee_club_screen.dart';
import '../../features/profile/wallet_screen.dart';
import '../../features/services/services_main_screen.dart';
import '../../features/travel/home/travel_main_screen.dart';
import '../../features/entertainment/home/entertainment_main_screen.dart';
import '../../features/ecommerce/home/ecommerce_main_screen.dart';
import 'widgets/membership_card.dart';

/// The COMMON Profile experience shared by every vertical's shell. Redesigned
/// to the approved reference (screens 29 / 35) — premium hero, SnapBee Club
/// card, live stat row, a Shop & Explore rail and a sectioned account menu —
/// while keeping every existing data path untouched: the real customer
/// fetch, the real unread-notification count, the real order-history load
/// and the real `auth.signOut()`.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _customerRepository = CustomerRepository(Supabase.instance.client);
  final _notificationRepository = NotificationRepository(Supabase.instance.client);

  CustomerModel? _customer;
  bool _loadingCustomer = true;
  int _unreadNotifications = 0;
  int _wishlistCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCustomer();
    _loadUnreadCount();
    _loadWishlistCount();
  }

  /// Profile previously showed a hardcoded name/phone/member-ID/tier/wallet
  /// regardless of who was signed in — `CustomerRepository.fetchByAuthUserId`
  /// already existed (used by signup) but nothing on this screen called it.
  Future<void> _loadCustomer() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _loadingCustomer = false);
      return;
    }
    try {
      final customer = await _customerRepository.fetchByAuthUserId(user.id);
      if (!mounted) return;
      setState(() {
        _customer = customer;
        _loadingCustomer = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCustomer = false);
    }
  }

  /// The bell's badge previously showed a hardcoded "3" for every customer
  /// regardless of their real `customer_notifications` rows.
  Future<void> _loadUnreadCount() async {
    try {
      final notifications = await _notificationRepository.fetchMyNotifications();
      if (!mounted) return;
      setState(() {
        _unreadNotifications = notifications.where((n) => !n.isRead).length;
      });
    } catch (_) {
      // Leave at 0 — an honest "nothing to show" beats a fabricated count.
    }
  }

  Future<void> _loadWishlistCount() async {
    try {
      final items = await WishlistRepository(Supabase.instance.client).fetchWishlist();
      if (!mounted) return;
      setState(() => _wishlistCount = items.length);
    } catch (_) {
      // Leave at 0.
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to place orders.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    // No explicit navigation needed: main.dart's `_AuthGate` listens to
    // `onAuthStateChange` and swaps back to LoginScreen the moment this
    // sign-out event fires.
    await Supabase.instance.client.auth.signOut();
  }

  /// Fetches this customer's real order history so Profile's history entry
  /// shows actual account data (OrderHistoryScreen renders an empty state,
  /// never sample data, when the list is empty).
  Future<void> _openOrderHistory(BuildContext context) async {
    List<OrderHistoryModel> history = const [];
    try {
      final rows = await OrderRepository(Supabase.instance.client).fetchMyOrders();
      history = [for (final row in rows) OrderHistoryModel.fromOrderRow(row)];
    } catch (_) {
      // OrderHistoryScreen has no error state of its own — an empty list
      // is the honest fallback rather than fabricated orders.
    }
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OrderHistoryScreen(orders: history)),
    );
  }

  void _push(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen))
        .then((_) => _loadUnreadCount());
  }

  void _openVertical(int index) {
    switch (index) {
      case 0:
        Navigator.of(context).popUntil((r) => r.isFirst);
        break;
      case 1:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ServicesMainScreen()));
        break;
      case 2:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const TravelMainScreen()));
        break;
      case 3:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const EntertainmentMainScreen()));
        break;
      case 4:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const EcommerceMainScreen()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final customer = _customer;
    final tier = customer != null
        ? MembershipThresholds.tierForCompletedOrders(customer.completedOrders)
        : MembershipTier.bronze;
    final completedOrders = customer?.completedOrders ?? 0;
    final displayName =
        customer?.fullName ?? (_loadingCustomer ? 'Loading…' : 'SnapBee Customer');
    final displayPhone = customer != null ? '+91 ${customer.mobileNumber}' : '—';
    final displayEmail = customer?.email ?? '';
    final walletBalance = customer?.walletBalance ?? 0;
    final rewardPoints = customer?.rewardPoints ?? 0;

    return Scaffold(
      backgroundColor: SnapBeeColors.scaffold,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 30),
          children: [
            // ---- Header ---------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(SnapBeeSpacing.gutter, 10, 8, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: SnapBeeWordmark(subtitle: 'Daily Essentials', center: false),
                  ),
                  Stack(
                    children: [
                      IconButton(
                        onPressed: () => _push(const NotificationScreen()),
                        icon: const Icon(Icons.notifications_none_rounded, color: SnapBeeColors.ink),
                      ),
                      if (_unreadNotifications > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: SnapBeeColors.danger, shape: BoxShape.circle),
                            child: Text(
                              _unreadNotifications > 9 ? '9+' : '$_unreadNotifications',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => _push(SettingsScreen(
                      customer: _customer,
                      onEditProfile: () => _push(ProfileDetailsScreen(customer: _customer)),
                    )),
                    icon: const Icon(Icons.settings_outlined, color: SnapBeeColors.ink),
                  ),
                ],
              ),
            ),

            // ---- Profile hero -------------------------------------------
            Container(
              margin: const EdgeInsets.fromLTRB(SnapBeeSpacing.gutter, 4, SnapBeeSpacing.gutter, 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SnapBeeColors.surface,
                borderRadius: BorderRadius.circular(SnapBeeSpacing.rCard),
                boxShadow: SnapBeeShadows.card,
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: SnapBeeColors.navy),
                        clipBehavior: Clip.antiAlias,
                        child: (customer?.profilePhotoUrl != null && customer!.profilePhotoUrl!.isNotEmpty)
                            ? Image.network(customer.profilePhotoUrl!, fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(Icons.person_rounded, color: Colors.white, size: 32))
                            : const Icon(Icons.person_rounded, color: Colors.white, size: 32),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: SnapBeeColors.orange,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, size: 11, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(child: Text(displayName, style: SnapBeeText.h2, overflow: TextOverflow.ellipsis)),
                            const SizedBox(width: 4),
                            const Icon(Icons.verified_rounded, size: 15, color: SnapBeeColors.info),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(displayPhone, style: SnapBeeText.caption),
                        if (displayEmail.isNotEmpty)
                          Text(displayEmail, style: SnapBeeText.caption, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  SnapBeePillButton(
                    label: 'Edit',
                    icon: Icons.edit_rounded,
                    onTap: () => _push(ProfileDetailsScreen(customer: _customer)),
                  ),
                ],
              ),
            ),

            // ---- SnapBee Club card -------------------------------------
            MembershipCard(
              tier: tier,
              totalOrders: completedOrders,
              benefitsCount: 4,
              ordersToNextTier: MembershipThresholds.ordersToNextTier(completedOrders),
              progress: MembershipThresholds.progressWithinTier(completedOrders),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(SnapBeeSpacing.gutter, 8, SnapBeeSpacing.gutter, 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text('SnapBee Club · ${tier.label} member', style: SnapBeeText.label),
                  ),
                  InkWell(
                    onTap: () => _push(SnapBeeClubScreen(customer: _customer)),
                    child: Row(
                      children: const [
                        Text('View Benefits', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: SnapBeeColors.orange)),
                        Icon(Icons.chevron_right, size: 16, color: SnapBeeColors.orange),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ---- Live stat row ---------------------------------------
            SnapBeeStatRow(
              stats: [
                SnapBeeStat(
                  icon: Icons.shopping_bag_rounded,
                  value: '$completedOrders',
                  label: 'Completed Orders',
                  color: SnapBeeColors.orange,
                  onTap: () => _push(const OrdersScreen()),
                ),
                SnapBeeStat(
                  icon: Icons.star_rounded,
                  value: '$rewardPoints',
                  label: 'Reward Points',
                  color: SnapBeeColors.star,
                  onTap: () => _push(RewardsScreen(customer: _customer)),
                ),
                SnapBeeStat(
                  icon: Icons.account_balance_wallet_rounded,
                  value: '₹${walletBalance.toStringAsFixed(0)}',
                  label: 'Wallet Balance',
                  color: SnapBeeColors.success,
                  onTap: () => _push(WalletScreen(customer: _customer)),
                ),
                SnapBeeStat(
                  icon: Icons.favorite_rounded,
                  value: '$_wishlistCount',
                  label: 'Wishlist Items',
                  color: SnapBeeColors.danger,
                  onTap: () => _push(const WishlistScreen()),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ---- Shop & Explore ---------------------------------------
            const SnapBeeSectionHeader(title: 'Shop & Explore', actionLabel: null),
            Padding(
              padding: SnapBeeSpacing.screenH,
              child: Row(
                children: [
                  _explore(0, 'Daily\nEssentials', Icons.storefront_rounded, SnapBeeColors.pastelMint, SnapBeeColors.success),
                  _explore(1, 'Services', Icons.handyman_rounded, const Color(0xFFE3F6EE), const Color(0xFF0E9F6E)),
                  _explore(2, 'Travel', Icons.flight_rounded, const Color(0xFFE6EEFF), const Color(0xFF2563EB)),
                  _explore(3, 'Entertain\nment', Icons.confirmation_num_rounded, const Color(0xFFFCE7EF), const Color(0xFFD6336C)),
                  _explore(4, 'E-Commerce', Icons.shopping_cart_rounded, const Color(0xFFF0E9FE), const Color(0xFF7C3AED)),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // ---- My Account menu --------------------------------------
            SnapBeeMenuCard(
              sectionTitle: 'My Account',
              items: [
                SnapBeeMenuItem(icon: Icons.person_rounded, title: 'Personal Details', color: SnapBeeColors.orange, onTap: () => _push(ProfileDetailsScreen(customer: _customer))),
                SnapBeeMenuItem(icon: Icons.workspace_premium_rounded, title: 'SnapBee Club', color: SnapBeeColors.gold, onTap: () => _push(MembershipCardScreen(customer: _customer))),
                SnapBeeMenuItem(icon: Icons.account_balance_wallet_rounded, title: 'Wallet', subtitle: '₹${walletBalance.toStringAsFixed(2)}', color: SnapBeeColors.platinum, onTap: () => _push(WalletScreen(customer: _customer))),
                SnapBeeMenuItem(icon: Icons.local_offer_rounded, title: 'Coupons', color: SnapBeeColors.danger, onTap: () => _push(const CouponsScreen())),
                SnapBeeMenuItem(icon: Icons.star_rounded, title: 'Rewards', subtitle: '$rewardPoints points', color: SnapBeeColors.star, onTap: () => _push(RewardsScreen(customer: _customer))),
                SnapBeeMenuItem(icon: Icons.group_add_rounded, title: 'Referrals', color: SnapBeeColors.info, onTap: () => _push(ReferralsScreen(customer: _customer))),
                SnapBeeMenuItem(icon: Icons.location_on_rounded, title: 'Saved Addresses', color: SnapBeeColors.success, onTap: () => _push(const SavedAddressesScreen())),
                SnapBeeMenuItem(icon: Icons.notifications_rounded, title: 'Notifications', color: SnapBeeColors.orange, onTap: () => _push(const NotificationScreen())),
                SnapBeeMenuItem(icon: Icons.settings_rounded, title: 'Settings', color: SnapBeeColors.inkSoft, onTap: () => _push(SettingsScreen(customer: _customer, onEditProfile: () => _push(ProfileDetailsScreen(customer: _customer))))),
                SnapBeeMenuItem(icon: Icons.support_agent_rounded, title: 'Help & Support', color: SnapBeeColors.info, onTap: () => _push(const HelpSupportScreen())),
              ],
            ),

            SnapBeeMenuCard(
              sectionTitle: 'Activity',
              items: [
                SnapBeeMenuItem(icon: Icons.receipt_long_rounded, title: 'My Orders', subtitle: 'Track, reorder', color: SnapBeeColors.orange, onTap: () => _push(const OrdersScreen())),
                SnapBeeMenuItem(icon: Icons.event_note_rounded, title: 'Booking History', subtitle: 'Services, Travel, Entertainment', color: SnapBeeColors.info, onTap: () => _push(const BookingHistoryScreen())),
                SnapBeeMenuItem(icon: Icons.history_rounded, title: 'Order History', color: SnapBeeColors.success, onTap: () => _openOrderHistory(context)),
                SnapBeeMenuItem(icon: Icons.favorite_rounded, title: 'Wishlist', subtitle: '$_wishlistCount saved', color: SnapBeeColors.danger, onTap: () => _push(const WishlistScreen())),
              ],
            ),

            SnapBeeCard(
              margin: const EdgeInsets.fromLTRB(SnapBeeSpacing.gutter, 14, SnapBeeSpacing.gutter, 6),
              onTap: () => _push(const AboutSnapBeeScreen()),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: SnapBeeColors.orangeTint, shape: BoxShape.circle),
                    child: const Icon(Icons.info_rounded, color: SnapBeeColors.orange, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('About SnapBee', style: SnapBeeText.title),
                        const SizedBox(height: 2),
                        Text('Know more about our mission, features and policies.', style: SnapBeeText.caption),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: SnapBeeColors.inkFaint),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(SnapBeeSpacing.gutter, 12, SnapBeeSpacing.gutter, 4),
              child: SnapBeeOutlineButton(
                label: 'Logout',
                icon: Icons.logout_rounded,
                color: SnapBeeColors.danger,
                onPressed: _logout,
              ),
            ),

            const SnapBeePromoFooter(
              title: 'Good Food. Better Life.',
              subtitle: 'Thank you for being a part of SnapBee!',
              scriptAccent: 'Together for a\nBetter Tomorrow!',
            ),
          ],
        ),
      ),
    );
  }

  Widget _explore(int index, String label, IconData icon, Color fill, Color color) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(SnapBeeSpacing.rTile),
        onTap: () => _openVertical(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
          child: Column(
            children: [
              Container(
                height: 52,
                width: double.infinity,
                decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: SnapBeeColors.ink, height: 1.1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
