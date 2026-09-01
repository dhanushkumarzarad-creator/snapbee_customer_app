// ============================================================================
// entertainment_repository.dart
// ----------------------------------------------------------------------------
// The only place the Entertainment sector talks to Supabase. Seat locking/
// booking always goes through the SECURITY DEFINER RPCs in
// supabase/entertainment_module.sql (lock_movie_seats /
// confirm_movie_booking / cancel_movie_booking) — never a direct write to
// movie_show_seats, so the server-side race-safe lock is always honored.
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';

class EntertainmentRepository {
  EntertainmentRepository(this._client);
  final SupabaseClient _client;

  // ---- Movies ------------------------------------------------------------------
  Future<List<String>> listCities() async {
    final rows = await _client.from('movie_theatres').select('city').eq('is_active', true);
    final set = <String>{};
    for (final r in (rows as List)) {
      set.add(r['city'] as String);
    }
    return set.toList()..sort();
  }

  Future<List<Map<String, dynamic>>> listTheatresInCity(String city) async {
    final rows = await _client.from('movie_theatres').select().eq('city', city).eq('is_active', true).eq('is_blocked', false);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<List<Map<String, dynamic>>> listShowsForTheatre(String theatreId) async {
    final rows = await _client
        .from('movie_shows')
        .select('*, movies(title, poster_url, language, format, duration_minutes), movie_screens!inner(id, name, theatre_id)')
        .eq('movie_screens.theatre_id', theatreId)
        .eq('is_active', true)
        .order('show_date')
        .order('show_time');
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<List<Map<String, dynamic>>> listSeatsForShow(String showId) async {
    final rows = await _client
        .from('movie_show_seats')
        .select('*, movie_screen_seats(row_label, seat_number, display_row_order)')
        .eq('show_id', showId)
        .order('id');
    return List<Map<String, dynamic>>.from(rows as List);
  }

  /// Race-safe server-side lock — see lock_movie_seats() in
  /// entertainment_module.sql. Returns {lock_token, expires_at, seat_count}.
  Future<Map<String, dynamic>> lockSeats({required String showId, required List<String> seatIds}) async {
    final result = await _client.rpc('lock_movie_seats', params: {'p_show_id': showId, 'p_seat_ids': seatIds});
    return Map<String, dynamic>.from(result as Map);
  }

  Future<String> confirmBooking({
    required String showId,
    required List<String> seatIds,
    required String lockToken,
    Map<String, dynamic> guestDetails = const {},
  }) async {
    final id = await _client.rpc('confirm_movie_booking', params: {
      'p_show_id': showId,
      'p_seat_ids': seatIds,
      'p_lock_token': lockToken,
      'p_guest_details': guestDetails,
    });
    return id as String;
  }

  Future<List<Map<String, dynamic>>> myMovieBookings() async {
    final rows = await _client.from('movie_bookings').select().order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<Map<String, dynamic>> cancelMovieBooking(String bookingId, {String? reason}) async {
    final result = await _client.rpc('cancel_movie_booking', params: {'p_booking_id': bookingId, 'p_reason': reason});
    return Map<String, dynamic>.from(result as Map);
  }

  // ---- Events ---------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> listActiveEvents() async {
    final rows = await _client.from('entertainment_events').select().eq('is_active', true).eq('is_blocked', false).order('event_date');
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<List<Map<String, dynamic>>> listEventTicketTypes(String eventId) async {
    final rows = await _client.from('event_ticket_types').select().eq('event_id', eventId).eq('is_active', true);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<String> bookEvent({
    required String eventId,
    required List<Map<String, dynamic>> items,
    Map<String, dynamic> guestDetails = const {},
    String? idempotencyKey,
  }) async {
    final id = await _client.rpc('create_event_booking', params: {
      'p_event_id': eventId,
      'p_items': items,
      'p_guest_details': guestDetails,
      'p_idempotency_key': idempotencyKey,
    });
    return id as String;
  }

  Future<List<Map<String, dynamic>>> myEventBookings() async {
    final rows = await _client.from('event_bookings').select('*, entertainment_events(title, venue, event_date)').order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  // ---- Amusement parks -----------------------------------------------------------
  Future<List<Map<String, dynamic>>> listActiveParks() async {
    final rows = await _client.from('amusement_parks').select().eq('is_active', true).eq('is_blocked', false);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<List<Map<String, dynamic>>> listParkTicketTypes(String parkId) async {
    final rows = await _client.from('amusement_park_ticket_types').select().eq('park_id', parkId).eq('is_active', true);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<String> bookPark({
    required String parkId,
    required DateTime visitDate,
    required List<Map<String, dynamic>> items,
    String? idempotencyKey,
  }) async {
    final id = await _client.rpc('create_amusement_park_booking', params: {
      'p_park_id': parkId,
      'p_visit_date': visitDate.toIso8601String().split('T').first,
      'p_items': items,
      'p_add_ons': const [],
      'p_guest_details': const {},
      'p_idempotency_key': idempotencyKey,
    });
    return id as String;
  }

  Future<List<Map<String, dynamic>>> myParkBookings() async {
    final rows = await _client.from('amusement_park_bookings').select('*, amusement_parks(name, city)').order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List);
  }
}
