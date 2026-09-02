// ============================================================================
// ecommerce_repository.dart
// ----------------------------------------------------------------------------
// The only place the E-Commerce sector talks to Supabase. Cart is
// client-side (mirrors Daily Essentials' own lib/data/cart/cart_store.dart
// pattern — this app's established convention) — checkout converts it to
// real ecommerce_orders rows via create_ecommerce_order, one order per
// vendor represented in the cart (same "one vendor per order" rule Daily
// Essentials uses). Every write goes through the SECURITY DEFINER RPCs in
// supabase/ecommerce_module.sql.
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';

class EcommerceRepository {
  EcommerceRepository(this._client);
  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> listCategories() async {
    final rows = await _client.from('ecommerce_categories').select().eq('is_active', true).order('display_order');
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<List<Map<String, dynamic>>> listProducts({String? categoryId, String? query}) async {
    var q = _client.from('ecommerce_products').select('*, ecommerce_vendors(business_name)').eq('is_active', true);
    if (categoryId != null) q = q.eq('category_id', categoryId);
    if (query != null && query.trim().isNotEmpty) q = q.ilike('name', '%${query.trim()}%');
    final rows = await q.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<Map<String, dynamic>?> getProduct(String productId) async {
    return await _client.from('ecommerce_products').select('*, ecommerce_vendors(business_name)').eq('id', productId).maybeSingle();
  }

  Future<List<Map<String, dynamic>>> listVariants(String productId) async {
    final rows = await _client.from('ecommerce_product_variants').select().eq('product_id', productId).eq('is_active', true);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<List<Map<String, dynamic>>> listReviews(String productId) async {
    final rows = await _client.from('ecommerce_reviews').select().eq('product_id', productId).order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  /// items: [{product_id, variant_id?, quantity}] — all for ONE vendor.
  Future<String> createOrder({
    required String vendorId,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> shippingAddress,
    String? idempotencyKey,
  }) async {
    final id = await _client.rpc('create_ecommerce_order', params: {
      'p_vendor_id': vendorId,
      'p_items': items,
      'p_shipping_address': shippingAddress,
      'p_idempotency_key': idempotencyKey,
    });
    return id as String;
  }

  Future<Map<String, dynamic>> confirmOrderPayment(String orderId, {required bool success}) async {
    final result = await _client.rpc('confirm_ecommerce_order_payment', params: {'p_order_id': orderId, 'p_success': success});
    return Map<String, dynamic>.from(result as Map);
  }

  Future<List<Map<String, dynamic>>> myOrders() async {
    final rows = await _client
        .from('ecommerce_orders')
        .select('*, ecommerce_vendors(business_name), ecommerce_order_items(product_id, product_name, variant_label, quantity, unit_price)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<Map<String, dynamic>> cancelOrder(String orderId, {String? reason}) async {
    final result = await _client.rpc('cancel_ecommerce_order', params: {'p_order_id': orderId, 'p_reason': reason});
    return Map<String, dynamic>.from(result as Map);
  }

  Future<void> submitReview(String orderId, String productId, {required num rating, String? reviewText}) async {
    await _client.rpc('submit_ecommerce_review', params: {
      'p_order_id': orderId,
      'p_product_id': productId,
      'p_rating': rating,
      'p_review_text': reviewText,
    });
  }
}
