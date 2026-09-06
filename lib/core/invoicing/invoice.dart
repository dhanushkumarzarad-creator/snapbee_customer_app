// ============================================================================
// invoice.dart
// ----------------------------------------------------------------------------
// The normalized invoice document, shared by every vertical (Daily
// Essentials, Services, Travel, Entertainment, E-Commerce). It is a 1:1
// mapping of the JSON returned by the `get_or_create_invoice(p_vertical,
// p_source_id)` RPC (supabase/invoices_shared_layer.sql) — every field is
// either an authoritative backend value or an explicit absence. Nothing here
// is computed client-side; the PDF/print layer only formats what the backend
// already decided.
//
// `Invoice.fromServiceInvoice` additionally adapts the pre-existing
// `ServiceInvoice` model (lib/features/services/models/service_invoice.dart)
// so the same PDF template can render a Services bill without changing that
// model or its repository.
// ============================================================================

import '../../features/services/models/service_invoice.dart';

/// Which backend vertical an invoice belongs to. The `wire` value is exactly
/// the string `get_or_create_invoice`'s `p_vertical` argument expects.
enum InvoiceVertical {
  dailyEssentials('daily_essentials', 'Daily Essentials'),
  services('services', 'Services'),
  travelTrip('travel_trip', 'Travel — Trip'),
  travelHotel('travel_hotel', 'Travel — Hotel'),
  movie('movie', 'Entertainment — Movie'),
  event('event', 'Entertainment — Event'),
  amusementPark('amusement_park', 'Entertainment — Amusement Park'),
  ecommerce('ecommerce', 'E-Commerce');

  const InvoiceVertical(this.wire, this.label);
  final String wire;
  final String label;

  static InvoiceVertical fromWire(String? value) => InvoiceVertical.values.firstWhere(
        (v) => v.wire == value,
        orElse: () => InvoiceVertical.dailyEssentials,
      );
}

