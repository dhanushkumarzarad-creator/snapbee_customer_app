/// One `service_chat` row (services_module_v2.sql SECTION 14) — the shared
/// per-booking thread between the customer, the vendor, and the assigned
/// technician/inspector. Read/write is gated by the existing
/// `service_chat_participant_select` / `_participant_insert` RLS policies,
/// which already include `customer_id in (select id from customers where
/// auth_user_id = auth.uid())`, so no RPC is needed.
class ServiceChatMessage {
  final String id;
  final String bookingId;
  final String senderType; // customer | technician | vendor | inspector | admin
  final String senderId;
  final String? message;
  final String? mediaUrl;
  final DateTime createdAt;

  const ServiceChatMessage({
    required this.id,
    required this.bookingId,
    required this.senderType,
    required this.senderId,
    required this.message,
    required this.mediaUrl,
    required this.createdAt,
  });

  /// True for this customer's own messages (aligns the bubble).
  /// [myCustomerId] is the caller's `customers.id`.
  bool isMine(String? myCustomerId) =>
      myCustomerId != null && senderType == 'customer' && senderId == myCustomerId;

  String get senderLabel => switch (senderType) {
        'vendor' => 'Provider',
        'technician' => 'Technician',
        'inspector' => 'Inspector',
        'admin' => 'SnapBee',
        _ => 'You',
      };

  factory ServiceChatMessage.fromJson(Map<String, dynamic> json) {
    return ServiceChatMessage(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      senderType: json['sender_type'] as String,
      senderId: json['sender_id'] as String,
      message: json['message'] as String?,
      mediaUrl: json['media_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
