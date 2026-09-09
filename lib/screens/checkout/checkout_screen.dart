import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:latlong2/latlong.dart';

import '../../core/constants/app_colors.dart';
import '../../core/design/snapbee_design.dart';
import '../../core/location/location_service.dart';
import '../../core/map/location_picker_screen.dart';
import '../../core/map/osm_map.dart';
import '../../core/map/picked_location.dart';
import '../../data/cart/cart_store.dart';
import '../../data/repositories/checkout_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../cart/models/cart_model.dart';
import '../cart/widgets/bill_summary_card.dart';
import '../orders/order_details_screen.dart';
import '../orders/order_success_screen.dart';
import 'add_address_screen.dart';

enum _PaymentMethod { upi, card, cod }

/// Checkout screen — delivery location, payment method and final bill
/// review before placing the order. Reached from [CartScreen]'s
/// "Proceed to Checkout" bar.
///
/// Real order placement: resolves the cart's single vendor to a
/// branch/category (`CheckoutRepository.resolveVendorContext`), captures a
/// real device location (no geocoding/maps API key exists anywhere in this
/// monorepo, so a fabricated street address was never an honest option),
/// then calls the existing `place_customer_order` RPC — the same real
/// eligibility/radius/quote logic the recommendation engine already
/// enforces, not bypassed or reimplemented here. There's still no real
/// address book or payment gateway wired into this app (Profile's "Saved
/// Addresses"/"Payments" menu entries are still stubs) — UPI/Card both
/// stay local-only selections with no gateway behind them. Cash on
/// Delivery is different: it's a real, backend-enforced choice
/// (`CheckoutRepository.placeOrder`'s `isCod`), since `orders` now has a
/// `payment_method` column the Delivery Partner dispatch engine's COD
/// gate and proof-of-delivery policy both key off of.
class CheckoutScreen extends StatefulWidget {
  final List<CartItemModel> items;
  final CartBill bill;

  const CheckoutScreen({super.key, required this.items, required this.bill});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _checkoutRepository = CheckoutRepository(Supabase.instance.client);
  final _orderRepository = OrderRepository(Supabase.instance.client);
  final _paymentRepository = PaymentRepository(Supabase.instance.client);
  final _addressController = TextEditingController();

  /// True only when a publishable Razorpay key + a Checkout launcher are
  /// both configured (PaymentRepository.isOnlinePaymentAvailable). While
  /// false, UPI/Card stay visible but disabled and COD is the working path.
  final bool _onlinePaymentReady = PaymentRepository.isOnlinePaymentAvailable;

  // Cash on Delivery is the only real, backend-enforced payment method
  // (see checkout_repository.dart's own doc comment: no payment gateway is
  // wired into this app). Defaulting to it — rather than UPI, as before —
  // means the common path never silently "succeeds" a payment nothing
  // actually collected.
  _PaymentMethod _selectedMethod = _PaymentMethod.cod;

  bool _isResolvingContext = true;
  String? _contextError;
  VendorDeliveryContext? _vendorContext;

  /// Set only from the map picker — a real coordinate the customer
  /// confirmed on the map (device GPS, a search hit, or a deliberate drag).
  LocationResult? _location;

  bool _isPlacingOrder = false;

