import 'package:flutter_test/flutter_test.dart';
import 'package:snapbee_customer_app/features/services/models/service_offer.dart';

void main() {
  group('ServiceOfferRow.fromJson', () {
    test('parses category_id and service_id when present, so an offer card can resolve where it navigates', () {
      final row = ServiceOfferRow.fromJson({
        'id': 'off-1',
        'description': '10% off AC service',
        'discount_type': 'percent',
        'discount_value': 10,
        'category_id': 'cat-1',
        'service_id': 'svc-1',
      });
      expect(row.categoryId, 'cat-1');
      expect(row.serviceId, 'svc-1');
    });

    test('defaults category_id and service_id to null for a storewide offer', () {
      final row = ServiceOfferRow.fromJson({
        'id': 'off-2',
        'description': 'Flat ₹100 off any booking',
        'discount_type': 'flat',
        'discount_value': 100,
      });
      expect(row.categoryId, isNull);
      expect(row.serviceId, isNull);
    });
  });
}
