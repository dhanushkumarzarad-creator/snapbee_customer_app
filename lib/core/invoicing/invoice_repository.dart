// ============================================================================
// invoice_repository.dart
// ----------------------------------------------------------------------------
// Single entry point for fetching an invoice document. Calls the
// `get_or_create_invoice(p_vertical, p_source_id)` RPC
// (supabase/invoices_shared_layer.sql), which is SECURITY DEFINER and
// enforces the existing authorization triad server-side (customer-of-record
// OR selling vendor/provider OR admin with the vertical's `view`
// permission) — this class never filters or authorizes client-side.
//
// Idempotency + unique numbering are the RPC's job: repeated calls for the
// same (vertical, source_id) always return the SAME invoice number, so it is
// safe to call this on every screen open / retry / app relaunch.
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';

import 'invoice.dart';

class InvoiceException implements Exception {
  final String message;
  const InvoiceException(this.message);
  @override
  String toString() => message;
}

class InvoiceRepository {
  InvoiceRepository(this._client);
  final SupabaseClient _client;

  Future<Invoice> fetch({
    required InvoiceVertical vertical,
    required String sourceId,
  }) async {
    if (_client.auth.currentSession == null) {
      throw const InvoiceException('Please sign in to view this invoice.');
    }
    try {
      final res = await _client.rpc('get_or_create_invoice', params: {
        'p_vertical': vertical.wire,
        'p_source_id': sourceId,
      });
      if (res is! Map) {
        throw const InvoiceException('This invoice could not be generated.');
      }
      return Invoice.fromJson(Map<String, dynamic>.from(res));
    } on InvoiceException {
      rethrow;
    } on PostgrestException catch (e) {
      throw InvoiceException(_map(e.message));
    } catch (_) {
      throw const InvoiceException(
        'Could not load this invoice. Please check your connection and try again.',
      );
    }
  }

  String _map(String message) {
    final m = message.toLowerCase();
    if (m.contains('not authorized')) {
      return 'You are not allowed to view this invoice.';
    }
    if (m.contains('not available yet')) {
      return 'The invoice is generated once the service is completed.';
    }
    if (m.contains('not found')) {
      return 'This order or booking could not be found.';
    }
    return 'Could not load this invoice. Please try again.';
  }
}
