// ============================================================================
// vendor_repository.dart
// ----------------------------------------------------------------------------
// Read-only, customer-facing store browsing against the live `vendors`
// table. The `vendors_public_select` RLS policy (is_vendor_customer_visible(id))
// is the real visibility boundary — this repo just selects and maps, then
// runs the same browse-time coverage gate the product catalog uses so an
// out-of-coverage store never appears on Home.
//
// The base card fields (id, name, city, district, logo_url, cover_image_url)
// come straight off `vendors`. Three optional display fields are then
// enriched in from other live, customer-readable tables and are ONLY shown
// when real data backs them (never fabricated):
//   * offerPercent    ← max(vendor_delivery_settings.offer_percent) across
//                        the store's branches
//   * deliveryEnabled ← any branch has delivery_enabled = true
//   * ratingAvg/Count ← avg(de_order_reviews.rating) for the vendor
// Daily Essentials still has no delivery-ETA source, so the card shows no
// "x mins" line — that would be invented data.
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';

import 'catalog_coverage_filter.dart';
import 'coverage_repository.dart';

class VendorRow {
  final String id;
  final String name;
  final String city;
  final String district;
  final String? logoUrl;
  final String? coverImageUrl;

  /// Best current offer % across the store's delivery settings, or null
  /// when the store has no offer configured.
  final double? offerPercent;

  /// True when at least one of the store's branches has delivery enabled.
  /// Null when unknown (enrichment failed / not loaded).
  final bool? deliveryEnabled;

  /// Average customer rating (1–5) from delivered-order reviews, or null
  /// when the store has no reviews yet.
  final double? ratingAvg;

  /// Number of reviews behind [ratingAvg].
  final int ratingCount;

  const VendorRow({
    required this.id,
    required this.name,
    this.city = '',
    this.district = '',
    this.logoUrl,
    this.coverImageUrl,
    this.offerPercent,
    this.deliveryEnabled,
    this.ratingAvg,
    this.ratingCount = 0,
  });

  /// Best image to show on a store card: cover first, then logo, else null
  /// (the card falls back to an icon placeholder).
  String? get displayImageUrl {
    if ((coverImageUrl ?? '').isNotEmpty) return coverImageUrl;
    if ((logoUrl ?? '').isNotEmpty) return logoUrl;
    return null;
  }

  /// "City · District" with the empty parts trimmed out.
  String get areaLabel {
    final parts = [city.trim(), district.trim()]
        .where((p) => p.isNotEmpty)
        .toSet()
        .toList();
    return parts.join(' · ');
  }

  /// Whether this card has a real offer worth badging.
  bool get hasOffer => (offerPercent ?? 0) > 0;

  /// Whether this card has a real rating worth showing.
  bool get hasRating => ratingCount > 0 && (ratingAvg ?? 0) > 0;

  VendorRow copyWith({
    double? offerPercent,
    bool? deliveryEnabled,
    double? ratingAvg,
    int? ratingCount,
  }) {
    return VendorRow(
      id: id,
      name: name,
      city: city,
      district: district,
      logoUrl: logoUrl,
      coverImageUrl: coverImageUrl,
      offerPercent: offerPercent ?? this.offerPercent,
      deliveryEnabled: deliveryEnabled ?? this.deliveryEnabled,
      ratingAvg: ratingAvg ?? this.ratingAvg,
      ratingCount: ratingCount ?? this.ratingCount,
    );
  }

  factory VendorRow.fromJson(Map<String, dynamic> json) {
    return VendorRow(
      id: json['id'] as String,
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? json['name'] as String
          : 'Store',
      city: json['city'] as String? ?? '',
      district: json['district'] as String? ?? '',
      logoUrl: json['logo_url'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
    );
  }
}

class VendorRepository {
  VendorRepository(this._client, {CatalogCoverageFilter? coverageFilter})
      : _coverage = coverageFilter ??
            CatalogCoverageFilter.forVendors(CoverageRepository(_client));

  final SupabaseClient _client;

  /// Browse-time coverage gate (india / state / district / radius), same one
  /// the product catalog uses. Fails open (see [CatalogCoverageFilter]).
  final CatalogCoverageFilter _coverage;

  static const String _table = 'vendors';
  static const String _columns =
      'id, name, city, district, logo_url, cover_image_url';

