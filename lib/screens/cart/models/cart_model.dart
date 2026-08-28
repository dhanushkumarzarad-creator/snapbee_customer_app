import 'package:flutter/foundation.dart';

/// A single product line in the cart.
///
/// Mirrors what you'd expect from a `cart_items` row joined with the
/// `products` table in Supabase: id, product info, quantity, and
/// both the selling price and the original (MRP) price so a discount
/// badge can be derived.
@immutable
class CartItemModel {
  final String id;
  final String productId;
  final String name;
  final String imageUrl;
  final String unit; // e.g. "500 g", "1 L", "6 pcs"
  final double price; // current selling price (per unit quantity)
  final double? originalPrice; // MRP, null/equal to price => no discount
  final int quantity;
  final int maxQuantity;
  final bool savedForLater;

  /// `products.vendor_id` this line item came from — real checkout is
  /// single-vendor (place_customer_order resolves one branch for the whole
  /// order), so [CartStore] refuses to mix vendors in one cart rather than
  /// letting an unresolvable cart reach checkout.
  final String vendorId;

  const CartItemModel({
    required this.id,
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.unit,
    required this.price,
    required this.vendorId,
    this.originalPrice,
    this.quantity = 1,
    this.maxQuantity = 10,
    this.savedForLater = false,
  });

  double get lineTotal => price * quantity;

  double get originalLineTotal => (originalPrice ?? price) * quantity;

  double get lineSavings {
    final savings = originalLineTotal - lineTotal;
    return savings > 0 ? savings : 0;
  }

  /// Discount percentage vs. original price, rounded to nearest whole number.
  int get discountPercent {
    if (originalPrice == null || originalPrice! <= price) return 0;
    return (((originalPrice! - price) / originalPrice!) * 100).round();
  }

  bool get hasDiscount => discountPercent > 0;

  CartItemModel copyWith({
    String? id,
    String? productId,
    String? name,
    String? imageUrl,
    String? unit,
    double? price,
    String? vendorId,
    double? originalPrice,
    int? quantity,
    int? maxQuantity,
    bool? savedForLater,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      vendorId: vendorId ?? this.vendorId,
      originalPrice: originalPrice ?? this.originalPrice,
      quantity: quantity ?? this.quantity,
      maxQuantity: maxQuantity ?? this.maxQuantity,
      savedForLater: savedForLater ?? this.savedForLater,
    );
  }

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] as String,
      productId: json['product_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      vendorId: json['vendor_id'] as String? ?? '',
      originalPrice: (json['original_price'] as num?)?.toDouble(),
      quantity: json['quantity'] as int? ?? 1,
      maxQuantity: json['max_quantity'] as int? ?? 10,
      savedForLater: json['saved_for_later'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'name': name,
      'image_url': imageUrl,
      'unit': unit,
      'price': price,
      'vendor_id': vendorId,
      'original_price': originalPrice,
      'quantity': quantity,
      'max_quantity': maxQuantity,
      'saved_for_later': savedForLater,
    };
  }
}

/// Aggregates the cart's line items and produces the full bill breakdown
/// (item total, delivery charge, platform fee, grand total), plus the
/// free-delivery progress used by the UI.
///
/// No coupon/discount line: there is no server-side coupon logic
/// (`place_customer_order` takes no coupon and recomputes the total
/// itself), so the cart must never show a discount it can't honor. Real
/// coupon codes are surfaced for discovery in the Offer Zone tab.
@immutable
class CartBill {
  final double itemTotal;
  final double deliveryCharge;
  final double platformFee;

  const CartBill({
    required this.itemTotal,
    required this.deliveryCharge,
    required this.platformFee,
  });

  double get grandTotal =>
      (itemTotal + deliveryCharge + platformFee).clamp(0, double.infinity);
}

/// Cart-level configuration and calculation helper.
///
/// Keeps pricing rules (free-delivery threshold, platform fee, base
/// delivery charge) in one place so [CartScreen] stays purely presentational.
class CartCalculator {
  final double baseDeliveryCharge;
  final double platformFee;
  final double freeDeliveryThreshold;

  const CartCalculator({
    this.baseDeliveryCharge = 25,
    this.platformFee = 6,
    this.freeDeliveryThreshold = 199,
  });

  double itemTotal(List<CartItemModel> items) {
    return items
        .where((i) => !i.savedForLater)
        .fold(0.0, (sum, i) => sum + i.lineTotal);
  }

  double totalMrpSavings(List<CartItemModel> items) {
    return items
        .where((i) => !i.savedForLater)
        .fold(0.0, (sum, i) => sum + i.lineSavings);
  }

  double deliveryChargeFor(double itemTotal) {
    return itemTotal >= freeDeliveryThreshold ? 0 : baseDeliveryCharge;
  }

  /// Amount still needed to unlock free delivery (0 if already unlocked).
  double amountToFreeDelivery(double itemTotal) {
    final remaining = freeDeliveryThreshold - itemTotal;
    return remaining > 0 ? remaining : 0;
  }

  /// 0.0 - 1.0 progress toward the free delivery threshold.
  double freeDeliveryProgress(double itemTotal) {
    if (freeDeliveryThreshold <= 0) return 1;
    final progress = itemTotal / freeDeliveryThreshold;
    return progress.clamp(0, 1);
  }

  CartBill computeBill(List<CartItemModel> items) {
    final total = itemTotal(items);
    return CartBill(
      itemTotal: total,
      deliveryCharge: deliveryChargeFor(total),
      platformFee: items.any((i) => !i.savedForLater) ? platformFee : 0,
    );
  }
}
