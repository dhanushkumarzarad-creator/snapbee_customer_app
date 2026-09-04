/// Backed by `service_subcategories` (snapbee_admin/supabase/
/// services_module_v2.sql). Admin-managed, never hardcoded — the middle
/// level of the finalized Services hierarchy
/// (Category -> Subcategory -> Service -> Vendor -> Method). A category with
/// zero active subcategories is browsed straight to its service list, so
/// this level is additive and never a dead end.
///
/// NOTE: as of this build no subcategory rows exist in production and
/// `services` has no `subcategory_id` column there, so the customer flow
/// currently collapses to Category -> Service exactly as the fallback above
/// describes. This model + `ServicesCatalogRepository.fetchSubcategories`
/// are in place for when that data lands.
class ServiceSubcategoryRow {
  final String id;
  final String categoryId;
  final String name;
  final String description;
  final int displayOrder;

  const ServiceSubcategoryRow({
    required this.id,
    required this.categoryId,
    required this.name,
    this.description = '',
    this.displayOrder = 0,
  });

  factory ServiceSubcategoryRow.fromJson(Map<String, dynamic> json) => ServiceSubcategoryRow(
        id: json['id'] as String,
        categoryId: json['category_id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      );
}
