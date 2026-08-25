/// Backed by `service_categories` (snapbee_admin/supabase/
/// services_module_v2.sql). Admin-managed, never hardcoded — same
/// convention CategoryScreen already uses for Daily Essentials categories.
class ServiceCategoryRow {
  final String id;
  final String name;
  final String description;
  final String? iconName;

  const ServiceCategoryRow({
    required this.id,
    required this.name,
    required this.description,
    this.iconName,
  });

  factory ServiceCategoryRow.fromJson(Map<String, dynamic> json) => ServiceCategoryRow(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        iconName: json['icon_name'] as String?,
      );
}
