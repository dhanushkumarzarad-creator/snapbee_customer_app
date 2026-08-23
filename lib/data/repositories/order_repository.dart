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
    );
  }
}

class OrderRepository {
  OrderRepository(this._client);

  final SupabaseClient _client;

  static const String _columns =
      'id, vendor_name, total_amount, status, order_date, created_at, '
      'on_the_way_at, delivered_at, cancelled_at, order_items(id)';

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
}
