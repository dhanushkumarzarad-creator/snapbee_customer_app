/// Backed by `service_offers` (services_module_v2.sql). Only active,
/// currently-valid offers are ever fetched (see
/// `ServicesCatalogRepository.fetchOffers`).
class ServiceOfferRow {
  final String id;
  final String? code;
  final String description;
  final String discountType;
  final double discountValue;
  final String? categoryId;
  final String? serviceId;

  const ServiceOfferRow({
    required this.id,
    this.code,
    required this.description,
    required this.discountType,
    required this.discountValue,
    this.categoryId,
    this.serviceId,
  });

  String get label => discountType == 'percent'
      ? '${discountValue.toStringAsFixed(0)}% off'
      : '₹${discountValue.toStringAsFixed(0)} off';

  factory ServiceOfferRow.fromJson(Map<String, dynamic> json) => ServiceOfferRow(
        id: json['id'] as String,
        code: json['code'] as String?,
        description: json['description'] as String? ?? '',
        discountType: json['discount_type'] as String,
        discountValue: (json['discount_value'] as num).toDouble(),
        categoryId: json['category_id'] as String?,
        serviceId: json['service_id'] as String?,
      );
}
