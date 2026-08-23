import 'package:flutter/material.dart';

import '../models/cart_model.dart';

/// Itemized bill breakdown — Item Total, Delivery Charge, Platform Fee,
/// Discount and Grand Total — shown as a clean receipt-style card,
/// the way Blinkit/Zepto/Instamart summarize the cart before checkout.
class BillSummaryCard extends StatelessWidget {
  final CartBill bill;
  final double mrpSavings;

  /// True while [bill.deliveryCharge] is still the local flat-rate
  /// estimate rather than the real, server-computed charge — checkout
  /// only learns the authoritative figure from `place_customer_order`'s
  /// own return value, after the order already exists. Labels the row
  /// "(est.)" rather than implying a precision this number doesn't have.
  final bool deliveryChargeIsEstimate;

  const BillSummaryCard({
    super.key,
    required this.bill,
    this.mrpSavings = 0,
    this.deliveryChargeIsEstimate = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final totalSavings = mrpSavings + bill.couponDiscount;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bill Details',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _BillRow(label: 'Item Total', value: bill.itemTotal, theme: theme),
          _BillRow(
            label: deliveryChargeIsEstimate
                ? 'Delivery Charge (est.)'
                : 'Delivery Charge',
            value: bill.deliveryCharge,
            isFree: bill.deliveryCharge == 0,
            theme: theme,
          ),
          _BillRow(
            label: 'Platform Fee',
            value: bill.platformFee,
            theme: theme,
          ),
          if (bill.couponDiscount > 0)
            _BillRow(
              label: 'Coupon Discount',
              value: -bill.couponDiscount,
              theme: theme,
              valueColor: const Color(0xFF2E7D32),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Grand Total',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '\u20b9${bill.grandTotal.toStringAsFixed(0)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (totalSavings > 0) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.savings_rounded,
                    size: 16,
                    color: Color(0xFF2E7D32),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You saved \u20b9${totalSavings.toStringAsFixed(0)} on this order',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF2E7D32),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  final String label;
  final double value;
  final ThemeData theme;
  final bool isFree;
  final Color? valueColor;

  const _BillRow({
    required this.label,
    required this.value,
    required this.theme,
    this.isFree = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    final bool isNegative = value < 0;
    final String amountText =
        '${isNegative ? '-' : ''}\u20b9${value.abs().toStringAsFixed(0)}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          isFree
              ? Text(
                  'FREE',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF2E7D32),
                    fontWeight: FontWeight.w700,
                  ),
                )
              : Text(
                  amountText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? colorScheme.onSurface,
                  ),
                ),
        ],
      ),
    );
  }
}
