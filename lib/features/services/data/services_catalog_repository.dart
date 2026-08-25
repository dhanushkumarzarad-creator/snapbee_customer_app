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

import '../models/service.dart';
import '../models/service_category.dart';
import '../models/service_offer.dart';
import '../models/service_vendor.dart';
import '../models/service_vendor_summary.dart';

class ServicesCatalogRepository {
  ServicesCatalogRepository(this._client);

  final SupabaseClient _client;

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

  Future<List<ServiceRow>> fetchServices(String categoryId) async {
    try {
      final rows = await _client
          .from('services')
          .select('*')
          .eq('category_id', categoryId)
          .order('display_order', ascending: true)
          .order('name');
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
      return (rows as List).map((r) => ServiceVendorSummary.fromJson(Map<String, dynamic>.from(r as Map))).toList();
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
      return (rows as List)
          .map((r) => ServiceVendorListing.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList()
        ..sort((a, b) => b.ratingAvg.compareTo(a.ratingAvg));
    } catch (_) {
      return const [];
    }
  }
}