  /// Customer-visible Daily Essentials stores — backs the "Popular Stores
  /// Near You" row on Home. RLS (`vendors_public_select`) already restricts
  /// this to stores that reached a customer-visible production state; the
  /// coverage filter then drops any that are outside the browsing
  /// customer's allowed area. Returns an empty list (never throws) on any
  /// failure or when the table isn't reachable yet.
  Future<List<VendorRow>> fetchCustomerVisibleStores({int limit = 12}) async {
    try {
      final rows = await _client
          .from(_table)
          .select(_columns)
          .eq('status', 'active')
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false)
          .limit(limit);
      final mapped = (rows as List)
          .map((r) => VendorRow.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
      final visible = await _coverage.apply(mapped, (v) => v.id);
      return _enrich(visible);
    } catch (_) {
      return const [];
    }
  }

  /// Resolves a set of vendor ids to their names (respecting the same
  /// `vendors_public_select` RLS). Used to label the store a product on the
  /// Home "Products For You" row is sold by. Returns `{}` on any failure.
  Future<Map<String, String>> fetchNamesByIds(Iterable<String> ids) async {
    final list = ids.where((e) => e.trim().isNotEmpty).toSet().toList();
    if (list.isEmpty) return const {};
    try {
      final rows =
          await _client.from(_table).select('id, name').inFilter('id', list);
      return {
        for (final r in (rows as List))
          (r as Map)['id'] as String: (r['name'] as String?)?.trim() ?? '',
      };
    } catch (_) {
      return const {};
    }
  }

  /// Attaches the optional display fields (offer %, delivery-enabled,
  /// rating) to [stores] from their own live, customer-readable tables.
  /// Every step fails open: on any error the store simply keeps its base
  /// fields and the card renders name + area only, exactly as before.
  Future<List<VendorRow>> _enrich(List<VendorRow> stores) async {
    if (stores.isEmpty) return stores;
    final ids = stores.map((s) => s.id).toList();
    final offers = await _fetchOffers(ids);
    final ratings = await _fetchRatings(ids);
    if (offers.isEmpty && ratings.isEmpty) return stores;
    return [
      for (final s in stores)
        s.copyWith(
          offerPercent: offers[s.id]?.percent,
          deliveryEnabled: offers[s.id]?.deliveryEnabled,
          ratingAvg: ratings[s.id]?.avg,
          ratingCount: ratings[s.id]?.count ?? 0,
        ),
    ];
  }

  Future<Map<String, ({double? percent, bool deliveryEnabled})>> _fetchOffers(
    List<String> vendorIds,
  ) async {
    try {
      final branches = await _client
          .from('vendor_branches')
          .select('id, vendor_id')
          .inFilter('vendor_id', vendorIds)
          .isFilter('deleted_at', null);
      final branchToVendor = <String, String>{};
      for (final b in (branches as List)) {
        final m = b as Map;
        branchToVendor[m['id'] as String] = m['vendor_id'] as String;
      }
      if (branchToVendor.isEmpty) return const {};

      final settings = await _client
          .from('vendor_delivery_settings')
          .select('branch_id, offer_percent, delivery_enabled')
          .inFilter('branch_id', branchToVendor.keys.toList());

      final out = <String, ({double? percent, bool deliveryEnabled})>{};
      for (final s in (settings as List)) {
        final m = s as Map;
        final vid = branchToVendor[m['branch_id'] as String];
        if (vid == null) continue;
        final pct = (m['offer_percent'] as num?)?.toDouble();
        final enabled = m['delivery_enabled'] as bool? ?? false;
        final prev = out[vid];
        var bestPct = prev?.percent;
        if (pct != null && (bestPct == null || pct > bestPct)) {
          bestPct = pct;
        }
        out[vid] = (
          percent: bestPct,
          deliveryEnabled: (prev?.deliveryEnabled ?? false) || enabled,
        );
      }
      return out;
    } catch (_) {
      return const {};
    }
  }

  Future<Map<String, ({double avg, int count})>> _fetchRatings(
    List<String> vendorIds,
  ) async {
    try {
      final rows = await _client
          .from('de_order_reviews')
          .select('vendor_id, rating')
          .inFilter('vendor_id', vendorIds);
      final sums = <String, double>{};
      final counts = <String, int>{};
      for (final r in (rows as List)) {
        final m = r as Map;
        final vid = m['vendor_id'] as String?;
        final rating = (m['rating'] as num?)?.toDouble();
        if (vid == null || rating == null) continue;
        sums[vid] = (sums[vid] ?? 0) + rating;
        counts[vid] = (counts[vid] ?? 0) + 1;
      }
      return {
        for (final vid in counts.keys)
          vid: (avg: sums[vid]! / counts[vid]!, count: counts[vid]!),
      };
    } catch (_) {
      return const {};
    }
  }
}
