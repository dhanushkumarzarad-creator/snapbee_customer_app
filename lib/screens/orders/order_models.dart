/// order_models.dart
/// Data models used by the SnapBee "My Orders" screen.
/// Pure Dart models — no Flutter/UI imports here (Clean Architecture:
/// these represent the Domain/Entity layer).
library;

/// Represents the current lifecycle stage of an order.
enum OrderStatus { placed, preparing, outForDelivery, delivered, cancelled }

/// Represents the payment state of an order.
enum OrderPaymentStatus { paid, payNow, cod }

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.placed:
        return 'Order Placed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

extension OrderPaymentStatusX on OrderPaymentStatus {
  String get label {
    switch (this) {
      case OrderPaymentStatus.paid:
        return 'Paid';
      case OrderPaymentStatus.payNow:
        return 'Pay Now';
      case OrderPaymentStatus.cod:
        return 'Pay on Delivery';
    }
  }
}

/// A single active/past order shown as a card on the Orders screen.
class OrderModel {
  final String orderId;
  final String shopName;
  final String storeImageUrl;
  final int itemsCount;
  final String deliveryEta;
  final String deliveryOtp;
  final double orderAmount;
  final OrderStatus status;
  final OrderPaymentStatus paymentStatus;

  const OrderModel({
    required this.orderId,
    required this.shopName,
    required this.storeImageUrl,
    required this.itemsCount,
    required this.deliveryEta,
    required this.deliveryOtp,
    required this.orderAmount,
    required this.status,
    required this.paymentStatus,
  });
}

/// A product shown inside the "Related Products" horizontal list.
class RelatedProductModel {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final double? originalPrice;

  const RelatedProductModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    this.originalPrice,
  });

  bool get hasDiscount => originalPrice != null && originalPrice! > price;
}

/// A store shown inside the "Nearby Stores" horizontal list.
class NearbyStoreModel {
  final String id;
  final String name;
  final String imageUrl;
  final double rating;
  final String distance;
  final String deliveryTime;

  const NearbyStoreModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.distance,
    required this.deliveryTime,
  });
}