  /// One key per checkout screen visit — reused across any retry of THIS
  /// attempt (e.g. a network failure that resets [_isPlacingOrder] and
  /// lets the customer tap Place Order again), so a retry can never create
  /// a second real order. A genuinely new attempt gets a fresh key because
  /// it gets a fresh screen. Dependency-free: this app has no uuid package
  /// and doesn't need real UUID formatting, only a unique opaque token.
  final String _idempotencyKey = List<int>.generate(
    16,
    (_) => Random.secure().nextInt(256),
  ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  @override
  void initState() {
    super.initState();
    _resolveVendorContext();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  String get _paymentLabel => switch (_selectedMethod) {
    _PaymentMethod.upi => 'UPI',
    _PaymentMethod.card => 'Credit / Debit Card',
    _PaymentMethod.cod => 'Cash on Delivery',
  };

  bool get _canPlaceOrder =>
      !_isResolvingContext &&
      _contextError == null &&
      _vendorContext != null &&
      _location != null &&
      _addressController.text.trim().isNotEmpty &&
      widget.items.isNotEmpty &&
      !_isPlacingOrder;

  Future<void> _resolveVendorContext() async {
    setState(() {
      _isResolvingContext = true;
      _contextError = null;
    });

    final vendorId = widget.items.isNotEmpty ? widget.items.first.vendorId : '';
    if (vendorId.isEmpty) {
      setState(() {
        _isResolvingContext = false;
        _contextError = 'Your cart is empty.';
      });
      return;
    }

    try {
      final context = await _checkoutRepository.resolveVendorContext(vendorId);
      if (!mounted) return;
      setState(() {
        _vendorContext = context;
        _isResolvingContext = false;
      });
    } on CheckoutException catch (error) {
      if (!mounted) return;
      setState(() {
        _contextError = error.message;
        _isResolvingContext = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _contextError = 'Could not load store details. Please try again.';
        _isResolvingContext = false;
      });
    }
  }

  Future<void> _openLocationPicker() async {
    final initial = _location == null
        ? null
        : PickedLocation(
            latitude: _location!.latitude,
            longitude: _location!.longitude,
            address: _addressController.text.trim(),
          );
    final result = await Navigator.of(context).push<AddressResult>(
      MaterialPageRoute(builder: (_) => AddAddressScreen(initial: initial)),
    );
    if (result == null || !mounted) return;
    setState(() {
      _location = LocationResult(
        latitude: result.location.latitude,
        longitude: result.location.longitude,
      );
      if (result.formatted.isNotEmpty) _addressController.text = result.formatted;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)));
  }

  Future<void> _placeOrder() async {
    if (!_canPlaceOrder) return;
    final vendorContext = _vendorContext!;
    final location = _location!;
    final isCod = _selectedMethod == _PaymentMethod.cod;

    setState(() => _isPlacingOrder = true);
    try {
      final result = await _checkoutRepository.placeOrder(
        branchId: vendorContext.branchId,
        categoryId: vendorContext.categoryId,
        items: widget.items,
        customerLat: location.latitude,
        customerLng: location.longitude,
        deliveryAddress: _addressController.text.trim(),
        isCod: isCod,
        idempotencyKey: _idempotencyKey,
      );

      if (isCod) {
        // Cash on Delivery — the order is complete the moment it's placed.
        CartStore.instance.clear();
        if (!mounted) return;
        setState(() => _isPlacingOrder = false);
        await _showOrderPlacedThenOpenDetails(result);
        return;
      }

      // Online payment: the order exists as an unpaid 'prepaid' order.
      // Drive it through the existing Razorpay gateway; the cart is only
      // cleared once payment is captured.
      await _runOnlinePayment(result);
    } on CheckoutException catch (error) {
      if (!mounted) return;
      setState(() => _isPlacingOrder = false);
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isPlacingOrder = false);
      _showMessage('Could not place your order. Please check your connection and try again.');
    }
  }

  /// UPI / Card path for a just-created 'prepaid' order. Uses the deployed
  /// razorpay-create-order + razorpay-verify-payment Edge Functions and the
  /// registered [PaymentCheckout] launcher. On dismiss/failure the unpaid
  /// order is cancelled server-side (de_cancel_unpaid_order), and the
  /// razorpay-webhook `payment.failed` backstop covers a client that closes
  /// mid-flow.
  Future<void> _runOnlinePayment(PlaceOrderResult result) async {
    final launcher = PaymentRepository.checkout;
    if (!_onlinePaymentReady || launcher == null) {
      // Should be unreachable (the UPI option is disabled when not ready),
      // but never leave a dangling unpaid order.
      await _paymentRepository.cancelUnpaidOrder(result.orderId);
      if (!mounted) return;
      setState(() => _isPlacingOrder = false);
      _showMessage('Online payment is not available yet. Please use Cash on Delivery.');
      return;
    }

    try {
      final gatewayOrder = await _paymentRepository.createGatewayOrder(
        vertical: 'daily_essentials',
        referenceId: result.orderId,
      );
      final user = Supabase.instance.client.auth.currentUser;
      final success = await launcher.open(
        keyId: gatewayOrder.keyId,
        razorpayOrderId: gatewayOrder.razorpayOrderId,
        amountPaise: gatewayOrder.amountPaise,
        currency: gatewayOrder.currency,
        customerName: user?.userMetadata?['full_name']?.toString() ?? 'SnapBee Customer',
        customerEmail: user?.email ?? '',
        customerPhone: user?.phone ?? '',
        description: 'SnapBee Daily Essentials order',
      );

      if (success == null) {
        await _paymentRepository.cancelUnpaidOrder(result.orderId);
        if (!mounted) return;
        setState(() => _isPlacingOrder = false);
        _showMessage('Payment cancelled. Your order was not placed.');
        return;
      }

      await _paymentRepository.verifyPayment(
        razorpayOrderId: success.razorpayOrderId,
        razorpayPaymentId: success.razorpayPaymentId,
        razorpaySignature: success.razorpaySignature,
      );

      CartStore.instance.clear();
      if (!mounted) return;
      setState(() => _isPlacingOrder = false);
      await _showOrderPlacedThenOpenDetails(result);
    } on PaymentException catch (e) {
      await _paymentRepository.cancelUnpaidOrder(result.orderId);
      if (!mounted) return;
      setState(() => _isPlacingOrder = false);
      _showMessage(e.message);
    } catch (_) {
      await _paymentRepository.cancelUnpaidOrder(result.orderId);
      if (!mounted) return;
      setState(() => _isPlacingOrder = false);
      _showMessage('Payment could not be completed. Your order was not placed.');
    }
  }

