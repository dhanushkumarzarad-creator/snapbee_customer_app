// ============================================================================
// services_catalog_repository.dart
// ----------------------------------------------------------------------------
// Read-only catalog access for the Services sector — categories, services,
// offers, and (new) verified-vendor listings per service. Backed by
// snapbee_admin/supabase/services_module_v2.sql. Deliberately separate from
// services_booking_repository.dart (browsing vs. the authenticated booking
// lifecycle) and from every Daily Essentials repository — Services never
// reads/writes `categories`/`products`/`vendors`.
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/location/customer_coverage_context.dart';
import '../../../data/repositories/catalog_coverage_filter.dart';
import '../../../data/repositories/coverage_repository.dart';
import '../models/service.dart';
import '../models/service_category.dart';
import '../models/service_method.dart';
import '../models/service_offer.dart';
import '../models/service_review.dart';
import '../models/service_subcategory.dart';
import '../models/service_vendor.dart';
import '../models/service_vendor_summary.dart';

class ServicesCatalogRepository {
  ServicesCatalogRepository(this._client, {CatalogCoverageFilter? coverageFilter})
      : _coverage = coverageFilter ??
            CatalogCoverageFilter.forServiceVendors(CoverageRepository(_client));

  final SupabaseClient _client;

  /// Browse-time gate that hides service providers outside the customer's
  /// allowed coverage (india / state / district / radius, backed by
  /// `service_areas` via `service_vendor_ids_in_coverage`). Applied to the
  /// customer-facing provider listings below so an out-of-coverage provider
  /// never appears in a list — not merely at booking. Fails open (see
  /// [CatalogCoverageFilter]).
  final CatalogCoverageFilter _coverage;

  Future<List<ServiceCategoryRow>> fetchCategories() async {
    try {
      final rows = await _client
          .from('service_categories')
          .select('*')
          .order('display_order', ascending: true)
          .order('name');
      return (rows as List).map((r) => ServiceCategoryRow.fromJson(Map<String, dynamic>.from(r as Map))).toList();
    } catch (_) {
      return const [];
    }
  }

