/// Backed by `service_warranties` (services_module_v2.sql). Only ever
/// shown to the customer once Admin has approved it
/// (`admin_review_service_warranty`) — `status = 'approved'` — a
/// vendor-configured warranty pending review is never surfaced as active.
class ServiceWarranty {
  final String id;
  final String bookingId;
  final int durationDays;
  final String? terms;
  final String status;
  final DateTime? activatedAt;
  final DateTime? expiresAt;

  const ServiceWarranty({
    required this.id,
    required this.bookingId,
    required this.durationDays,
    this.terms,
    required this.status,
    this.activatedAt,
    this.expiresAt,
  });

  bool get isActive =>
      status == 'approved' && (expiresAt == null || expiresAt!.isAfter(DateTime.now()));

  factory ServiceWarranty.fromJson(Map<String, dynamic> json) => ServiceWarranty(
        id: json['id'] as String,
        bookingId: json['booking_id'] as String,
        durationDays: (json['duration_days'] as num).toInt(),
        terms: json['terms'] as String?,
        status: json['status'] as String,
        activatedAt: json['activated_at'] == null ? null : DateTime.parse(json['activated_at'] as String),
        expiresAt: json['expires_at'] == null ? null : DateTime.parse(json['expires_at'] as String),
      );
}

/// Backed by `warranty_claims` (services_module_v2.sql).
class WarrantyClaim {
  final String id;
  final String warrantyId;
  final String description;
  final String status;
  final DateTime createdAt;

  const WarrantyClaim({
    required this.id,
    required this.warrantyId,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  factory WarrantyClaim.fromJson(Map<String, dynamic> json) => WarrantyClaim(
        id: json['id'] as String,
        warrantyId: json['warranty_id'] as String,
        description: json['description'] as String,
        status: json['status'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
