import 'package:flutter_test/flutter_test.dart';
import 'package:snapbee_customer_app/data/repositories/address_repository.dart';
import 'package:snapbee_customer_app/data/repositories/order_review_repository.dart';
import 'package:snapbee_customer_app/data/repositories/payment_repository.dart';

void main() {
  group('OrderReview.fromRow', () {
    test('maps the get_de_order_review row shape', () {
      final r = OrderReview.fromRow({
        'id': 'r1',
        'order_id': 'ORD-0042',
        'rating': 4,
        'review_text': 'Fresh and fast',
        'tags': ['Great Quality', 'On Time Delivery'],
        'product_ratings': {'p1': 5},
        'created_at': '2026-09-07T10:00:00Z',
      });
      expect(r.id, 'r1');
      expect(r.orderId, 'ORD-0042');
      expect(r.rating, 4);
      expect(r.tags, ['Great Quality', 'On Time Delivery']);
      expect(r.productRatings['p1'], 5);
    });

    test('tolerates null review_text / missing tags', () {
      final r = OrderReview.fromRow({
        'id': 'r2',
        'order_id': 'ORD-1',
        'rating': 5,
        'review_text': null,
        'tags': null,
        'product_ratings': null,
        'created_at': '2026-09-07T10:00:00Z',
      });
      expect(r.reviewText, isNull);
      expect(r.tags, isEmpty);
      expect(r.productRatings, isEmpty);
    });
  });

  group('CustomerAddress.fromRow', () {
    test('maps a full customer_addresses row', () {
      final a = CustomerAddress.fromRow({
        'id': 'a1',
        'label': 'Home',
        'tag': 'home',
        'recipient_name': 'Dhanush',
        'phone': '9876500000',
        'house': '12/3',
        'street': 'Anna Nagar',
        'landmark': null,
        'area': 'Anna Nagar',
        'city': 'Dharmapuri',
        'district': 'Dharmapuri',
        'state': 'TN',
        'pincode': '636701',
        'latitude': 12.128,
        'longitude': 78.157,
        'formatted_address': '12/3, Anna Nagar, Dharmapuri - 636701',
        'delivery_instructions': 'Ring the bell',
        'is_default': true,
      });
      expect(a.id, 'a1');
      expect(a.tag, 'home');
      expect(a.isDefault, isTrue);
      expect(a.latitude, closeTo(12.128, 1e-9));
      expect(a.formattedAddress, contains('Anna Nagar'));
    });

    test('defaults tag/label/is_default when absent', () {
      final a = CustomerAddress.fromRow({
        'id': 'a2',
        'latitude': 1.0,
        'longitude': 2.0,
        'formatted_address': 'somewhere',
      });
      expect(a.label, 'Home');
      expect(a.tag, 'other');
      expect(a.isDefault, isFalse);
    });
  });

  group('GatewayOrder.fromJson', () {
    test('maps the razorpay-create-order response', () {
      final g = GatewayOrder.fromJson({
        'razorpay_order_id': 'order_abc',
        'amount': 41000,
        'currency': 'INR',
        'key_id': 'rzp_test_x',
        'transaction_id': 'txn1',
      });
      expect(g.razorpayOrderId, 'order_abc');
      expect(g.amountPaise, 41000);
      expect(g.currency, 'INR');
      expect(g.keyId, 'rzp_test_x');
    });
  });

  test('online payment is unavailable until a key + launcher are configured', () {
    // No RAZORPAY_KEY_ID in test env and no PaymentCheckout registered.
    expect(PaymentRepository.isOnlinePaymentAvailable, isFalse);
  });
}
