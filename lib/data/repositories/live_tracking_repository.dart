// ============================================================================
// live_tracking_repository.dart
// ----------------------------------------------------------------------------
// Read-only polling of a Delivery Partner's current location while an order
// is out for delivery — backed by `delivery_partner_locations`
// (snapbee_admin/supabase/delivery_partner_system.sql §7), gated by the
// existing `delivery_partner_locations_customer_self_select` RLS policy
// (only visible while the partner is on one of THIS customer's own active
// orders — never standing visibility into any partner). No maps/geocoding
// API key exists anywhere in this monorepo (see checkout_screen.dart's own
// doc comment), so this surfaces raw coordinates + a relative "last
// updated" label rather than a map — same v1 "polling, not Realtime, no
// map" convention `phase14_delivery_backend_schema.sql` already established
// for every other app.
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';

class PartnerLocation {
  final String partnerName;
  final String? partnerPhone;
  final double lat;
  final double lng;
  final DateTime recordedAt;

  const PartnerLocation({
    required this.partnerName,
    this.partnerPhone,
    required this.lat,
    required this.lng,
    required this.recordedAt,
  });

  factory PartnerLocation.fromJson(Map<String, dynamic> json) {
    final partner = json['delivery_partners'] as Map<String, dynamic>?;
    return PartnerLocation(
      partnerName: (partner?['name'] as String?) ?? 'Your delivery partner',
      partnerPhone: partner?['mobile_number'] as String?,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      recordedAt: DateTime.parse(json['recorded_at'] as String),
    );
  }
}

class LiveTrackingRepository {
  LiveTrackingRepository(this._client);

  final SupabaseClient _client;

  /// Returns null (never throws) if the partner has no recorded location
  /// yet, or RLS doesn't currently permit seeing it (order no longer
  /// active) — both are ordinary "nothing to show yet" states, not errors.
  Future<PartnerLocation?> fetchPartnerLocation(String deliveryPartnerId) async {
    try {
      final row = await _client
          .from('delivery_partner_locations')
          .select('lat, lng, recorded_at, delivery_partners(name, mobile_number)')
          .eq('delivery_partner_id', deliveryPartnerId)
          .maybeSingle();
      if (row == null) return null;
      return PartnerLocation.fromJson(Map<String, dynamic>.from(row));
    } catch (_) {
      return null;
    }
  }
}
