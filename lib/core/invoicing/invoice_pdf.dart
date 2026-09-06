// ============================================================================
// invoice_pdf.dart
// ----------------------------------------------------------------------------
// Renders an [Invoice] to a print-ready PDF, identical template for every
// vertical. Uses `pw.MultiPage` so a long item / seat / ticket list flows
// across pages automatically, with the line-item table header repeating on
// each page. Optional/empty sections (vendor, discounts, coupon, tax,
// refund, cancellation) are simply omitted.
//
// Currency is written as "Rs " (not the ₹ glyph) because the bundled PDF
// core font is Latin-only; swapping in a ₹-capable TTF here + changing
// `money()` is the only change needed to show the symbol.
// ============================================================================

import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'invoice.dart';

class InvoicePdf {
  static const PdfColor _brand = PdfColor.fromInt(0xFFF7941D); // SnapBee orange
  static const PdfColor _ink = PdfColor.fromInt(0xFF1C1C1C);
  static const PdfColor _muted = PdfColor.fromInt(0xFF757575);
  static const PdfColor _line = PdfColor.fromInt(0xFFE0E0E0);
  static const PdfColor _rowAlt = PdfColor.fromInt(0xFFFCF4E8);

  /// The bundled PDF core font is Latin-1 only. Backend strings may carry
  /// arrow / dash / mid-dot / smart-quote glyphs; map the common ones to
  /// ASCII so nothing renders as a missing-glyph box.
  static String _t(Object? v) {
    final s = v?.toString() ?? '';
    if (s.isEmpty) return '-';
    const map = {
      '→': '->', '←': '<-', '—': '-', '–': '-',
      '•': '-', '·': '-', '₹': 'Rs ', '‘': "'",
      '’': "'", '“': '"', '”': '"', '€': 'EUR ',
    };
    var out = s;
    map.forEach((k, val) => out = out.replaceAll(k, val));
    return out;
  }

  static String money(double v, {String currency = 'INR'}) {
    final neg = v < 0;
    final a = v.abs();
    final whole = a.truncate();
    final frac = ((a - whole) * 100).round().toString().padLeft(2, '0');
    // Indian grouping (last 3 digits, then pairs).
    final digits = whole.toString();
    final buf = StringBuffer();
    final rev = digits.split('').reversed.toList();
    for (var i = 0; i < rev.length; i++) {
      if (i == 3 || (i > 3 && (i - 3) % 2 == 0)) buf.write(',');
      buf.write(rev[i]);
    }
    final grouped = buf.toString().split('').reversed.join();
    final sym = currency == 'INR' ? 'Rs ' : '$currency ';
    return '${neg ? '-' : ''}$sym$grouped.$frac';
  }

  static String _date(DateTime? d, {bool withTime = false}) {
    if (d == null) return '—';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final base = '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
    if (!withTime) return base;
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ap = d.hour < 12 ? 'AM' : 'PM';
    return '$base, ${h.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} $ap';
  }

