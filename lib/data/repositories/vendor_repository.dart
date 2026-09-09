// ============================================================================
// vendor_repository.dart
// ----------------------------------------------------------------------------
// Read-only, customer-facing store browsing against the live `vendors`
// table. The `vendors_public_select` RLS policy (is_vendor_customer_visible(id))
// is the real visibility boundary — this repo just selects and maps, then
// runs the same browse-time coverage gate the product catalog uses so an
// out-of-coverage store never appears on Home.
//
// Columns selected are the customer-safe subset only: id, name, city,
// district, logo_url, cover_image_url. No ratings / ETA / delivery-threshold
// columns exist for Daily Essentials yet, so this model does not carry (and
// the UI does not fabricate) them — same discipline as ProductModel's
// rating staying 0 and VendorStoreScreen's honest empty reviews state.
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

  const VendorRow({
    required this.id,
    required this.name,
    this.city = '',
    this.district = '',
    this.logoUrl,
    this.coverImageUrl,
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
      return _coverage.apply(mapped, (v) => v.id);
    } catch (_) {
      return const [];
    }
  }
}
