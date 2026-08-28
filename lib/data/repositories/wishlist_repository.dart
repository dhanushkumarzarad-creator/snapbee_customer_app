// ============================================================================
// wishlist_repository.dart
// ----------------------------------------------------------------------------
// The customer's saved-products list, backed by `public.customer_wishlists`
// (snapbee_admin/supabase/customer_wishlist.sql). One row per
// (customer, product); customer-self CRUD via RLS. Product detail is read
// through the `products` embed (products_public_select RLS) with the
// vendor name for the store label.
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../screens/wishlist/models/wishlist_model.dart';

/// Thrown when a wishlist action needs a signed-in customer and there
/// isn't one (no session, or no `customers` row linked to the auth user).
class WishlistUnavailableException implements Exception {
  final String message;
  WishlistUnavailableException([this.message = 'Sign in to use your wishlist.']);
  @override
  String toString() => message;
}

abstract class WishlistSource {
  Future<List<WishlistItemModel>> fetchWishlist();
  Future<Set<String>> fetchWishlistedProductIds();
  Future<void> add(String productId);
  Future<void> remove(String productId);
}

class WishlistRepository implements WishlistSource {
  WishlistRepository(this._client);

  final SupabaseClient _client;

  static const String _table = 'customer_wishlists';
  static const String _embed =
      'id, product_id, created_at, '
      'products(name, price, discount_price, image_urls, unit, status, vendor_id, vendors(name))';

  Future<String> _customerId() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw WishlistUnavailableException();
    final row = await _client
        .from('customers')
        .select('id')
        .eq('auth_user_id', userId)
        .maybeSingle();
    final id = row?['id'] as String?;
    if (id == null) throw WishlistUnavailableException();
    return id;
  }

  @override
  Future<List<WishlistItemModel>> fetchWishlist() async {
    final customerId = await _customerId();
    final rows = await _client
        .from(_table)
        .select(_embed)
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => _map(r as Map<String, dynamic>))
        .whereType<WishlistItemModel>()
        .toList();
  }

  @override
  Future<Set<String>> fetchWishlistedProductIds() async {
    final customerId = await _customerId();
    final rows = await _client
        .from(_table)
        .select('product_id')
        .eq('customer_id', customerId);
    return (rows as List)
        .map((r) => (r as Map<String, dynamic>)['product_id'] as String)
        .toSet();
  }

  @override
  Future<void> add(String productId) async {
    final customerId = await _customerId();
    try {
      await _client.from(_table).insert({
        'customer_id': customerId,
        'product_id': productId,
      });
    } on PostgrestException catch (error) {
      // 23505 = already wishlisted; treat as success (idempotent).
      if (error.code != '23505') rethrow;
    }
  }

  @override
  Future<void> remove(String productId) async {
    final customerId = await _customerId();
    await _client
        .from(_table)
        .delete()
        .eq('customer_id', customerId)
        .eq('product_id', productId);
  }

  WishlistItemModel? _map(Map<String, dynamic> r) {
    final product = r['products'] as Map<String, dynamic>?;
    if (product == null) return null; // product deleted out from under the row
    final price = (product['price'] as num?)?.toDouble() ?? 0;
    final discount = (product['discount_price'] as num?)?.toDouble();
    final images = (product['image_urls'] as List?)?.cast<String>() ?? const [];
    final vendor = product['vendors'] as Map<String, dynamic>?;
    return WishlistItemModel(
      id: r['id'] as String,
      productId: r['product_id'] as String,
      name: (product['name'] as String?) ?? '',
      imageUrl: images.isEmpty ? '' : images.first,
      storeName: (vendor?['name'] as String?) ?? '',
      unit: (product['unit'] as String?) ?? '',
      price: (discount != null && discount > 0 && discount < price) ? discount : price,
      originalPrice:
          (discount != null && discount > 0 && discount < price) ? price : null,
      inStock: (product['status'] as String?) == 'active',
      addedAt: DateTime.tryParse(r['created_at'] as String? ?? '') ?? DateTime.now(),
      vendorId: (product['vendor_id'] as String?) ?? '',
    );
  }
}
