import 'package:flutter_test/flutter_test.dart';
import 'package:snapbee_customer_app/data/repositories/live_tracking_repository.dart';

void main() {
  group('PartnerLocation.fromJson', () {
    test('parses a row with the embedded delivery_partners name/phone', () {
      final location = PartnerLocation.fromJson({
        'lat': 12.9716,
        'lng': 77.5946,
        'recorded_at': '2026-08-20T10:00:00Z',
        'delivery_partners': {'name': 'Suresh Babu', 'mobile_number': '+91 90000 11111'},
      });

      expect(location.partnerName, 'Suresh Babu');
      expect(location.partnerPhone, '+91 90000 11111');
      expect(location.lat, 12.9716);
      expect(location.lng, 77.5946);
    });

    test('falls back to a generic name when the partner embed is missing', () {
      final location = PartnerLocation.fromJson({
        'lat': 12.9716,
        'lng': 77.5946,
        'recorded_at': '2026-08-20T10:00:00Z',
      });

      expect(location.partnerName, 'Your delivery partner');
      expect(location.partnerPhone, isNull);
    });
  });
}
