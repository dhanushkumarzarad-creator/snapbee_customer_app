// ============================================================================
// services_booking_repository.dart
// ----------------------------------------------------------------------------
// The authenticated booking lifecycle: create/cancel a booking, fetch a
// customer's bookings, respond to a quotation/extra-work request, submit a
// review, raise a warranty claim/complaint/dispute. Every write goes
// through the same RPCs snapbee_admin/supabase/services_module_v2.sql
// exposes to a signed-in `authenticated` role — this repository never
// computes a price, a status transition, or an approval decision itself.
//
// Same conventions as checkout_repository.dart: a dedicated exception type
// whose `.message` is always safe to show directly, RPC error messages
// mapped to friendly text, an explicit signed-in check up front. Payment
// here is display-only (advance/remaining amounts, paid flags) — this app
// never lets a customer self-report "I paid the advance", since a real
// cash-collection confirmation belongs to whichever technician actually
// collected it (`record_service_payment`, called from the Technician app).
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/service_booking.dart';
import '../models/service_quotation.dart';
import '../models/service_warranty.dart';

/// Thrown for every Services failure the UI should show directly. [message]
/// is always safe to render as-is; no raw PostgrestException text leaks.
class ServicesException implements Exception {
  final String message;
  const ServicesException(this.message);

  @override
  String toString() => message;
}

class ServicesBookingRepository {
  ServicesBookingRepository(this._client);

  final SupabaseClient _client;

  static const String _bookingSelect =
      '*, services(name), service_vendors(business_name), '
      'service_booking_workers(technician_id, service_technicians(full_name))';

  Future<String> createBooking({
    required String serviceId,
    required String address,
    required double lat,
    required double lng,
    required DateTime preferredDate,
    required String preferredTimeSlot,
    String bookingType = 'one_time',
    String locationType = 'customer_home',
    String? customerNotes,
    bool isEmergency = false,
    List<String>? emergencyProblemMedia,
  }) async {
    if (_client.auth.currentSession == null) {
      throw const ServicesException('Your session has expired. Please sign in again.');
    }
    try {
      final bookingId = await _client.rpc('create_service_booking', params: {
        'p_service_id': serviceId,
        'p_address': address,
        'p_lat': lat,
        'p_lng': lng,
        'p_preferred_date': _dateOnly(preferredDate),
        'p_preferred_time_slot': preferredTimeSlot,
        'p_booking_type': bookingType,
        'p_location_type': locationType,
        'p_customer_notes': customerNotes,
        'p_is_emergency': isEmergency,
        'p_emergency_problem_media': emergencyProblemMedia,
      });
      if (bookingId == null || (bookingId as String).isEmpty) {
        throw const ServicesException('Could not create your booking. Please try again.');
      }
      return bookingId;
    } on AuthException {
      throw const ServicesException('Your session has expired. Please sign in again.');
    } on ServicesException {
      rethrow;
    } on PostgrestException catch (error) {
      throw ServicesException(_mapRpcError(error.message));
    } catch (_) {
      throw const ServicesException('Could not create your booking. Please check your connection and try again.');
    }
  }

