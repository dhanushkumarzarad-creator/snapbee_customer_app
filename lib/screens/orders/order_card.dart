/// order_card.dart
/// A single premium "Active Order" card — store image, order details,
/// live status chip, chat icon, and the Track / Pay-Now-or-Paid actions.
///
/// Matches the SnapBee visual language used on Category & Offer Zone
/// screens: soft orange accent (#F7941D), rounded corners, light shadow.
library;

import 'package:flutter/material.dart';
import 'order_models.dart';

/// Shared SnapBee accent — keep in sync with the app-wide AppColors class.
const Color kSnapBeeOrange = Color(0xFFF7941D);

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTrackNow;
  final VoidCallback onChat;
  final VoidCallback? onPayNow;

  const OrderCard({
    super.key,
    required this.order,
    required this.onTrackNow,
    required this.onChat,
    this.onPayNow,
  });

  Color _statusColor(BuildContext context) {
    switch (order.status) {
      case OrderStatus.placed:
        return Colors.blueGrey;
      case OrderStatus.preparing:
        return kSnapBeeOrange;
      case OrderStatus.outForDelivery:
        return const Color(0xFF3949AB); // indigo, matches Track button
      case OrderStatus.delivered:
        return const Color(0xFF43A047);
      case OrderStatus.cancelled:
        return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPaid = order.paymentStatus == OrderPaymentStatus.paid;
    final statusColor = _statusColor(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Store image
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  order.storeImageUrl,
                  width: 84,
                  height: 84,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 84,
                    height: 84,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.storefront_rounded,
                      color: kSnapBeeOrange,
                      size: 32,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Order details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            order.shopName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _StatusChip(
                          label: order.status.label,
                          color: statusColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Order ID: ${order.orderId}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _InfoRow(
                      icon: Icons.shopping_bag_outlined,
                      label: '${order.itemsCount} Items',
                    ),
                    const SizedBox(height: 4),
                    _InfoRow(
                      icon: Icons.access_time_rounded,
                      label: order.deliveryEta,
                    ),
                    if (order.deliveryOtp.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _InfoRow(
                        icon: Icons.lock_outline_rounded,
                        label: 'Delivery OTP: ${order.deliveryOtp}',
                        highlight: true,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'Order Amount',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '₹${order.orderAmount.toStringAsFixed(0)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: kSnapBeeOrange,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onChat,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kSnapBeeOrange.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: kSnapBeeOrange,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onTrackNow,
                  icon: const Icon(Icons.local_shipping_outlined, size: 18),
                  label: const Text('Track Now'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF3949AB),
                    side: const BorderSide(color: Color(0xFF3949AB)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: isPaid ? null : onPayNow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPaid
                        ? const Color(0xFF43A047)
                        : kSnapBeeOrange,
                    disabledBackgroundColor: const Color(0xFF43A047),
                    disabledForegroundColor: Colors.white,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    order.paymentStatus.label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlight;

  const _InfoRow({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: highlight
              ? kSnapBeeOrange
              : theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: highlight
                ? kSnapBeeOrange
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
