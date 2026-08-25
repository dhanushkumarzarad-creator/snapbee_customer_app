/// A general (not service-scoped) verified-vendor summary — backed by
/// `service_vendors` directly (via `service_vendors_public_select` RLS,
/// same policy `ServiceVendorListing` relies on), for the "Trusted
/// Providers" Home section. Distinct from [ServiceVendorListing]
/// (models/service_vendor.dart), which carries a per-service price and is
/// only meaningful once a specific service has been chosen.
class ServiceVendorSummary {
  final String id;
  final String businessName;
  final String businessType;
  final double ratingAvg;
  final int ratingCount;

  const ServiceVendorSummary({
    required this.id,
    required this.businessName,
    required this.businessType,
    required this.ratingAvg,
    required this.ratingCount,
  });

  factory ServiceVendorSummary.fromJson(Map<String, dynamic> json) => ServiceVendorSummary(
        id: json['id'] as String,
        businessName: json['business_name'] as String,
        businessType: json['business_type'] as String? ?? 'business',
        ratingAvg: ((json['rating_avg'] as num?) ?? 0).toDouble(),
        ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
      );
}
