// ============================================================================
// service_method.dart — one bookable "Service Method" as the Customer App
// sees it, mapped from a `browse_service_methods` RPC row
// (snapbee_admin/supabase/services_method_architecture_customer_browse.sql).
// ----------------------------------------------------------------------------
// The RPC has already made every visibility decision server-side:
//   * only vendor-enabled configs (status live, or auto-restricted with
//     nothing else holding the live slot) of an approved+active vendor;
//   * a method the customer is genuinely OUTSIDE the method-specific radius
//     of is omitted entirely (never appears here) — this is independent of
//     the vendor's overall radius, so the vendor and their other methods
//     still show.
// So a row reaching this model is always one the customer is allowed to
// see. What is left for the app is the transient state: `isAvailable` /
// `unavailableReason` split it into "book now" vs. "Currently Unavailable"
// (used for a globally emergency-disabled method or an auto-restricted
// config — existing bookings are unaffected either way).
//
// This model is deliberately pure (no Flutter import) and carries ONLY
// customer-facing fields — no config status, QC state, AI risk, or admin
// review. Nothing here is ever rendered as a raw enum/machine name.
// ============================================================================

/// Book-now vs. show-but-disabled. `hidden` is never constructed from an RPC
/// row (the server omits those); it exists so grouping/filtering code can be
/// explicit when it drops a row for a non-RPC reason.
enum MethodAvailability { available, currentlyUnavailable, hidden }

/// Why a listed method cannot be booked right now. Mirrors the coarse
/// `unavailable_reason` machine codes browse_service_methods may emit; any
/// unrecognised / generic code collapses to [unknown].
enum MethodUnavailableReason { outsideHours, holiday, closed, capacityFull, noStaff, unknown }

MethodUnavailableReason _reasonFromWire(String? code) {
  switch (code) {
    case 'outside_hours':
      return MethodUnavailableReason.outsideHours;
    case 'holiday':
      return MethodUnavailableReason.holiday;
    case 'closed':
      return MethodUnavailableReason.closed;
    case 'capacity_full':
      return MethodUnavailableReason.capacityFull;
    case 'no_staff':
      return MethodUnavailableReason.noStaff;
    default:
      return MethodUnavailableReason.unknown;
  }
}

extension MethodUnavailableReasonLabel on MethodUnavailableReason {
  /// Short, customer-safe phrase — no internal terminology, no exposure of
  /// the vendor's staffing / QC internals.
  String get customerLabel {
    switch (this) {
      case MethodUnavailableReason.outsideHours:
        return 'Outside booking hours';
      case MethodUnavailableReason.holiday:
        return 'Closed for a holiday';
      case MethodUnavailableReason.closed:
        return 'Temporarily closed';
      case MethodUnavailableReason.capacityFull:
        return 'Fully booked for now';
      case MethodUnavailableReason.noStaff:
        return 'No slots open right now';
      case MethodUnavailableReason.unknown:
        return 'Currently unavailable';
    }
  }
}

class ServiceMethodRow {
  /// `service_vendor_method_configs.id` — passed to `create_service_booking`
  /// as `p_vendor_method_config_id`, which re-validates it server-side and
  /// links the resulting booking to this exact live method configuration.
  final String configId;
  final String vendorId;
  final String vendorName;
  final double vendorRatingAvg;
  final int vendorRatingCount;

  final String? serviceId;
  final String? serviceName;
  final String? subcategoryId;

  final String methodId;
  final String? methodVersionId; // for get_method_content()
  final String methodCode; // stable machine key: 'home_visit', 'store_pickup', ...
  final String methodName;
  final String methodShortName;

  /// Short, customer-friendly "what this is" (translated method description,
  /// English fallback). May be empty.
  final String definition;

  /// "What you need to provide / be ready for" (translated, English
  /// fallback). May be empty.
  final String bookingRequirements;

  final double? price;
  final double? minCharge;
  final double? maxCharge;
  final double travelCharge;
  final int? durationMinutes;
  final int advanceBookingHours;

  final double? radiusKm;
  final bool withinRadius;
  final double? distanceKm;

  final int? capacity;

  /// Always 0 from a browse (no target date/slot to measure against). Kept
  /// so a future date-aware surface can populate it.
  final int bookedToday;
  final bool requiresStaff;
  final String? cancellationNotes;
  final String? requiredProofNote;

  final bool isAvailable;
  final MethodUnavailableReason? unavailableReason;

  const ServiceMethodRow({
    required this.configId,
    required this.vendorId,
    required this.vendorName,
    this.vendorRatingAvg = 0,
    this.vendorRatingCount = 0,
    this.serviceId,
    this.serviceName,
    this.subcategoryId,
    required this.methodId,
    this.methodVersionId,
    required this.methodCode,
    required this.methodName,
    required this.methodShortName,
    this.definition = '',
    this.bookingRequirements = '',
    this.price,
    this.minCharge,
    this.maxCharge,
    this.travelCharge = 0,
    this.durationMinutes,
    this.advanceBookingHours = 0,
    this.radiusKm,
    this.withinRadius = true,
    this.distanceKm,
    this.capacity,
    this.bookedToday = 0,
    this.requiresStaff = false,
    this.cancellationNotes,
    this.requiredProofNote,
    this.isAvailable = true,
    this.unavailableReason,
  });

  MethodAvailability get availability =>
      isAvailable ? MethodAvailability.available : MethodAvailability.currentlyUnavailable;

  /// Customer-facing one-liner for the availability pill.
  String get availabilityLabel => isAvailable
      ? 'Available'
      : (unavailableReason?.customerLabel ?? 'Currently Unavailable');

