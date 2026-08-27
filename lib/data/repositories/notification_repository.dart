// ============================================================================
// notification_repository.dart
// ----------------------------------------------------------------------------
// Real backend for the Notification Center, backed by the new
// `customer_notifications` table (supabase/customer_notifications.sql),
// gated by `customer_notifications_self_select`/`_self_update` RLS
// (customer_id in (select id from customers where auth_user_id = auth.uid()))
// — same "no session, no data; never filter by customer client-side"
// convention as order_repository.dart. `NotificationModel.fromJson` already
// maps 1:1 onto this table's columns.
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../screens/notification/notification_model.dart';

class NotificationRepository {
  NotificationRepository(this._client);

  final SupabaseClient _client;

  static const String _table = 'customer_notifications';

  Future<List<NotificationModel>> fetchMyNotifications({int limit = 100}) async {
    if (_client.auth.currentSession == null) return const [];
    final rows = await _client.from(_table).select().order('created_at', ascending: false).limit(limit);
    return (rows as List).map((r) => NotificationModel.fromJson(Map<String, dynamic>.from(r as Map))).toList();
  }

  Future<void> markAsRead(String notificationId) async {
    await _client.from(_table).update({'is_read': true}).eq('id', notificationId);
  }

  Future<void> markAllAsRead() async {
    await _client.from(_table).update({'is_read': true}).eq('is_read', false);
  }
}
