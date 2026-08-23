import 'package:flutter/material.dart';

import '../../data/repositories/order_repository.dart';
import '../order_history/models/order_history_model.dart';
import 'order_card.dart' show kSnapBeeOrange;
import 'order_models.dart';

/// Screen-agnostic view of "an order" — adapts either an active
/// [OrderModel] (from the Orders tab) or a past [OrderHistoryModel]
/// (from Order History) into the fields [OrderDetailsScreen] renders,
/// so one screen serves both entry points without duplicating layout.
class OrderDetailsData {
  final String orderId;
  final String storeName;
  final String storeImageUrl;
  final int itemsCount;
  final double amount;
  final String etaOrDate;
  final String? deliveryOtp;
  final String paymentLabel;
  final int
  timelineStage; // 0=placed 1=preparing 2=out for delivery 3=delivered
  final bool isCancelled;

  const OrderDetailsData({
    required this.orderId,
    required this.storeName,
    required this.storeImageUrl,
    required this.itemsCount,
    required this.amount,
    required this.etaOrDate,
    required this.paymentLabel,
    required this.timelineStage,
    required this.isCancelled,
    this.deliveryOtp,
  });

  factory OrderDetailsData.fromOrder(OrderModel order) {
    int stage;
    switch (order.status) {
      case OrderStatus.placed:
        stage = 0;
        break;
      case OrderStatus.preparing:
        stage = 1;
        break;
      case OrderStatus.outForDelivery:
        stage = 2;
        break;
      case OrderStatus.delivered:
        stage = 3;
        break;
      case OrderStatus.cancelled:
        stage = 0;
        break;
    }
    return OrderDetailsData(
      orderId: order.orderId.startsWith('#')
          ? order.orderId.substring(1)
          : order.orderId,
      storeName: order.shopName,
      storeImageUrl: order.storeImageUrl,
      itemsCount: order.itemsCount,
      amount: order.orderAmount,
      etaOrDate: order.deliveryEta,
      paymentLabel: order.paymentStatus.label,
      timelineStage: stage,
      isCancelled: order.status == OrderStatus.cancelled,
      deliveryOtp: order.deliveryOtp.isEmpty ? null : order.deliveryOtp,
    );
  }

  /// Real order, freshly loaded from Supabase (`OrderRepository`) — used
  /// right after checkout places a real order via `place_customer_order`.
  /// Unlike [fromOrder]/[fromHistory] (dummy-data adapters), every field
  /// here is either an authoritative RPC/DB value or an honest absence: no
  /// delivery OTP exists on the live `orders` table yet, so [deliveryOtp]
  /// always stays null rather than fabricating one; the "eta" line shows
  /// the real order timestamp since no ETA estimate is computed anywhere
  /// yet either; and [paymentLabel] is whatever the customer actually
  /// picked at checkout — `orders` has no payment-method column at all
  /// (no payment gateway is wired into this app), so it's carried through
  /// as-selected rather than assumed.
  factory OrderDetailsData.fromSupabaseOrder(
    OrderRow order, {
    required String paymentLabel,
  }) {
    return OrderDetailsData(
      orderId: order.id,
      storeName: order.vendorName.isEmpty ? 'Store' : order.vendorName,
      storeImageUrl: '',
      itemsCount: order.itemCount,
      amount: order.totalAmount,
      etaOrDate: 'Placed ${order.orderDate.toLocal()}'.split('.').first,
      paymentLabel: paymentLabel,
      timelineStage: order.timelineStage,
      isCancelled: order.isCancelled,
    );
  }

  factory OrderDetailsData.fromHistory(OrderHistoryModel order) {
    int stage;
    switch (order.deliveryStatus) {
      case DeliveryStatus.placed:
        stage = 0;
        break;
      case DeliveryStatus.preparing:
        stage = 1;
        break;
      case DeliveryStatus.outForDelivery:
        stage = 2;
        break;
      case DeliveryStatus.delivered:
        stage = 3;
        break;
      case DeliveryStatus.cancelled:
        stage = 0;
        break;
    }
    return OrderDetailsData(
      orderId: order.orderNumber,
      storeName: order.storeName,
      storeImageUrl: order.storeImageUrl,
      itemsCount: order.itemCount,
      amount: order.amount,
      etaOrDate: OrderHistoryTimeUtils.formatDateTime(order.placedAt),
      paymentLabel: order.paymentStatus.label,
      timelineStage: stage,
      isCancelled: order.deliveryStatus == DeliveryStatus.cancelled,
    );
  }
}

class OrderDetailsScreen extends StatelessWidget {
  final OrderDetailsData order;

  const OrderDetailsScreen({super.key, required this.order});

  static const _stages = [
    'Order Placed',
    'Preparing',
    'Out for Delivery',
    'Delivered',
  ];
  static const _stageIcons = [
    Icons.receipt_long_rounded,
    Icons.soup_kitchen_rounded,
    Icons.two_wheeler_rounded,
    Icons.check_circle_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Order #${order.orderId}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        scrolledUnderElevation: 1,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const SizedBox(height: 8),
            _Card(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      order.storeImageUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 64,
                        height: 64,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: kSnapBeeOrange,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.storeName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${order.itemsCount} item${order.itemsCount == 1 ? '' : 's'} • ₹${order.amount.toStringAsFixed(0)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.etaOrDate,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (order.deliveryOtp != null)
              _Card(
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      color: kSnapBeeOrange,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Delivery OTP',
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      order.deliveryOtp!,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: kSnapBeeOrange,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            _Card(
              child: order.isCancelled
                  ? Row(
                      children: [
                        Icon(
                          Icons.cancel_rounded,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'This order was cancelled',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Status',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        for (var i = 0; i < _stages.length; i++)
                          _TimelineStep(
                            label: _stages[i],
                            icon: _stageIcons[i],
                            isDone: i <= order.timelineStage,
                            isLast: i == _stages.length - 1,
                          ),
                      ],
                    ),
            ),
            _Card(
              child: Row(
                children: [
                  const Icon(
                    Icons.payments_rounded,
                    color: kSnapBeeOrange,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Payment',
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      order.paymentLabel,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: child,
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDone;
  final bool isLast;

  const _TimelineStep({
    required this.label,
    required this.icon,
    required this.isDone,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDone
        ? const Color(0xFF2E7D32)
        : theme.colorScheme.outlineVariant;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDone
                      ? const Color(0xFF2E7D32)
                      : theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 15,
                  color: isDone
                      ? Colors.white
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: color.withValues(alpha: 0.4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20, top: 4),
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isDone ? FontWeight.w700 : FontWeight.w500,
                  color: isDone
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
