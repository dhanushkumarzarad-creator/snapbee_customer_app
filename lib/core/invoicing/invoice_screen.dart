// ============================================================================
// invoice_screen.dart
// ----------------------------------------------------------------------------
// One screen serves every vertical. Give it a [vertical] + [sourceId] (an
// order / booking id) and it:
//   * fetches the invoice via InvoiceRepository -> get_or_create_invoice RPC
//   * shows an on-screen summary that always renders (no pdf.js needed)
//   * shows a live PDF preview where the platform can rasterise
//   * offers Print / Share / Download per real platform capability
//
// Nothing here computes money or payment status — it only lays out what the
// backend returned.
// ============================================================================

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_colors.dart';
import 'invoice.dart';
import 'invoice_delivery.dart';
import 'invoice_pdf.dart';
import 'invoice_repository.dart';

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({
    super.key,
    required this.vertical,
    required this.sourceId,
    this.titleOverride,
  });

  final InvoiceVertical vertical;
  final String sourceId;
  final String? titleOverride;

  static Route<void> route({
    required InvoiceVertical vertical,
    required String sourceId,
    String? titleOverride,
  }) {
    return MaterialPageRoute(
      builder: (_) => InvoiceScreen(
        vertical: vertical,
        sourceId: sourceId,
        titleOverride: titleOverride,
      ),
    );
  }

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  late final _repo = InvoiceRepository(Supabase.instance.client);

  bool _loading = true;
  String? _error;
  Invoice? _invoice;
  Uint8List? _pdfBytes;
  InvoicePlatformCapabilities _caps = const InvoicePlatformCapabilities(
    canPrint: false,
    canShare: false,
    canPreview: false,
  );
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final caps = await InvoicePlatformCapabilities.detect();
      final invoice = await _repo.fetch(vertical: widget.vertical, sourceId: widget.sourceId);
      final bytes = await InvoicePdf.build(invoice);
      if (!mounted) return;
      setState(() {
        _caps = caps;
        _invoice = invoice;
        _pdfBytes = bytes;
        _loading = false;
      });
    } on InvoiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load this invoice. Please try again.';
        _loading = false;
      });
    }
  }

  Future<void> _run(Future<void> Function(InvoiceDelivery) action, String failMsg) async {
    final bytes = _pdfBytes;
    final invoice = _invoice;
    if (bytes == null || invoice == null || _busy) return;
    setState(() => _busy = true);
    try {
      await action(InvoiceDelivery(invoice, bytes));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failMsg)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.titleOverride ?? 'Invoice'),
      ),
      body: SafeArea(child: _body()),
      bottomNavigationBar: _invoice == null ? null : _actionBar(),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _load);
    }
    final invoice = _invoice!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _InvoiceSummaryCard(invoice: invoice),
        const SizedBox(height: 16),
        _PreviewSection(
          canPreview: _caps.canPreview,
          pdfBytes: _pdfBytes!,
        ),
      ],
    );
  }

  Widget _actionBar() {
    final children = <Widget>[];
    if (_caps.canPrint) {
      children.add(_ActionButton(
        icon: Icons.print_rounded,
        label: 'Print',
        onTap: _busy ? null : () => _run((d) => d.printDocument(), 'Could not open the print dialog.'),
      ));
    }
    if (_caps.canShare) {
      children.add(_ActionButton(
        icon: Icons.ios_share_rounded,
        label: 'Share',
        onTap: _busy ? null : () => _run((d) => d.share().then((_) {}), 'Could not share the invoice.'),
      ));
      children.add(_ActionButton(
        icon: Icons.download_rounded,
        label: 'Download',
        primary: true,
        onTap: _busy
            ? null
            : () => _run((d) => d.download().then((_) {}), 'Could not download the invoice.'),
      ));
    }
    if (children.isEmpty) {
      children.add(_ActionButton(
        icon: Icons.info_outline_rounded,
        label: 'Sharing not supported on this device',
        onTap: null,
      ));
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: children[i]),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final style = primary
        ? ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryOrange,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(46),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryOrangeLight,
            foregroundColor: AppColors.primaryOrangeDark,
            elevation: 0,
            minimumSize: const Size.fromHeight(46),
          );
    return ElevatedButton.icon(
      onPressed: onTap,
      style: style,
      icon: Icon(icon, size: 18),
      label: Text(label, overflow: TextOverflow.ellipsis),
    );
  }
}

