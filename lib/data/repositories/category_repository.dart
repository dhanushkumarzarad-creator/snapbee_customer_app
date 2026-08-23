// ============================================================================
// category_repository.dart
// ----------------------------------------------------------------------------
// Read-only access to the real `categories` table — Admin (snapbee_admin's
// Categories & Products screen) is the sole source of truth. Nothing here
// hard-codes category names/images/ids; every row displayed comes from this
// query. Mirrors customer_repository.dart's convention: a plain class
// wrapping SupabaseClient, no state-management framework.
//
// `display_order` is an optional column Admin can set to control category
// ordering (snapbee_admin/supabase/categories_display_order.sql — additive,
// reviewed but not yet applied at time of writing). Since this app must
// never reproduce the "column does not exist" outage the whole categories
// feature already went through once, ordering by it is attempted first and
// falls back to ordering by `name` alone if the column isn't there yet.
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';

class CategoryRow {
  final String id;
  final String name;
  final String? description;
  final String status;
  final String? imageUrl;
  final String? parentCategoryId;

  const CategoryRow({
    required this.id,
    required this.name,
    this.description,
    required this.status,
    this.imageUrl,
    this.parentCategoryId,
  });

  factory CategoryRow.fromJson(Map<String, dynamic> json) => CategoryRow(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    status: json['status'] as String,
    imageUrl: json['image_url'] as String?,
    parentCategoryId: json['parent_category_id'] as String?,
  );
}

class CategoryRepository {
  CategoryRepository(this._client);

  final SupabaseClient _client;

  static const String _table = 'categories';
  static const String _columns =
      'id, name, description, status, image_url, parent_category_id';

  /// All active categories — the left-rail / grid entry points. Only
  /// filters on `status`, since that's the one column confirmed to match
  /// the live data; no `parent_category_id`/`deleted_at` filtering, which
  /// previously excluded rows that don't fit those assumptions.
  Future<List<CategoryRow>> fetchTopLevelCategories() {
    return _orderedFetch(
      () => _client.from(_table).select(_columns).eq('status', 'active'),
    );
  }

  /// Subcategories of [parentId] — "Shop by Category" within a category.
  Future<List<CategoryRow>> fetchSubcategories(String parentId) {
    return _orderedFetch(
      () => _client
          .from(_table)
          .select(_columns)
          .eq('parent_category_id', parentId)
          .eq('status', 'active'),
    );
  }

  /// [build] must construct a fresh filter chain each call — a
  /// PostgrestFilterBuilder is single-use, so the fallback attempt below
  /// needs its own instance rather than reusing one that already threw.
  Future<List<CategoryRow>> _orderedFetch(
    PostgrestFilterBuilder<PostgrestList> Function() build,
  ) async {
    List<dynamic> rows;
    try {
      rows = await build()
          .order('display_order', ascending: true, nullsFirst: false)
          .order('name');
    } on PostgrestException catch (error) {
      if (error.code != '42703') rethrow;
      rows = await build().order('name');
    }
    return rows
        .map((row) => CategoryRow.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}
