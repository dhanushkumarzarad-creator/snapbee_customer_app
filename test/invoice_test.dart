import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:snapbee_customer_app/core/invoicing/invoice.dart';
import 'package:snapbee_customer_app/core/invoicing/invoice_delivery.dart';
import 'package:snapbee_customer_app/core/invoicing/invoice_pdf.dart';
import 'package:snapbee_customer_app/features/services/models/service_invoice.dart';

/// A representative `get_or_create_invoice` JSON payload (Daily Essentials,
/// COD, no tax, no refund, live order).
Map<String, dynamic> _deJson({
  String number = 'SNB-DE-000042',
  String? refund,
  bool cancelled = false,
  List<Map<String, dynamic>>? lines,
}) {
  return jsonDecode(jsonEncode({
    'invoice_number': number,
    'issued_at': '2026-09-06T09:30:00Z',
    'vertical': 'daily_essentials',
    'vertical_label': 'Daily Essentials',
    'source_id': 'ORD-990001',
    'source_label': 'Order',
    'status': cancelled ? 'cancelled' : 'pending',
    'placed_at': '2026-09-06T09:25:00Z',
    'currency': 'INR',
    'seller': {'name': 'SnapBee', 'note': 'SnapBee multi-service platform', 'tax_id': null},
    'vendor': {'label': 'Sold by', 'name': 'Fresh Mart', 'phone': '9000000003', 'tax_id': null},
    'customer': {
      'id': 'c0000000-0000-0000-0000-0000000000a1',
      'name': 'INV Owner',
      'phone': '9000000101',
      'address': '12 MG Road',
    },
    'lines': lines ??
        [
          {'description': 'Rice 5kg', 'qty': 2, 'unit_price': 100.0, 'amount': 200.0},
          {'description': 'Salt 1kg', 'qty': 1, 'unit_price': 50.0, 'amount': 50.0},
        ],
    'charges': [
      {'label': 'Delivery charge', 'amount': 30.0}
    ],
    'discounts': [],
    'coupon': null,
    'taxes': [],
    'tax_note': 'GST/tax not configured for Daily Essentials.',
    'subtotal': 250.0,
    'charges_total': 30.0,
    'discount_total': 0.0,
    'tax_total': 0.0,
    'grand_total': 280.0,
    'amount_paid': 0.0,
    'amount_due': 280.0,
    'payment': {
      'method': 'cod',
      'method_label': 'Cash on Delivery',
      'status': 'pending',
      'status_label': 'Payment pending — pay on delivery',
    },
    'refund': refund == null
        ? null
        : {
            'amount': 240.0,
            'cancellation_fee': 40.0,
            'status': refund,
            'reason': 'customer request',
            'processed_at': '2026-09-07T10:00:00Z',
          },
    'cancellation': cancelled
        ? {'cancelled_at': '2026-09-06T12:00:00Z', 'reason': 'changed mind'}
        : null,
  })) as Map<String, dynamic>;
}

