// ============================================================================
// product_repository.dart
// ----------------------------------------------------------------------------
// Read-only, customer-facing product browsing against the *live* `products`
// schema. Column list re-verified column-by-column against production before
// this change: id, name, price, status, category, deleted_at, created_at,
// updated_at, vendor_id, category_id, description, unit, image_urls,
// discount_price, is_available, qc_status, publish_state, stock_quantity,
// branch_id, track_inventory (plus dimension / AI columns not needed here).
//
// `unit`, `discount_price`, `is_available`, `stock_quantity` and
// `track_inventory` ARE live columns now. An earlier revision of this file
// pre-dated them and hard-coded `unit` to '' and `discountPrice` to null;
// that is fixed here so real per-product variant text, MRP strike-through,
// discount % and out-of-stock state can surface on the catalog cards. They
// are selected via [_fullColumns] with the same defensive 42703 fall-back to
// [_baseColumns] this repo already uses, so a stripped-down environment that
// lacks one of them keeps working (the fields just fall back to their
// defaults).
//
// `vendor_id` is selected unconditionally: real checkout needs it to resolve
// which vendor/branch an order belongs to, so a product with no vendor can't
// usefully reach the cart at all.
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';

import 'catalog_coverage_filter.dart';
import 'coverage_repository.dart';

class ProductRow {
  final String id;
  final String name;
  final double price;
  final String category;
  final List<String> imageUrls;
  final String vendorId;

  /// Per-product variant / pack text, e.g. "500 g", "1 L", "1 pc". Empty
  /// when the vendor hasn't set one.
  final String unit;

  /// Live `products.discount_price`. Non-null and below [price] means the
  /// product is on offer; the plain [price] then acts as the struck-through
  /// MRP. Null (or >= price) means no discount — see [discountPrice].
  final double? discountPriceValue;

  /// Live `products.is_available` — the vendor's manual on/off switch for a
  /// product, independent of stock. Defaults to true when absent.
  final bool isAvailable;

  /// Live `products.stock_quantity` (null when not tracked / column absent).
  final int? stockQuantity;

  /// Live `products.track_inventory` — when true, [stockQuantity] gates
  /// availability; when false, stock is not counted.
  final bool trackInventory;

  const ProductRow({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.vendorId,
    this.imageUrls = const [],
    this.unit = '',
    this.discountPriceValue,
    this.isAvailable = true,
    this.stockQuantity,
    this.trackInventory = false,
  });

  String? get primaryImageUrl => imageUrls.isEmpty ? null : imageUrls.first;

  /// The active discount price, or null when the product is not discounted
  /// (a non-positive or >= MRP value counts as "no discount").
  double? get discountPrice {
    final d = discountPriceValue;
    if (d == null || d <= 0 || d >= price) return null;
    return d;
  }

  /// Whether a customer can add this product to the cart right now: the
  /// vendor switch is on AND (inventory isn't tracked OR there is stock).
  bool get inStock =>
      isAvailable && (!trackInventory || (stockQuantity ?? 0) > 0);

  String get displayPrice {
    final value = discountPrice ?? price;
    final rounded = value % 1 == 0
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
    return '₹$rounded';
  }

  factory ProductRow.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['price'];
    final rawDiscount = json['discount_price'];
    return ProductRow(
      id: json['id'] as String,
      name: json['name'] as String,
      price: rawPrice is num
          ? rawPrice.toDouble()
          : double.tryParse(rawPrice.toString()) ?? 0,
      category: json['category'] as String? ?? '',
      vendorId: json['vendor_id'] as String? ?? '',
      imageUrls: (json['image_urls'] as List?)?.cast<String>() ?? const [],
      unit: (json['unit'] as String?)?.trim() ?? '',
      discountPriceValue: rawDiscount is num
          ? rawDiscount.toDouble()
          : (rawDiscount == null
              ? null
              : double.tryParse(rawDiscount.toString())),
      isAvailable: json['is_available'] as bool? ?? true,
      stockQuantity: (json['stock_quantity'] as num?)?.toInt(),
      trackInventory: json['track_inventory'] as bool? ?? false,
    );
  }
}

class ProductRepository {
  ProductRepository(this._client, {CatalogCoverageFilter? coverageFilter})
      : _coverage = coverageFilter ??
            CatalogCoverageFilter.forVendors(CoverageRepository(_client));

  final SupabaseClient _client;

  /// Browse-time gate that hides vendors outside the customer's allowed
  /// coverage (india / state / district / radius). Applied to every
  /// customer-facing list this repository returns — home, category, list and
  /// search — so an out-of-coverage vendor's products never reach the UI,
  /// not merely the checkout. Fails open (see [CatalogCoverageFilter]).
  final CatalogCoverageFilter _coverage;

