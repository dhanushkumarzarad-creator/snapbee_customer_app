// ============================================================================
// travel_repository.dart
// ----------------------------------------------------------------------------
// The only place the Travel sector talks to Supabase. Every write goes
// through the SECURITY DEFINER RPCs in supabase/travel_module.sql — this
// class never writes booking/payment rows directly. Reads rely on RLS
// (travel_bookings_customer_select etc.) rather than an explicit
// `.eq('customer_id', ...)` filter, matching the rest of this app's data
// layer (customer_repository.dart's own convention).
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';

class TravelRepository {
  TravelRepository(this._client);
  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> listActiveVehicleTypes() async {
    final rows = await _client.from('travel_vehicle_types').select().eq('is_active', true).order('display_order');
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<List<Map<String, dynamic>>> listAvailableVehicles({required String vehicleTypeId}) async {
    final rows = await _client
        .from('travel_vehicles')
        .select('*, travel_vendors(business_name)')
        .eq('vehicle_type_id', vehicleTypeId)
        .eq('is_active', true)
        .eq('is_blocked', false);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<Map<String, dynamic>> computeTripPrice({
    required String vehicleTypeId,
    required String vendorId,
    required DateTime startDate,
    required DateTime endDate,
    required bool withDriver,
  }) async {
    final result = await _client.rpc('compute_travel_trip_price', params: {
      'p_vehicle_type_id': vehicleTypeId,
      'p_vendor_id': vendorId,
      'p_start_date': startDate.toIso8601String().split('T').first,
      'p_end_date': endDate.toIso8601String().split('T').first,
      'p_with_driver': withDriver,
    });
    return Map<String, dynamic>.from(result as Map);
  }

  Future<String> createTripBooking({
    required String vehicleId,
    required String pickup,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
    required int passengers,
    required bool withDriver,
    String? purpose,
  }) async {
    final id = await _client.rpc('create_travel_trip_booking', params: {
      'p_vehicle_id': vehicleId,
      'p_pickup': pickup,
      'p_destination': destination,
      'p_start_date': startDate.toIso8601String().split('T').first,
      'p_end_date': endDate.toIso8601String().split('T').first,
      'p_passengers': passengers,
      'p_with_driver': withDriver,
      'p_purpose': purpose,
    });
    return id as String;
  }

  Future<List<Map<String, dynamic>>> myTripBookings() async {
    final rows = await _client
        .from('travel_bookings')
        .select('*, travel_vehicle_types(name), travel_vehicles(registration_number)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<Map<String, dynamic>> cancelTripBooking(String bookingId, {String? reason}) async {
    final result = await _client.rpc('cancel_travel_booking', params: {'p_booking_id': bookingId, 'p_reason': reason});
    return Map<String, dynamic>.from(result as Map);
  }

  // ---- Hotels ----------------------------------------------------------------
  Future<List<Map<String, dynamic>>> searchHotels({required String city}) async {
    final rows = await _client.from('travel_hotels').select().ilike('city', '%$city%').eq('is_active', true).eq('is_blocked', false);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<List<Map<String, dynamic>>> listHotelRooms(String hotelId) async {
    final rows = await _client.from('travel_hotel_rooms').select().eq('hotel_id', hotelId).eq('is_active', true);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<String> createHotelBooking({
    required String roomId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int roomsCount,
    required int guestsCount,
  }) async {
    final id = await _client.rpc('create_travel_hotel_booking', params: {
      'p_room_id': roomId,
      'p_check_in': checkIn.toIso8601String().split('T').first,
      'p_check_out': checkOut.toIso8601String().split('T').first,
      'p_rooms_count': roomsCount,
      'p_guests_count': guestsCount,
    });
    return id as String;
  }

  Future<List<Map<String, dynamic>>> myHotelBookings() async {
    final rows = await _client.from('travel_hotel_bookings').select('*, travel_hotels(name, city)').order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<Map<String, dynamic>> cancelHotelBooking(String bookingId, {String? reason}) async {
    final result = await _client.rpc('cancel_travel_hotel_booking', params: {'p_booking_id': bookingId, 'p_reason': reason});
    return Map<String, dynamic>.from(result as Map);
  }
}
