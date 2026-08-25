import 'package:flutter_test/flutter_test.dart';
import 'package:snapbee_customer_app/features/services/models/service.dart';
import 'package:snapbee_customer_app/features/services/models/service_booking.dart';
import 'package:snapbee_customer_app/features/services/models/service_category.dart';
import 'package:snapbee_customer_app/features/services/models/service_quotation.dart';
import 'package:snapbee_customer_app/features/services/models/service_vendor.dart';
import 'package:snapbee_customer_app/features/services/models/service_warranty.dart';

void main() {
  group('ServiceCategoryRow.fromJson', () {
    test('parses id/name/description/icon_name', () {
      final row = ServiceCategoryRow.fromJson({
        'id': 'cat-1',
        'name': 'AC Repair & Service',
        'description': 'AC installation, repair, gas refill and servicing',
        'icon_name': 'ac_unit',
      });
      expect(row.id, 'cat-1');
      expect(row.name, 'AC Repair & Service');
      expect(row.iconName, 'ac_unit');
    });

    test('defaults description to empty and icon_name to null when absent', () {
      final row = ServiceCategoryRow.fromJson({'id': 'cat-2', 'name': 'Plumber'});
      expect(row.description, '');
      expect(row.iconName, isNull);
    });
  });

  group('ServiceRow.fromJson', () {
    test('parses base_price as a double and duration_minutes as an int', () {
      final row = ServiceRow.fromJson({
        'id': 'svc-1',
        'category_id': 'cat-1',
        'name': 'AC Gas Refill',
        'base_price': 999,
        'duration_minutes': 45,
      });
      expect(row.basePrice, 999.0);
      expect(row.durationMinutes, 45);
    });

    test('defaults new v2 columns safely when the row predates them', () {
      final row = ServiceRow.fromJson({
        'id': 'svc-2',
        'category_id': 'cat-1',
        'name': 'General Checkup',
        'base_price': 199,
      });
      expect(row.durationMinutes, 60);
      expect(row.requiresInspection, isFalse);
      expect(row.supportsEmergency, isFalse);
      expect(row.minAdvancePercent, 10);
    });

    test('parses requires_inspection/supports_emergency/warranty_days', () {
      final row = ServiceRow.fromJson({
        'id': 'svc-3',
        'category_id': 'cat-1',
        'name': 'AC Deep Repair',
        'base_price': 1500,
        'requires_inspection': true,
        'supports_emergency': true,
        'warranty_days': 30,
      });
      expect(row.requiresInspection, isTrue);
      expect(row.supportsEmergency, isTrue);
      expect(row.warrantyDays, 30);
    });
  });

  group('ServiceBookingStatusX', () {
    test('round-trips every real v2 status value from the DB check constraint', () {
      const wireValues = [
        'pending', 'vendor_accepted', 'technician_assigned', 'en_route', 'arrived',
        'work_started', 'work_in_progress', 'completion_pending', 'completed', 'cancelled',
      ];
      for (final wire in wireValues) {
        final status = ServiceBookingStatusX.fromWire(wire);
        expect(status, isNotNull);
      }
      expect(ServiceBookingStatusX.fromWire('work_in_progress'), ServiceBookingStatus.workInProgress);
      expect(ServiceBookingStatusX.fromWire('technician_assigned'), ServiceBookingStatus.technicianAssigned);
    });

    test('an unrecognized status falls back to pending, never throws', () {
      expect(ServiceBookingStatusX.fromWire('some_future_status'), ServiceBookingStatus.pending);
    });

    test('timelineStep is null for cancelled (it never appears on the timeline)', () {
      expect(ServiceBookingStatus.cancelled.timelineStep, isNull);
      expect(ServiceBookingStatus.pending.timelineStep, 0);
      expect(ServiceBookingStatus.completed.timelineStep, 8);
    });

    test('isCancellable is true only before a technician is en route', () {
      expect(ServiceBookingStatus.pending.isCancellable, isTrue);
      expect(ServiceBookingStatus.vendorAccepted.isCancellable, isTrue);
      expect(ServiceBookingStatus.technicianAssigned.isCancellable, isTrue);
      expect(ServiceBookingStatus.enRoute.isCancellable, isFalse);
      expect(ServiceBookingStatus.workInProgress.isCancellable, isFalse);
      expect(ServiceBookingStatus.completed.isCancellable, isFalse);
      expect(ServiceBookingStatus.cancelled.isCancellable, isFalse);
    });
  });

  group('ServiceBookingRow.fromJson', () {
    test('parses embedded services/service_vendors/service_booking_workers rows', () {
      final row = ServiceBookingRow.fromJson({
        'id': 'SVC-0001',
        'service_id': 'svc-1',
        'services': {'name': 'AC Gas Refill'},
        'vendor_id': 'sv-1',
        'service_vendors': {'business_name': 'CoolFix Services'},
        'service_booking_workers': [
          {
            'technician_id': 'st-1',
            'service_technicians': {'full_name': 'Ramesh Kumar'},
          },
        ],
        'status': 'en_route',
        'booking_type': 'one_time',
        'address': '123 Main St',
        'preferred_date': '2026-09-01',
        'preferred_time_slot': 'morning',
        'quoted_price': 999,
        'arrival_otp': '482913',
        'payment_status': 'partial',
        'advance_amount': 100,
        'advance_paid': true,
        'created_at': '2026-08-24T10:00:00Z',
      });

      expect(row.serviceName, 'AC Gas Refill');
      expect(row.vendorName, 'CoolFix Services');
      expect(row.technicianName, 'Ramesh Kumar');
      expect(row.status, ServiceBookingStatus.enRoute);
      expect(row.arrivalOtp, '482913');
      expect(row.advancePaid, isTrue);
    });

    test('leaves vendor/technician fields null before assignment', () {
      final row = ServiceBookingRow.fromJson({
        'id': 'SVC-0002',
        'service_id': 'svc-1',
        'services': {'name': 'AC Gas Refill'},
        'status': 'pending',
        'address': '123 Main St',
        'preferred_date': '2026-09-01',
        'preferred_time_slot': 'evening',
        'quoted_price': 999,
        'created_at': '2026-08-24T10:00:00Z',
      });

      expect(row.vendorId, isNull);
      expect(row.vendorName, isNull);
      expect(row.technicianName, isNull);
      expect(row.advanceAmount, 0);
      expect(row.advancePaid, isFalse);
    });
  });

  group('ServiceVendorListing.fromJson', () {
    test('parses the nested service_vendors embed and its own price column', () {
      final listing = ServiceVendorListing.fromJson({
        'price': 999,
        'service_vendors': {
          'id': 'sv-1',
          'business_name': 'CoolFix Services',
          'business_type': 'business',
          'rating_avg': 4.5,
          'rating_count': 20,
        },
      });
      expect(listing.vendorId, 'sv-1');
      expect(listing.businessName, 'CoolFix Services');
      expect(listing.ratingAvg, 4.5);
      expect(listing.price, 999.0);
    });
  });

  group('ServiceQuotation.fromJson', () {
    test('parses nested quotation_line_items', () {
      final quotation = ServiceQuotation.fromJson({
        'id': 'q-1',
        'booking_id': 'SVC-0001',
        'status': 'sent_to_customer',
        'subtotal': 1000,
        'tax_amount': 180,
        'total_amount': 1180,
        'quotation_line_items': [
          {'item_type': 'labor', 'description': 'Repair labor', 'quantity': 1, 'unit_price': 700, 'line_total': 700},
          {'item_type': 'part', 'description': 'Compressor', 'quantity': 1, 'unit_price': 300, 'line_total': 300},
        ],
      });
      expect(quotation.lineItems, hasLength(2));
      expect(quotation.totalAmount, 1180.0);
    });
  });

  group('ServiceExtraWorkRequest', () {
    test('isPendingCustomerApproval is true only for pending + customer approval mode', () {
      final pendingCustomer = ServiceExtraWorkRequest.fromJson({
        'id': 'ew-1', 'booking_id': 'SVC-0001', 'description': 'Extra part', 'price': 200,
        'status': 'pending', 'approval_mode': 'customer',
      });
      final aiApproved = ServiceExtraWorkRequest.fromJson({
        'id': 'ew-2', 'booking_id': 'SVC-0001', 'description': 'Extra part', 'price': 50,
        'status': 'ai_approved', 'approval_mode': 'ai_auto',
      });
      expect(pendingCustomer.isPendingCustomerApproval, isTrue);
      expect(aiApproved.isPendingCustomerApproval, isFalse);
    });
  });

  group('ServiceWarranty.isActive', () {
    test('true when approved and not yet expired', () {
      final warranty = ServiceWarranty.fromJson({
        'id': 'w-1', 'booking_id': 'SVC-0001', 'duration_days': 30, 'status': 'approved',
        'expires_at': DateTime.now().add(const Duration(days: 10)).toIso8601String(),
      });
      expect(warranty.isActive, isTrue);
    });

    test('false when pending admin approval', () {
      final warranty = ServiceWarranty.fromJson({
        'id': 'w-2', 'booking_id': 'SVC-0001', 'duration_days': 30, 'status': 'pending_admin_approval',
      });
      expect(warranty.isActive, isFalse);
    });

    test('false when approved but already expired', () {
      final warranty = ServiceWarranty.fromJson({
        'id': 'w-3', 'booking_id': 'SVC-0001', 'duration_days': 30, 'status': 'approved',
        'expires_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      });
      expect(warranty.isActive, isFalse);
    });
  });
}
