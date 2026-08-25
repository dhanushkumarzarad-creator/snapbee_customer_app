import 'package:flutter/material.dart';

import '../models/service_quotation.dart';

/// Shows a customer-approval-pending quotation's line items and total, and
/// returns `true` (approve) / `false` (reject) via [Navigator.pop], or null
/// if dismissed without a decision. Section 5 of the Services spec: this is
/// the "customer approval" gate between an inspection and the actual repair
/// work order — the price shown here has already been through
/// `admin_review_service_quotation`, never a vendor's raw, unreviewed number.
Future<bool?> showQuotationResponseSheet(BuildContext context, ServiceQuotation quotation) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quotation for your approval', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            for (final item in quotation.lineItems)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text('${item.description} × ${item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 1)}')),
                    Text('₹${item.lineTotal.toStringAsFixed(0)}'),
                  ],
                ),
              ),
            const Divider(),
            Row(
              children: [
                const Expanded(child: Text('Tax', style: TextStyle(color: Colors.grey))),
                Text('₹${quotation.taxAmount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Expanded(child: Text('Total', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
                Text('₹${quotation.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
