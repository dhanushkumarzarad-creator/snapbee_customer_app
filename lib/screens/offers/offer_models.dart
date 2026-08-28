/// A large hero / promo banner shown in the carousel sections.
class OfferBannerModel {
  final String id;
  final String imageUrl;
  final String title;
  final String? discountLabel; // e.g. "50% OFF"
  final String? ctaText; // e.g. "Order Now"

  const OfferBannerModel({
    required this.id,
    required this.imageUrl,
    required this.title,
    this.discountLabel,
    this.ctaText,
  });
}

/// A single product shown inside the "Special Offers" horizontal list.
class SpecialOfferProduct {
  final String id;
  final String name;
  final String imageUrl;
  final double offerPrice;
  final double oldPrice;

  /// Needed to add the product to the (single-vendor) cart.
  final String vendorId;
  final String unit;

  const SpecialOfferProduct({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.offerPrice,
    required this.oldPrice,
    this.vendorId = '',
    this.unit = '',
  });

  int get discountPercent => oldPrice <= 0
      ? 0
      : (((oldPrice - offerPrice) / oldPrice) * 100).round();
}

/// A quick promo tile, e.g. "Free Delivery" or "Best % Offers".
class QuickOfferModel {
  final String id;
  final String title;
  final String tagText; // small ribbon/badge text e.g. "SPECIAL OFFER"
  final String iconAsset; // icon or emoji-style asset path
  final bool isNetworkIcon;

  const QuickOfferModel({
    required this.id,
    required this.title,
    required this.tagText,
    required this.iconAsset,
    this.isNetworkIcon = false,
  });
}

/// A store/vendor card shown in "Store Offers".
class StoreOfferModel {
  final String id;
  final String name;
  final String logoUrl;
  final double rating;
  final String deliveryTime; // e.g. "15-30 Min"
  final String distance; // e.g. "1.5 KM"
  final bool isVerified;
  final bool isBookmarked;

  const StoreOfferModel({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.rating,
    required this.deliveryTime,
    required this.distance,
    this.isVerified = false,
    this.isBookmarked = false,
  });
}