  /// The middle level of the finalized Services hierarchy
  /// (Category -> Subcategory -> Service -> Vendor -> Method). A category
  /// with zero active subcategories is browsed straight to its service
  /// list, so this returns an empty list rather than being a dead end.
  /// Backed by `service_subcategories_public_select` RLS
  /// (services_module_v2.sql SECTION 1).
  Future<List<ServiceSubcategoryRow>> fetchSubcategories(String categoryId) async {
    try {
      final rows = await _client
          .from('service_subcategories')
          .select('*')
          .eq('category_id', categoryId)
          .order('display_order', ascending: true)
          .order('name');
      return (rows as List)
          .map((r) => ServiceSubcategoryRow.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Services in a category, optionally narrowed to one [subcategoryId]
  /// (the Category -> Subcategory -> Service step). `services.subcategory_id`
  /// is nullable, so a category whose services aren't sub-categorised yet
  /// still lists them when no [subcategoryId] is passed.
  Future<List<ServiceRow>> fetchServices(String categoryId, {String? subcategoryId}) async {
    try {
      var query = _client.from('services').select('*').eq('category_id', categoryId);
      if (subcategoryId != null) query = query.eq('subcategory_id', subcategoryId);
      final rows = await query.order('display_order', ascending: true).order('name');
      return (rows as List).map((r) => ServiceRow.fromJson(Map<String, dynamic>.from(r as Map))).toList();
    } catch (_) {
      return const [];
    }
  }

  /// A single service by id — used to resolve a `service_offers.service_id`
  /// into the real `ServiceRow` it discounts, so an offer card can navigate
  /// straight to that service's detail page instead of being a dead tap.
  Future<ServiceRow?> fetchServiceById(String id) async {
    try {
      final row = await _client.from('services').select('*').eq('id', id).maybeSingle();
      if (row == null) return null;
      return ServiceRow.fromJson(Map<String, dynamic>.from(row));
    } catch (_) {
      return null;
    }
  }

  /// A single category by id — used to resolve a `service_offers.category_id`
  /// (a category-wide offer with no specific `service_id`) into the real
  /// `ServiceCategoryRow` it discounts, for the same offer-card navigation.
  Future<ServiceCategoryRow?> fetchCategoryById(String id) async {
    try {
      final row = await _client.from('service_categories').select('*').eq('id', id).maybeSingle();
      if (row == null) return null;
      return ServiceCategoryRow.fromJson(Map<String, dynamic>.from(row));
    } catch (_) {
      return null;
    }
  }

  /// A handful of active services across all categories, for the "Popular
  /// Services" section on Services Home. No engagement-based ranking data
  /// exists anywhere in this schema (no booking-count/view-count column),
  /// so this is honestly just "recently added, active" — not a fabricated
  /// popularity signal.
  Future<List<ServiceRow>> fetchPopularServices({int limit = 8}) async {
    try {
      final rows = await _client
          .from('services')
          .select('*')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(limit);
      return (rows as List).map((r) => ServiceRow.fromJson(Map<String, dynamic>.from(r as Map))).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Real, general-purpose "Trusted Providers" listing for Services Home —
  /// approved+active vendors ordered by rating, not scoped to any one
  /// service. Backed directly by `service_vendors_public_select` RLS
  /// (services_module_v2.sql SECTION 22).
  Future<List<ServiceVendorSummary>> fetchTopRatedVendors({int limit = 8}) async {
    try {
      final rows = await _client
          .from('service_vendors')
          .select('id, business_name, business_type, rating_avg, rating_count')
          .order('rating_avg', ascending: false)
          .limit(limit);
      final vendors = (rows as List)
          .map((r) => ServiceVendorSummary.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
      return _coverage.apply(vendors, (v) => v.id);
    } catch (_) {
      return const [];
    }
  }

  Future<List<ServiceOfferRow>> fetchOffers() async {
    try {
      final rows = await _client
          .from('service_offers')
          .select('*')
          .eq('is_active', true)
          .order('created_at', ascending: false);
      return (rows as List).map((r) => ServiceOfferRow.fromJson(Map<String, dynamic>.from(r as Map))).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Reviews left by other customers for completed bookings of this
  /// service. Needs `service_reviews_public_select` RLS
  /// (supabase/service_reviews_public_read.sql) — until that's applied the
  /// join returns nothing and this degrades to an empty list, exactly like
  /// every other read here.
  Future<List<ServiceReview>> fetchServiceReviews(String serviceId, {int limit = 20}) async {
    try {
      final rows = await _client
          .from('service_reviews')
          .select('rating, review_text, created_at, service_bookings!inner(service_id, status), customers(name)')
          .eq('service_bookings.service_id', serviceId)
          .eq('service_bookings.status', 'completed')
          .order('created_at', ascending: false)
          .limit(limit);
      return (rows as List).map((r) => ServiceReview.fromJson(Map<String, dynamic>.from(r as Map))).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Verified providers offering a given service — reads `service_pricing`
  /// (admin-approved rows only, via `service_pricing_public_select` RLS)
  /// joined with `service_vendors` (approved/active only, via
  /// `service_vendors_public_select` RLS). A service with zero approved
  /// vendor pricing yet returns an empty list — never a fabricated "no
  /// providers" placeholder row.
  Future<List<ServiceVendorListing>> fetchVerifiedProviders(String serviceId) async {
    try {
      final rows = await _client
          .from('service_pricing')
          .select('price, service_vendors(id, business_name, business_type, rating_avg, rating_count)')
          .eq('service_id', serviceId)
          .eq('status', 'approved');
      final providers = (rows as List)
          .map((r) => ServiceVendorListing.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList()
        ..sort((a, b) => b.ratingAvg.compareTo(a.ratingAvg));
      return _coverage.apply(providers, (p) => p.vendorId);
    } catch (_) {
      return const [];
    }
  }

  /// NEW Services Master Method architecture — the bookable delivery methods
  /// for a service (across every eligible provider), via the
  /// `browse_service_methods` RPC
  /// (snapbee_admin/supabase/services_method_architecture_customer_browse.sql).
  ///
  /// The RPC is the sole authority on method visibility and availability:
  /// approved+active provider, live + vendor-enabled config, the
  /// method-specific radius rule (a method the customer is provably outside
  /// of is not returned at all — distinct from the vendor's overall
  /// radius), and the "still listed but not bookable" state for an
  /// emergency-disabled method or an auto-restricted config. This method
  /// only forwards the customer's browse-time location (reusing the shared
  /// [CustomerCoverageContext] every other Services list already uses) so
  /// the server can apply that per-method radius rule, then maps the rows.
  ///
  /// Pass [subcategoryId] to scope to one subcategory, or [vendorId] to
  /// scope to one provider's methods (the vendor-profile case — "each
  /// service listed individually with its own methods"): the RPC has no
  /// vendor parameter, so that one filters client-side after the fetch.
  ///
  /// The RPC applies the per-method RADIUS rule server-side; the other
  /// three coverage modes (india / state / district) are applied here via
  /// the same [_coverage] gate every other Services listing uses, so an
  /// out-of-coverage provider's methods never appear either. Both fail OPEN.
  ///
  /// Fails soft to an empty list — RPC not deployed, transport error, or
  /// simply no method configs live yet — exactly like every other read in
  /// this repository. The caller keeps the legacy verified-provider list as
  /// the fallback surface so the screen never regresses to blank.
  Future<List<ServiceMethodRow>> fetchServiceMethods({
    String? serviceId,
    String? categoryId,
    String? subcategoryId,
    String? vendorId,
    String languageCode = 'en',
  }) async {
    try {
      final signal = await CustomerCoverageContext.instance.resolve();
      final result = await _client.rpc('browse_service_methods', params: {
        'p_category_id': categoryId,
        'p_service_id': serviceId,
        'p_subcategory_id': subcategoryId,
        'p_lat': signal.lat,
        'p_lng': signal.lng,
        'p_language_code': languageCode,
      });
      if (result is! List) return const [];
      var methods = result
          .map((r) => ServiceMethodRow.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
      if (vendorId != null) {
        methods = methods.where((m) => m.vendorId == vendorId).toList();
      }
      return _coverage.apply(methods, (m) => m.vendorId);
    } catch (_) {
      return const [];
    }
  }
}
