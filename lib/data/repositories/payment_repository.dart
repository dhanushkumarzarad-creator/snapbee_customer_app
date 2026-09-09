// ============================================================================
// payment_repository.dart
// ----------------------------------------------------------------------------
// The Customer app's client-side boundary to the EXISTING SnapBee Razorpay
// gateway. It never touches a secret: it only invokes the deployed Edge
// Functions (razorpay-create-order / razorpay-verify-payment) and one
// client-safe cleanup RPC. All money-moving decisions — amount
// re-derivation, HMAC signature verification, idempotent capture, webhook
// replay guarding — happen server-side in
// snapbee_admin/supabase/functions/razorpay-* +
// razorpay_payment_gateway_foundation.sql +
// razorpay_daily_essentials_wiring.sql.
//
// Flow for a Daily Essentials online-payment order:
//   1. place_customer_order(p_payment_method:'prepaid')  -> order_id      (checkout_repository)
//   2. createGatewayOrder(vertical:'daily_essentials', referenceId:order) -> {razorpayOrderId, keyId, amountPaise}
//   3. open Razorpay Checkout with those values                          (PaymentCheckout — see below)
//   4a. on success  -> verifyPayment(orderId, paymentId, signature)      -> server captures + confirms
//   4b. on dismiss  -> cancelUnpaidOrder(order_id)                       -> server cancels the unpaid order
//
// Step 3 needs the Razorpay Checkout SDK + a publishable RAZORPAY_KEY_ID.
// Neither ships in this repo yet, so [PaymentCheckout] is an injectable
// interface with no default implementation — `isOnlinePaymentAvailable`
// stays false until one is registered and the key is configured, and
// checkout keeps Cash on Delivery as the working path.
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/env_config.dart';

class GatewayOrder {
  final String razorpayOrderId;
  final int amountPaise;
  final String currency;
  final String keyId;
  final String transactionId;

  const GatewayOrder({
    required this.razorpayOrderId,
    required this.amountPaise,
    required this.currency,
    required this.keyId,
    required this.transactionId,
  });

  factory GatewayOrder.fromJson(Map<String, dynamic> j) => GatewayOrder(
        razorpayOrderId: j['razorpay_order_id'] as String,
        amountPaise: (j['amount'] as num).toInt(),
        currency: (j['currency'] as String?) ?? 'INR',
        keyId: (j['key_id'] as String?) ?? '',
        transactionId: (j['transaction_id'] as String?) ?? '',
      );
}

class PaymentException implements Exception {
  final String message;
  const PaymentException(this.message);
  @override
  String toString() => message;
}

/// The result the Razorpay Checkout sheet hands back on success — supplied
/// by whatever [PaymentCheckout] implementation is registered.
class CheckoutSuccess {
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String razorpaySignature;
  const CheckoutSuccess({
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    required this.razorpaySignature,
  });
}

/// Injectable Razorpay Checkout launcher. A real implementation wraps the
/// Razorpay Checkout SDK (mobile) or checkout.js (web). Register one with
/// [PaymentRepository.registerCheckout] once the SDK + RAZORPAY_KEY_ID are
/// available; until then online payment is disabled and COD is used.
abstract class PaymentCheckout {
  /// Opens the Razorpay sheet. Returns the success payload, or null if the
  /// customer dismissed / the payment failed.
  Future<CheckoutSuccess?> open({
    required String keyId,
    required String razorpayOrderId,
    required int amountPaise,
    required String currency,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String description,
  });
}

class PaymentRepository {
  PaymentRepository(this._client);

  final SupabaseClient _client;

  static PaymentCheckout? _checkout;

  /// Register the platform Razorpay Checkout launcher (see [PaymentCheckout]).
  static void registerCheckout(PaymentCheckout checkout) => _checkout = checkout;

  static PaymentCheckout? get checkout => _checkout;

  /// True only when BOTH a publishable key is configured and a checkout
  /// launcher is registered. Checkout reads this to decide whether to offer
  /// UPI/Card as a real option.
  static bool get isOnlinePaymentAvailable =>
      EnvConfig.razorpayKeyId.isNotEmpty && _checkout != null;

  /// Creates a Razorpay order for a SnapBee reference (calls the deployed
  /// `razorpay-create-order` Edge Function; the amount is re-derived
  /// server-side and never sent from here).
  Future<GatewayOrder> createGatewayOrder({
    required String vertical,
    String? referenceId,
    Map<String, dynamic>? payload,
  }) async {
    final body = <String, dynamic>{'vertical': vertical};
    if (referenceId != null) body['reference_id'] = referenceId;
    if (payload != null) body['payload'] = payload;
    try {
      final res = await _client.functions.invoke('razorpay-create-order', body: body);
      final data = res.data;
      if (data is Map && data['razorpay_order_id'] != null) {
        return GatewayOrder.fromJson(Map<String, dynamic>.from(data));
      }
      final err = (data is Map ? data['error'] : null) ?? 'Could not start the payment.';
      throw PaymentException(err.toString());
    } on PaymentException {
      rethrow;
    } catch (_) {
      throw const PaymentException('Could not start the payment. Please try again.');
    }
  }

  /// Fast-path verification after Razorpay Checkout succeeds (calls the
  /// deployed `razorpay-verify-payment` Edge Function, which recomputes the
  /// HMAC signature server-side before capturing).
  Future<void> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final res = await _client.functions.invoke(
        'razorpay-verify-payment',
        body: {
          'razorpay_order_id': razorpayOrderId,
          'razorpay_payment_id': razorpayPaymentId,
          'razorpay_signature': razorpaySignature,
        },
      );
      final data = res.data;
      if (data is Map && (data['status'] == 'captured' || data['already_captured'] == true)) {
        return;
      }
      final err = (data is Map ? data['error'] : null) ?? 'Payment verification failed.';
      throw PaymentException(err.toString());
    } on PaymentException {
      rethrow;
    } catch (_) {
      throw const PaymentException(
        'We could not confirm your payment. If money was deducted it will be '
        'auto-refunded, or contact support.',
      );
    }
  }

  /// Client-side cleanup when the customer dismisses the Razorpay sheet
  /// without paying — cancels their own still-pending, unpaid prepaid
  /// order (server-enforced: cannot touch a COD order, a paid order, or
  /// someone else's order).
  Future<void> cancelUnpaidOrder(String orderId) async {
    try {
      await _client.rpc('de_cancel_unpaid_order', params: {'p_order_id': orderId});
    } catch (_) {
      // Best-effort — a webhook `payment.failed` is the reliable backstop.
    }
  }
}
