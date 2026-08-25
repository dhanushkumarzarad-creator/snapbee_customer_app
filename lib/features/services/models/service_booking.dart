/// Mirrors the exact `service_bookings.status` check-constraint values —
/// see services_module_v2.sql SECTION 5. The full 10-state lifecycle, not
/// v1's smaller 6-state version.
enum ServiceBookingStatus {
  pending,
  vendorAccepted,
  technicianAssigned,
  enRoute,
  arrived,
  workStarted,
  workInProgress,
  completionPending,
  completed,
  cancelled,
}

extension ServiceBookingStatusX on ServiceBookingStatus {
  static ServiceBookingStatus fromWire(String value) {
    switch (value) {
      case 'pending':
        return ServiceBookingStatus.pending;
      case 'vendor_accepted':
        return ServiceBookingStatus.vendorAccepted;
      case 'technician_assigned':
        return ServiceBookingStatus.technicianAssigned;
      case 'en_route':
        return ServiceBookingStatus.enRoute;
      case 'arrived':
        return ServiceBookingStatus.arrived;
      case 'work_started':
        return ServiceBookingStatus.workStarted;
      case 'work_in_progress':
        return ServiceBookingStatus.workInProgress;
      case 'completion_pending':
        return ServiceBookingStatus.completionPending;
      case 'completed':
        return ServiceBookingStatus.completed;
      case 'cancelled':
        return ServiceBookingStatus.cancelled;
      default:
        return ServiceBookingStatus.pending;
    }
  }

  String get label {
    switch (this) {
      case ServiceBookingStatus.pending:
        return 'Finding a provider';
      case ServiceBookingStatus.vendorAccepted:
        return 'Provider confirmed';
      case ServiceBookingStatus.technicianAssigned:
        return 'Technician assigned';
      case ServiceBookingStatus.enRoute:
        return 'Technician on the way';
      case ServiceBookingStatus.arrived:
        return 'Technician arrived';
      case ServiceBookingStatus.workStarted:
        return 'Work started';
      case ServiceBookingStatus.workInProgress:
        return 'Work in progress';
      case ServiceBookingStatus.completionPending:
        return 'Awaiting your confirmation';
      case ServiceBookingStatus.completed:
        return 'Completed';
      case ServiceBookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Step index (0-based) into the timeline shown on the booking detail
  /// screen. Cancelled bookings don't map onto the timeline at all.
  int? get timelineStep {
    switch (this) {
      case ServiceBookingStatus.pending:
        return 0;
      case ServiceBookingStatus.vendorAccepted:
        return 1;
      case ServiceBookingStatus.technicianAssigned:
        return 2;
      case ServiceBookingStatus.enRoute:
        return 3;
      case ServiceBookingStatus.arrived:
        return 4;
      case ServiceBookingStatus.workStarted:
        return 5;
      case ServiceBookingStatus.workInProgress:
        return 6;
      case ServiceBookingStatus.completionPending:
        return 7;
      case ServiceBookingStatus.completed:
        return 8;
      case ServiceBookingStatus.cancelled:
        return null;
    }
  }

  static const int timelineLength = 9;

  bool get isCancellable => switch (this) {
        ServiceBookingStatus.pending ||
        ServiceBookingStatus.vendorAccepted ||
        ServiceBookingStatus.technicianAssigned =>
          true,
        _ => false,
      };
}

/// Backed by `service_bookings` (services_module_v2.sql) — deliberately
/// separate from `orders` (Daily Essentials), and from this app's own
/// checkout/order models: a Services booking is not an order.
class ServiceBookingRow {
  final String id;
  final String serviceId;
  final String serviceName;
  final String? vendorId;
  final String? vendorName;
  final String? technicianName;
  final ServiceBookingStatus status;
  final String bookingType;
  final bool isInspection;
  final String address;
  final DateTime preferredDate;
  final String preferredTimeSlot;
  final double quotedPrice;
  final String? customerNotes;
  final bool isEmergency;
  final double emergencyCharge;
  final String? arrivalOtp;
  final String? completionOtp;
  final double advancePercent;
  final double advanceAmount;
  final bool advancePaid;
  final double remainingAmount;
  final bool remainingPaid;
  final String paymentStatus;
  final DateTime createdAt;

  const ServiceBookingRow({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    this.vendorId,
    this.vendorName,
    this.technicianName,
    required this.status,
    required this.bookingType,
    required this.isInspection,
    required this.address,
    required this.preferredDate,
    required this.preferredTimeSlot,
    required this.quotedPrice,
    this.customerNotes,
    required this.isEmergency,
    required this.emergencyCharge,
    this.arrivalOtp,
    this.completionOtp,
    required this.advancePercent,
    required this.advanceAmount,
    required this.advancePaid,
    required this.remainingAmount,
    required this.remainingPaid,
    required this.paymentStatus,
    required this.createdAt,
  });

  factory ServiceBookingRow.fromJson(Map<String, dynamic> json) {
    final service = json['services'] as Map<String, dynamic>?;
    final vendor = json['service_vendors'] as Map<String, dynamic>?;
    final workers = json['service_booking_workers'] as List?;
    String? leadTechnicianName;
    if (workers != null && workers.isNotEmpty) {
      final firstWorker = Map<String, dynamic>.from(workers.first as Map);
      final technicianEmbed = firstWorker['service_technicians'] as Map<String, dynamic>?;
      leadTechnicianName = technicianEmbed?['full_name'] as String?;
    }
    return ServiceBookingRow(
      id: json['id'] as String,
      serviceId: json['service_id'] as String,
      serviceName: (service?['name'] as String?) ?? 'Service',
      vendorId: json['vendor_id'] as String?,
      vendorName: vendor?['business_name'] as String?,
      technicianName: leadTechnicianName,
      status: ServiceBookingStatusX.fromWire(json['status'] as String),
      bookingType: json['booking_type'] as String? ?? 'one_time',
      isInspection: json['is_inspection'] as bool? ?? false,
      address: json['address'] as String? ?? '',
      preferredDate: DateTime.parse(json['preferred_date'] as String),
      preferredTimeSlot: json['preferred_time_slot'] as String,
      quotedPrice: (json['quoted_price'] as num).toDouble(),
      customerNotes: json['customer_notes'] as String?,
      isEmergency: json['is_emergency'] as bool? ?? false,
      emergencyCharge: ((json['emergency_charge'] as num?) ?? 0).toDouble(),
      arrivalOtp: json['arrival_otp'] as String?,
      completionOtp: json['completion_otp'] as String?,
      advancePercent: ((json['advance_percent'] as num?) ?? 10).toDouble(),
      advanceAmount: ((json['advance_amount'] as num?) ?? 0).toDouble(),
      advancePaid: json['advance_paid'] as bool? ?? false,
      remainingAmount: ((json['remaining_amount'] as num?) ?? 0).toDouble(),
      remainingPaid: json['remaining_paid'] as bool? ?? false,
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
