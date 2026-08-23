import 'package:flutter/material.dart';

import 'models/order_history_model.dart';
import 'widgets/order_history_card.dart';
import '../orders/order_details_screen.dart';

/// Premium order history screen for the SnapBee Customer App — modeled
/// after Blinkit / Swiggy / Zepto past-orders screens.
///
/// Groups orders into Today / Yesterday / This Month / Older Orders.
/// Wire this up to real data by passing [orders] from your
/// Supabase-backed order provider/bloc and handling [onViewDetails] /
/// [onReorder]. Falls back to sample data for previewing.
class OrderHistoryScreen extends StatefulWidget {
  final List<OrderHistoryModel>? orders;
  final Future<void> Function()? onRefresh;
  final void Function(OrderHistoryModel order)? onViewDetails;
  final void Function(OrderHistoryModel order)? onReorder;
  final VoidCallback? onStartShopping;

  const OrderHistoryScreen({
    super.key,
    this.orders,
    this.onRefresh,
    this.onViewDetails,
    this.onReorder,
    this.onStartShopping,
  });

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late List<OrderHistoryModel> _orders;

  @override
  void initState() {
    super.initState();
    _orders = List<OrderHistoryModel>.from(widget.orders ?? _sampleOrders());
  }

  @override
  void didUpdateWidget(covariant OrderHistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.orders != null && widget.orders != oldWidget.orders) {
      _orders = List<OrderHistoryModel>.from(widget.orders!);
    }
  }

  Map<OrderHistoryBucket, List<OrderHistoryModel>> _groupByBucket() {
    final Map<OrderHistoryBucket, List<OrderHistoryModel>> grouped = {
      OrderHistoryBucket.today: [],
      OrderHistoryBucket.yesterday: [],
      OrderHistoryBucket.thisMonth: [],
      OrderHistoryBucket.older: [],
    };

    final sorted = List<OrderHistoryModel>.from(_orders)
      ..sort((a, b) => b.placedAt.compareTo(a.placedAt));

    for (final order in sorted) {
      final bucket = OrderHistoryTimeUtils.bucketFor(order.placedAt);
      grouped[bucket]!.add(order);
    }
    return grouped;
  }

  void _viewDetails(OrderHistoryModel order) {
    if (widget.onViewDetails != null) {
      widget.onViewDetails!(order);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            OrderDetailsScreen(order: OrderDetailsData.fromHistory(order)),
      ),
    );
  }

  void _reorder(OrderHistoryModel order) {
    widget.onReorder?.call(order);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Items from #${order.orderNumber} added to cart'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grouped = _groupByBucket();
    final bool isEmpty = _orders.isEmpty;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Order History',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        scrolledUnderElevation: 1,
      ),
      body: SafeArea(
        child: isEmpty
            ? _EmptyOrderHistoryState(onStartShopping: widget.onStartShopping)
            : RefreshIndicator(
                onRefresh: widget.onRefresh ?? () async {},
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final bool isWide = constraints.maxWidth >= 720;
                    final sections = [
                      ..._buildSection(
                        OrderHistoryBucket.today,
                        grouped[OrderHistoryBucket.today]!,
                      ),
                      ..._buildSection(
                        OrderHistoryBucket.yesterday,
                        grouped[OrderHistoryBucket.yesterday]!,
                      ),
                      ..._buildSection(
                        OrderHistoryBucket.thisMonth,
                        grouped[OrderHistoryBucket.thisMonth]!,
                      ),
                      ..._buildSection(
                        OrderHistoryBucket.older,
                        grouped[OrderHistoryBucket.older]!,
                      ),
                    ];

                    final list = ListView(
                      padding: const EdgeInsets.only(top: 8, bottom: 24),
                      children: sections,
                    );

                    if (!isWide) return list;

                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: list,
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  List<Widget> _buildSection(
    OrderHistoryBucket bucket,
    List<OrderHistoryModel> orders,
  ) {
    if (orders.isEmpty) return const [];

    return [
      _SectionHeader(title: bucket.label),
      ...orders.map(
        (order) => OrderHistoryCard(
          order: order,
          onViewDetails: () => _viewDetails(order),
          onReorder: () => _reorder(order),
        ),
      ),
    ];
  }

  /// Sample data used only when the screen isn't wired up to a real
  /// data source yet — handy for quick previews during development.
  List<OrderHistoryModel> _sampleOrders() {
    final now = DateTime.now();
    return [
      OrderHistoryModel(
        id: 'o1',
        orderNumber: 'SB-ORD-10293',
        storeName: 'SnapBee Daily Essentials',
        storeImageUrl: '',
        placedAt: now.subtract(const Duration(hours: 1)),
        amount: 482,
        itemCount: 6,
        itemsPreview: 'Milk, Bread, Eggs +3 more',
        paymentStatus: PaymentStatus.paid,
        deliveryStatus: DeliveryStatus.outForDelivery,
      ),
      OrderHistoryModel(
        id: 'o2',
        orderNumber: 'SB-ORD-10281',
        storeName: 'Green Leaf Grocers',
        storeImageUrl: '',
        placedAt: now.subtract(const Duration(hours: 5)),
        amount: 219,
        itemCount: 4,
        itemsPreview: 'Tomatoes, Onions, Potatoes +1 more',
        paymentStatus: PaymentStatus.paid,
        deliveryStatus: DeliveryStatus.delivered,
      ),
      OrderHistoryModel(
        id: 'o3',
        orderNumber: 'SB-ORD-10214',
        storeName: 'Spice Route Kitchen',
        storeImageUrl: '',
        placedAt: now.subtract(const Duration(days: 1, hours: 3)),
        amount: 356,
        itemCount: 3,
        itemsPreview: 'Paneer Butter Masala, Naan +1 more',
        paymentStatus: PaymentStatus.paid,
        deliveryStatus: DeliveryStatus.delivered,
      ),
      OrderHistoryModel(
        id: 'o4',
        orderNumber: 'SB-ORD-10166',
        storeName: 'SnapBee Pharmacy',
        storeImageUrl: '',
        placedAt: now.subtract(const Duration(days: 6)),
        amount: 640,
        itemCount: 2,
        itemsPreview: 'Vitamin C Tablets, Face Wash',
        paymentStatus: PaymentStatus.refunded,
        deliveryStatus: DeliveryStatus.cancelled,
      ),
      OrderHistoryModel(
        id: 'o5',
        orderNumber: 'SB-ORD-10042',
        storeName: 'Urban Electronics Hub',
        storeImageUrl: '',
        placedAt: now.subtract(const Duration(days: 12)),
        amount: 5999,
        itemCount: 1,
        itemsPreview: 'Philips Air Fryer HD9200',
        paymentStatus: PaymentStatus.paid,
        deliveryStatus: DeliveryStatus.delivered,
      ),
      OrderHistoryModel(
        id: 'o6',
        orderNumber: 'SB-ORD-09711',
        storeName: 'SnapBee Daily Essentials',
        storeImageUrl: '',
        placedAt: DateTime(
          now.month == 1 ? now.year - 1 : now.year,
          now.month == 1 ? 12 : now.month - 1,
          15,
        ),
        amount: 312,
        itemCount: 5,
        itemsPreview: 'Rice, Dal, Sugar +2 more',
        paymentStatus: PaymentStatus.failed,
        deliveryStatus: DeliveryStatus.cancelled,
      ),
    ];
  }
}

/// Sticky-feeling section label ("Today", "Yesterday", "This Month", "Older Orders").
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// Friendly empty state shown when there's no order history at all.
class _EmptyOrderHistoryState extends StatelessWidget {
  final VoidCallback? onStartShopping;

  const _EmptyOrderHistoryState({this.onStartShopping});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.5,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 54,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No orders yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your past orders will show up here\nonce you place your first one.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed:
                  onStartShopping ?? () => Navigator.of(context).maybePop(),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Start Shopping'),
            ),
          ],
        ),
      ),
    );
  }
}
