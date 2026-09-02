// ============================================================================
// coverage_repository.dart
// ----------------------------------------------------------------------------
// Thin wrapper over the two server-side coverage RPCs — the ONLY authorities
// on which vendors a browsing customer is allowed to see. The customer app
// never re-implements the coverage rules (india / state / district /
// radius); it just intersects these id sets with the products / providers it
// already fetches.
//
//   - vendor_ids_in_coverage           (snapbee_admin/supabase/vendor_coverage_config.sql)
//       Daily Essentials: products -> vendors -> vendor_branches
//       (reuses vendor_branches.latitude/longitude/delivery_radius_km).
//   - service_vendor_ids_in_coverage   (snapbee_admin/supabase/services_coverage_config.sql)
//       Services: service provider listings -> service_vendors -> service_areas
//       (reuses service_areas.center_lat/center_lng/radius_km/pincodes).
//
// No duplicate location system is created here — both RPCs read columns that
// already existed.
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';

class CoverageRepository {
  CoverageRepository(this._client);

  final SupabaseClient _client;

  /// Daily Essentials vendor ids in coverage for this customer signal.
  ///
  /// Returns `null` (not an empty set) when the RPC isn't deployed yet
  /// (`vendor_coverage_config.sql` not applied) so callers can fail OPEN —
  /// a missing migration must never blank the whole catalog. A real empty
  /// result is returned as an empty set (and DOES hide every vendor — that
  /// is the point of the feature).
  Future<Set<String>?> fetchCoveredVendorIds({
    double? lat,
    double? lng,
    String? state,
    String? district,
  }) {
    return _idSet('vendor_ids_in_coverage', {
      'p_lat': lat,
      'p_lng': lng,
      'p_state': state,
      'p_district': district,
    }, missingMarker: 'vendor_ids_in_coverage');
  }

  /// Services provider (`service_vendors.id`) set in coverage for this
  /// customer signal. Same null-means-fail-open contract as above
  /// (`services_coverage_config.sql` not applied yet).
  Future<Set<String>?> fetchCoveredServiceVendorIds({
    double? lat,
    double? lng,
    String? state,
    String? district,
    String? pincode,
  }) {
    return _idSet('service_vendor_ids_in_coverage', {
      'p_lat': lat,
      'p_lng': lng,
      'p_state': state,
      'p_district': district,
      'p_pincode': pincode,
    }, missingMarker: 'service_vendor_ids_in_coverage');
  }

  Future<Set<String>?> _idSet(
    String rpc,
    Map<String, dynamic> params, {
    required String missingMarker,
  }) async {
    try {
      final rows = await _client.rpc(rpc, params: params);
      if (rows is! List) return <String>{};
      return {
        for (final r in rows)
          if (r is Map && r['vendor_id'] != null)
            r['vendor_id'].toString()
          else if (r is String)
            r,
      };
    } on PostgrestException catch (error) {
      final msg = error.toString().toLowerCase();
      final missing = error.code == 'PGRST202' ||
          error.code == '42883' ||
          msg.contains(missingMarker) ||
          msg.contains('could not find the function') ||
          msg.contains('does not exist');
      if (missing) return null;
      rethrow;
    }
  }
}
