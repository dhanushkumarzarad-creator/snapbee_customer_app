// ============================================================================
// offer_repository.dart
// ----------------------------------------------------------------------------
// Real, read-only data for the Offer Zone tab. Three independent sources,
// each degrades to an empty list on its own so one missing table/column
// never blanks the whole screen:
//
//   heroBanners     <- public.cms_banners  (customer-readable subset added by
//                      snapbee_admin/supabase/customer_offer_visibility.sql:
//                      status='active', not deleted, inside start/end window)
//   coupons         <- public.coupons      (same customer-readable subset)
//   specialOffers   <- public.products     (products_public_select RLS) whose
//                      discount_price is set and below price
//
// Replaces the old lib/screens/offers/dummy_offer_data.dart.
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../screens/offers/offer_models.dart';
import 'catalog_coverage_filter.dart';
import 'coverage_repository.dart';

/// The three reads the Offer Zone screen depends on. Kept as an interface so
/// the screen can be widget-tested with a fake.
abstract class OfferSource {
  Future<List<OfferBannerModel>> fetchHeroBanners({int limit});
  Future<List<SpecialOfferProduct>> fetchSpecialOffers({int limit});
  Future<List<QuickOfferModel>> fetchCoupons({int limit});
}

class OfferRepository implements OfferSource {
  OfferRepository(this._client, {CatalogCoverageFilter? coverageFilter})
      : _coverage = coverageFilter ??
            CatalogCoverageFilter.forVendors(CoverageRepository(_client));

  final SupabaseClient _client;

  /// The Offer Zone's special-offers list is a customer-facing product browse
  /// surface, so it goes through the same browse-time vendor coverage gate as
  /// the rest of the catalogue (Home / category / list / search). Fails open
  /// (see [CatalogCoverageFilter]). Hero banners and coupons are not
  /// vendor-scoped and are left unfiltered.
  final CatalogCoverageFilter _coverage;

  /// Active, in-window banners with an image. Empty list on any failure.
  @override
  Future<List<OfferBannerModel>> fetchHeroBanners({int limit = 6}) async {
    try {
      final rows = await _client
          .from('cms_banners')
          .select('id, title, image_url, target_url')
          .order('start_date', ascending: false)
          .limit(limit);
      return (rows as List)
          .map((r) => r as Map<String, dynamic>)
          .where((r) => (r['image_url'] as String?)?.isNotEmpty ?? false)
          .map(
            (r) => OfferBannerModel(
              id: r['id'] as String,
              imageUrl: r['image_url'] as String,
              title: (r['title'] as String?) ?? '',
            ),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Active, in-window coupon codes, mapped to the small promo tiles. Empty
  /// list on any failure.
  @override
  Future<List<QuickOfferModel>> fetchCoupons({int limit = 10}) async {
    try {
      final rows = await _client
          .from('coupons')
          .select('id, code, description, discount')
          .order('end_date', ascending: true)
          .limit(limit);
      return (rows as List).map((raw) {
        final r = raw as Map<String, dynamic>;
        final discount = (r['discount'] as num?)?.toDouble() ?? 0;
        final desc = (r['description'] as String?)?.trim();
        return QuickOfferModel(
          id: r['id'] as String,
          title: r['code'] as String,
          tagText: (desc != null && desc.isNotEmpty)
              ? desc
              : (discount > 0 ? '${discount.toStringAsFixed(0)}% OFF' : 'OFFER'),
          iconAsset: '',
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Customer-visible products with a real discount (`discount_price` set and
  /// below `price`). Empty list if the column isn't present or nothing is
  /// discounted.
  @override
  Future<List<SpecialOfferProduct>> fetchSpecialOffers({int limit = 12}) async {
    try {
      final rows = await _client
          .from('products')
          .select('id, name, price, discount_price, unit, vendor_id, image_urls')
          .eq('status', 'active')
          .isFilter('deleted_at', null)
          .not('discount_price', 'is', null)
          .order('updated_at', ascending: false)
          .limit(limit);
      final offers = (rows as List)
          .map((raw) => raw as Map<String, dynamic>)
          .map(_mapSpecialOffer)
          .where((p) => p != null)
          .cast<SpecialOfferProduct>()
          .toList();
      return _coverage.apply(offers, (p) => p.vendorId);
    } on PostgrestException catch (error) {
      // discount_price column not migrated in yet -> no special offers.
      if (error.code == '42703') return const [];
      return const [];
    } catch (_) {
      return const [];
    }
  }

  SpecialOfferProduct? _mapSpecialOffer(Map<String, dynamic> r) {
    final price = (r['price'] as num?)?.toDouble() ?? 0;
    final discount = (r['discount_price'] as num?)?.toDouble();
    if (discount == null || discount <= 0 || discount >= price) return null;
    final images = (r['image_urls'] as List?)?.cast<String>() ?? const [];
    return SpecialOfferProduct(
      id: r['id'] as String,
      name: (r['name'] as String?) ?? '',
      imageUrl: images.isEmpty ? '' : images.first,
      offerPrice: discount,
      oldPrice: price,
      vendorId: (r['vendor_id'] as String?) ?? '',
      unit: (r['unit'] as String?) ?? '',
    );
  }
}
