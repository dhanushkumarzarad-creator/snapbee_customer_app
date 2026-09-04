// Pure grouping logic for the customer Service-Method surfaces
// (vendor_method_group.dart). Proves the finalized rules:
//   * vendor-level method suspension does NOT hide the vendor — a vendor
//     with one suspended (absent) method and one live method still appears,
//     with the live method;
//   * "Currently Unavailable" methods are kept (shown greyed), not dropped;
//   * ordering: providers with a bookable method first, then rating desc;
//     within a provider/service, available methods first;
//   * an out-of-coverage provider that produced no rows simply isn't a
//     group (the repository / RPC already filtered it).

import 'package:flutter_test/flutter_test.dart';
import 'package:snapbee_customer_app/features/services/models/service_method.dart';
import 'package:snapbee_customer_app/features/services/models/vendor_method_group.dart';

ServiceMethodRow _m({
  required String vendorId,
  required String vendorName,
  double vendorRating = 0,
  int vendorRatingCount = 0,
  String? serviceId = 'svc-1',
  String? serviceName = 'Service One',
  required String methodCode,
  required String methodName,
  bool available = true,
  double? distanceKm,
}) =>
    ServiceMethodRow(
      configId: '$vendorId-$methodCode',
      vendorId: vendorId,
      vendorName: vendorName,
      vendorRatingAvg: vendorRating,
      vendorRatingCount: vendorRatingCount,
      serviceId: serviceId,
      serviceName: serviceName,
      methodId: 'mid-$methodCode',
      methodCode: methodCode,
      methodName: methodName,
      methodShortName: methodName,
      distanceKm: distanceKm,
      isAvailable: available,
      unavailableReason: available ? null : MethodUnavailableReason.capacityFull,
    );

void main() {
  group('groupMethodsByVendor', () {
    test('vendor with a suspended (absent) method still shows, with its live method', () {
      // The RPC omits the suspended config entirely, so only "home_visit"
      // arrives for vendor A. It must still be a group.
      final rows = [
        _m(vendorId: 'A', vendorName: 'Alpha', methodCode: 'home_visit', methodName: 'Home Visit'),
      ];
      final groups = groupMethodsByVendor(rows);
      expect(groups, hasLength(1));
      expect(groups.single.vendorId, 'A');
      expect(groups.single.methods.map((m) => m.methodCode), ['home_visit']);
    });

    test('currently-unavailable methods are kept, not dropped', () {
      final rows = [
        _m(vendorId: 'A', vendorName: 'Alpha', methodCode: 'home_visit', methodName: 'Home Visit', available: false),
        _m(vendorId: 'A', vendorName: 'Alpha', methodCode: 'pickup_and_drop', methodName: 'Pickup & Drop'),
      ];
      final g = groupMethodsByVendor(rows).single;
      expect(g.methods, hasLength(2));
      expect(g.availableCount, 1);
      // available method sorts before the unavailable one
      expect(g.methods.first.methodCode, 'pickup_and_drop');
    });

    test('providers ordered: has-a-bookable-method first, then rating desc', () {
      final rows = [
        _m(vendorId: 'LOWRATE', vendorName: 'Low', vendorRating: 3.0, vendorRatingCount: 5,
            methodCode: 'home_visit', methodName: 'Home Visit'),
        _m(vendorId: 'HIGHRATE', vendorName: 'High', vendorRating: 4.9, vendorRatingCount: 40,
            methodCode: 'home_visit', methodName: 'Home Visit'),
        _m(vendorId: 'NOFREE', vendorName: 'Busy', vendorRating: 5.0, vendorRatingCount: 99,
            methodCode: 'home_visit', methodName: 'Home Visit', available: false),
      ];
      final order = groupMethodsByVendor(rows).map((g) => g.vendorId).toList();
      expect(order, ['HIGHRATE', 'LOWRATE', 'NOFREE']);
    });

    test('distance is the smallest across a vendor\'s rows', () {
      final rows = [
        _m(vendorId: 'A', vendorName: 'Alpha', methodCode: 'home_visit', methodName: 'Home Visit', distanceKm: 8.2),
        _m(vendorId: 'A', vendorName: 'Alpha', methodCode: 'pickup_and_drop', methodName: 'Pickup & Drop', distanceKm: 3.1),
      ];
      expect(groupMethodsByVendor(rows).single.distanceKm, 3.1);
    });
  });

  group('groupMethodsByService', () {
    test('one vendor, methods split across services, each service its own bucket', () {
      final rows = [
        _m(vendorId: 'A', vendorName: 'Alpha', serviceId: 's1', serviceName: 'Hair Cut',
            methodCode: 'appointment_booking', methodName: 'Appointment'),
        _m(vendorId: 'A', vendorName: 'Alpha', serviceId: 's1', serviceName: 'Hair Cut',
            methodCode: 'walk_in', methodName: 'Walk-in', available: false),
        _m(vendorId: 'A', vendorName: 'Alpha', serviceId: 's2', serviceName: 'Hair Spa',
            methodCode: 'home_visit', methodName: 'Home Visit'),
      ];
      final buckets = groupMethodsByService(rows);
      expect(buckets.map((b) => b.serviceName), ['Hair Cut', 'Hair Spa']);
      final hairCut = buckets.first;
      expect(hairCut.methods, hasLength(2));
      expect(hairCut.methods.first.methodCode, 'appointment_booking'); // available first
      expect(hairCut.availableCount, 1);
    });
  });
}