  Future<List<ServiceBookingRow>> fetchMyBookings() async {
    try {
      final rows = await _client.from('service_bookings').select(_bookingSelect).order('created_at', ascending: false);
      return (rows as List).map((r) => ServiceBookingRow.fromJson(Map<String, dynamic>.from(r as Map))).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<ServiceBookingRow?> fetchBooking(String bookingId) async {
    try {
      final row = await _client.from('service_bookings').select(_bookingSelect).eq('id', bookingId).maybeSingle();
      return row == null ? null : ServiceBookingRow.fromJson(Map<String, dynamic>.from(row));
    } catch (_) {
      return null;
    }
  }

  Future<void> cancelBooking(String bookingId, {String? reason}) async {
    try {
      await _client.rpc('cancel_service_booking', params: {'p_booking_id': bookingId, 'p_reason': reason});
    } on PostgrestException catch (error) {
      throw ServicesException(_mapRpcError(error.message));
    } catch (_) {
      throw const ServicesException('Could not cancel this booking. Please try again.');
    }
  }

  /// The quotation currently awaiting the customer's response for this
  /// booking, or null if none — only `sent_to_customer` (i.e.
  /// Admin-approved) quotations are ever fetched here.
  Future<ServiceQuotation?> fetchPendingQuotation(String bookingId) async {
    try {
      final row = await _client
          .from('quotations')
          .select('*, quotation_line_items(*)')
          .eq('booking_id', bookingId)
          .eq('status', 'sent_to_customer')
          .maybeSingle();
      return row == null ? null : ServiceQuotation.fromJson(Map<String, dynamic>.from(row));
    } catch (_) {
      return null;
    }
  }

  Future<void> respondToQuotation({required String quotationId, required bool approve}) async {
    try {
      await _client.rpc('respond_to_service_quotation', params: {'p_quotation_id': quotationId, 'p_approve': approve});
    } on PostgrestException catch (error) {
      throw ServicesException(_mapRpcError(error.message));
    } catch (_) {
      throw const ServicesException('Could not submit your response. Please try again.');
    }
  }

  Future<List<ServiceExtraWorkRequest>> fetchExtraWorkRequests(String bookingId) async {
    try {
      // Explicit column list — never select(*) here: extra_work_requests also
      // carries admin/AI-internal columns (ai_risk_score, ai_recommendation)
      // that must not reach a customer-facing client (see SERVICES_ARCHITECTURE.md).
      final rows = await _client
          .from('extra_work_requests')
          .select('id, booking_id, description, price, status, approval_mode')
          .eq('booking_id', bookingId)
          .order('created_at', ascending: false);
      return (rows as List)
          .map((r) => ServiceExtraWorkRequest.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Confirms the work is done — moves the booking from `completion_pending`
  /// to `completed` (server-side `confirm_service_completion` also raises
  /// the invoice, sets the remaining balance, and opens any warranty). The
  /// customer's own app already holds `completion_otp` (RLS lets them read
  /// their booking row), so it's submitted straight through as the
  /// confirmation gesture.
  Future<void> confirmCompletion({required String bookingId, required String otp}) async {
    if (_client.auth.currentSession == null) {
      throw const ServicesException('Your session has expired. Please sign in again.');
    }
    try {
      await _client.rpc('confirm_service_completion', params: {'p_booking_id': bookingId, 'p_otp': otp});
    } on PostgrestException catch (error) {
      throw ServicesException(_mapRpcError(error.message));
    } catch (_) {
      throw const ServicesException('Could not confirm completion. Please try again.');
    }
  }

  Future<void> respondToExtraWork({required String requestId, required bool approve}) async {
    try {
      await _client.rpc('respond_to_service_extra_work', params: {'p_request_id': requestId, 'p_approve': approve});
    } on PostgrestException catch (error) {
      throw ServicesException(_mapRpcError(error.message));
    } catch (_) {
      throw const ServicesException('Could not submit your response. Please try again.');
    }
  }

  Future<ServiceWarranty?> fetchWarranty(String bookingId) async {
    try {
      final row = await _client.from('service_warranties').select('*').eq('booking_id', bookingId).maybeSingle();
      return row == null ? null : ServiceWarranty.fromJson(Map<String, dynamic>.from(row));
    } catch (_) {
      return null;
    }
  }

  Future<List<WarrantyClaim>> fetchWarrantyClaims(String warrantyId) async {
    try {
      // Explicit column list — warranty_claims also carries admin/AI-internal
      // columns (ai_risk_flag, ai_risk_reason) that must not reach a
      // customer-facing client (see SERVICES_ARCHITECTURE.md).
      final rows = await _client
          .from('warranty_claims')
          .select('id, warranty_id, description, status, created_at')
          .eq('warranty_id', warrantyId)
          .order('created_at', ascending: false);
      return (rows as List).map((r) => WarrantyClaim.fromJson(Map<String, dynamic>.from(r as Map))).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> raiseWarrantyClaim({
    required String warrantyId,
    required String description,
    List<String>? mediaUrls,
  }) async {
    try {
      await _client.rpc('raise_service_warranty_claim', params: {
        'p_warranty_id': warrantyId,
        'p_description': description,
        'p_media_urls': mediaUrls,
      });
    } on PostgrestException catch (error) {
      throw ServicesException(_mapRpcError(error.message));
    } catch (_) {
      throw const ServicesException('Could not submit your warranty claim. Please try again.');
    }
  }

  /// Returns null if no review exists yet for this booking.
  Future<Map<String, dynamic>?> fetchExistingReview(String bookingId) async {
    try {
      final row = await _client.from('service_reviews').select('rating, review_text').eq('booking_id', bookingId).maybeSingle();
      return row == null ? null : Map<String, dynamic>.from(row);
    } catch (_) {
      return null;
    }
  }

  Future<void> submitReview({required String bookingId, required int rating, String? reviewText}) async {
    try {
      await _client.rpc('submit_service_review', params: {
        'p_booking_id': bookingId,
        'p_rating': rating,
        'p_review_text': reviewText,
      });
    } on PostgrestException catch (error) {
      throw ServicesException(_mapRpcError(error.message));
    } catch (_) {
      throw const ServicesException('Could not submit your review. Please try again.');
    }
  }

  Future<void> raiseComplaint({required String bookingId, required String category, required String description}) async {
    try {
      await _client.rpc('raise_service_complaint', params: {
        'p_booking_id': bookingId,
        'p_category': category,
        'p_description': description,
      });
    } on PostgrestException catch (error) {
      throw ServicesException(_mapRpcError(error.message));
    } catch (_) {
      throw const ServicesException('Could not submit your complaint. Please try again.');
    }
  }

  Future<void> raiseDispute({
    required String bookingId,
    required String disputeType,
    required String description,
    String? complaintId,
  }) async {
    try {
      await _client.rpc('raise_service_dispute', params: {
        'p_booking_id': bookingId,
        'p_dispute_type': disputeType,
        'p_description': description,
        'p_complaint_id': complaintId,
      });
    } on PostgrestException catch (error) {
      throw ServicesException(_mapRpcError(error.message));
    } catch (_) {
      throw const ServicesException('Could not submit your dispute. Please try again.');
    }
  }

  String _dateOnly(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Maps this module's RPC `raise exception` messages onto customer-friendly
  /// text, same style as checkout_repository.dart's `_mapRpcError`.
  String _mapRpcError(String message) {
    if (message.contains('no customer profile linked')) {
      return 'Your account is not fully set up yet. Please contact support.';
    }
    if (message.contains('not currently available')) {
      return 'This service is no longer available. Please choose another.';
    }
    if (message.contains('problem photo/video is mandatory')) {
      return 'Please attach a photo or video of the problem for an emergency booking.';
    }
    if (message.contains('preferred date cannot be in the past')) {
      return 'Please choose a valid upcoming date.';
    }
    if (message.contains('no longer be cancelled')) {
      return 'This booking can no longer be cancelled.';
    }
    if (message.contains('not authorized')) {
      return 'You are not authorized to do this.';
    }
    if (message.contains('has not been completed yet')) {
      return 'You can rate this booking once the work is completed.';
    }
    if (message.contains('not awaiting completion confirmation') || message.contains('incorrect OTP')) {
      return 'This booking is not ready for completion confirmation yet.';
    }
    if (message.contains('already been reviewed')) {
      return 'You have already reviewed this booking.';
    }
    if (message.contains('not awaiting your response')) {
      return 'This quotation has already been responded to.';
    }
    if (message.contains('warranty not found') || message.contains('not approved') || message.contains('expired')) {
      return 'This warranty is not eligible for a claim right now.';
    }
    return 'Something went wrong. Please try again.';
  }
}