  /// True when the customer must do / bring something extra before this
  /// method can be booked — drives whether a "Before booking" line shows.
  bool get hasBookingRequirements =>
      bookingRequirements.trim().isNotEmpty ||
      advanceBookingHours > 0 ||
      (requiredProofNote != null && requiredProofNote!.trim().isNotEmpty);

  /// The full "before booking" sentence, assembled from the translated
  /// requirements copy + any structured extras. Empty when there is nothing
  /// to ask of the customer.
  String get bookingRequirementsText {
    final parts = <String>[];
    if (bookingRequirements.trim().isNotEmpty) parts.add(bookingRequirements.trim());
    if (advanceBookingHours > 0) {
      parts.add('Book at least $advanceBookingHours hour${advanceBookingHours == 1 ? '' : 's'} ahead');
    }
    if (requiredProofNote != null && requiredProofNote!.trim().isNotEmpty) {
      parts.add(requiredProofNote!.trim());
    }
    return parts.join(' · ');
  }

  /// Compact price line, e.g. "₹250" or "₹250 + ₹50 travel" or "₹200–₹400".
  /// Null when the provider has not set a price (rare — QC normally
  /// requires one) so the caller can hide the line rather than print "₹0".
  String? get priceLabel {
    String? base;
    if (price != null) {
      base = '₹${price!.toStringAsFixed(0)}';
    } else if (minCharge != null && maxCharge != null) {
      base = '₹${minCharge!.toStringAsFixed(0)}–₹${maxCharge!.toStringAsFixed(0)}';
    } else if (minCharge != null) {
      base = 'From ₹${minCharge!.toStringAsFixed(0)}';
    }
    if (base == null) return null;
    if (travelCharge > 0) return '$base + ₹${travelCharge.toStringAsFixed(0)} travel';
    return base;
  }

  String? get durationLabel =>
      durationMinutes == null ? null : '${durationMinutes!} min';

  static double? _toDouble(Object? v) => v == null ? null : (v as num).toDouble();
  static int? _toInt(Object? v) => v == null ? null : (v as num).toInt();
  static String _str(Object? v) => (v as String?)?.trim() ?? '';

  factory ServiceMethodRow.fromJson(Map<String, dynamic> json) {
    final available = json['is_available'] as bool? ?? true;
    final rawName = _str(json['method_name']);
    return ServiceMethodRow(
      configId: json['config_id'] as String,
      vendorId: json['vendor_id'] as String,
      vendorName: _str(json['vendor_name']).isNotEmpty ? _str(json['vendor_name']) : 'Verified provider',
      vendorRatingAvg: _toDouble(json['vendor_rating_avg']) ?? 0,
      vendorRatingCount: _toInt(json['vendor_rating_count']) ?? 0,
      serviceId: json['service_id'] as String?,
      serviceName: json['service_name'] as String?,
      subcategoryId: json['subcategory_id'] as String?,
      methodId: json['method_id'] as String,
      methodVersionId: json['method_version_id'] as String?,
      methodCode: _str(json['method_code']),
      methodName: rawName.isNotEmpty ? rawName : 'Booking method',
      methodShortName: _str(json['method_short_name']).isNotEmpty
          ? _str(json['method_short_name'])
          : (rawName.isNotEmpty ? rawName : 'Booking method'),
      definition: _str(json['method_definition']),
      bookingRequirements: _str(json['booking_requirements']),
      price: _toDouble(json['price']),
      minCharge: _toDouble(json['min_charge']),
      maxCharge: _toDouble(json['max_charge']),
      travelCharge: _toDouble(json['travel_charge']) ?? 0,
      durationMinutes: _toInt(json['duration_minutes']),
      advanceBookingHours: _toInt(json['advance_booking_hours']) ?? 0,
      radiusKm: _toDouble(json['radius_km']),
      withinRadius: json['within_radius'] as bool? ?? true,
      distanceKm: _toDouble(json['distance_km']),
      capacity: _toInt(json['capacity']),
      bookedToday: _toInt(json['booked_today']) ?? 0,
      requiresStaff: json['requires_staff'] as bool? ?? false,
      cancellationNotes: json['cancellation_notes'] as String?,
      requiredProofNote: json['required_proof_note'] as String?,
      isAvailable: available,
      unavailableReason: available ? null : _reasonFromWire(json['unavailable_reason'] as String?),
    );
  }
}

/// Localized long-form microcopy for a method version, from the
/// `get_method_content(method_version_id, language_code)` RPC. Only the
/// customer-facing fields are kept. Used by a future "full method details"
/// sheet — the browse row above already carries the short definition and
/// booking requirements a card needs.
class ServiceMethodContent {
  final String languageUsed;
  final String name;
  final String shortName;
  final String description;
  final String customerExperience;
  final String requirements;
  final String cancellationRules;

  const ServiceMethodContent({
    required this.languageUsed,
    required this.name,
    required this.shortName,
    required this.description,
    required this.customerExperience,
    required this.requirements,
    required this.cancellationRules,
  });

  /// Best one-line definition: the method's customer-experience blurb,
  /// falling back to its description, then its short name.
  String get shortDefinition {
    for (final s in [customerExperience, description, shortName]) {
      final t = s.trim();
      if (t.isNotEmpty) return t;
    }
    return '';
  }

  factory ServiceMethodContent.fromJson(Map<String, dynamic> json) => ServiceMethodContent(
        languageUsed: json['language_used'] as String? ?? 'en',
        name: json['name'] as String? ?? '',
        shortName: json['short_name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        customerExperience: json['customer_experience'] as String? ?? '',
        requirements: json['requirements'] as String? ?? '',
        cancellationRules: json['cancellation_rules'] as String? ?? '',
      );
}
