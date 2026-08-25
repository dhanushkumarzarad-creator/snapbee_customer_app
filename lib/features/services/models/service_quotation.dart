/// Backed by `quotations`/`quotation_line_items` (services_module_v2.sql).
/// Only ever reaches the customer once `admin_review_service_quotation`
/// has approved it (`status = 'sent_to_customer'`) — the RLS/RPC layer,
/// not this model, enforces that a customer never sees a price Admin
/// hasn't already reviewed.
class QuotationLineItem {
  final String itemType;
  final String description;
  final double quantity;
  final double unitPrice;
  final double lineTotal;

  const QuotationLineItem({
    required this.itemType,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  factory QuotationLineItem.fromJson(Map<String, dynamic> json) => QuotationLineItem(
        itemType: json['item_type'] as String,
        description: json['description'] as String,
        quantity: (json['quantity'] as num).toDouble(),
        unitPrice: (json['unit_price'] as num).toDouble(),
        lineTotal: (json['line_total'] as num).toDouble(),
      );
}

class ServiceQuotation {
  final String id;
  final String bookingId;
  final String status;
  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final List<QuotationLineItem> lineItems;

  const ServiceQuotation({
    required this.id,
    required this.bookingId,
    required this.status,
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    this.lineItems = const [],
  });

  factory ServiceQuotation.fromJson(Map<String, dynamic> json) {
    final items = json['quotation_line_items'] as List?;
    return ServiceQuotation(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      status: json['status'] as String,
      subtotal: ((json['subtotal'] as num?) ?? 0).toDouble(),
      taxAmount: ((json['tax_amount'] as num?) ?? 0).toDouble(),
      totalAmount: ((json['total_amount'] as num?) ?? 0).toDouble(),
      lineItems: items == null
          ? const []
          : items.map((i) => QuotationLineItem.fromJson(Map<String, dynamic>.from(i as Map))).toList(),
    );
  }
}

/// Backed by `extra_work_requests` (services_module_v2.sql).
class ServiceExtraWorkRequest {
  final String id;
  final String bookingId;
  final String description;
  final double price;
  final String status;
  final String approvalMode;

  const ServiceExtraWorkRequest({
    required this.id,
    required this.bookingId,
    required this.description,
    required this.price,
    required this.status,
    required this.approvalMode,
  });

  factory ServiceExtraWorkRequest.fromJson(Map<String, dynamic> json) => ServiceExtraWorkRequest(
        id: json['id'] as String,
        bookingId: json['booking_id'] as String,
        description: json['description'] as String,
        price: (json['price'] as num).toDouble(),
        status: json['status'] as String,
        approvalMode: json['approval_mode'] as String,
      );

  bool get isPendingCustomerApproval => status == 'pending' && approvalMode == 'customer';
}