  static const String _table = 'products';
  static const String _fullColumns =
      'id, name, price, category, vendor_id, image_urls, unit, discount_price, '
      'is_available, stock_quantity, track_inventory';
  static const String _baseColumns = 'id, name, price, category, vendor_id';

  /// Products whose `category` text column matches one of [categoryNames]
  /// (the live schema links products to categories by name, not by a
  /// category_id FK — that column doesn't exist on `products`).
  Future<List<ProductRow>> fetchByCategoryNames(
    List<String> categoryNames, {
    int limit = 20,
  }) async {
    if (categoryNames.isEmpty) return [];
    return _fetch(
      (columns) => _baseQuery(columns)
          .inFilter('category', categoryNames)
          .order('created_at', ascending: false)
          .limit(limit),
    );
  }

  /// All customer-visible products, no category filter — for surfaces like
  /// "Trending" or "Featured" that browse the whole catalog.
  Future<List<ProductRow>> fetchAll({int limit = 20}) async {
    return _fetch(
      (columns) => _baseQuery(
        columns,
      ).order('created_at', ascending: false).limit(limit),
    );
  }

  /// [build] must construct a fresh filter chain each call — a
  /// PostgrestFilterBuilder is single-use, so the fallback attempt below
  /// needs its own instance. Tries the full column set first; falls back to
  /// the base set if any additive column isn't migrated in yet, same pattern
  /// this app's category repository uses for `display_order`.
  ///
  /// Every customer-facing list goes through here, so browse-time vendor
  /// coverage filtering is applied in exactly one place (covers home,
  /// category, list and search).
  Future<List<ProductRow>> _fetch(
    PostgrestTransformBuilder<PostgrestList> Function(String columns) build,
  ) async {
    List<ProductRow> mapped;
    try {
      mapped = _mapRows(await build(_fullColumns));
    } on PostgrestException catch (error) {
      if (error.code != '42703') rethrow;
      mapped = _mapRows(await build(_baseColumns));
    }
    return _coverage.apply(mapped, (row) => row.vendorId);
  }

  /// Resolves [categoryName] (case-insensitive) to a category (and its
  /// subcategories, if any) and returns that category's customer-visible
  /// products. Returns an empty list if no matching category exists,
  /// rather than throwing — a bad/unknown name is a legitimate empty
  /// result for a browsing screen, not an error.
  Future<List<ProductRow>> fetchByCategoryName(
    String categoryName, {
    int limit = 20,
  }) async {
    final matches = await _client
        .from('categories')
        .select('id, name')
        .ilike('name', categoryName);
    final matchedNames = (matches as List<dynamic>)
        .map((row) => row['name'] as String)
        .toList();
    final matchedIds = matches.map((row) => row['id'] as String).toList();
    if (matchedNames.isEmpty) return [];

    final subcategories = await _client
        .from('categories')
        .select('name')
        .inFilter('parent_category_id', matchedIds);
    final subcategoryNames = (subcategories as List<dynamic>)
        .map((row) => row['name'] as String)
        .toList();

    return fetchByCategoryNames([
      ...matchedNames,
      ...subcategoryNames,
    ], limit: limit);
  }

  /// Customer-visible products sold by one vendor — backs the Vendor / Store
  /// Details screen (reached from a product card or a past order). Goes
  /// through the same [_fetch] path so browse-time coverage filtering still
  /// applies; an unknown / empty vendor id yields an empty list, not an
  /// error.
  Future<List<ProductRow>> fetchByVendorId(String vendorId, {int limit = 50}) async {
    if (vendorId.trim().isEmpty) return const [];
    return _fetch(
      (columns) => _baseQuery(columns)
          .eq('vendor_id', vendorId)
          .order('created_at', ascending: false)
          .limit(limit),
    );
  }

  /// Customer-visible products whose name matches [query] (case-insensitive,
  /// substring match) — backs the Search screen. Empty/whitespace-only
  /// queries return no results rather than the whole catalog.
  Future<List<ProductRow>> searchByName(String query, {int limit = 30}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];
    return _fetch(
      (columns) => _baseQuery(columns)
          .ilike('name', '%$trimmed%')
          .order('created_at', ascending: false)
          .limit(limit),
    );
  }

  PostgrestFilterBuilder<PostgrestList> _baseQuery(String columns) {
    return _client
        .from(_table)
        .select(columns)
        .eq('status', 'active')
        .isFilter('deleted_at', null);
  }

  List<ProductRow> _mapRows(dynamic rows) {
    return (rows as List<dynamic>)
        .map((row) => ProductRow.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}
