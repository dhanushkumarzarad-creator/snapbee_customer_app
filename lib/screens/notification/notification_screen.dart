import 'package:flutter/material.dart';

import 'notification_card.dart';
import 'notification_model.dart';

/// Premium notification center for the SnapBee Customer App.
///
/// Groups notifications into Today / Yesterday / This Week / Earlier,
/// supports "mark all as read", swipe-to-dismiss, and shows an empty
/// state when there's nothing to show. Pass in real data from your
/// Supabase-backed provider/bloc via the [notifications] parameter —
/// sample data is used only when none is provided, for previewing.
class NotificationScreen extends StatefulWidget {
  final List<NotificationModel>? notifications;
  final Future<void> Function()? onRefresh;
  final void Function(NotificationModel notification)? onNotificationTap;

  const NotificationScreen({
    super.key,
    this.notifications,
    this.onRefresh,
    this.onNotificationTap,
  });

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late List<NotificationModel> _items;

  @override
  void initState() {
    super.initState();
    _items = List<NotificationModel>.from(
      widget.notifications ?? _sampleNotifications(),
    );
  }

  @override
  void didUpdateWidget(covariant NotificationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.notifications != null &&
        widget.notifications != oldWidget.notifications) {
      _items = List<NotificationModel>.from(widget.notifications!);
    }
  }

  bool get _hasUnread => _items.any((n) => !n.isRead);

  void _markAllAsRead() {
    if (!_hasUnread) return;
    setState(() {
      _items = _items.map((n) => n.copyWith(isRead: true)).toList();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleTap(NotificationModel notification) {
    if (!notification.isRead) {
      setState(() {
        final index = _items.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _items[index] = _items[index].copyWith(isRead: true);
        }
      });
    }
    widget.onNotificationTap?.call(notification);
  }

  void _handleDismiss(NotificationModel notification) {
    setState(() {
      _items.removeWhere((n) => n.id == notification.id);
    });
  }

  Map<NotificationBucket, List<NotificationModel>> _groupByBucket() {
    final Map<NotificationBucket, List<NotificationModel>> grouped = {
      NotificationBucket.today: [],
      NotificationBucket.yesterday: [],
      NotificationBucket.thisWeek: [],
      NotificationBucket.older: [],
    };

    final sorted = List<NotificationModel>.from(_items)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    for (final n in sorted) {
      final bucket = NotificationTimeUtils.bucketFor(n.createdAt);
      grouped[bucket]!.add(n);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grouped = _groupByBucket();
    final bool isEmpty = _items.isEmpty;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        scrolledUnderElevation: 1,
        actions: [
          if (!isEmpty)
            TextButton(
              onPressed: _hasUnread ? _markAllAsRead : null,
              child: Text(
                'Mark all as read',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _hasUnread
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                ),
              ),
            ),
        ],
      ),
      body: isEmpty
          ? const _EmptyState()
          : RefreshIndicator(
              onRefresh: widget.onRefresh ?? () async {},
              child: ListView(
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                children: [
                  ..._buildSection(
                    NotificationBucket.today,
                    grouped[NotificationBucket.today]!,
                  ),
                  ..._buildSection(
                    NotificationBucket.yesterday,
                    grouped[NotificationBucket.yesterday]!,
                  ),
                  ..._buildSection(
                    NotificationBucket.thisWeek,
                    grouped[NotificationBucket.thisWeek]!,
                  ),
                  ..._buildSection(
                    NotificationBucket.older,
                    grouped[NotificationBucket.older]!,
                  ),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildSection(
    NotificationBucket bucket,
    List<NotificationModel> items,
  ) {
    if (items.isEmpty) return const [];

    return [
      _SectionHeader(title: bucket.label),
      ...items.map(
        (n) => NotificationCard(
          notification: n,
          onTap: () => _handleTap(n),
          onDismiss: () => _handleDismiss(n),
        ),
      ),
    ];
  }

  /// Sample data used only when the screen isn't wired up to a real
  /// data source yet — handy for quick previews during development.
  List<NotificationModel> _sampleNotifications() {
    final now = DateTime.now();
    return [
      NotificationModel(
        id: '1',
        type: NotificationType.order,
        title: 'Order Confirmed',
        message:
            'Your order #SB-ORD-10293 has been confirmed and is being packed.',
        createdAt: now.subtract(const Duration(minutes: 2)),
        isRead: false,
      ),
      NotificationModel(
        id: '2',
        type: NotificationType.delivery,
        title: 'Out for Delivery',
        message: 'Ravi is on the way with your order. Arriving in 12 mins.',
        createdAt: now.subtract(const Duration(minutes: 40)),
        isRead: false,
      ),
      NotificationModel(
        id: '3',
        type: NotificationType.offer,
        title: 'Flat 50% OFF on Groceries',
        message: 'Hurry! Use code SNAP50 before midnight to save big.',
        createdAt: now.subtract(const Duration(hours: 3)),
        isRead: true,
      ),
      NotificationModel(
        id: '4',
        type: NotificationType.payment,
        title: 'Payment Successful',
        message: '₹482 was paid successfully for order #SB-ORD-10281.',
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
        isRead: true,
      ),
      NotificationModel(
        id: '5',
        type: NotificationType.reward,
        title: 'You just reached Gold Club!',
        message: 'Enjoy lower fees and priority support on every order now.',
        createdAt: now.subtract(const Duration(days: 1, hours: 5)),
        isRead: false,
      ),
      NotificationModel(
        id: '6',
        type: NotificationType.referral,
        title: 'Referral Bonus Credited',
        message: 'You earned ₹100 wallet cash for referring Priya.',
        createdAt: now.subtract(const Duration(days: 3)),
        isRead: true,
      ),
      NotificationModel(
        id: '7',
        type: NotificationType.wishlist,
        title: 'Price Drop Alert',
        message: 'An item in your wishlist just got cheaper by ₹30.',
        createdAt: now.subtract(const Duration(days: 4)),
        isRead: true,
      ),
      NotificationModel(
        id: '8',
        type: NotificationType.announcement,
        title: 'Scheduled Maintenance',
        message: 'SnapBee will be briefly unavailable tonight from 2-3 AM.',
        createdAt: now.subtract(const Duration(days: 6)),
        isRead: true,
      ),
    ];
  }
}

/// Sticky-feeling section label ("Today", "Yesterday", "This Week", "Earlier").
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// Friendly empty state shown when there are no notifications at all.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.5,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 48,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No notifications yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Updates about your orders, offers and rewards\nwill show up here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
