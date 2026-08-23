import 'package:flutter/foundation.dart';

/// A single saved product in the customer's wishlist.
///
/// Mirrors a `wishlist_items` row joined with `products` / `vendors`
/// in Supabase: product info, store/vendor name, current selling price
/// and the original (MRP) price so a discount badge can be derived,
/// plus a simple in-stock flag for disabling "Move to Cart".
@immutable
class WishlistItemModel {
  final String id;
  final String productId;
  final String name;
  final String imageUrl;
  final String storeName;
  final String unit; // e.g. "500 g", "1 L", "6 pcs"
  final double price;
  final double? originalPrice;
  final bool inStock;
  final DateTime addedAt;

  const WishlistItemModel({
    required this.id,
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.storeName,
    required this.unit,
    required this.price,
    this.originalPrice,
    this.inStock = true,
    required this.addedAt,
  });

  /// Discount percentage vs. original price, rounded to nearest whole number.
  int get discountPercent {
    if (originalPrice == null || originalPrice! <= price) return 0;
    return (((originalPrice! - price) / originalPrice!) * 100).round();
  }

  bool get hasDiscount => discountPercent > 0;

  WishlistItemModel copyWith({
    String? id,
    String? productId,
    String? name,
    String? imageUrl,
    String? storeName,
    String? unit,
    double? price,
    double? originalPrice,
    bool? inStock,
    DateTime? addedAt,
  }) {
    return WishlistItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      storeName: storeName ?? this.storeName,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      inStock: inStock ?? this.inStock,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  factory WishlistItemModel.fromJson(Map<String, dynamic> json) {
    return WishlistItemModel(
      id: json['id'] as String,
      productId: json['product_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      storeName: json['store_name'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      originalPrice: (json['original_price'] as num?)?.toDouble(),
      inStock: json['in_stock'] as bool? ?? true,
      addedAt:
          DateTime.tryParse(json['added_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'name': name,
      'image_url': imageUrl,
      'store_name': storeName,
      'unit': unit,
      'price': price,
      'original_price': originalPrice,
      'in_stock': inStock,
      'added_at': addedAt.toIso8601String(),
    };
  }
}
