import 'package:flutter_test/flutter_test.dart';
import 'package:snapbee_customer_app/features/services/booking/method_booking_fields.dart';

/// The method -> booking-form-shape decision (spec section 7). One
/// [MethodBookingPlan] per Master Method code drives which sections the
/// booking screen shows and which `p_location_type` it sends.
void main() {
  group('MethodBookingPlan.forCode', () {
    test('all 11 master method codes map to a distinct, sensible plan', () {
      final cases = <String, ({bool addr, bool date, bool slot, String loc})>{
        'store_pickup': (addr: false, date: true, slot: true, loc: 'provider_location'),
        'store_delivery': (addr: true, date: true, slot: true, loc: 'customer_home'),
        'appointment_booking': (addr: false, date: true, slot: true, loc: 'provider_location'),
        'home_visit': (addr: true, date: true, slot: true, loc: 'customer_home'),
        'instant_on_demand': (addr: true, date: false, slot: false, loc: 'customer_home'),
        'pickup_and_drop': (addr: true, date: true, slot: true, loc: 'pickup_drop'),
        'multi_step_workflow': (addr: true, date: true, slot: true, loc: 'onsite'),
        'subscription': (addr: true, date: true, slot: true, loc: 'customer_home'),
        'lead_generation': (addr: false, date: false, slot: false, loc: 'other'),
        'hybrid': (addr: true, date: true, slot: true, loc: 'other'),
        'walk_in': (addr: false, date: false, slot: false, loc: 'provider_location'),
      };

      for (final entry in cases.entries) {
        final p = MethodBookingPlan.forCode(entry.key);
        final want = entry.value;
        expect(p.needsServiceAddress, want.addr, reason: '${entry.key} address');
        expect(p.needsDate, want.date, reason: '${entry.key} date');
        expect(p.needsTimeSlot, want.slot, reason: '${entry.key} slot');
        expect(p.locationType, want.loc, reason: '${entry.key} location_type');
        expect(p.intro, isNotEmpty, reason: '${entry.key} intro');
      }
    });

    test('every location_type is one create_service_booking accepts', () {
      const allowed = {'customer_home', 'provider_location', 'onsite', 'pickup_drop', 'other'};
      for (final code in [
        'store_pickup', 'store_delivery', 'appointment_booking', 'home_visit', 'instant_on_demand',
        'pickup_and_drop', 'multi_step_workflow', 'subscription', 'lead_generation', 'hybrid', 'walk_in', null
      ]) {
        expect(allowed.contains(MethodBookingPlan.forCode(code).locationType), isTrue, reason: '$code');
      }
    });

    test('unknown / null code falls back to the generic full form', () {
      final p = MethodBookingPlan.forCode(null);
      expect(p.needsServiceAddress, isTrue);
      expect(p.needsDate, isTrue);
      expect(p.needsTimeSlot, isTrue);
      expect(p.locationType, 'customer_home');
    });
  });
}
