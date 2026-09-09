/// orders_screen.dart
/// SnapBee — "My Orders" screen.
///
/// Layout:
///  1. SnapBee AppBar (back, title, history, favourite, cart+badge)
///  2. Active Orders list (OrderCard) from OrderRepository
///  3. SnapBee bottom navigation
///
/// Presentation-layer only (Clean Architecture): no business logic lives
/// in the widget tree itself.
library;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/design/snapbee_design.dart';
import '../../data/repositories/order_repository.dart';
import '../../features/profile/help_support_screen.dart';
import 'order_models.dart';
import 'order_card.dart';
import 'order_details_screen.dart';
import '../cart/cart_screen.dart';
import '../order_history/order_history_screen.dart';
import '../order_history/models/order_history_model.dart';

class OrdersScreen extends StatefulWidget {
  /// Number of items currently in the cart — feeds the AppBar cart badge.
  final int cartItemCount;

  const OrdersScreen({super.key, this.cartItemCount = 0});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _orderRepository = OrderRepository(Supabase.instance.client);

  List<OrderModel> _activeOrders = const [];
  bool _isLoading = true;
  String? _errorMessage;

  // Purely presentational filter over the already-loaded active orders.
  int _statusFilter = 0; // 0=All 1=Processing 2=Out for Delivery
  static const _filterLabels = ['All Orders', 'Processing', 'Out for Delivery'];

  List<OrderModel> get _visibleOrders {
    switch (_statusFilter) {
      case 1:
        return _activeOrders
            .where((o) => o.status == OrderStatus.placed || o.status == OrderStatus.preparing)
            .toList();
      case 2:
        return _activeOrders.where((o) => o.status == OrderStatus.outForDelivery).toList();
      default:
        return _activeOrders;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadActiveOrders();
  }

  Future<void> _loadActiveOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final rows = await _orderRepository.fetchMyOrders();
      if (!mounted) return;
      setState(() {
        _activeOrders = [
          for (final row in rows)
            if (!row.isCancelled && row.timelineStage < 3) _toOrderModel(row),
        ];
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  /// Adapts a real [OrderRow] onto this screen's existing [OrderModel] —
  /// same "screen-agnostic order data" idea `OrderDetailsData`'s own
  /// factories already use. No delivery OTP/ETA exist on the live
  /// `orders` table yet, so those stay honestly empty rather than
  /// fabricated.
  OrderModel _toOrderModel(OrderRow row) {
    final status = switch (row.timelineStage) {
      2 => OrderStatus.outForDelivery,
      1 => OrderStatus.preparing,
      _ => OrderStatus.placed,
    };
    return OrderModel(
      orderId: row.id,
      shopName: row.vendorName.isEmpty ? 'Store' : row.vendorName,
      storeImageUrl: '',
      itemsCount: row.itemCount,
      deliveryEta: '',
      deliveryOtp: '',
      orderAmount: row.totalAmount,
      status: status,
      paymentStatus: OrderPaymentStatus.cod,
    );
  }

  /// Fetches this customer's real order history and hands it to
  /// OrderHistoryScreen (which renders an empty state, never sample data,
  /// when the list is empty).
  Future<void> _openOrderHistory() async {
    List<OrderHistoryModel> history = const [];
    try {
      final rows = await _orderRepository.fetchMyOrders();
      history = [for (final row in rows) OrderHistoryModel.fromOrderRow(row)];
    } catch (_) {
      // OrderHistoryScreen has no error state of its own — an empty list
      // is the honest fallback rather than fabricated orders.
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OrderHistoryScreen(orders: history)),
    );
  }

  void _handleTrackNow(OrderModel order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            OrderDetailsScreen(order: OrderDetailsData.fromOrder(order)),
      ),
    );
  }

  // Neither chat nor online payment exist yet — no ChatScreen, no payment
  // gateway, and every real order is fetched as OrderPaymentStatus.cod
  // (see _toOrderModel; there's no payment_status column on the live
  // `orders` table to read a real value from). These handlers used to fake
  // success (a snackbar saying "Payment successful!" that flipped the
  // order to paid only in local state, never persisted — a customer would
  // believe they'd paid when nothing happened) — now they say plainly that
  // the feature isn't available instead of pretending it worked.

