import 'package:flutter/material.dart';

/// Payment status for a past order.
enum PaymentStatus { paid, pending, failed, refunded }

extension PaymentStatusX on PaymentStatus {
  static PaymentStatus fromKey(String key) {
    return PaymentStatus.values.firstWhere(
      (e) => e.key == key,
      orElse: () => PaymentStatus.paid,
    );
  }

  String get key => toString().split('.').last;

  String get label {
    switch (this) {
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.pending:
        return 'Payment Pending';
      case PaymentStatus.failed:
        return 'Payment Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }

  Color get color {
    switch (this) {
      case PaymentStatus.paid:
        return const Color(0xFF2E7D32);
      case PaymentStatus.pending:
        return const Color(0xFFE65100);
      case PaymentStatus.failed:
        return const Color(0xFFC62828);
      case PaymentStatus.refunded:
        return const Color(0xFF1565C0);
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentStatus.paid:
        return Icons.check_circle_rounded;
      case PaymentStatus.pending:
        return Icons.schedule_rounded;
      case PaymentStatus.failed:
        return Icons.error_rounded;
      case PaymentStatus.refunded:
        return Icons.currency_exchange_rounded;
    }
  }
}

/// Delivery/fulfilment status for a past order.
enum DeliveryStatus { placed, preparing, outForDelivery, delivered, cancelled }

extension DeliveryStatusX on DeliveryStatus {
  static DeliveryStatus fromKey(String key) {
    return DeliveryStatus.values.firstWhere(
      (e) => e.key == key,
      orElse: () => DeliveryStatus.delivered,
    );
  }

  String get key => toString().split('.').last;

  String get label {
    switch (this) {
      case DeliveryStatus.placed:
        return 'Order Placed';
      case DeliveryStatus.preparing:
        return 'Preparing';
      case DeliveryStatus.outForDelivery:
        return 'Out for Delivery';
      case DeliveryStatus.delivered:
        return 'Delivered';
      case DeliveryStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case DeliveryStatus.placed:
        return const Color(0xFF1565C0);
      case DeliveryStatus.preparing:
        return const Color(0xFFE65100);
      case DeliveryStatus.outForDelivery:
        return const Color(0xFF6A1B9A);
      case DeliveryStatus.delivered:
        return const Color(0xFF2E7D32);
      case DeliveryStatus.cancelled:
        return const Color(0xFFC62828);
    }
  }

  IconData get icon {
    switch (this) {
      case DeliveryStatus.placed:
        return Icons.receipt_long_rounded;
      case DeliveryStatus.preparing:
        return Icons.soup_kitchen_rounded;
      case DeliveryStatus.outForDelivery:
        return Icons.two_wheeler_rounded;
      case DeliveryStatus.delivered:
        return Icons.check_circle_rounded;
      case DeliveryStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }

  bool get isReorderable =>
      this == DeliveryStatus.delivered || this == DeliveryStatus.cancelled;
}

/// A single past order shown in the order history list.
///
/// Mirrors an `orders` row joined with `vendors` in Supabase: store
/// info, order id/timestamps, amount, item count/preview, and both
/// payment and delivery status so the card can render both badges.
@immutable
class OrderHistoryModel {
  final String id;
  final String orderNumber; // e.g. "SB-ORD-102345"
  final String storeName;
  final String storeImageUrl;
  final DateTime placedAt;
  final double amount;
  final int itemCount;
  final String itemsPreview; // e.g. "Milk, Bread, Eggs +2 more"
  final PaymentStatus paymentStatus;
  final DeliveryStatus deliveryStatus;

  const OrderHistoryModel({
    required this.id,
    required this.orderNumber,
    required this.storeName,
    required this.storeImageUrl,
    required this.placedAt,
    required this.amount,
    required this.itemCount,
    required this.itemsPreview,
    required this.paymentStatus,
    required this.deliveryStatus,
  });

  factory OrderHistoryModel.fromJson(Map<String, dynamic> json) {
    return OrderHistoryModel(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String? ?? '',
      storeName: json['store_name'] as String? ?? '',
      storeImageUrl: json['store_image_url'] as String? ?? '',
      placedAt:
          DateTime.tryParse(json['placed_at'] as String? ?? '') ??
          DateTime.now(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      itemCount: json['item_count'] as int? ?? 0,
      itemsPreview: json['items_preview'] as String? ?? '',
      paymentStatus: PaymentStatusX.fromKey(
        json['payment_status'] as String? ?? 'paid',
      ),
      deliveryStatus: DeliveryStatusX.fromKey(
        json['delivery_status'] as String? ?? 'delivered',
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'store_name': storeName,
      'store_image_url': storeImageUrl,
      'placed_at': placedAt.toIso8601String(),
      'amount': amount,
      'item_count': itemCount,
      'items_preview': itemsPreview,
      'payment_status': paymentStatus.key,
      'delivery_status': deliveryStatus.key,
    };
  }
}

/// Which time-bucket an order belongs in, used to group the list into
/// sections: Today, Yesterday, This Month, Older Orders.
enum OrderHistoryBucket { today, yesterday, thisMonth, older }

extension OrderHistoryBucketX on OrderHistoryBucket {
  String get label {
    switch (this) {
      case OrderHistoryBucket.today:
        return 'Today';
      case OrderHistoryBucket.yesterday:
        return 'Yesterday';
      case OrderHistoryBucket.thisMonth:
        return 'This Month';
      case OrderHistoryBucket.older:
        return 'Older Orders';
    }
  }
}

/// Time helpers kept separate from the model so they're easy to unit test.
class OrderHistoryTimeUtils {
  const OrderHistoryTimeUtils._();

  /// Buckets an order's timestamp into Today / Yesterday / This Month / Older.
  static OrderHistoryBucket bucketFor(DateTime dateTime, {DateTime? now}) {
    final DateTime reference = now ?? DateTime.now();

    if (_isSameDay(dateTime, reference)) {
      return OrderHistoryBucket.today;
    }
    if (_isYesterday(dateTime, reference)) {
      return OrderHistoryBucket.yesterday;
    }
    if (dateTime.year == reference.year && dateTime.month == reference.month) {
      return OrderHistoryBucket.thisMonth;
    }
    return OrderHistoryBucket.older;
  }

  /// Formats a friendly date & time string, e.g. "24 Jul, 3:45 PM".
  static String formatDateTime(DateTime dateTime) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour12 = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.day} ${months[dateTime.month - 1]}, $hour12:$minute $period';
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool _isYesterday(DateTime dateTime, DateTime reference) {
    final yesterday = reference.subtract(const Duration(days: 1));
    return _isSameDay(dateTime, yesterday);
  }
}
