import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/design/snapbee_design.dart';
import '../../core/invoicing/invoice.dart';
import '../../core/invoicing/invoice_button.dart';
import '../../core/map/osm_map.dart';
import '../../data/repositories/live_tracking_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../order_history/models/order_history_model.dart';
import 'order_card.dart' show kSnapBeeOrange;
import 'order_models.dart';
import 'rate_reviews_screen.dart';
import 'reorder_screen.dart';

/// Screen-agnostic view of "an order" — adapts either an active
/// [OrderModel] (from the Orders tab) or a past [OrderHistoryModel]
/// (from Order History) into the fields [OrderDetailsScreen] renders,
/// so one screen serves both entry points without duplicating layout.
class OrderDetailsData {
  final String orderId;
  final String storeName;
  final String storeImageUrl;
  final int itemsCount;
  final double amount;
  final String etaOrDate;
  final String? deliveryOtp;
  final String paymentLabel;
  final int
  timelineStage; // 0=placed 1=preparing 2=out for delivery 3=delivered
  final bool isCancelled;

  /// Only ever set by [fromSupabaseOrder] — the dummy `OrderModel`/
  /// `OrderHistoryModel` adapters have no real delivery-partner identity to
  /// carry, so live tracking never renders for those two entry points.
  final String? deliveryPartnerId;

  /// True only for [fromSupabaseOrder] — the Cancel action only makes sense
  /// (and only has a real backend row behind it) for a genuine Supabase
  /// order, never the dummy `OrderModel`/`OrderHistoryModel` adapters.
  final bool isReal;

  /// The raw `orders.status` value (only set by [fromSupabaseOrder]) — more
  /// precise than [timelineStage] for deciding cancel-eligibility, since
  /// several distinct real statuses (`ready`, `pickedUp`) collapse onto the
  /// same `timelineStage` as `pending`/`accepted`.
  final String? rawStatus;

  const OrderDetailsData({
    required this.orderId,
    required this.storeName,
    required this.storeImageUrl,
    required this.itemsCount,
    required this.amount,
    required this.etaOrDate,
    required this.paymentLabel,
    required this.timelineStage,
    required this.isCancelled,
    this.deliveryOtp,
    this.deliveryPartnerId,
    this.isReal = false,
    this.rawStatus,
  });

  factory OrderDetailsData.fromOrder(OrderModel order) {
    int stage;
    switch (order.status) {
      case OrderStatus.placed:
        stage = 0;
        break;
      case OrderStatus.preparing:
        stage = 1;
        break;
      case OrderStatus.outForDelivery:
        stage = 2;
        break;
      case OrderStatus.delivered:
        stage = 3;
        break;
      case OrderStatus.cancelled:
        stage = 0;
        break;
    }
    return OrderDetailsData(
      orderId: order.orderId.startsWith('#')
          ? order.orderId.substring(1)
          : order.orderId,
      storeName: order.shopName,
      storeImageUrl: order.storeImageUrl,
      itemsCount: order.itemsCount,
      amount: order.orderAmount,
      etaOrDate: order.deliveryEta,
      paymentLabel: order.paymentStatus.label,
      timelineStage: stage,
      isCancelled: order.status == OrderStatus.cancelled,
      deliveryOtp: order.deliveryOtp.isEmpty ? null : order.deliveryOtp,
    );
  }

  /// Real order, freshly loaded from Supabase (`OrderRepository`) — used
  /// right after checkout places a real order via `place_customer_order`.
  /// Unlike [fromOrder]/[fromHistory] (dummy-data adapters), every field
  /// here is either an authoritative RPC/DB value or an honest absence: no
  /// delivery OTP exists on the live `orders` table yet, so [deliveryOtp]
  /// always stays null rather than fabricating one; the "eta" line shows
  /// the real order timestamp since no ETA estimate is computed anywhere
  /// yet either; and [paymentLabel] is whatever the customer actually
  /// picked at checkout — `orders` has no payment-method column at all
  /// (no payment gateway is wired into this app), so it's carried through
  /// as-selected rather than assumed.
  factory OrderDetailsData.fromSupabaseOrder(
    OrderRow order, {
    required String paymentLabel,
  }) {
    return OrderDetailsData(
      orderId: order.id,
      storeName: order.vendorName.isEmpty ? 'Store' : order.vendorName,
      storeImageUrl: '',
      itemsCount: order.itemCount,
      amount: order.totalAmount,
      etaOrDate: 'Placed ${order.orderDate.toLocal()}'.split('.').first,
      paymentLabel: paymentLabel,
      timelineStage: order.timelineStage,
      isCancelled: order.isCancelled,
      deliveryPartnerId: order.deliveryPartnerId,
      isReal: true,
      rawStatus: order.status,
    );
  }