  /// Loads the just-created order back from Supabase (not just the RPC's own
  /// return values), then replaces Checkout with the full-screen
  /// [OrderSuccessScreen] (reference 12). Falls back to the RPC result only
  /// if that read-back itself fails (a transient network hiccup right after
  /// a successful placement), so the customer still lands somewhere correct.
  Future<void> _showOrderPlacedThenOpenDetails(PlaceOrderResult result) async {
    final navigator = Navigator.of(context);

    OrderRow? order;
    try {
      order = await _orderRepository.fetchOrderById(result.orderId);
    } catch (_) {
      order = null;
    }
    if (!mounted) return;

    final storeName =
        (order != null && order.vendorName.isNotEmpty) ? order.vendorName : 'Store';
    final data = order != null
        ? OrderDetailsData.fromSupabaseOrder(order, paymentLabel: _paymentLabel)
        : OrderDetailsData(
            orderId: result.orderId,
            storeName: storeName,
            storeImageUrl: '',
            itemsCount: widget.items.fold<int>(0, (sum, i) => sum + i.quantity),
            amount: result.totalAmount,
            etaOrDate: 'Order placed',
            paymentLabel: _paymentLabel,
            timelineStage: 0,
            isCancelled: false,
          );

    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (_) => OrderSuccessScreen(
          orderId: result.orderId,
          amount: result.totalAmount,
          paymentLabel: _paymentLabel,
          storeName: storeName,
          placedAt: order?.orderDate ?? DateTime.now(),
          detailsData: data,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemCount = widget.items.fold<int>(0, (sum, i) => sum + i.quantity);

    return Scaffold(
      backgroundColor: SnapBeeColors.scaffold,
      appBar: const SnapBeeAppBar(
        subtitle: 'Daily Essentials',
        trailing: Padding(
          padding: EdgeInsets.only(right: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_user_rounded, size: 15, color: SnapBeeColors.success),
              SizedBox(width: 4),
              Text('100% Secure', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: SnapBeeColors.success)),
            ],
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            const SizedBox(height: 10),
            const _CheckoutSteps(current: 1),
            const SizedBox(height: 6),
            _SectionCard(
              icon: Icons.location_on_rounded,
              title: 'Delivery Location',
              child: _DeliveryLocationBlock(
                isResolvingStore: _isResolvingContext,
                storeError: _contextError,
                onRetryStore: _resolveVendorContext,
                location: _location,
                onPickLocation: _openLocationPicker,
                addressController: _addressController,
                onAddressChanged: () => setState(() {}),
              ),
            ),
            _SectionCard(
              icon: Icons.receipt_long_rounded,
              title:
                  '$itemCount item${itemCount == 1 ? '' : 's'} in this order',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final item in widget.items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item.name} x${item.quantity}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          Text(
                            '₹${item.lineTotal.toStringAsFixed(0)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            _SectionCard(
              icon: Icons.payments_rounded,
              title: 'Payment Method',
              child: Column(
                children: [
                  _PaymentOption(
                    label: 'UPI (GPay, PhonePe, Paytm)',
                    subtitle: _onlinePaymentReady
                        ? 'Fast • Secure • via Razorpay'
                        : 'Requires Razorpay setup — use Cash on Delivery for now',
                    icon: Icons.qr_code_rounded,
                    selected: _selectedMethod == _PaymentMethod.upi,
                    enabled: _onlinePaymentReady,
                    onTap: _onlinePaymentReady
                        ? () => setState(() => _selectedMethod = _PaymentMethod.upi)
                        : () => _showMessage(
                              'Online payment needs Razorpay credentials configured. Please use Cash on Delivery.',
                            ),
                  ),
                  _PaymentOption(
                    label: 'Credit / Debit Card',
                    subtitle: _onlinePaymentReady
                        ? 'Visa, Mastercard, RuPay • via Razorpay'
                        : 'Requires Razorpay setup — use Cash on Delivery for now',
                    icon: Icons.credit_card_rounded,
                    selected: _selectedMethod == _PaymentMethod.card,
                    enabled: _onlinePaymentReady,
                    onTap: _onlinePaymentReady
                        ? () => setState(() => _selectedMethod = _PaymentMethod.card)
                        : () => _showMessage(
                              'Online payment needs Razorpay credentials configured. Please use Cash on Delivery.',
                            ),
                  ),
                  _PaymentOption(
                    label: 'Cash on Delivery',
                    subtitle: 'Pay when your order arrives',
                    icon: Icons.local_shipping_outlined,
                    selected: _selectedMethod == _PaymentMethod.cod,
                    onTap: () =>
                        setState(() => _selectedMethod = _PaymentMethod.cod),
                  ),
                ],
              ),
            ),
            BillSummaryCard(bill: widget.bill, deliveryChargeIsEstimate: true),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _canPlaceOrder ? _placeOrder : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isPlacingOrder
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Place Order • ₹${widget.bill.grandTotal.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Real delivery-location capture — no fabricated address anywhere in this
/// block. Shows store-resolution status, then a map picker
/// ([LocationPickerScreen]) that yields a real coordinate + address, then a
/// mini OSM preview of the chosen point and a still-editable
/// address/landmark field (this text becomes `p_delivery_address`; the
/// coordinate becomes `customer_lat`/`customer_lng`).
class _DeliveryLocationBlock extends StatelessWidget {
  final bool isResolvingStore;
  final String? storeError;
  final VoidCallback onRetryStore;
  final LocationResult? location;
  final VoidCallback onPickLocation;
  final TextEditingController addressController;
  final VoidCallback onAddressChanged;

  const _DeliveryLocationBlock({
    required this.isResolvingStore,
    required this.storeError,
    required this.onRetryStore,
    required this.location,
    required this.onPickLocation,
    required this.addressController,
    required this.onAddressChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isResolvingStore) {
      return const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text('Checking store availability…'),
        ],
      );
    }

    if (storeError != null) {
      return Row(
        children: [
          Expanded(
            child: Text(
              storeError!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
          TextButton(onPressed: onRetryStore, child: const Text('Retry')),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (location == null)
          OutlinedButton.icon(
            onPressed: onPickLocation,
            icon: const Icon(Icons.map_outlined, size: 16),
            label: const Text('Set delivery location on map'),
          )
        else ...[
          StaticLocationMap(
            point: LatLng(location!.latitude, location!.longitude),
            height: 140,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF2E7D32)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${location!.latitude.toStringAsFixed(5)}, '
                  '${location!.longitude.toStringAsFixed(5)}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              TextButton.icon(
                onPressed: onPickLocation,
                icon: const Icon(Icons.edit_location_alt_outlined, size: 16),
                label: const Text('Change'),
              ),
            ],
          ),
        ],
        const SizedBox(height: 10),
        TextField(
          controller: addressController,
          onChanged: (_) => onAddressChanged(),
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Delivery address / landmark',
            hintText: 'House no., street, landmark',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primaryOrange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  /// False for UPI/Card — no payment gateway is wired into this app (see
  /// checkout_repository.dart), so those options stay visible (real,
  /// planned methods — not hidden) but greyed out and unselectable rather
  /// than silently "succeeding" a payment nothing actually collected.
  final bool enabled;

  const _PaymentOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = enabled ? AppColors.primaryOrange : theme.colorScheme.outlineVariant;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primaryOrangeLight.withValues(alpha: 0.5)
                : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.primaryOrange
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                enabled
                    ? (selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded)
                    : Icons.lock_outline_rounded,
                size: enabled ? 24 : 18,
                color: selected ? AppColors.primaryOrange : theme.colorScheme.outlineVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The 4-step Cart → Checkout → Payment → Order Placed indicator from the
/// reference. Purely visual.
class _CheckoutSteps extends StatelessWidget {
  final int current;
  const _CheckoutSteps({required this.current});

  static const _labels = ['Cart', 'Checkout', 'Payment', 'Order Placed'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SnapBeeSpacing.gutter),
      child: Row(
        children: [
          for (int i = 0; i < _labels.length; i++) ...[
            if (i != 0)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  color: i <= current ? SnapBeeColors.orange : SnapBeeColors.hairline,
                ),
              ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i <= current ? SnapBeeColors.orange : SnapBeeColors.chipFill,
                  ),
                  child: i < current
                      ? const Icon(Icons.check, size: 13, color: Colors.white)
                      : Text('${i + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: i == current ? Colors.white : SnapBeeColors.inkFaint,
                          )),
                ),
                const SizedBox(height: 3),
                Text(_labels[i],
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: i == current ? FontWeight.w800 : FontWeight.w500,
                      color: i <= current ? SnapBeeColors.ink : SnapBeeColors.inkFaint,
                    )),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
