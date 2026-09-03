// ============================================================================
// checkout_repository.dart
// ----------------------------------------------------------------------------
// Real order placement — wraps the existing `place_customer_order` RPC
// (snapbee_admin/supabase/delivery_recommendation_engine.sql), the ONE
// authoritative write path for orders. This repository never computes
// price, weight, or delivery charge itself: `place_customer_order`
// recomputes every one of those server-side from live
// `products`/`vendor_delivery_settings` rows (and internally calls the
// same `compute_delivery_quote` the recommendation engine uses for
// eligibility/radius/vehicle-recommendation) so a customer can never
// submit their own numbers, and delivery eligibility is never bypassed by
// this app — it's enforced inside the RPC itself, atomically with order
// creation.
//
// `isCod` maps onto the `p_payment_method` param
// (snapbee_admin/supabase/delivery_partner_system.sql §10) — the RPC
// stores it as `orders.payment_method`, which the Delivery Partner
// dispatch engine's COD gate and proof-of-delivery policy both key off of.
// There is still no real payment gateway wired into this app, so UPI/Card
// both collapse to `prepaid` here; only Cash on Delivery is a real,
// backend-enforced distinction.
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../screens/cart/models/cart_model.dart';

class VendorDeliveryContext {
  final String branchId;
  final String categoryId;

  const VendorDeliveryContext({
    required this.branchId,
    required this.categoryId,
  });
}

class PlaceOrderResult {
  final String orderId;
  final double finalDeliveryCharge;
  final double itemsSubtotal;
  final double totalAmount;

  const PlaceOrderResult({
    required this.orderId,
    required this.finalDeliveryCharge,
    required this.itemsSubtotal,
    required this.totalAmount,
  });
}

/// Thrown for every checkout failure the UI should show directly — empty
/// cart, expired session, unavailable vendor/branch/product, out of
/// delivery radius, network failure. [message] is always safe to render
/// as-is; no raw PostgrestException/platform text ever reaches the UI.
class CheckoutException implements Exception {
  final String message;
  const CheckoutException(this.message);

  @override
  String toString() => message;
}

class CheckoutRepository {
  CheckoutRepository(this._client);

  final SupabaseClient _client;

  /// Resolves the vendor's primary branch + primary category — the same
  /// "primary branch/category" MVP simplification snapbee_vendor's own
  /// `SupabaseDeliveryRepository` already established for a vendor's own
  /// delivery-offer settings (`_primaryBranchId`/`_primaryCategoryId`).
  /// True per-branch/per-category checkout (a customer picking among
  /// several branches of the same vendor) is a larger UI change this pass
  /// doesn't need — every cart is already single-vendor by construction
  /// (see `CartStore`), and `place_customer_order` itself only ever takes
  /// one branch/category for the whole order.
  Future<VendorDeliveryContext> resolveVendorContext(String vendorId) async {
    final branchRow = await _client
        .from('vendor_branches')
        .select('id')
        .eq('vendor_id', vendorId)
        .eq('is_primary', true)
        .maybeSingle();
    final branchId = branchRow?['id'] as String?;
    if (branchId == null) {
      throw const CheckoutException(
        'This store is not set up for delivery yet. Please choose another store.',
      );
    }

    final categoryRow = await _client
        .from('vendor_categories')
        .select('category_id')
        .eq('vendor_id', vendorId)
        .eq('is_primary', true)
        .maybeSingle();
    final categoryId = categoryRow?['category_id'] as String?;
    if (categoryId == null) {
      throw const CheckoutException(
        'This store has not configured a delivery category yet.',
      );
    }

    return VendorDeliveryContext(branchId: branchId, categoryId: categoryId);
  }

  Future<PlaceOrderResult> placeOrder({
    required String branchId,
    required String categoryId,
    required List<CartItemModel> items,
    required double customerLat,
    required double customerLng,
    required String deliveryAddress,
    bool isCod = false,
    // Reuse the SAME key across a retry of the same checkout attempt (e.g.
    // CheckoutScreen holding one key for its whole lifetime) so a network
    // retry or a stray duplicate request can never create two real orders
    // — place_customer_order (snapbee_admin/supabase/
    // daily_essentials_order_idempotency.sql) returns the original order
    // instead of creating a second one when the same (customer, key) pair
    // is seen again. Optional and additive: omitting it places the order
    // exactly as before, with no replay protection.
    String? idempotencyKey,
  }) async {
    if (items.isEmpty) {
      throw const CheckoutException('Your cart is empty.');
    }
    if (_client.auth.currentSession == null) {
      throw const CheckoutException(
        'Your session has expired. Please sign in again.',
      );
    }

    final payloadItems = items
        .map((item) => {'product_id': item.productId, 'quantity': item.quantity})
        .toList();

    try {
      final rows = await _client.rpc(
        'place_customer_order',
        params: {
          'p_branch_id': branchId,
          'p_category_id': categoryId,
          'p_items': payloadItems,
          'p_customer_lat': customerLat,
          'p_customer_lng': customerLng,
          'p_delivery_address': deliveryAddress,
          'p_payment_method': isCod ? 'cod' : 'prepaid',
          'p_idempotency_key': idempotencyKey,
        },
      );

      if (rows.isEmpty) {
        throw const CheckoutException('Could not place your order. Please try again.');
      }
      final row = Map<String, dynamic>.from(rows.first as Map);
      return PlaceOrderResult(
        orderId: row['order_id'] as String,
        finalDeliveryCharge: (row['final_delivery_charge'] as num?)?.toDouble() ?? 0,
        itemsSubtotal: (row['items_subtotal'] as num?)?.toDouble() ?? 0,
        totalAmount: (row['total_amount'] as num?)?.toDouble() ?? 0,
      );
    } on AuthException {
      throw const CheckoutException(
        'Your session has expired. Please sign in again.',
      );
    } on CheckoutException {
      rethrow;
    } on PostgrestException catch (error) {
      throw CheckoutException(_mapRpcError(error.message));
    } catch (_) {
      throw const CheckoutException(
        'Could not place your order. Please check your connection and try again.',
      );
    }
  }

  /// Maps `place_customer_order`'s own `raise exception` messages (see the
  /// RPC body) onto customer-friendly text. Falls through to a generic
  /// message for anything not explicitly recognized, rather than showing
  /// raw SQL error text.
  String _mapRpcError(String message) {
    if (message.contains('no customer profile linked')) {
      return 'Your account is not fully set up yet. Please contact support.';
    }
    if (message.contains('invalid branch')) {
      return 'This store is currently unavailable. Please try another store.';
    }
    if (message.contains('invalid or unavailable product')) {
      return 'One or more items in your cart are no longer available. Please review your cart.';
    }
    if (message.contains('order must have at least one item')) {
      return 'Your cart is empty.';
    }
    if (message.contains('delivery not available')) {
      final reason = message.split('delivery not available:').last.trim();
      return reason.isEmpty
          ? 'Delivery is not available for your location.'
          : reason;
    }
    return 'Could not place your order. Please try again.';
  }
}
