import 'offer_models.dart';

/// Demo data for the Offer Zone screen.
/// Replace these with Supabase-backed repositories later —
/// the widgets only depend on the model classes, not on this file.
class DummyOfferData {
  DummyOfferData._();

  static final List<OfferBannerModel> heroBanners = [
    const OfferBannerModel(
      id: 'hero1',
      imageUrl:
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800',
      title: 'Delicious Burger\nSuper Discount',
      discountLabel: '50% OFF',
      ctaText: 'Limited Offer',
    ),
    const OfferBannerModel(
      id: 'hero2',
      imageUrl:
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800',
      title: 'Fresh Groceries\nDaily Essentials',
      discountLabel: '30% OFF',
      ctaText: 'Shop Now',
    ),
    const OfferBannerModel(
      id: 'hero3',
      imageUrl:
          'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=800',
      title: 'Weekend Combo\nFamily Pack',
      discountLabel: 'FLAT ₹100 OFF',
      ctaText: 'Grab Deal',
    ),
  ];

  static final List<SpecialOfferProduct> specialOffers = [
    const SpecialOfferProduct(
      id: 'p1',
      name: 'Apple',
      imageUrl:
          'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=400',
      offerPrice: 80,
      oldPrice: 100,
    ),
    const SpecialOfferProduct(
      id: 'p2',
      name: 'Chicken Biryani',
      imageUrl:
          'https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=400',
      offerPrice: 100,
      oldPrice: 150,
    ),
    const SpecialOfferProduct(
      id: 'p3',
      name: 'Sunflower Oil',
      imageUrl:
          'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=400',
      offerPrice: 120,
      oldPrice: 150,
    ),
    const SpecialOfferProduct(
      id: 'p4',
      name: 'Orange Juice',
      imageUrl:
          'https://images.unsplash.com/photo-1613478223719-2ab802602423?w=400',
      offerPrice: 50,
      oldPrice: 80,
    ),
  ];

  static final List<QuickOfferModel> quickOffers = [
    const QuickOfferModel(
      id: 'q1',
      title: 'Free Delivery',
      tagText: 'SPECIAL OFFER',
      iconAsset: '🚚',
    ),
    const QuickOfferModel(
      id: 'q2',
      title: '% Offers',
      tagText: 'BEST OFFER',
      iconAsset: '🏷️',
    ),
  ];

  static final List<StoreOfferModel> storeOffers = [
    const StoreOfferModel(
      id: 's1',
      name: "Angel's Grocery Store",
      logoUrl:
          'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?w=200',
      rating: 4.0,
      deliveryTime: '15-30 Min',
      distance: '1.5 KM',
      isVerified: true,
    ),
    const StoreOfferModel(
      id: 's2',
      name: 'Fresh Mart Daily',
      logoUrl:
          'https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=200',
      rating: 4.5,
      deliveryTime: '20-35 Min',
      distance: '2.1 KM',
      isVerified: true,
    ),
    const StoreOfferModel(
      id: 's3',
      name: 'Green Basket',
      logoUrl:
          'https://images.unsplash.com/photo-1542838132-92c53300491e?w=200',
      rating: 3.8,
      deliveryTime: '25-40 Min',
      distance: '3.0 KM',
      isVerified: false,
    ),
  ];

  static final List<OfferBannerModel> promoBanners = [
    const OfferBannerModel(
      id: 'promo1',
      imageUrl:
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800',
      title: 'Delicious Burger\nSuper Discount',
      discountLabel: '50%',
    ),
    const OfferBannerModel(
      id: 'promo2',
      imageUrl:
          'https://images.unsplash.com/photo-1551782450-a2132b4ba21d?w=800',
      title: 'Pizza Mania\nBuy 1 Get 1',
      discountLabel: 'BOGO',
    ),
  ];
}
