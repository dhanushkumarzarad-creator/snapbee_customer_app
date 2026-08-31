/// One `service_notifications` row (supabase/service_notifications.sql).
/// Its per-actor RLS already covers the customer
/// (`recipient_type = 'customer'` + `recipient_id in (select id from
/// customers where auth_user_id = auth.uid())`), and the triggers write
/// customer rows for chat messages, booking status changes and quotations.
/// Until that file is applied `ServicesBookingRepository.fetchNotifications`
/// returns an empty list and the header bell shows no count.
class ServiceNotification {
  final String id;
  final String? bookingId;
  final String kind; // booking_status | chat | quotation
  final String title;
  final String? body;
  final bool isRead;
  final DateTime createdAt;

  const ServiceNotification({
    required this.id,
    required this.bookingId,
    required this.kind,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  factory ServiceNotification.fromJson(Map<String, dynamic> json) {
    return ServiceNotification(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String?,
      kind: json['kind'] as String? ?? 'booking_status',
      title: json['title'] as String? ?? '',
      body: (json['body'] as String?)?.trim().isEmpty ?? true ? null : (json['body'] as String).trim(),
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
