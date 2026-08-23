import 'package:flutter/material.dart';

/// All notification categories supported by the SnapBee Customer App.
enum NotificationType {
  order,
  delivery,
  offer,
  payment,
  reward,
  referral,
  announcement,
  wishlist,
}

/// Core data model for a single notification.
///
/// Kept intentionally simple and null-safe so it can be mapped
/// 1:1 to a Supabase `notifications` table row later:
/// id, customer_id, type, title, message, is_read, created_at, deep_link.
@immutable
class NotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  /// Optional route/deep-link to navigate to when the notification is tapped
  /// (e.g. `/order/SB-ORD-102345`).
  final String? actionRoute;

  /// Optional thumbnail (offer banner, product image, etc.). Falls back to
  /// a type-based icon when null.
  final String? imageUrl;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.actionRoute,
    this.imageUrl,
  });

  NotificationModel copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? message,
    DateTime? createdAt,
    bool? isRead,
    String? actionRoute,
    String? imageUrl,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      actionRoute: actionRoute ?? this.actionRoute,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      type: NotificationTypeX.fromKey(
        json['type'] as String? ?? 'announcement',
      ),
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      isRead: json['is_read'] as bool? ?? false,
      actionRoute: json['action_route'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.key,
      'title': title,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'action_route': actionRoute,
      'image_url': imageUrl,
    };
  }
}

/// Which relative time-bucket a notification belongs in, used to
/// group the list into sections in the UI.
enum NotificationBucket { today, yesterday, thisWeek, older }

extension NotificationBucketX on NotificationBucket {
  String get label {
    switch (this) {
      case NotificationBucket.today:
        return 'Today';
      case NotificationBucket.yesterday:
        return 'Yesterday';
      case NotificationBucket.thisWeek:
        return 'This Week';
      case NotificationBucket.older:
        return 'Earlier';
    }
  }
}

/// Icon, color and label metadata for each [NotificationType], plus
/// helpers for (de)serializing and computing relative time / buckets.
extension NotificationTypeX on NotificationType {
  static NotificationType fromKey(String key) {
    return NotificationType.values.firstWhere(
      (e) => e.key == key,
      orElse: () => NotificationType.announcement,
    );
  }

  String get key => toString().split('.').last;

  IconData get icon {
    switch (this) {
      case NotificationType.order:
        return Icons.shopping_bag_rounded;
      case NotificationType.delivery:
        return Icons.two_wheeler_rounded;
      case NotificationType.offer:
        return Icons.local_offer_rounded;
      case NotificationType.payment:
        return Icons.account_balance_wallet_rounded;
      case NotificationType.reward:
        return Icons.emoji_events_rounded;
      case NotificationType.referral:
        return Icons.card_giftcard_rounded;
      case NotificationType.announcement:
        return Icons.campaign_rounded;
      case NotificationType.wishlist:
        return Icons.favorite_rounded;
    }
  }

  /// Base color used for the icon badge background/foreground.
  /// Chosen to feel at home next to a Blinkit/Swiggy-style palette.
  Color get color {
    switch (this) {
      case NotificationType.order:
        return const Color(0xFF2E7D32); // green
      case NotificationType.delivery:
        return const Color(0xFF1565C0); // blue
      case NotificationType.offer:
        return const Color(0xFFE65100); // orange
      case NotificationType.payment:
        return const Color(0xFF6A1B9A); // purple
      case NotificationType.reward:
        return const Color(0xFFF9A825); // gold
      case NotificationType.referral:
        return const Color(0xFF00897B); // teal
      case NotificationType.announcement:
        return const Color(0xFFC62828); // red
      case NotificationType.wishlist:
        return const Color(0xFFD81B60); // pink
    }
  }

  String get label {
    switch (this) {
      case NotificationType.order:
        return 'Order';
      case NotificationType.delivery:
        return 'Delivery';
      case NotificationType.offer:
        return 'Offer';
      case NotificationType.payment:
        return 'Payment';
      case NotificationType.reward:
        return 'Reward';
      case NotificationType.referral:
        return 'Referral';
      case NotificationType.announcement:
        return 'Announcement';
      case NotificationType.wishlist:
        return 'Wishlist';
    }
  }
}

/// Time helpers kept separate from the model so they're easy to unit test.
class NotificationTimeUtils {
  const NotificationTimeUtils._();

  /// Returns a compact, human-friendly relative time string:
  /// "Just now", "2 min ago", "1 hour ago", "Yesterday", "3 days ago",
  /// or a short date for anything older.
  static String relativeTime(DateTime dateTime, {DateTime? now}) {
    final DateTime reference = now ?? DateTime.now();
    final Duration diff = reference.difference(dateTime);

    if (diff.isNegative || diff.inSeconds < 60) {
      return 'Just now';
    }
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m min${m == 1 ? '' : 's'} ago';
    }
    if (diff.inHours < 24 && _isSameDay(dateTime, reference)) {
      final h = diff.inHours;
      return '$h hour${h == 1 ? '' : 's'} ago';
    }
    if (_isYesterday(dateTime, reference)) {
      return 'Yesterday';
    }
    if (diff.inDays < 7) {
      final d = diff.inDays;
      return '$d day${d == 1 ? '' : 's'} ago';
    }

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
    return '${dateTime.day} ${months[dateTime.month - 1]}';
  }

  /// Buckets a notification's timestamp into Today / Yesterday / This Week / Older.
  static NotificationBucket bucketFor(DateTime dateTime, {DateTime? now}) {
    final DateTime reference = now ?? DateTime.now();

    if (_isSameDay(dateTime, reference)) {
      return NotificationBucket.today;
    }
    if (_isYesterday(dateTime, reference)) {
      return NotificationBucket.yesterday;
    }
    final startOfToday = DateTime(
      reference.year,
      reference.month,
      reference.day,
    );
    final diffDays = startOfToday
        .difference(DateTime(dateTime.year, dateTime.month, dateTime.day))
        .inDays;
    if (diffDays < 7) {
      return NotificationBucket.thisWeek;
    }
    return NotificationBucket.older;
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool _isYesterday(DateTime dateTime, DateTime reference) {
    final yesterday = reference.subtract(const Duration(days: 1));
    return _isSameDay(dateTime, yesterday);
  }
}