class _PreviewSection extends StatelessWidget {
  const _PreviewSection({required this.canPreview, required this.pdfBytes});

  final bool canPreview;
  final Uint8List pdfBytes;

  @override
  Widget build(BuildContext context) {
    if (!canPreview) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardGrey,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primaryOrange),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'A full PDF preview is not available on this platform. '
                'Use Download or Share below to open the invoice PDF.',
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      height: 520,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: PdfPreview(
        build: (_) async => pdfBytes,
        allowPrinting: false,
        allowSharing: false,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        pdfPreviewPageDecoration: const BoxDecoration(color: Colors.white),
      ),
    );
  }
}

class _InvoiceSummaryCard extends StatelessWidget {
  const _InvoiceSummaryCard({required this.invoice});
  final Invoice invoice;

  String _money(double v) => InvoicePdf.money(v, currency: invoice.currency)
      .replaceFirst('Rs ', '₹'); // on-screen we can use the glyph

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget row(String k, String v, {bool bold = false, Color? color}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(k, style: TextStyle(color: color ?? AppColors.textSecondary))),
              const SizedBox(width: 12),
              Text(
                v,
                style: TextStyle(
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: color ?? AppColors.textPrimary,
                ),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('SnapBee',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              ),
              const Spacer(),
              Text(invoice.invoiceNumber,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 4),
          Text('${invoice.verticalLabel} · ${invoice.sourceLabel} ${invoice.sourceId}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const Divider(height: 20),
          if (invoice.vendor != null) row(invoice.vendor!.label ?? 'Vendor', invoice.vendor!.name),
          row('Billed to', invoice.customer.name),
          const SizedBox(height: 8),
          row('Subtotal', _money(invoice.subtotal)),
          for (final c in invoice.charges) row(c.label, _money(c.amount)),
          for (final d in invoice.discounts)
            row(d.label, _money(d.amount), color: AppColors.accentGreen),
          if (invoice.coupon != null)
            row('Coupon (${invoice.coupon!.label})', _money(invoice.coupon!.amount),
                color: AppColors.accentGreen),
          for (final t in invoice.taxes)
            row(t.rate != null ? '${t.label} @ ${t.rate}%' : t.label, _money(t.amount)),
          const Divider(height: 16),
          row('Grand total', _money(invoice.grandTotal), bold: true),
          if (invoice.amountPaid > 0) row('Amount paid', _money(invoice.amountPaid)),
          if (invoice.amountPaid > 0)
            row('Amount due', _money(invoice.amountDue), bold: true, color: AppColors.primaryOrangeDark),
          const SizedBox(height: 10),
          _Chip(
            icon: Icons.payments_rounded,
            text: '${invoice.payment.methodLabel} — ${invoice.payment.statusLabel}',
          ),
          if (!invoice.hasTax && invoice.taxNote != null) ...[
            const SizedBox(height: 6),
            Text(invoice.taxNote!,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ],
          if (invoice.refund != null) ...[
            const SizedBox(height: 6),
            _Chip(
              icon: Icons.replay_rounded,
              text:
                  'Refund ${_money(invoice.refund!.amount)} · ${invoice.refund!.status}',
              color: AppColors.accentBlue,
            ),
          ],
          if (invoice.cancellation != null) ...[
            const SizedBox(height: 6),
            _Chip(
              icon: Icons.cancel_rounded,
              text: 'Cancelled — ${invoice.cancellation!.reason}',
              color: AppColors.accentRed,
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text, this.color});
  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: c),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: c, fontSize: 12.5))),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_rounded, size: 44, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