  factory OrderDetailsData.fromHistory(OrderHistoryModel order) {
    int stage;
    switch (order.deliveryStatus) {
      case DeliveryStatus.placed:
        stage = 0;
        break;
      case DeliveryStatus.preparing:
        stage = 1;
        break;
      case DeliveryStatus.outForDelivery:
        stage = 2;
        break;
      case DeliveryStatus.delivered:
        stage = 3;
        break;
      case DeliveryStatus.cancelled:
        stage = 0;
        break;
    }
    return OrderDetailsData(
      orderId: order.orderNumber,
      storeName: order.storeName,
      storeImageUrl: order.storeImageUrl,
      itemsCount: order.itemCount,
      amount: order.amount,
      etaOrDate: OrderHistoryTimeUtils.formatDateTime(order.placedAt),
      paymentLabel: order.paymentStatus.label,
      timelineStage: stage,
      isCancelled: order.deliveryStatus == DeliveryStatus.cancelled,
    );
  }
}

class OrderDetailsScreen extends StatefulWidget {
  final OrderDetailsData order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  static const _stages = [
    'Order Placed',
    'Preparing',
    'Out for Delivery',
    'Delivered',
  ];
  static const _stageIcons = [
    Icons.receipt_long_rounded,
    Icons.soup_kitchen_rounded,
    Icons.two_wheeler_rounded,
    Icons.check_circle_rounded,
  ];

  late final _trackingRepository = LiveTrackingRepository(Supabase.instance.client);
  late final _orderRepository = OrderRepository(Supabase.instance.client);
  Timer? _trackingTimer;
  PartnerLocation? _partnerLocation;
  late OrderDetailsData _order = widget.order;
  bool _cancelling = false;

  /// Only out-for-delivery orders with a real, backend-assigned partner —
  /// see [OrderDetailsData.deliveryPartnerId]'s doc comment.
  bool get _tracksLive =>
      !_order.isCancelled && _order.timelineStage == 2 && _order.deliveryPartnerId != null;

  /// Mirrors the `orders_update_own_customer` RLS policy's own `using`
  /// clause (supabase/orders_customer_vendor_cancellation_rls.sql) — a
  /// tighter gate than [OrderDetailsData.isCancelled] since `ready`/
  /// `pickedUp` are no longer cancellable but aren't "cancelled" either.
  bool get _canCancel =>
      _order.isReal && (_order.rawStatus == 'pending' || _order.rawStatus == 'accepted');

