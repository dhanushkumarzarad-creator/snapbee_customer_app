// ============================================================================
// order_review_repository.dart
// ----------------------------------------------------------------------------
// The Customer app's ONLY path to Daily Essentials order reviews. Wraps the
// real `submit_de_order_review` / `get_de_order_review` RPCs
// (snapbee_admin/supabase/daily_essentials_order_reviews.sql) — the RPCs
// (SECURITY DEFINER) enforce "you own this order", "the order is delivered"
// and "one review per order"; this repository only maps errors to
// customer-friendly text.
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';

/// A review the customer has already submitted for an order.
class OrderReview {
  final String id;
  final String orderId;
  final int rating;
  final String? reviewText;
  final List<String> tags;
  final Map<String, dynamic> productRatings;
  final DateTime createdAt;

  const OrderReview({
    required this.id,
    required this.orderId,
    required this.rating,
    this.reviewText,
    this.tags = const [],
    this.productRatings = const {},
    required this.createdAt,
  });

  factory OrderReview.fromRow(Map<String, dynamic> row) => OrderReview(
        id: row['id'] as String,
        orderId: row['order_id'] as String,
        rating: (row['rating'] as num).toInt(),
        reviewText: row['review_text'] as String?,
        tags: (row['tags'] as List?)?.cast<String>() ?? const [],
        productRatings:
            (row['product_ratings'] as Map?)?.cast<String, dynamic>() ?? const {},
        createdAt: DateTime.parse(row['created_at'] as String),
      );
}

class OrderReviewException implements Exception {
  final String message;
  const OrderReviewException(this.message);
  @override
  String toString() => message;
}

class OrderReviewRepository {
  OrderReviewRepository(this._client);

  final SupabaseClient _client;

  /// The calling customer's own review for [orderId], or null if they
  /// haven't reviewed it yet.
  Future<OrderReview?> fetchMyOrderReview(String orderId) async {
    try {
      final rows = await _client
          .rpc('get_de_order_review', params: {'p_order_id': orderId});
      final list = (rows as List?) ?? const [];
      if (list.isEmpty) return null;
      return OrderReview.fromRow(Map<String, dynamic>.from(list.first as Map));
    } catch (_) {
      // A read failure just means the screen shows the blank form — no
      // fabricated review, no hard error.
      return null;
    }
  }

  /// Persists a store review for a delivered order. Returns the new review
  /// id. Throws [OrderReviewException] with safe text on any failure.
  Future<String> submitOrderReview({
    required String orderId,
    required int rating,
    String? reviewText,
    List<String> tags = const [],
    Map<String, int> productRatings = const {},
  }) async {
    try {
      final id = await _client.rpc('submit_de_order_review', params: {
        'p_order_id': orderId,
        'p_rating': rating,
        'p_review_text': reviewText,
        'p_tags': tags,
        'p_product_ratings': productRatings,
      });
      return id as String;
    } on PostgrestException catch (e) {
      final m = e.message.toLowerCase();
      if (m.contains('already reviewed')) {
        throw const OrderReviewException('You have already reviewed this order.');
      }
      if (m.contains('delivered')) {
        throw const OrderReviewException('You can only review an order once it has been delivered.');
      }
      if (m.contains('not authorized') || m.contains('order not found')) {
        throw const OrderReviewException("We couldn't find this order on your account.");
      }
      if (m.contains('no customer profile')) {
        throw const OrderReviewException('Your account is not fully set up yet. Please contact support.');
      }
      throw const OrderReviewException('Could not submit your review. Please try again.');
    } catch (_) {
      throw const OrderReviewException('Could not submit your review. Please check your connection and try again.');
    }
  }
}
