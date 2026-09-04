// ============================================================================
// vendor_method_group.dart — pure grouping of flat `browse_service_methods`
// rows into the two shapes the Customer App renders:
//   * by vendor  — the "choose a provider" list on one service's detail;
//   * by service — a vendor's profile, where each service is listed
//     individually with its own eligible methods (spec: Vendor Profile).
// No Flutter, no Supabase — unit-testable in isolation.
// ============================================================================

import 'service_method.dart';

/// One provider and the methods they offer within the current browse scope.
class VendorMethodGroup {
  final String vendorId;
  final String vendorName;
  final double ratingAvg;
  final int ratingCount;
  final double? distanceKm;
  final List<ServiceMethodRow> methods;

  const VendorMethodGroup({
    required this.vendorId,
    required this.vendorName,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.distanceKm,
    this.methods = const [],
  });

  /// A vendor is shown as long as they have ANY method in scope — even if
  /// every one is currently unavailable, and even if some of their other
  /// methods were suspended/hidden server-side (spec: vendor-level method
  /// suspension must NOT hide the whole vendor).
  bool get hasAnyBookable => methods.any((m) => m.isAvailable);
  int get availableCount => methods.where((m) => m.isAvailable).length;
}

/// One of a vendor's services and the methods available for it.
class ServiceMethodBucket {
  final String? serviceId;
  final String serviceName;
  final List<ServiceMethodRow> methods;

  const ServiceMethodBucket({
    required this.serviceId,
    required this.serviceName,
    required this.methods,
  });

  int get availableCount => methods.where((m) => m.isAvailable).length;
}

int _methodSort(ServiceMethodRow a, ServiceMethodRow b) {
  if (a.isAvailable != b.isAvailable) return a.isAvailable ? -1 : 1;
  return a.methodName.toLowerCase().compareTo(b.methodName.toLowerCase());
}

/// Group by provider. Vendors ordered by rating (desc) then name; within a
/// vendor, bookable methods first, then by method name. Distance (if the
/// RPC returned it) is the smallest across that vendor's rows.
List<VendorMethodGroup> groupMethodsByVendor(List<ServiceMethodRow> rows) {
  final byVendor = <String, List<ServiceMethodRow>>{};
  for (final r in rows) {
    byVendor.putIfAbsent(r.vendorId, () => []).add(r);
  }

  final groups = byVendor.entries.map((e) {
    final vendorRows = [...e.value]..sort(_methodSort);
    final first = vendorRows.first;
    return VendorMethodGroup(
      vendorId: e.key,
      vendorName: first.vendorName,
      ratingAvg: first.vendorRatingAvg,
      ratingCount: first.vendorRatingCount,
      distanceKm: vendorRows
          .map((m) => m.distanceKm)
          .whereType<double>()
          .fold<double?>(null, (min, d) => min == null || d < min ? d : min),
      methods: vendorRows,
    );
  }).toList();

  groups.sort((a, b) {
    if (a.hasAnyBookable != b.hasAnyBookable) return a.hasAnyBookable ? -1 : 1;
    final r = b.ratingAvg.compareTo(a.ratingAvg);
    if (r != 0) return r;
    return a.vendorName.toLowerCase().compareTo(b.vendorName.toLowerCase());
  });
  return groups;
}

/// Group one vendor's rows by service, for the vendor profile screen.
/// Services ordered by name; within a service, bookable methods first.
List<ServiceMethodBucket> groupMethodsByService(List<ServiceMethodRow> rows) {
  final byService = <String, List<ServiceMethodRow>>{};
  for (final r in rows) {
    byService.putIfAbsent(r.serviceId ?? '', () => []).add(r);
  }

  final buckets = byService.entries.map((e) {
    final serviceRows = [...e.value]..sort(_methodSort);
    return ServiceMethodBucket(
      serviceId: e.key.isEmpty ? null : e.key,
      serviceName: serviceRows.first.serviceName ?? 'Other services',
      methods: serviceRows,
    );
  }).toList();

  buckets.sort((a, b) => a.serviceName.toLowerCase().compareTo(b.serviceName.toLowerCase()));
  return buckets;
}
