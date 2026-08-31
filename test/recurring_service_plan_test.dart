import 'package:flutter_test/flutter_test.dart';
import 'package:snapbee_customer_app/features/services/models/recurring_service_plan.dart';

void main() {
  group('RecurringServicePlan.fromJson', () {
    test('parses fields and the embedded service name', () {
      final p = RecurringServicePlan.fromJson({
        'id': 'p1',
        'service_id': 's1',
        'frequency': 'biweekly',
        'custom_interval_days': null,
        'is_amc': false,
        'next_run_date': '2026-10-01',
        'status': 'active',
        'preferred_time_slot': 'morning',
        'services': {'name': 'Home cleaning'},
      });
      expect(p.id, 'p1');
      expect(p.serviceName, 'Home cleaning');
      expect(p.isActive, isTrue);
      expect(p.frequencyLabel, 'Every 2 weeks');
      expect(p.preferredTimeSlot, 'morning');
    });

    test('custom frequency label uses the interval, status helpers', () {
      final p = RecurringServicePlan.fromJson({
        'id': 'p2',
        'service_id': 's2',
        'frequency': 'custom',
        'custom_interval_days': 10,
        'is_amc': true,
        'next_run_date': '2026-10-01',
        'status': 'paused',
      });
      expect(p.frequencyLabel, 'Every 10 days');
      expect(p.isAmc, isTrue);
      expect(p.isPaused, isTrue);
      expect(p.isActive, isFalse);
    });
  });
}