double _d(dynamic v) => v == null ? 0 : (v as num).toDouble();
String? _s(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

DateTime? _dt(dynamic v) {
  if (v == null) return null;
  try {
    return DateTime.parse(v as String).toLocal();
  } catch (_) {
    return null;
  }
}

class InvoiceParty {
  final String? label;
  final String name;
  final String? phone;
  final String? address;
  final String? taxId;
  final String? meta;
  final String? note;

  const InvoiceParty({
    this.label,
    required this.name,
    this.phone,
    this.address,
    this.taxId,
    this.meta,
    this.note,
  });

  factory InvoiceParty.fromJson(Map<String, dynamic> j, {String fallbackName = ''}) => InvoiceParty(
        label: _s(j['label']),
        name: _s(j['name']) ?? fallbackName,
        phone: _s(j['phone']),
        address: _s(j['address']),
        taxId: _s(j['tax_id']),
        meta: _s(j['meta']),
        note: _s(j['note']),
      );
}

class InvoiceLine {
  final String description;
  final String? meta;
  final num quantity;
  final double unitPrice;
  final double amount;

  const InvoiceLine({
    required this.description,
    this.meta,
    required this.quantity,
    required this.unitPrice,
    required this.amount,
  });

  factory InvoiceLine.fromJson(Map<String, dynamic> j) => InvoiceLine(
        description: _s(j['description']) ?? 'Item',
        meta: _s(j['meta']),
        quantity: (j['qty'] as num?) ?? 1,
        unitPrice: _d(j['unit_price']),
        amount: _d(j['amount']),
      );
}

/// A named money row that is NOT a line item — a delivery/shipping/service
/// charge, an add-on, a discount (negative), a coupon, or a tax row.
class InvoiceAdjustment {
  final String label;
  final double amount;
  final double? rate; // percent, tax rows only; null otherwise

  const InvoiceAdjustment({required this.label, required this.amount, this.rate});

  factory InvoiceAdjustment.fromJson(Map<String, dynamic> j) => InvoiceAdjustment(
        label: _s(j['label']) ?? '',
        amount: _d(j['amount']),
        rate: j['rate'] == null ? null : _d(j['rate']),
      );
}

class InvoicePayment {
  final String method;
  final String methodLabel;
  final String status;
  final String statusLabel;
  final String? reference;
  final DateTime? paidAt;
  final String? model;
  final double? advanceAmount;
  final double? remainingAmount;

  const InvoicePayment({
    required this.method,
    required this.methodLabel,
    required this.status,
    required this.statusLabel,
    this.reference,
    this.paidAt,
    this.model,
    this.advanceAmount,
    this.remainingAmount,
  });

  factory InvoicePayment.fromJson(Map<String, dynamic>? j) {
    j ??= const {};
    return InvoicePayment(
      method: _s(j['method']) ?? 'unknown',
      methodLabel: _s(j['method_label']) ?? 'Not recorded',
      status: _s(j['status']) ?? 'pending',
      statusLabel: _s(j['status_label']) ?? 'Payment pending',
      reference: _s(j['reference']),
      paidAt: _dt(j['paid_at']),
      model: _s(j['model']),
      advanceAmount: j['advance_amount'] == null ? null : _d(j['advance_amount']),
      remainingAmount: j['remaining_amount'] == null ? null : _d(j['remaining_amount']),
    );
  }
}

class InvoiceRefund {
  final double amount;
  final double cancellationFee;
  final String status;
  final String? reason;
  final DateTime? processedAt;

  const InvoiceRefund({
    required this.amount,
    required this.cancellationFee,
    required this.status,
    this.reason,
    this.processedAt,
  });

  static InvoiceRefund? fromJson(dynamic v) {
    if (v is! Map) return null;
    final j = Map<String, dynamic>.from(v);
    return InvoiceRefund(
      amount: _d(j['amount']),
      cancellationFee: _d(j['cancellation_fee']),
      status: _s(j['status']) ?? 'processed',
      reason: _s(j['reason']),
      processedAt: _dt(j['processed_at']),
    );
  }
}

class InvoiceCancellation {
  final DateTime? cancelledAt;
  final String reason;

  const InvoiceCancellation({this.cancelledAt, required this.reason});

  static InvoiceCancellation? fromJson(dynamic v) {
    if (v is! Map) return null;
    final j = Map<String, dynamic>.from(v);
    return InvoiceCancellation(
      cancelledAt: _dt(j['cancelled_at']),
      reason: _s(j['reason']) ?? 'Not specified',
    );
  }
}

class Invoice {
  final String invoiceNumber;
  final DateTime? issuedAt;
  final InvoiceVertical vertical;
  final String verticalLabel;
  final String sourceId;
  final String sourceLabel; // "Order" / "Booking"
  final String? status;
  final DateTime? placedAt;
  final String currency;

  final InvoiceParty seller;
  final InvoiceParty? vendor;
  final InvoiceParty customer;

  final List<InvoiceLine> lines;
  final List<InvoiceAdjustment> charges;
  final List<InvoiceAdjustment> discounts;
  final InvoiceAdjustment? coupon;
  final List<InvoiceAdjustment> taxes;
  final String? taxNote;

  final double subtotal;
  final double chargesTotal;
  final double discountTotal;
  final double taxTotal;
  final double grandTotal;
  final double amountPaid;
  final double amountDue;

  final InvoicePayment payment;
  final InvoiceRefund? refund;
  final InvoiceCancellation? cancellation;

  const Invoice({
    required this.invoiceNumber,
    this.issuedAt,
    required this.vertical,
    required this.verticalLabel,
    required this.sourceId,
    required this.sourceLabel,
    this.status,
    this.placedAt,
    required this.currency,
    required this.seller,
    this.vendor,
    required this.customer,
    required this.lines,
    required this.charges,
    required this.discounts,
    this.coupon,
    required this.taxes,
    this.taxNote,
    required this.subtotal,
    required this.chargesTotal,
    required this.discountTotal,
    required this.taxTotal,
    required this.grandTotal,
    required this.amountPaid,
    required this.amountDue,
    required this.payment,
    this.refund,
    this.cancellation,
  });

  bool get isCancelled => cancellation != null || status == 'cancelled';
  bool get hasTax => taxes.isNotEmpty && taxTotal > 0;

  static List<InvoiceAdjustment> _adjList(dynamic v) {
    if (v is! List) return const [];
    return v
        .whereType<Map>()
        .map((e) => InvoiceAdjustment.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  factory Invoice.fromJson(Map<String, dynamic> j) {
    return Invoice(
      invoiceNumber: _s(j['invoice_number']) ?? '—',
      issuedAt: _dt(j['issued_at']),
      vertical: InvoiceVertical.fromWire(_s(j['vertical'])),
      verticalLabel: _s(j['vertical_label']) ?? '',
      sourceId: _s(j['source_id']) ?? '',
      sourceLabel: _s(j['source_label']) ?? 'Order',
      status: _s(j['status']),
      placedAt: _dt(j['placed_at']),
      currency: _s(j['currency']) ?? 'INR',
      seller: InvoiceParty.fromJson(
        Map<String, dynamic>.from(j['seller'] as Map? ?? const {}),
        fallbackName: 'SnapBee',
      ),
      vendor: j['vendor'] is Map
          ? InvoiceParty.fromJson(Map<String, dynamic>.from(j['vendor'] as Map))
          : null,
      customer: InvoiceParty.fromJson(
        Map<String, dynamic>.from(j['customer'] as Map? ?? const {}),
        fallbackName: 'Customer',
      ),
      lines: (j['lines'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => InvoiceLine.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      charges: _adjList(j['charges']),
      discounts: _adjList(j['discounts']),
      coupon: j['coupon'] is Map
          ? InvoiceAdjustment.fromJson(Map<String, dynamic>.from(j['coupon'] as Map))
          : null,
      taxes: _adjList(j['taxes']),
      taxNote: _s(j['tax_note']),
      subtotal: _d(j['subtotal']),
      chargesTotal: _d(j['charges_total']),
      discountTotal: _d(j['discount_total']),
      taxTotal: _d(j['tax_total']),
      grandTotal: _d(j['grand_total']),
      amountPaid: _d(j['amount_paid']),
      amountDue: _d(j['amount_due']),
      payment: InvoicePayment.fromJson(
        j['payment'] is Map ? Map<String, dynamic>.from(j['payment'] as Map) : null,
      ),
      refund: InvoiceRefund.fromJson(j['refund']),
      cancellation: InvoiceCancellation.fromJson(j['cancellation']),
    );
  }

  /// Adapts the pre-existing [ServiceInvoice] (unchanged) into the shared
  /// shape so the same PDF template renders a Services bill. Used as a
  /// local fallback if the RPC path is unavailable; the RPC
  /// (`get_or_create_invoice('services', ...)`) is still preferred because
  /// it also carries party + payment-status detail.
  factory Invoice.fromServiceInvoice(
    ServiceInvoice si, {
    required String bookingId,
    String? providerName,
    String? customerName,
  }) {
    final charges = <InvoiceAdjustment>[
      if (si.partsTotal != 0) InvoiceAdjustment(label: 'Parts', amount: si.partsTotal),
      if (si.extraWorkTotal != 0)
        InvoiceAdjustment(label: 'Extra work', amount: si.extraWorkTotal),
    ];
    return Invoice(
      invoiceNumber: si.invoiceNumber,
      issuedAt: si.generatedAt,
      vertical: InvoiceVertical.services,
      verticalLabel: 'Services',
      sourceId: bookingId,
      sourceLabel: 'Booking',
      status: null,
      placedAt: si.generatedAt,
      currency: 'INR',
      seller: const InvoiceParty(name: 'SnapBee', note: 'SnapBee multi-service platform'),
      vendor: InvoiceParty(label: 'Serviced by', name: providerName ?? 'Service provider'),
      customer: InvoiceParty(name: customerName ?? 'Customer'),
      lines: [
        InvoiceLine(
          description: 'Service charge',
          quantity: 1,
          unitPrice: si.subtotal,
          amount: si.subtotal,
        ),
      ],
      charges: charges,
      discounts: [
        if (si.discountAmount != 0)
          InvoiceAdjustment(label: 'Discount', amount: -si.discountAmount.abs()),
      ],
      coupon: null,
      taxes: [
        if (si.taxAmount > 0) InvoiceAdjustment(label: 'Tax (as configured)', amount: si.taxAmount),
      ],
      taxNote: si.taxAmount > 0 ? null : 'No tax recorded on this service invoice.',
      subtotal: si.subtotal,
      chargesTotal: si.partsTotal + si.extraWorkTotal,
      discountTotal: si.discountAmount.abs(),
      taxTotal: si.taxAmount,
      grandTotal: si.totalAmount,
      amountPaid: 0,
      amountDue: si.totalAmount,
      payment: const InvoicePayment(
        method: 'recorded',
        methodLabel: 'Collected by provider',
        status: 'pending',
        statusLabel: 'See booking for payment status',
      ),
      refund: null,
      cancellation: null,
    );
  }
}
