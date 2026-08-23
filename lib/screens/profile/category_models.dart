/// Domain models for the Categories feature.
///
/// Kept framework-agnostic (no Flutter imports) so they can sit in the
/// `domain` layer of the app's Clean Architecture and be reused by the
/// data layer (Supabase mapping) without change.
library;

class CategoryModel {
  final String id;
  final String name;
  final String emoji;
  final String imageUrl;
  final List<FeaturedProductModel> featuredProducts;
  final List<SubCategoryModel> subCategories;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.imageUrl,
    required this.featuredProducts,
    required this.subCategories,
  });
}

class FeaturedProductModel {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final double? mrp; // original price, used to derive discount badge
  final double rating;
  final String unit; // e.g. "1 kg", "500 ml"

  const FeaturedProductModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.rating,
    required this.unit,
    this.mrp,
  });

  int? get discountPercent {
    if (mrp == null || mrp! <= price) return null;
    return (((mrp! - price) / mrp!) * 100).round();
  }
}

class SubCategoryModel {
  final String id;
  final String name;
  final String imageUrl;

  const SubCategoryModel({
    required this.id,
    required this.name,
    required this.imageUrl,
  });
}
