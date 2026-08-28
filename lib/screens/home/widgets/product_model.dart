import '../../../data/repositories/product_repository.dart' show ProductRow;

/// Data model representing a single product in the SnapBee catalog.
///
/// This model is intentionally backend-agnostic (plain Dart, no Supabase
/// types) so it can be reused across widgets, services, and repositories.
class ProductModel {
  final String id;
  final String name;
  final String imageAssetPath;
  final double rating;
  final int ratingCount;
  final double currentPrice;
  final double? oldPrice;
  final String unit; // e.g. "500 g", "1 L", "1 pc"
  final bool inStock;

  /// The vendor this product belongs to (`products.vendor_id`, live column).
  /// Empty string for the sample-data catalog used in previews — real rows
  /// always carry one, and checkout refuses to proceed without it (a cart
  /// item with no vendor can't be resolved to a branch/order).
  final String vendorId;

  const ProductModel({
    required this.id,
    required this.name,
    required this.imageAssetPath,
    required this.currentPrice,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.oldPrice,
    this.unit = '',
    this.inStock = true,
    this.vendorId = '',
  });

  /// Whether this product currently has a discount applied.
  bool get hasDiscount => oldPrice != null && oldPrice! > currentPrice;

  /// Discount percentage rounded to the nearest whole number.
  /// Returns 0 when there is no valid discount.
  int get discountPercent {
    if (!hasDiscount) return 0;
    final percent = ((oldPrice! - currentPrice) / oldPrice!) * 100;
    return percent.round();
  }

  /// Builds a UI-ready [ProductModel] from a real catalog row. `rating`/
  /// `ratingCount` have no backing column yet (no reviews feature exists)
  /// so they stay at their defaults (0) rather than being fabricated.
  factory ProductModel.fromRow(ProductRow row) {
    return ProductModel(
      id: row.id,
      name: row.name,
      imageAssetPath: row.primaryImageUrl ?? '',
      currentPrice: row.discountPrice ?? row.price,
      oldPrice: row.discountPrice != null ? row.price : null,
      unit: row.unit,
      vendorId: row.vendorId,
    );
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      imageAssetPath: json['image_asset_path'] as String,
      currentPrice: (json['current_price'] as num).toDouble(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
      oldPrice: (json['old_price'] as num?)?.toDouble(),
      unit: json['unit'] as String? ?? '',
      inStock: json['in_stock'] as bool? ?? true,
      vendorId: json['vendor_id'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image_asset_path': imageAssetPath,
      'current_price': currentPrice,
      'rating': rating,
      'rating_count': ratingCount,
      'old_price': oldPrice,
      'unit': unit,
      'in_stock': inStock,
      'vendor_id': vendorId,
    };
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? imageAssetPath,
    double? rating,
    int? ratingCount,
    double? currentPrice,
    double? oldPrice,
    String? unit,
    bool? inStock,
    String? vendorId,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageAssetPath: imageAssetPath ?? this.imageAssetPath,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      currentPrice: currentPrice ?? this.currentPrice,
      oldPrice: oldPrice ?? this.oldPrice,
      vendorId: vendorId ?? this.vendorId,
      unit: unit ?? this.unit,
      inStock: inStock ?? this.inStock,
    );
  }
}
