import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads get_my_booking_history() — a SECURITY DEFINER RPC
/// (supabase/unified_booking_history.sql) that UNIONs the calling
/// customer's own bookings across every sector (Daily Essentials,
/// Services, Travel trips, Travel hotels, Movies, Events, Amusement
/// Parks) into one normalized shape. Every sector keeps its own real
/// history/cancellation screens — this is a read-only aggregate view for
/// Profile -> Booking History, not a new booking workflow.
class BookingHistoryRepository {
  BookingHistoryRepository(this._client);
  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchAll() async {
    final rows = await _client.rpc('get_my_booking_history');
    return List<Map<String, dynamic>>.from(rows as List);
  }
}
