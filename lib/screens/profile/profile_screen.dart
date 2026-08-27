import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/membership_constants.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../../models/customer_model.dart';
import '../notification/notification_screen.dart';
import '../orders/orders_screen.dart';
import '../wishlist/wishlist_screen.dart';
import '../order_history/order_history_screen.dart';
import '../order_history/models/order_history_model.dart';
import 'widgets/membership_card.dart';

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

  @override
  void initState() {
    super.initState();
    _loadCustomer();
    _loadUnreadCount();
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

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature is coming soon.')),
    );
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

  /// OrderHistoryScreen falls back to fabricated sample orders when opened
  /// with no `orders` passed in — fetch this customer's real order history
  /// first so Profile's "History" quick action shows actual account data
  /// instead, same fix as the Orders tab's own History entry points.
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

  @override
  Widget build(BuildContext context) {
    final customer = _customer;
    final tier = customer?.membershipTier ?? MembershipTier.bronze;
    final completedOrders = customer?.completedOrders ?? 0;
    final displayName = customer?.fullName ?? (_loadingCustomer ? 'Loading…' : 'SnapBee Customer');
    final displayPhone = customer != null ? '+91 ${customer.mobileNumber}' : '—';
    final displayMemberId = customer?.customerCode ?? '—';
    final walletBalance = customer?.walletBalance ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xffF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "My Profile",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: const Icon(Icons.menu, color: Colors.black),
        actions: [
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationScreen(),
                    ),
                  ).then((_) => _loadUnreadCount());
                },
                icon: const Icon(
                  Icons.notifications_none,
                  color: Colors.black,
                ),
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryOrange,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _unreadNotifications > 9 ? '9+' : '$_unreadNotifications',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
            ],
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 12),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .05),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primaryOrange,
                              AppColors.primaryOrangeDark,
                            ],
                          ),
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF20243A),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF9C5A28), Color(0xFFC9793C)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "${_tierEmoji(tier)} ${tier.label} Bee",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: .2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          displayPhone,
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "Member ID : $displayMemberId",
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            MembershipCard(
              tier: tier,
              totalOrders: completedOrders,
              benefitsCount: 3,
              ordersToNextTier: MembershipThresholds.ordersToNextTier(completedOrders),
              progress: MembershipThresholds.progressWithinTier(completedOrders),
            ),
            const SizedBox(height: 18),

            // Wallet Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .05),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    height: 55,
                    width: 55,
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrangeLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: AppColors.primaryOrange,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "SnapBee Wallet",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Balance ₹${walletBalance.toStringAsFixed(2)}",
                          style: TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _comingSoon('Adding money to your wallet'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Add Money"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: const [
                  Text(
                    "Quick Actions",
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _quickAction(
                    Icons.local_offer,
                    "Coupons",
                    AppColors.primaryOrange,
                    onTap: () => _comingSoon('Coupons'),
                  ),
                  _quickAction(
                    Icons.card_giftcard,
                    "Rewards",
                    Colors.green,
                    onTap: () => _comingSoon('Rewards'),
                  ),
                  _quickAction(
                    Icons.people,
                    "Refer",
                    Colors.blue,
                    onTap: () => _comingSoon('Referrals'),
                  ),
                  _quickAction(
                    Icons.support_agent,
                    "Support",
                    Colors.red,
                    onTap: () => _comingSoon('Support'),
                  ),
                  _quickAction(
                    Icons.location_on,
                    "Address",
                    Colors.deepPurple,
                    onTap: () => _comingSoon('Saved addresses'),
                  ),
                  _quickAction(
                    Icons.favorite,
                    "Wishlist",
                    Colors.pink,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WishlistScreen(),
                        ),
                      );
                    },
                  ),
                  _quickAction(
                    Icons.history,
                    "History",
                    Colors.teal,
                    onTap: () => _openOrderHistory(context),
                  ),
                  _quickAction(
                    Icons.more_horiz,
                    "More",
                    Colors.grey,
                    onTap: () => _comingSoon('More options'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .05),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                type: MaterialType.transparency,
                borderRadius: BorderRadius.circular(18),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _menuTile(
                      Icons.shopping_bag_outlined,
                      "My Orders",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OrdersScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    _menuTile(
                      Icons.favorite_border,
                      "Wishlist",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WishlistScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    _menuTile(
                      Icons.location_on_outlined,
                      "Saved Addresses",
                      onTap: () => _comingSoon('Saved addresses'),
                    ),
                    const Divider(height: 1),
                    _menuTile(
                      Icons.account_balance_wallet_outlined,
                      "Payments",
                      onTap: () => _comingSoon('Payment methods'),
                    ),
                    const Divider(height: 1),
                    _menuTile(
                      Icons.notifications_outlined,
                      "Notifications",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationScreen(),
                          ),
                        ).then((_) => _loadUnreadCount());
                      },
                    ),
                    const Divider(height: 1),
                    _menuTile(
                      Icons.settings_outlined,
                      "Settings",
                      onTap: () => _comingSoon('Settings'),
                    ),
                    const Divider(height: 1),
                    _menuTile(
                      Icons.help_outline,
                      "Help & Support",
                      onTap: () => _comingSoon('Help & Support'),
                    ),
                    const Divider(height: 1),
                    _menuTile(
                      Icons.info_outline,
                      "About SnapBee",
                      onTap: () => _comingSoon('About SnapBee'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text("Logout"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  static String _tierEmoji(MembershipTier tier) {
    switch (tier) {
      case MembershipTier.bronze:
        return '🥉';
      case MembershipTier.silver:
        return '🥈';
      case MembershipTier.gold:
        return '🥇';
      case MembershipTier.platinum:
        return '💎';
    }
  }

  static Widget _menuTile(
    IconData icon,
    String title, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryOrange),
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
      trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }

  static Widget _quickAction(
    IconData icon,
    String title,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withValues(alpha: .12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
