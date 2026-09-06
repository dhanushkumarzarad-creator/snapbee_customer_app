// ============================================================================
// invoice_button.dart
// ----------------------------------------------------------------------------
// Drop-in entry points to the shared [InvoiceScreen]. Two shapes:
//   * InvoiceActionTile   — a full-width ListTile, for an order/booking
//                           detail screen
//   * InvoiceActionButton — a compact OutlinedButton, for a list row
// Both just navigate; all fetching / PDF / share logic lives in InvoiceScreen.
// ============================================================================

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'invoice.dart';
import 'invoice_screen.dart';

void openInvoice(
  BuildContext context, {
  required InvoiceVertical vertical,
  required String sourceId,
  String? title,
}) {
  Navigator.of(context).push(
    InvoiceScreen.route(vertical: vertical, sourceId: sourceId, titleOverride: title),
  );
}

class InvoiceActionTile extends StatelessWidget {
  const InvoiceActionTile({
    super.key,
    required this.vertical,
    required this.sourceId,
    this.title = 'View invoice / bill',
    this.subtitle = 'PDF · download · share · print',
  });

  final InvoiceVertical vertical;
  final String sourceId;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            leading: const CircleAvatar(
              backgroundColor: AppColors.primaryOrangeLight,
              child: Icon(Icons.receipt_long_rounded, color: AppColors.primaryOrangeDark),
            ),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => openInvoice(context, vertical: vertical, sourceId: sourceId),
          ),
        ),
      ),
    );
  }
}

class InvoiceActionButton extends StatelessWidget {
  const InvoiceActionButton({
    super.key,
    required this.vertical,
    required this.sourceId,
    this.label = 'Invoice',
    this.dense = true,
  });

  final InvoiceVertical vertical;
  final String sourceId;
  final String label;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => openInvoice(context, vertical: vertical, sourceId: sourceId),
      icon: const Icon(Icons.receipt_long_rounded, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryOrangeDark,
        side: const BorderSide(color: AppColors.primaryOrangeLight),
        padding: dense
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        visualDensity: dense ? VisualDensity.compact : null,
      ),
    );
  }
}