void main() {
  group('Invoice.fromJson', () {
    test('parses the normalized RPC document faithfully', () {
      final inv = Invoice.fromJson(_deJson());

      expect(inv.invoiceNumber, 'SNB-DE-000042');
      expect(inv.vertical, InvoiceVertical.dailyEssentials);
      expect(inv.sourceId, 'ORD-990001');
      expect(inv.lines, hasLength(2));
      expect(inv.lines.first.quantity, 2);
      expect(inv.lines.first.amount, 200.0);
      expect(inv.charges.single.label, 'Delivery charge');
      expect(inv.grandTotal, 280.0);
      expect(inv.payment.methodLabel, 'Cash on Delivery');
      expect(inv.payment.status, 'pending');
      expect(inv.refund, isNull);
      expect(inv.cancellation, isNull);
    });

    test('does NOT invent tax when the backend reports none', () {
      final inv = Invoice.fromJson(_deJson());
      expect(inv.taxes, isEmpty);
      expect(inv.taxTotal, 0.0);
      expect(inv.hasTax, isFalse);
      expect(inv.taxNote, contains('not configured'));
    });

    test('surfaces a configured tax row only when present', () {
      final j = _deJson();
      j['taxes'] = [
        {'label': 'Taxes', 'rate': 12.0, 'amount': 30.0}
      ];
      j['tax_total'] = 30.0;
      j['tax_note'] = null;
      final inv = Invoice.fromJson(j);
      expect(inv.hasTax, isTrue);
      expect(inv.taxes.single.rate, 12.0);
      expect(inv.taxes.single.amount, 30.0);
    });

    test('carries the refund / adjustment block through', () {
      final inv = Invoice.fromJson(_deJson(refund: 'processed'));
      expect(inv.refund, isNotNull);
      expect(inv.refund!.amount, 240.0);
      expect(inv.refund!.cancellationFee, 40.0);
      expect(inv.refund!.status, 'processed');
      expect(inv.refund!.reason, 'customer request');
    });

    test('carries the cancellation block and marks the invoice cancelled', () {
      final inv = Invoice.fromJson(_deJson(cancelled: true));
      expect(inv.isCancelled, isTrue);
      expect(inv.cancellation!.reason, 'changed mind');
    });

    test('tolerates empty line lists and missing optional sections', () {
      final j = _deJson(lines: []);
      j.remove('vendor');
      j.remove('refund');
      j.remove('cancellation');
      final inv = Invoice.fromJson(j);
      expect(inv.lines, isEmpty);
      expect(inv.vendor, isNull);
      expect(inv.refund, isNull);
      expect(inv.cancellation, isNull);
      expect(inv.payment.statusLabel, isNotEmpty); // still has a payment block
    });

    test('unknown vertical wire string falls back without throwing', () {
      final j = _deJson();
      j['vertical'] = 'something_new';
      expect(() => Invoice.fromJson(j), returnsNormally);
    });
  });

  group('Invoice.fromServiceInvoice (preserves the existing Services model)', () {
    test('adapts a ServiceInvoice into the shared shape, keeping the SVC-INV number', () {
      final si = ServiceInvoice.fromJson({
        'invoice_number': 'SVC-INV-000003',
        'subtotal': 800,
        'parts_total': 150,
        'extra_work_total': 0,
        'discount_amount': 50,
        'tax_amount': 171,
        'total_amount': 1071,
        'generated_at': '2026-09-01T10:00:00Z',
      });
      final inv = Invoice.fromServiceInvoice(si, bookingId: 'SB-1', providerName: 'CoolAir');

      expect(inv.invoiceNumber, 'SVC-INV-000003');
      expect(inv.vertical, InvoiceVertical.services);
      expect(inv.vendor!.name, 'CoolAir');
      expect(inv.discounts.single.amount, -50.0);
      expect(inv.taxes.single.amount, 171.0);
      expect(inv.grandTotal, 1071.0);
    });

    test('omits the tax row when the service invoice has no tax', () {
      final si = ServiceInvoice.fromJson({
        'invoice_number': 'SVC-INV-000009',
        'subtotal': 500,
        'parts_total': 0,
        'extra_work_total': 0,
        'discount_amount': 0,
        'tax_amount': 0,
        'total_amount': 500,
        'generated_at': '2026-09-01T10:00:00Z',
      });
      final inv = Invoice.fromServiceInvoice(si, bookingId: 'SB-2');
      expect(inv.taxes, isEmpty);
      expect(inv.taxNote, isNotNull);
    });
  });

  group('InvoicePdf', () {
    test('money() groups in the Indian style with a Latin-safe currency token', () {
      expect(InvoicePdf.money(280), 'Rs 280.00');
      expect(InvoicePdf.money(1234567.5), 'Rs 12,34,567.50');
      expect(InvoicePdf.money(-40), '-Rs 40.00');
    });

    test('build() produces a non-trivial PDF byte stream', () async {
      final bytes = await InvoicePdf.build(Invoice.fromJson(_deJson()));
      expect(bytes.lengthInBytes, greaterThan(1000));
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-'); // PDF magic
    });

    test('build() paginates a long line list without throwing', () async {
      final many = List.generate(
        120,
        (i) => {
          'description': 'Line item number $i with a fairly long description to force wrapping',
          'qty': (i % 3) + 1,
          'unit_price': 19.99,
          'amount': 19.99 * ((i % 3) + 1),
        },
      );
      final bytes = await InvoicePdf.build(Invoice.fromJson(_deJson(lines: many)));
      expect(bytes.lengthInBytes, greaterThan(3000));
    });

    test('build() renders a cancelled + refunded invoice', () async {
      final j = _deJson(refund: 'processed', cancelled: true);
      final bytes = await InvoicePdf.build(Invoice.fromJson(j));
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });
  });

  group('InvoiceDelivery', () {
    test('filename is derived from the invoice number and is filesystem-safe', () async {
      final d = await InvoiceDelivery.forInvoice(Invoice.fromJson(_deJson(number: 'SNB-DE-000042')));
      expect(d.fileName, 'SnapBee_Invoice_SNB-DE-000042.pdf');
      expect(d.fileName, isNot(contains('/')));
    });
  });
}
