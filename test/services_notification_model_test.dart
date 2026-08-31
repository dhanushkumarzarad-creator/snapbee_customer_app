import 'package:flutter_test/flutter_test.dart';
import 'package:snapbee_customer_app/features/services/models/service_notification.dart';

void main() {
  group('ServiceNotification.fromJson', () {
    test('parses fields and trims/nulls an empty body', () {
      final n = ServiceNotification.fromJson({
        'id': 'n1',
        'booking_id': 'BK-1',
        'kind': 'chat',
        'title': 'New message',
        'body': '  see you at 3  ',
        'is_read': false,
        'created_at': '2026-09-06T09:00:00Z',
      });
      expect(n.id, 'n1');
      expect(n.bookingId, 'BK-1');
      expect(n.kind, 'chat');
      expect(n.body, 'see you at 3');
      expect(n.isRead, isFalse);
    });

    test('defaults kind, nulls blank body and missing booking_id', () {
      final n = ServiceNotification.fromJson({
        'id': 'n2',
        'title': 'Quotation ready for approval',
        'body': '   ',
        'is_read': true,
        'created_at': '2026-09-06T09:00:00Z',
      });
      expect(n.kind, 'booking_status');
      expect(n.body, isNull);
      expect(n.bookingId, isNull);
      expect(n.isRead, isTrue);
    });
  });
}
