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

  group('RecurringServicePlan.nextRunAfter — matches the SQL cadence math', () {
    final from = DateTime(2026, 8, 15);

    test('weekly = +7 days', () {
      expect(RecurringServicePlan.nextRunAfter(from, 'weekly'), DateTime(2026, 8, 22));
    });
    test('biweekly = +14 days', () {
      expect(RecurringServicePlan.nextRunAfter(from, 'biweekly'), DateTime(2026, 8, 29));
    });
    test('monthly = +1 calendar month', () {
      expect(RecurringServicePlan.nextRunAfter(from, 'monthly'), DateTime(2026, 9, 15));
      // month rollover
      expect(RecurringServicePlan.nextRunAfter(DateTime(2026, 12, 10), 'monthly'), DateTime(2027, 1, 10));
    });
    test('quarterly = +3 calendar months', () {
      expect(RecurringServicePlan.nextRunAfter(from, 'quarterly'), DateTime(2026, 11, 15));
    });
    test('custom uses the supplied interval, default 30', () {
      expect(RecurringServicePlan.nextRunAfter(from, 'custom', customIntervalDays: 10), DateTime(2026, 8, 25));
      expect(RecurringServicePlan.nextRunAfter(from, 'custom'), DateTime(2026, 9, 14));
    });
    test('unknown frequency falls back to monthly', () {
      expect(RecurringServicePlan.nextRunAfter(from, 'yearly'), DateTime(2026, 9, 15));
    });
    test('drops the time component of `from`', () {
      final r = RecurringServicePlan.nextRunAfter(DateTime(2026, 8, 15, 23, 59), 'weekly');
      expect(r, DateTime(2026, 8, 22));
    });
  });
}
