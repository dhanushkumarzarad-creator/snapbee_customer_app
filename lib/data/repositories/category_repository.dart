// ============================================================================
// category_repository.dart
// ----------------------------------------------------------------------------
// Read-only access to Admin-managed category data. Admin (snapbee_admin's
// "Categories & Products" screen) is the sole source of truth — nothing here
// hard-codes names/images/ids.
//
// The shared `categories` table now carries `vertical`
// (daily_essentials | services | travel | entertainment | ecommerce),
// `display_order` and `visibility` (snapbee_admin/supabase/
// category_vertical_images.sql). Older environments may not have those
// columns yet, so every query attempts the full column/order set first and
// falls back on PostgREST 42703 — the same defensive pattern the rest of
// this app uses.
//
// Services and E-Commerce keep their own vertical-specific category tables
// (`service_categories` / `service_subcategories`, `ecommerce_categories`);
// the cross-vertical Categories browse screen reads those directly so no
// data is duplicated and vertical business logic stays separate. Travel and
// Entertainment categories live in `categories` under their `vertical` tag.
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';

class CategoryRow {
  final String id;
  final String name;
  final String? description;
  final String status;
  final String? imageUrl;
  final String? parentCategoryId;

  /// daily_essentials | services | travel | entertainment | ecommerce.
  /// Null (pre-migration rows) is treated as daily_essentials by callers.
  final String? vertical;
  final int? displayOrder;
  final bool visibility;

  const CategoryRow({
    required this.id,
    required this.name,
    this.description,
    required this.status,
    this.imageUrl,
    this.parentCategoryId,
    this.vertical,
    this.displayOrder,
    this.visibility = true,
  });

  bool get isMain => parentCategoryId == null;

  factory CategoryRow.fromJson(Map<String, dynamic> json) => CategoryRow(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    status: json['status'] as String,
    imageUrl: json['image_url'] as String?,
    parentCategoryId: json['parent_category_id'] as String?,
    vertical: json['vertical'] as String?,
    displayOrder: (json['display_order'] as num?)?.toInt(),
    visibility: json['visibility'] as bool? ?? true,
  );
}

class CategoryRepository {
  CategoryRepository(this._client);

  final SupabaseClient _client;

  static const String _table = 'categories';
  static const String _fullColumns =
      'id, name, description, status, image_url, parent_category_id, '
      'vertical, display_order, visibility';
  static const String _baseColumns =
      'id, name, description, status, image_url, parent_category_id';

  /// All active categories (mains + subs, any vertical) — kept unchanged for
  /// the Home "Shop by Category" row which has always shown a flat list.
  Future<List<CategoryRow>> fetchTopLevelCategories() {
    return _orderedFetch(
      (cols) => _client.from(_table).select(cols).eq('status', 'active'),
    );
  }

  /// Main categories of one vertical — the Categories screen's ALL grid and
  /// the FOOD/GROCERY/MEAT filters. `parent_category_id IS NULL` +
  /// `vertical` (or null vertical, treated as daily_essentials).
  Future<List<CategoryRow>> fetchMains({
    String vertical = 'daily_essentials',
  }) async {
    try {
      return await _orderedFetch((cols) {
        var q = _client
            .from(_table)
            .select(cols)
            .eq('status', 'active')
            .isFilter('parent_category_id', null);
        if (vertical == 'daily_essentials') {
          // include legacy rows whose vertical is still null
          q = q.or('vertical.eq.daily_essentials,vertical.is.null');
        } else {
          q = q.eq('vertical', vertical);
        }
        return q;
      });
    } on PostgrestException catch (error) {
      // `vertical` column missing (un-migrated env): fall back to all mains.
      if (error.code != '42703') rethrow;
      return _orderedFetch(
        (cols) => _client
            .from(_table)
            .select(cols)
            .eq('status', 'active')
            .isFilter('parent_category_id', null),
      );
    }
  }

  /// Subcategories of [parentId].
  Future<List<CategoryRow>> fetchSubcategories(String parentId) {
    return _orderedFetch(
      (cols) => _client
          .from(_table)
          .select(cols)
          .eq('parent_category_id', parentId)
          .eq('status', 'active'),
    );
  }

  /// [build] must construct a fresh filter chain each call — a
  /// PostgrestFilterBuilder is single-use.
  Future<List<CategoryRow>> _orderedFetch(
    PostgrestFilterBuilder<PostgrestList> Function(String columns) build,
  ) async {
    List<dynamic> rows;
    try {
      rows = await build(_fullColumns)
          .order('display_order', ascending: true, nullsFirst: false)
          .order('name');
    } on PostgrestException catch (error) {
      if (error.code != '42703') rethrow;
      rows = await build(_baseColumns).order('name');
    }
    return rows
        .map((row) => CategoryRow.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  // ---- Services vertical (own tables, read-only) -----------------------

  Future<List<CategoryRow>> fetchServiceCategories() async {
    try {
      final rows = await _client
          .from('service_categories')
          .select('id, name, description, image_url, display_order, is_active')
          .eq('is_active', true)
          .order('display_order', ascending: true)
          .order('name');
      return [
        for (final r in (rows as List))
          if (r is Map) _svcRow(Map<String, dynamic>.from(r), parentId: null),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<List<CategoryRow>> fetchServiceSubcategories(String categoryId) async {
    try {
      final rows = await _client
          .from('service_subcategories')
          .select('id, category_id, name, description, image_url, display_order, is_active')
          .eq('category_id', categoryId)
          .eq('is_active', true)
          .order('display_order', ascending: true)
          .order('name');
      return [
        for (final r in (rows as List))
          if (r is Map)
            _svcRow(
              Map<String, dynamic>.from(r),
              parentId: r['category_id'] as String?,
            ),
      ];
    } catch (_) {
      return const [];
    }
  }

  CategoryRow _svcRow(Map<String, dynamic> j, {String? parentId}) => CategoryRow(
    id: j['id'] as String,
    name: j['name'] as String,
    description: j['description'] as String?,
    status: (j['is_active'] as bool? ?? true) ? 'active' : 'inactive',
    imageUrl: j['image_url'] as String?,
    parentCategoryId: parentId,
    vertical: 'services',
    displayOrder: (j['display_order'] as num?)?.toInt(),
  );

  // ---- E-Commerce vertical (own table, read-only) ---------------------

  Future<List<CategoryRow>> fetchEcommerceCategories() async {
    try {
      final rows = await _client
          .from('ecommerce_categories')
          .select('id, name, description, image_url, display_order, is_active')
          .eq('is_active', true)
          .order('display_order', ascending: true)
          .order('name');
      return [
        for (final r in (rows as List))
          if (r is Map)
            CategoryRow(
              id: r['id'] as String,
              name: r['name'] as String,
              description: r['description'] as String?,
              status: 'active',
              imageUrl: r['image_url'] as String?,
              parentCategoryId: null,
              vertical: 'ecommerce',
              displayOrder: (r['display_order'] as num?)?.toInt(),
            ),
      ];
    } catch (_) {
      return const [];
    }
  }
}
