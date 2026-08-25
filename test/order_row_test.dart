import 'package:flutter_test/flutter_test.dart';
import 'package:snapbee_customer_app/data/repositories/order_repository.dart';

void main() {
  group('OrderRow.fromJson', () {
    test('carries delivery_partner_id through when present', () {
      final row = OrderRow.fromJson({
        'id': 'ORD-1',
        'vendor_name': 'Fresh Mart',
        'total_amount': 250,
        'status': 'onTheWay',
        'order_date': '2026-08-20T10:00:00Z',
        'delivery_partner_id': 'dp-123',
      });

      expect(row.deliveryPartnerId, 'dp-123');
    });

    test('defaults delivery_partner_id to null when the order is not yet assigned', () {
      final row = OrderRow.fromJson({
        'id': 'ORD-2',
        'vendor_name': 'Fresh Mart',
        'total_amount': 250,
        'status': 'pending',
        'order_date': '2026-08-20T10:00:00Z',
      });

      expect(row.deliveryPartnerId, isNull);
    });
  });
}
