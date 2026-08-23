import 'package:flutter_test/flutter_test.dart';
import 'package:snapbee_customer_app/data/repositories/order_repository.dart';
import 'package:snapbee_customer_app/screens/order_history/models/order_history_model.dart';

/// Covers OrderHistoryModel.fromOrderRow — the adapter that replaced
/// OrderHistoryScreen's fabricated sample-order fallback. Before this fix,
/// every "History" entry point (Orders tab x2, Profile) opened
/// OrderHistoryScreen with no `orders` argument, so real customers always
/// saw made-up orders (fake vendor names, fake order numbers like
/// "#SB-ORD-10293", fake amounts) instead of their real order history.
void main() {
  group('OrderHistoryModel.fromOrderRow', () {
    test('delivered order maps id/vendor/amount/items through as-is', () {
      final row = OrderRow(
        id: 'order-1',
        vendorName: 'Green Leaf Grocers',
        totalAmount: 219,
        status: 'pending',
        orderDate: DateTime(2026, 8, 23, 9, 39),
        deliveredAt: DateTime(2026, 8, 23, 10, 5),
        itemCount: 4,
      );

      final model = OrderHistoryModel.fromOrderRow(row);

      expect(model.id, 'order-1');
      expect(model.orderNumber, 'order-1');
      expect(model.storeName, 'Green Leaf Grocers');
      expect(model.amount, 219);
      expect(model.itemCount, 4);
      expect(model.itemsPreview, '4 items');
      expect(model.deliveryStatus, DeliveryStatus.delivered);
      expect(model.paymentStatus, PaymentStatus.paid);
    });

    test('a single item uses singular "1 item" in the preview', () {
      final row = OrderRow(
        id: 'order-2',
        vendorName: 'Spice Route Kitchen',
        totalAmount: 100,
        status: 'pending',
        orderDate: DateTime(2026, 8, 22),
        itemCount: 1,
      );

      expect(OrderHistoryModel.fromOrderRow(row).itemsPreview, '1 item');
    });

    test('cancelled takes priority over any timeline stage', () {
      final row = OrderRow(
        id: 'order-3',
        vendorName: 'Store',
        totalAmount: 50,
        status: 'cancelled',
        orderDate: DateTime(2026, 8, 20),
        onTheWayAt: DateTime(2026, 8, 20, 1),
        cancelledAt: DateTime(2026, 8, 20, 2),
      );

      expect(OrderHistoryModel.fromOrderRow(row).deliveryStatus, DeliveryStatus.cancelled);
    });

    test('an order with no vendor_name falls back to "Store", never blank', () {
      final row = OrderRow(
        id: 'order-4',
        vendorName: '',
        totalAmount: 75,
        status: 'pending',
        orderDate: DateTime(2026, 8, 21),
      );

      expect(OrderHistoryModel.fromOrderRow(row).storeName, 'Store');
    });

    test('mid-flight timeline stages (placed/preparing/out for delivery) map correctly', () {
      DeliveryStatus statusFor(OrderRow row) => OrderHistoryModel.fromOrderRow(row).deliveryStatus;

      expect(
        statusFor(OrderRow(id: 'a', vendorName: 'S', totalAmount: 1, status: 'pending', orderDate: DateTime(2026))),
        DeliveryStatus.placed,
      );
      expect(
        statusFor(OrderRow(id: 'b', vendorName: 'S', totalAmount: 1, status: 'preparing', orderDate: DateTime(2026))),
        DeliveryStatus.preparing,
      );
      expect(
        statusFor(OrderRow(
          id: 'c',
          vendorName: 'S',
          totalAmount: 1,
          status: 'pending',
          orderDate: DateTime(2026),
          onTheWayAt: DateTime(2026),
        )),
        DeliveryStatus.outForDelivery,
      );
    });
  });
}