  static Future<Uint8List> build(Invoice inv) async {
    final doc = pw.Document(
      title: 'SnapBee Invoice ${inv.invoiceNumber}',
      author: 'SnapBee',
    );

    const baseText = pw.TextStyle(color: _ink, fontSize: 9.5);
    const muted = pw.TextStyle(color: _muted, fontSize: 8.5);
    const h1 = pw.TextStyle(color: _ink, fontSize: 15, fontWeight: pw.FontWeight.bold);
    const label = pw.TextStyle(
      color: _muted,
      fontSize: 7.5,
      fontWeight: pw.FontWeight.bold,
      letterSpacing: 0.6,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 30, 32, 40),
        theme: pw.ThemeData.withFont(base: pw.Font.helvetica(), bold: pw.Font.helveticaBold()),
        header: (ctx) => ctx.pageNumber == 1
            ? pw.SizedBox()
            : pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                child: pw.Text('SnapBee  ·  Invoice ${inv.invoiceNumber}', style: muted),
              ),
        footer: (ctx) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}  ·  Computer-generated invoice, no signature required.',
            style: muted,
          ),
        ),
        build: (ctx) => [
          _brandHeader(inv, h1, label, baseText, muted),
          pw.SizedBox(height: 16),
          _parties(inv, label, baseText, muted),
          pw.SizedBox(height: 16),
          _itemsTable(inv, baseText, label),
          pw.SizedBox(height: 10),
          _totals(inv, baseText, muted),
          pw.SizedBox(height: 14),
          _paymentBlock(inv, label, baseText, muted),
          if (inv.refund != null) ...[
            pw.SizedBox(height: 10),
            _refundBlock(inv, label, baseText),
          ],
          if (inv.cancellation != null) ...[
            pw.SizedBox(height: 10),
            _cancellationBlock(inv, label, baseText),
          ],
          if (inv.taxNote != null && !inv.hasTax) ...[
            pw.SizedBox(height: 10),
            pw.Text('Tax: ${_t(inv.taxNote)}', style: muted),
          ],
          pw.SizedBox(height: 18),
          pw.Text(
            'Thank you for using SnapBee.',
            style: const pw.TextStyle(color: _muted, fontSize: 8.5, fontStyle: pw.FontStyle.italic),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _brandHeader(
    Invoice inv,
    pw.TextStyle h1,
    pw.TextStyle label,
    pw.TextStyle baseText,
    pw.TextStyle muted,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: const pw.BoxDecoration(color: _brand),
              child: pw.Text(
                'SnapBee',
                style: const pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(_t(inv.seller.note ?? 'SnapBee multi-service platform'), style: muted),
            if (inv.seller.taxId != null) pw.Text(_t('Tax ID: ${inv.seller.taxId}'), style: muted),
          ],
        ),
        pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('TAX INVOICE / BILL', style: h1),
            pw.SizedBox(height: 4),
            _kv('Invoice No.', inv.invoiceNumber, label, baseText),
            _kv('Invoice date', _date(inv.issuedAt, withTime: true), label, baseText),
            _kv('${inv.sourceLabel} ID', inv.sourceId, label, baseText),
            if (inv.placedAt != null)
              _kv('${inv.sourceLabel} date', _date(inv.placedAt, withTime: true), label, baseText),
            _kv('Category', _t(inv.verticalLabel), label, baseText),
            if (inv.status != null)
              _kv('Status', inv.status!.toUpperCase(), label, baseText),
          ],
        ),
      ],
    );
  }

  static pw.Widget _kv(String k, String v, pw.TextStyle label, pw.TextStyle baseText) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 2),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('$k  ', style: label),
          pw.ConstrainedBox(
            constraints: const pw.BoxConstraints(maxWidth: 190),
            child: pw.Text(_t(v), style: baseText, textAlign: pw.TextAlign.right),
          ),
        ],
      ),
    );
  }

  static pw.Widget _parties(
    Invoice inv,
    pw.TextStyle label,
    pw.TextStyle baseText,
    pw.TextStyle muted,
  ) {
    pw.Widget box(String heading, InvoiceParty? p) {
      return pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _line),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(_t(p?.label ?? heading).toUpperCase(), style: label),
              pw.SizedBox(height: 4),
              pw.Text(_t(p?.name ?? '-'),
                  style: baseText.copyWith(fontWeight: pw.FontWeight.bold)),
              if (p?.address != null) pw.Text(_t(p!.address), style: muted),
              if (p?.phone != null) pw.Text(_t('Phone: ${p!.phone}'), style: muted),
              if (p?.meta != null) pw.Text(_t(p!.meta), style: muted),
              if (p?.taxId != null) pw.Text(_t('Tax ID: ${p!.taxId}'), style: muted),
            ],
          ),
        ),
      );
    }

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        box('Billed to', inv.customer),
        pw.SizedBox(width: 10),
        box('Vendor / Provider', inv.vendor),
      ],
    );
  }

  static pw.Widget _itemsTable(Invoice inv, pw.TextStyle baseText, pw.TextStyle label) {
    final headStyle = label.copyWith(fontSize: 7);
    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _brand),
        children: [
          _cell('#', headStyle.copyWith(color: PdfColors.white), pw.Alignment.center),
          _cell('DESCRIPTION', headStyle.copyWith(color: PdfColors.white), pw.Alignment.centerLeft),
          _cell('QTY', headStyle.copyWith(color: PdfColors.white), pw.Alignment.centerRight),
          _cell('UNIT PRICE', headStyle.copyWith(color: PdfColors.white), pw.Alignment.centerRight),
          _cell('AMOUNT', headStyle.copyWith(color: PdfColors.white), pw.Alignment.centerRight),
        ],
      ),
    ];

    if (inv.lines.isEmpty) {
      rows.add(pw.TableRow(children: [
        _cell('', baseText, pw.Alignment.center),
        _cell('No itemised lines recorded for this ${inv.sourceLabel.toLowerCase()}.',
            baseText.copyWith(color: _muted), pw.Alignment.centerLeft),
        _cell('', baseText, pw.Alignment.centerRight),
        _cell('', baseText, pw.Alignment.centerRight),
        _cell(money(inv.subtotal, currency: inv.currency), baseText, pw.Alignment.centerRight),
      ]));
    } else {
      for (var i = 0; i < inv.lines.length; i++) {
        final l = inv.lines[i];
        rows.add(pw.TableRow(
          decoration: i.isOdd ? const pw.BoxDecoration(color: _rowAlt) : null,
          children: [
            _cell('${i + 1}', baseText, pw.Alignment.center),
            _cell(
              l.meta == null ? _t(l.description) : '${_t(l.description)}\n${_t(l.meta)}',
              baseText,
              pw.Alignment.centerLeft,
            ),
            _cell(_qty(l.quantity), baseText, pw.Alignment.centerRight),
            _cell(money(l.unitPrice, currency: inv.currency), baseText, pw.Alignment.centerRight),
            _cell(money(l.amount, currency: inv.currency), baseText, pw.Alignment.centerRight),
          ],
        ));
      }
    }

    return pw.Table(
      border: pw.TableBorder.all(color: _line, width: 0.5),
      columnWidths: const {
        0: pw.FixedColumnWidth(24),
        1: pw.FlexColumnWidth(5),
        2: pw.FixedColumnWidth(38),
        3: pw.FixedColumnWidth(78),
        4: pw.FixedColumnWidth(82),
      },
      children: rows,
    );
  }

  static String _qty(num q) => q == q.roundToDouble() ? q.toInt().toString() : q.toString();

  static pw.Widget _cell(String text, pw.TextStyle style, pw.Alignment align) {
    return pw.Container(
      alignment: align,
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(_t(text), style: style),
    );
  }

  static pw.Widget _totals(Invoice inv, pw.TextStyle baseText, pw.TextStyle muted) {
    pw.Widget row(String k, String v, {bool bold = false, PdfColor? color}) {
      final s = baseText.copyWith(
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: color ?? _ink,
        fontSize: bold ? 11 : 9.5,
      );
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [pw.Text(_t(k), style: s), pw.Text(_t(v), style: s)],
        ),
      );
    }

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 250,
          child: pw.Column(
            children: [
              row('Subtotal', money(inv.subtotal, currency: inv.currency)),
              for (final c in inv.charges)
                row(_t(c.label), money(c.amount, currency: inv.currency)),
              for (final d in inv.discounts)
                row(_t(d.label), money(d.amount, currency: inv.currency), color: _muted),
              if (inv.coupon != null)
                row(_t('Coupon (${inv.coupon!.label})'),
                    money(inv.coupon!.amount, currency: inv.currency), color: _muted),
              for (final t in inv.taxes)
                row(
                  t.rate != null ? _t('${t.label} @ ${_qty(t.rate!)}%') : _t(t.label),
                  money(t.amount, currency: inv.currency),
                ),
              pw.Divider(color: _line, height: 10),
              row('Grand total', money(inv.grandTotal, currency: inv.currency), bold: true),
              if (inv.amountPaid > 0)
                row('Amount paid', money(inv.amountPaid, currency: inv.currency), color: _muted),
              if (inv.amountPaid > 0)
                row('Amount due', money(inv.amountDue, currency: inv.currency),
                    bold: true, color: _brand),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _panel(String heading, List<pw.Widget> children, pw.TextStyle label) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFFAFAFA),
        border: pw.Border.all(color: _line),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(_t(heading).toUpperCase(), style: label),
          pw.SizedBox(height: 4),
          ...children,
        ],
      ),
    );
  }

  static pw.Widget _paymentBlock(
    Invoice inv,
    pw.TextStyle label,
    pw.TextStyle baseText,
    pw.TextStyle muted,
  ) {
    final p = inv.payment;
    return _panel('Payment', [
      pw.Text(_t('Method: ${p.methodLabel}'), style: baseText),
      pw.Text(_t('Status: ${p.statusLabel}'), style: baseText),
      if (p.reference != null) pw.Text(_t('Reference: ${p.reference}'), style: muted),
      if (p.paidAt != null) pw.Text('Paid on: ${_date(p.paidAt, withTime: true)}', style: muted),
      if (p.model != null) pw.Text(_t('Payment model: ${p.model}'), style: muted),
      if ((p.advanceAmount ?? 0) != 0)
        pw.Text('Advance: ${money(p.advanceAmount!, currency: inv.currency)}', style: muted),
      if ((p.remainingAmount ?? 0) != 0)
        pw.Text('Remaining: ${money(p.remainingAmount!, currency: inv.currency)}', style: muted),
    ], label);
  }

  static pw.Widget _refundBlock(Invoice inv, pw.TextStyle label, pw.TextStyle baseText) {
    final r = inv.refund!;
    return _panel('Refund / Adjustment', [
      pw.Text('Refund amount: ${money(r.amount, currency: inv.currency)}', style: baseText),
      if (r.cancellationFee != 0)
        pw.Text('Cancellation fee: ${money(r.cancellationFee, currency: inv.currency)}',
            style: baseText),
      pw.Text(_t('Status: ${r.status}'), style: baseText),
      if (r.reason != null) pw.Text(_t('Reason: ${r.reason}'), style: baseText),
      if (r.processedAt != null)
        pw.Text('Processed on: ${_date(r.processedAt, withTime: true)}', style: baseText),
    ], label);
  }

  static pw.Widget _cancellationBlock(Invoice inv, pw.TextStyle label, pw.TextStyle baseText) {
    final c = inv.cancellation!;
    return _panel('Cancellation', [
      if (c.cancelledAt != null)
        pw.Text('Cancelled on: ${_date(c.cancelledAt, withTime: true)}', style: baseText),
      pw.Text(_t('Reason: ${c.reason}'), style: baseText),
    ], label);
  }
}