  Future<void> _cancelOrder() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _CancelOrderReasonDialog(),
    );
    if (reason == null || !mounted) return;

    setState(() => _cancelling = true);
    try {
      final updated = await _orderRepository.cancelOrder(_order.orderId, reason: reason);
      if (!mounted) return;
      setState(() {
        _order = OrderDetailsData.fromSupabaseOrder(updated, paymentLabel: _order.paymentLabel);
        _cancelling = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order cancelled.')),
      );
    } on OrderCancellationException catch (e) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not cancel this order. Please try again.')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    if (_tracksLive) {
      _pollLocation();
      _trackingTimer = Timer.periodic(const Duration(seconds: 15), (_) => _pollLocation());
    }
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    super.dispose();
  }

  Future<void> _pollLocation() async {
    final location = await _trackingRepository.fetchPartnerLocation(widget.order.deliveryPartnerId!);
    if (!mounted) return;
    setState(() => _partnerLocation = location);
  }

  ({String label, Color color, Color fill, IconData icon}) get _statusChip {
    if (_order.isCancelled) {
      return (label: 'Cancelled', color: SnapBeeColors.danger, fill: SnapBeeColors.dangerFill, icon: Icons.cancel_rounded);
    }
    switch (_order.timelineStage) {
      case 3:
        return (label: 'Delivered', color: SnapBeeColors.success, fill: SnapBeeColors.successFill, icon: Icons.check_circle_rounded);
      case 2:
        return (label: 'Out for Delivery', color: SnapBeeColors.info, fill: SnapBeeColors.infoFill, icon: Icons.local_shipping_rounded);
      case 1:
        return (label: 'Preparing', color: SnapBeeColors.warn, fill: SnapBeeColors.warnFill, icon: Icons.soup_kitchen_rounded);
      default:
        return (label: 'Order Placed', color: SnapBeeColors.orange, fill: SnapBeeColors.orangeTint, icon: Icons.receipt_long_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final order = _order;
    final chip = _statusChip;
    final shortId = order.orderId.length > 8 ? order.orderId.substring(0, 8).toUpperCase() : order.orderId.toUpperCase();

    return Scaffold(
      backgroundColor: SnapBeeColors.scaffold,
      appBar: SnapBeeAppBar(
        subtitle: order.timelineStage == 2 && !order.isCancelled ? 'Order Tracking' : 'Order Details',
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(SnapBeeSpacing.gutter, 6, SnapBeeSpacing.gutter, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order #$shortId', style: SnapBeeText.h1),
                        const SizedBox(height: 2),
                        Text(order.etaOrDate, style: SnapBeeText.caption),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(color: chip.fill, borderRadius: BorderRadius.circular(SnapBeeSpacing.rPill)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(chip.icon, size: 14, color: chip.color),
                        const SizedBox(width: 5),
                        Text(chip.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: chip.color)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _Card(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      order.storeImageUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 64,
                        height: 64,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: kSnapBeeOrange,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.storeName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${order.itemsCount} item${order.itemsCount == 1 ? '' : 's'} • ₹${order.amount.toStringAsFixed(0)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.etaOrDate,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_tracksLive)
              _Card(
                child: _LiveTrackingBody(location: _partnerLocation),
              ),
            if (order.deliveryOtp != null)
              _Card(
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      color: kSnapBeeOrange,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Delivery OTP',
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      order.deliveryOtp!,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: kSnapBeeOrange,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            _Card(
              child: order.isCancelled
                  ? Row(
                      children: [
                        Icon(
                          Icons.cancel_rounded,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'This order was cancelled',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Status',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        for (var i = 0; i < _stages.length; i++)
                          _TimelineStep(
                            label: _stages[i],
                            icon: _stageIcons[i],
                            isDone: i <= order.timelineStage,
                            isLast: i == _stages.length - 1,
                          ),
                      ],
                    ),
            ),
            _Card(
              child: Row(
                children: [
                  const Icon(
                    Icons.payments_rounded,
                    color: kSnapBeeOrange,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Payment',
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      order.paymentLabel,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (order.isReal)
              InvoiceActionTile(
                vertical: InvoiceVertical.dailyEssentials,
                sourceId: order.orderId,
              ),
            if (order.isReal)
              Padding(
                padding: const EdgeInsets.fromLTRB(SnapBeeSpacing.gutter, 8, SnapBeeSpacing.gutter, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: SnapBeeOutlineButton(
                        label: 'Reorder',
                        icon: Icons.autorenew_rounded,
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReorderScreen(orderId: order.orderId, storeName: order.storeName),
                          ),
                        ),
                      ),
                    ),
                    if (order.timelineStage == 3 && !order.isCancelled) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: SnapBeePrimaryButton(
                          label: 'Rate Store',
                          icon: Icons.star_rounded,
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RateReviewsScreen(orderId: order.orderId, storeName: order.storeName),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            if (_canCancel)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: OutlinedButton.icon(
                  onPressed: _cancelling ? null : _cancelOrder,
                  icon: _cancelling
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.cancel_outlined, color: theme.colorScheme.error),
                  label: Text(
                    'Cancel Order',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.colorScheme.error),
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CancelOrderReasonDialog extends StatefulWidget {
  @override
  State<_CancelOrderReasonDialog> createState() => _CancelOrderReasonDialogState();
}

class _CancelOrderReasonDialogState extends State<_CancelOrderReasonDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancel this order?'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 2,
        decoration: const InputDecoration(labelText: 'Reason (optional)'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          child: const Text('Back'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context, rootNavigator: true)
              .pop(_controller.text.trim().isEmpty ? 'Not specified' : _controller.text.trim()),
          child: const Text('Cancel Order'),
        ),
      ],
    );
  }
}

/// The tracking card's content — [location] is null while the partner
/// hasn't sent a location update yet (freshly accepted) or a poll hasn't
/// landed; both render the same "waiting for update" line rather than an
/// error, since this is ordinary transient state, not a failure.
class _LiveTrackingBody extends StatelessWidget {
  final PartnerLocation? location;

  const _LiveTrackingBody({required this.location});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = location;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.two_wheeler_rounded, color: kSnapBeeOrange, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                loc?.partnerName ?? 'Your delivery partner',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (loc?.partnerPhone != null)
              Text(loc!.partnerPhone!, style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 8),
        if (loc != null) ...[
          StaticLocationMap(
            point: LatLng(loc.lat, loc.lng),
            zoom: 15,
            height: 160,
            pinColor: kSnapBeeOrange,
            extraMarkers: [
              Marker(
                point: LatLng(loc.lat, loc.lng),
                width: 36,
                height: 36,
                child: const Icon(Icons.two_wheeler_rounded, color: kSnapBeeOrange, size: 26),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Text(
          loc == null
              ? 'Waiting for a location update…'
              : '${loc.lat.toStringAsFixed(5)}, ${loc.lng.toStringAsFixed(5)} • updated ${_relativeTime(loc.recordedAt)}',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  static String _relativeTime(DateTime at) {
    final diff = DateTime.now().difference(at);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: SnapBeeSpacing.gutter, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SnapBeeColors.surface,
        borderRadius: BorderRadius.circular(SnapBeeSpacing.rTile),
        boxShadow: SnapBeeShadows.card,
      ),
      child: child,
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDone;
  final bool isLast;

  const _TimelineStep({
    required this.label,
    required this.icon,
    required this.isDone,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDone
        ? const Color(0xFF2E7D32)
        : theme.colorScheme.outlineVariant;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDone
                      ? const Color(0xFF2E7D32)
                      : theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 15,
                  color: isDone
                      ? Colors.white
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: color.withValues(alpha: 0.4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20, top: 4),
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isDone ? FontWeight.w700 : FontWeight.w500,
                  color: isDone
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
