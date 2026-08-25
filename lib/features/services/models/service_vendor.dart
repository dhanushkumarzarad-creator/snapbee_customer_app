/// A customer-facing view of one `service_vendors` row, joined with its
/// `service_pricing` row for a specific service — backed by the
/// `service_vendors_public_select`/`service_pricing_public_select` RLS
/// policies added alongside this app's Services sector (services_module_v2.sql
/// SECTION 22). Only approved, active vendors with admin-approved pricing
/// are ever visible here — trust info shown is real, never fabricated.
class ServiceVendorListing {
  final String vendorId;
  final String businessName;
  final String businessType;
  final double ratingAvg;
  final int ratingCount;
  final double price;

  const ServiceVendorListing({
    required this.vendorId,
    required this.businessName,
    required this.businessType,
    required this.ratingAvg,
    required this.ratingCount,
    required this.price,
  });

  factory ServiceVendorListing.fromJson(Map<String, dynamic> json) {
    final vendor = json['service_vendors'] as Map<String, dynamic>;
    return ServiceVendorListing(
      vendorId: vendor['id'] as String,
      businessName: vendor['business_name'] as String,
      businessType: vendor['business_type'] as String? ?? 'business',
      ratingAvg: ((vendor['rating_avg'] as num?) ?? 0).toDouble(),
      ratingCount: (vendor['rating_count'] as num?)?.toInt() ?? 0,
      price: ((json['price'] as num?) ?? 0).toDouble(),
    );
  }
}
