// Model-level coverage for the NEW Services Master Method architecture's
// customer browse row (`ServiceMethodRow`), mapped from a
// `browse_service_methods` RPC row
// (snapbee_admin/supabase/services_method_architecture_customer_browse.sql).
//
// Proves the customer-facing rules the spec fixes:
//   * LIVE + available            -> isAvailable, no reason
//   * LIVE but transiently blocked -> !isAvailable + a customer-safe label
//     (capacity full / working hours / holiday / closed / no staff)
//   * radius rule is server-side  -> withinRadius round-trips; a row that
//     reaches the model is one the customer may see
//   * NO internal AI / QC / admin-review / status terminology is ever
//     surfaced by any getter.

import 'package:flutter_test/flutter_test.dart';
import 'package:snapbee_customer_app/features/services/models/service_method.dart';

Map<String, dynamic> _row({
  String configId = 'cfg-1',
  String vendorId = 'v-1',
  String vendorName = 'Acme Services',
  num vendorRatingAvg = 4.5,
  int vendorRatingCount = 12,
  String? serviceId = 'svc-1',
  String? serviceName = 'AC Deep Clean',
  String? subcategoryId,
  String methodId = 'm-1',
  String? methodVersionId = 'mv-1',
  String methodCode = 'home_visit',
  String methodName = 'Home Visit',
  String methodShortName = 'Home Visit',
  String methodDefinition = 'A technician comes to your home.',
  String bookingRequirements = 'Keep the area accessible.',
  num? price = 250,
  num? minCharge,
  num? maxCharge,
  num travelCharge = 0,
  int? durationMinutes = 60,
  int advanceBookingHours = 0,
  num? radiusKm,
  bool withinRadius = true,
  num? distanceKm,
  int? capacity = 5,
  int bookedToday = 0,
  bool requiresStaff = false,
  bool isAvailable = true,
  String? unavailableReason,
}) =>
    {
      'config_id': configId,
      'vendor_id': vendorId,
      'vendor_name': vendorName,
      'vendor_rating_avg': vendorRatingAvg,
      'vendor_rating_count': vendorRatingCount,
      'service_id': serviceId,
      'service_name': serviceName,
      'subcategory_id': subcategoryId,
      'method_id': methodId,
      'method_version_id': methodVersionId,
      'method_code': methodCode,
      'method_name': methodName,
      'method_short_name': methodShortName,
      'method_definition': methodDefinition,
      'booking_requirements': bookingRequirements,
      'price': price,
      'min_charge': minCharge,
      'max_charge': maxCharge,
      'travel_charge': travelCharge,
      'duration_minutes': durationMinutes,
      'advance_booking_hours': advanceBookingHours,
      'radius_km': radiusKm,
      'within_radius': withinRadius,
      'distance_km': distanceKm,
      'capacity': capacity,
      'booked_today': bookedToday,
      'requires_staff': requiresStaff,
      'is_available': isAvailable,
      'unavailable_reason': unavailableReason,
    };

void main() {
  group('ServiceMethodRow.fromJson', () {
    test('maps a live, available row', () {
      final m = ServiceMethodRow.fromJson(_row());
      expect(m.methodCode, 'home_visit');
      expect(m.methodName, 'Home Visit');
      expect(m.isAvailable, isTrue);
      expect(m.availability, MethodAvailability.available);
      expect(m.unavailableReason, isNull);
      expect(m.availabilityLabel, 'Available');
      expect(m.priceLabel, '₹250');
      expect(m.durationLabel, '60 min');
    });

    test('price label folds in travel charge and a min–max band', () {
      expect(ServiceMethodRow.fromJson(_row(travelCharge: 50)).priceLabel, '₹250 + ₹50 travel');
      expect(
        ServiceMethodRow.fromJson(_row(price: null, minCharge: 200, maxCharge: 400)).priceLabel,
        '₹200–₹400',
      );
      expect(ServiceMethodRow.fromJson(_row(price: null)).priceLabel, isNull);
    });

    test('booking-requirements text assembles translated copy + advance hours', () {
      final m = ServiceMethodRow.fromJson(_row(advanceBookingHours: 2));
      expect(m.hasBookingRequirements, isTrue);
      expect(m.bookingRequirementsText, contains('Keep the area accessible.'));
      expect(m.bookingRequirementsText, contains('2 hours ahead'));
    });

    for (final entry in const {
      'capacity_full': 'Fully booked for now',
      'outside_hours': 'Outside booking hours',
      'holiday': 'Closed for a holiday',
      'closed': 'Temporarily closed',
      'no_staff': 'No slots open right now',
    }.entries) {
      test('transiently unavailable: ${entry.key} -> "${entry.value}"', () {
        final m = ServiceMethodRow.fromJson(
          _row(isAvailable: false, unavailableReason: entry.key),
        );
        expect(m.isAvailable, isFalse);
        expect(m.availability, MethodAvailability.currentlyUnavailable);
        expect(m.unavailableReason, isNot(MethodUnavailableReason.unknown));
        expect(m.availabilityLabel, entry.value);
      });
    }

    test('an unrecognised / coarse reason still reads as "Currently unavailable"', () {
      final m = ServiceMethodRow.fromJson(
        _row(isAvailable: false, unavailableReason: 'temporarily_unavailable'),
      );
      expect(m.isAvailable, isFalse);
      expect(m.unavailableReason, MethodUnavailableReason.unknown);
      expect(m.availabilityLabel, 'Currently unavailable');
    });

    test('within_radius round-trips (server owns the radius HIDE)', () {
      expect(ServiceMethodRow.fromJson(_row(radiusKm: 10, withinRadius: true)).withinRadius, isTrue);
      // A false value can still arrive for a vendor with no service area; the
      // model does not re-hide — the RPC already dropped genuinely out-of-
      // range rows.
      expect(ServiceMethodRow.fromJson(_row(withinRadius: false)).withinRadius, isFalse);
    });

    test('no internal QC / admin / risk / status terminology leaks through any string getter', () {
      final m = ServiceMethodRow.fromJson(_row(isAvailable: false, unavailableReason: 'temporarily_unavailable'));
      final surfaced = [
        m.methodName,
        m.methodShortName,
        m.definition,
        m.bookingRequirementsText,
        m.availabilityLabel,
        m.priceLabel ?? '',
        m.durationLabel ?? '',
      ].join(' | ').toLowerCase();
      for (final banned in const [
        'qc', 'admin_qc', 'admin review', 'ai_', 'risk', 'superseded',
        'draft', 'restricted', 'changes_requested', 'emergency_disabled',
      ]) {
        expect(surfaced.contains(banned), isFalse, reason: 'leaked "$banned" in: $surfaced');
      }
    });
  });
}
