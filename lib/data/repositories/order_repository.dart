// ============================================================================
// order_repository.dart
// ----------------------------------------------------------------------------
// Read-only access to the customer's own real orders — the live `orders`
// table, gated by the existing `orders_customer_self_select` RLS policy
// (delivery_recommendation_engine.sql: `customer_id in (select id from
// customers where auth_user_id = auth.uid())`), so this never needs to
// filter by customer client-side. `order_items(id)` is embedded via the
// live `order_items_order_id_fkey` FK purely to get an item count — no
// admin-only columns are ever selected.
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';

class OrderRow {
  final String id;
  final String vendorName;
  final double totalAmount;
  final String status;
  final DateTime orderDate;
  final DateTime? onTheWayAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final int itemCount;

  /// Set once the dispatch engine's assignment is accepted (see
  /// `sync_order_on_assignment_change()` in
  /// delivery_partner_system.sql §2) — drives whether Order Details shows
  /// the live-tracking card.
  final String? deliveryPartnerId;

  const OrderRow({
    required this.id,
    required this.vendorName,
    required this.totalAmount,
    required this.status,
    required this.orderDate,
    this.onTheWayAt,
    this.deliveredAt,
    this.cancelledAt,
    this.itemCount = 0,
    this.deliveryPartnerId,
  });

  /// 0=placed 1=preparing 2=out for delivery 3=delivered — derived from
  /// the real timestamp columns where they exist (authoritative), falling
  /// back to the `status` string only for the placed/preparing/cancelled
  /// distinction those columns can't express. No live producer sets
  /// `status` to anything but 'pending' yet (place_customer_order's only
  /// value), so 'preparing' here is a forward-compatible guess, not an
  /// observed real value.
  int get timelineStage {
    if (deliveredAt != null) return 3;
    if (onTheWayAt != null) return 2;
    if (status == 'preparing') return 1;
    return 0;
  }

  bool get isCancelled => cancelledAt != null || status == 'cancelled';

  static DateTime? _parseNullable(dynamic value) =>
      value == null ? null : DateTime.parse(value as String);

  factory OrderRow.fromJson(Map<String, dynamic> json) {
    return OrderRow(
      id: json['id'] as String,
      vendorName: json['vendor_name'] as String? ?? '',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'pending',
      orderDate: DateTime.parse(
        (json['order_date'] ?? json['created_at']) as String,
      ),
      onTheWayAt: _parseNullable(json['on_the_way_at']),
      deliveredAt: _parseNullable(json['delivered_at']),
      cancelledAt: _parseNullable(json['cancelled_at']),
      itemCount: (json['order_items'] as List?)?.length ?? 0,
      deliveryPartnerId: json['delivery_partner_id'] as String?,
    );
  }
}

class OrderRepository {
  OrderRepository(this._client);

  final SupabaseClient _client;

  static const String _columns =
      'id, vendor_name, total_amount, status, order_date, created_at, '
      'on_the_way_at, delivered_at, cancelled_at, delivery_partner_id, order_items(id)';

  /// The signed-in customer's own orders, most recent first. Empty list
  /// (not an error) when nothing has been ordered yet or no customer
  /// profile is linked to this session — same "no session, no data"
  /// convention this app's other real repositories already use.
  Future<List<OrderRow>> fetchMyOrders({int limit = 20}) async {
    if (_client.auth.currentSession == null) return const [];
    final rows = await _client
        .from('orders')
        .select(_columns)
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((row) => OrderRow.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  /// A single order by id — used right after `place_customer_order`
  /// succeeds, to load the just-created order back from Supabase rather
  /// than trusting only the RPC's own return values. Returns null (not an
  /// error) if the order can't be found or read back under RLS.
  Future<OrderRow?> fetchOrderById(String orderId) async {
    final row = await _client
        .from('orders')
        .select(_columns)
        .eq('id', orderId)
        .maybeSingle();
    if (row == null) return null;
    return OrderRow.fromJson(Map<String, dynamic>.from(row));
  }

  /// Cancels the signed-in customer's own order via the real
  /// `cancel_customer_order` RPC (supabase/cancel_customer_order.sql) —
  /// validates ownership/status server-side with specific error messages,
  /// and fires a real `notify_customer()` cancellation notification.
  /// (`orders_update_own_customer` RLS — supabase/
  /// orders_customer_vendor_cancellation_rls.sql — independently enforces
  /// the same "only pending/accepted, only to cancelled" rule underneath,
  /// so this stays safe even if called some other way.) A
  /// `PostgrestException` here carries the RPC's own `raise exception`
  /// text (surfaced as-is — it's already customer-safe, unlike raw
  /// SQL/RLS errors).
  Future<OrderRow> cancelOrder(String orderId, {required String reason}) async {
    try {
      await _client.rpc('cancel_customer_order', params: {
        'p_order_id': orderId,
        'p_reason': reason,
      });
      final row = await _client.from('orders').select(_columns).eq('id', orderId).single();
      return OrderRow.fromJson(Map<String, dynamic>.from(row));
    } on PostgrestException catch (error) {
      throw OrderCancellationException(_mapError(error.message));
    }
  }

  String _mapError(String message) {
    if (message.contains('no longer be cancelled') || message.contains('already being prepared')) {
      return 'This order can no longer be cancelled.';
    }
    if (message.contains('order not found')) {
      return 'This order could not be found.';
    }
    return 'Could not cancel this order. Please try again.';
  }
}

class OrderCancellationException implements Exception {
  final String message;
  const OrderCancellationException(this.message);

  @override
  String toString() => message;
}
