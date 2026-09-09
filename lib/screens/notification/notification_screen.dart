import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/design/snapbee_design.dart';
import '../../data/repositories/notification_repository.dart';
import 'notification_card.dart';
import 'notification_model.dart';

/// Premium notification center for the SnapBee Customer App.
///
/// Groups notifications into Today / Yesterday / This Week / Earlier,
/// supports "mark all as read", swipe-to-dismiss, and shows an empty
/// state when there's nothing to show. When [notifications] isn't passed
/// (every current caller), it self-loads the signed-in customer's real
/// notifications from `NotificationRepository` (customer_notifications
/// table) — replacing what used to always be the empty state, since no
/// backend for this existed until supabase/customer_notifications.sql.
/// [notifications] stays available for callers that already have data,
/// or want to test this widget without a live Supabase session.
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
  NotificationRepository? _repo;

  @override
  void initState() {
    super.initState();
    _items = List<NotificationModel>.from(widget.notifications ?? const []);
    if (widget.notifications == null) {
      _repo = NotificationRepository(Supabase.instance.client);
      _loadReal();
    }
  }

  Future<void> _loadReal() async {
    try {
      final real = await _repo!.fetchMyNotifications();
      if (!mounted) return;
      setState(() => _items = real);
    } catch (_) {
      // Leave empty — the screen's own empty state is the honest fallback.
    }
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
    _repo?.markAllAsRead();
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
      _repo?.markAsRead(notification.id);
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
    final grouped = _groupByBucket();
    final bool isEmpty = _items.isEmpty;

    return Scaffold(
      backgroundColor: SnapBeeColors.scaffold,
      appBar: SnapBeeAppBar(
        subtitle: 'Daily Essentials',
        trailing: (!isEmpty && _hasUnread)
            ? Padding(
                padding: const EdgeInsets.only(right: 8),
                child: SnapBeePillButton(
                  label: 'Mark all read',
                  icon: Icons.done_all_rounded,
                  onTap: _markAllAsRead,
                ),
              )
            : null,
      ),
      body: isEmpty
          ? const _EmptyState()
          : RefreshIndicator(
              onRefresh: widget.onRefresh ?? (_repo != null ? _loadReal : () async {}),
              child: ListView(
                padding: const EdgeInsets.only(top: 4, bottom: 24),
                children: [
                  const SnapBeePageHeader(
                    icon: Icons.notifications_rounded,
                    title: 'Notifications',
                    subtitle: 'Stay updated with your orders, offers and more',
                  ),
                  const SizedBox(height: 4),
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
    return const SnapBeeEmptyState(
      mascot: SnapBeeMascots.notification,
      title: 'No notifications yet',
      message: 'Updates about your orders, offers and rewards will show up here.',
    );
  }
}
