/// One `service_invoices` row (services_module_v2.sql) — raised by
/// `confirm_service_completion` when the customer confirms the work is
/// done. Readable by the customer via `service_invoices_customer_self_select`
/// RLS. `total_amount` is the customer-facing total
/// (`subtotal + parts + extra work + tax`); `platform_fee_amount` and
/// `commission_amount` are platform-internal and are NOT part of what the
/// customer pays, so they are intentionally not surfaced here.
class ServiceInvoice {
  final String invoiceNumber;
  final double subtotal;
  final double partsTotal;
  final double extraWorkTotal;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  final DateTime generatedAt;

  const ServiceInvoice({
    required this.invoiceNumber,
    required this.subtotal,
    required this.partsTotal,
    required this.extraWorkTotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.generatedAt,
  });

  factory ServiceInvoice.fromJson(Map<String, dynamic> json) {
    return ServiceInvoice(
      invoiceNumber: json['invoice_number'] as String? ?? '',
      subtotal: ((json['subtotal'] as num?) ?? 0).toDouble(),
      partsTotal: ((json['parts_total'] as num?) ?? 0).toDouble(),
      extraWorkTotal: ((json['extra_work_total'] as num?) ?? 0).toDouble(),
      discountAmount: ((json['discount_amount'] as num?) ?? 0).toDouble(),
      taxAmount: ((json['tax_amount'] as num?) ?? 0).toDouble(),
      totalAmount: ((json['total_amount'] as num?) ?? 0).toDouble(),
      generatedAt: DateTime.parse(json['generated_at'] as String),
    );
  }
}
