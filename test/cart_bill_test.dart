import 'package:flutter_test/flutter_test.dart';
import 'package:snapbee_customer_app/screens/cart/models/cart_model.dart';

CartItemModel _item({double price = 100, int qty = 1}) => CartItemModel(
      id: 'i1',
      productId: 'p1',
      name: 'Thing',
      imageUrl: '',
      unit: '',
      price: price,
      vendorId: 'v1',
      quantity: qty,
    );

void main() {
  group('CartCalculator.computeBill', () {
    test('grand total is exactly items + delivery + platform fee — no discount line', () {
      const calc = CartCalculator(baseDeliveryCharge: 25, platformFee: 6, freeDeliveryThreshold: 199);
      final bill = calc.computeBill([_item(price: 100, qty: 1)]);

      expect(bill.itemTotal, 100);
      expect(bill.deliveryCharge, 25); // below the free-delivery threshold
      expect(bill.platformFee, 6);
      expect(bill.grandTotal, 131);
    });

    test('free delivery above the threshold, still no discount', () {
      const calc = CartCalculator(baseDeliveryCharge: 25, platformFee: 6, freeDeliveryThreshold: 199);
      final bill = calc.computeBill([_item(price: 250, qty: 1)]);

      expect(bill.deliveryCharge, 0);
      expect(bill.grandTotal, 256);
    });
  });
}