  void _handleChat(OrderModel order) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat support is not available yet.')),
    );
  }

  void _handlePayNow(OrderModel order) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Online payment is not available yet — please pay via Cash on Delivery.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    // Responsive content clamp for tablet / web / desktop widths.
    final maxContentWidth = width > 900 ? 720.0 : width;
    final visible = _visibleOrders;

    return Scaffold(
      backgroundColor: SnapBeeColors.scaffold,
      appBar: SnapBeeAppBar(
        subtitle: 'Daily Essentials',
        showBack: Navigator.of(context).canPop(),
        trailing: Padding(
          padding: const EdgeInsets.only(right: 4),
          child: _CartIconWithBadge(count: widget.cartItemCount),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: RefreshIndicator(
              color: SnapBeeColors.orange,
              onRefresh: _loadActiveOrders,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  const SizedBox(height: 6),
                  const SnapBeeHeroCard(
                    titleTop: 'Your Orders',
                    titleAccent: 'Good Food Brings Happiness!',
                    subtitle: 'Thank you for choosing SnapBee!',
                    mascot: SnapBeeMascots.orders,
                    scriptAccent: 'Local Orders\nHappier Lives!',
                  ),
                  const SizedBox(height: 4),
                  SnapBeeFilterChips(
                    labels: _filterLabels,
                    selectedIndex: _statusFilter,
                    icons: const [Icons.list_rounded, Icons.schedule_rounded, Icons.local_shipping_rounded],
                    onSelected: (i) => setState(() => _statusFilter = i),
                  ),
                  const SizedBox(height: 6),
                  _SectionHeader(
                    title: 'Active Orders',
                    actionLabel: 'History',
                    actionIcon: Icons.history_rounded,
                    onActionTap: _openOrderHistory,
                  ),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_errorMessage != null)
                    _OrdersLoadError(
                      message: _errorMessage!,
                      onRetry: _loadActiveOrders,
                    )
                  else if (visible.isEmpty)
                    const _EmptyOrdersState()
                  else
                    ...visible.map(
                      (order) => OrderCard(
                        order: order,
                        onTrackNow: () => _handleTrackNow(order),
                        onChat: () => _handleChat(order),
                        onPayNow: () => _handlePayNow(order),
                      ),
                    ),
                  const SizedBox(height: 6),
                  _HelpBanner(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
      // No bottomNavigationBar here on purpose: MainScreen owns "the one
      // and only BottomNavigationWidget instance" (see its own doc comment)
      // and this screen is pushed on top of it via Navigator.push.
    );
  }
}

/// "Have an issue with your order?" support strip from the reference.
class _HelpBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _HelpBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: SnapBeeColors.skyCard,
        borderRadius: BorderRadius.circular(SnapBeeSpacing.rCard),
      ),
      child: Row(
        children: [
          const SnapBeeMascotImage(asset: SnapBeeMascots.notification, height: 44),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Have an issue with your order?', style: SnapBeeText.title),
                Text("We're here to help you!", style: SnapBeeText.caption),
              ],
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: SnapBeeColors.navy, borderRadius: BorderRadius.circular(SnapBeeSpacing.rPill)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.support_agent_rounded, color: Colors.white, size: 15),
                  SizedBox(width: 5),
                  Text('Contact Support', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartIconWithBadge extends StatelessWidget {
  final int count;

  const _CartIconWithBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined),
          tooltip: 'Cart',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CartScreen()),
            );
          },
        ),
        if (count > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: const BoxDecoration(
                color: kSnapBeeOrange,
                shape: BoxShape.circle,
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onActionTap;

  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.actionIcon,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (actionLabel != null)
            TextButton.icon(
              onPressed: onActionTap,
              icon: Icon(actionIcon, size: 16),
              label: Text(actionLabel!),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurface,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrdersLoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _OrdersLoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 40, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            'Could not load your orders.\n$message',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _EmptyOrdersState extends StatelessWidget {
  const _EmptyOrdersState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No active orders right now',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your placed orders will show up here.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

