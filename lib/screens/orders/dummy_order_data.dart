/// dummy_order_data.dart
/// Local dummy data source for the Orders screen's recommendation content
/// (Related Products / Nearby Stores) — neither is backed by any real
/// vendor/order relationship yet, so both stay dummy data for now. The
/// active-orders list this file used to also provide is gone: Orders now
/// reads real orders via `OrderRepository` (Supabase-backed), the live
/// `orders` table `place_customer_order` actually writes to.
library;

import 'order_models.dart';

class DummyOrderData {
  DummyOrderData._();

  static final List<RelatedProductModel> relatedProducts = [
    const RelatedProductModel(
      id: 'p1',
      name: 'Apple',
      imageUrl:
          'https://images.unsplash.com/photo-1568702846914-96b305d2aaeb?w=300',
      price: 80,
      originalPrice: 100,
    ),
    const RelatedProductModel(
      id: 'p2',
      name: 'Chicken Biriyani',
      imageUrl:
          'https://images.unsplash.com/photo-1563379926898-05f4575a45d8?w=300',
      price: 100,
      originalPrice: 150,
    ),
    const RelatedProductModel(
      id: 'p3',
      name: 'Sunflower Oil',
      imageUrl:
          'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=300',
      price: 120,
      originalPrice: 150,
    ),
    const RelatedProductModel(
      id: 'p4',
      name: 'Orange Juice',
      imageUrl:
          'https://images.unsplash.com/photo-1613478223719-2ab802602423?w=300',
      price: 50,
      originalPrice: 80,
    ),
    const RelatedProductModel(
      id: 'p5',
      name: 'Fresh Tomato',
      imageUrl:
          'https://images.unsplash.com/photo-1546094096-0df4bcaaa337?w=300',
      price: 40,
      originalPrice: 60,
    ),
  ];

  static final List<NearbyStoreModel> nearbyStores = [
    const NearbyStoreModel(
      id: 's1',
      name: 'Angel\'s Grocery Store',
      imageUrl:
          'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?w=300',
      rating: 4.5,
      distance: '1.2 km',
      deliveryTime: '20 min',
    ),
    const NearbyStoreModel(
      id: 's2',
      name: 'Fresh Mart',
      imageUrl:
          'https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=300',
      rating: 4.3,
      distance: '2.0 km',
      deliveryTime: '30 min',
    ),
    const NearbyStoreModel(
      id: 's3',
      name: 'Daily Needs Store',
      imageUrl:
          'https://images.unsplash.com/photo-1601599963565-b7f49deb1c96?w=300',
      rating: 4.7,
      distance: '0.8 km',
      deliveryTime: '15 min',
    ),
    const NearbyStoreModel(
      id: 's4',
      name: 'Spice Route Restaurant',
      imageUrl:
          'https://images.unsplash.com/photo-1552566626-52f8b828add9?w=300',
      rating: 4.6,
      distance: '1.5 km',
      deliveryTime: '25 min',
    ),
  ];
}
