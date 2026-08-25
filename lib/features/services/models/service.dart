/// Backed by `services` (services_module_v2.sql) — a bookable catalog item.
class ServiceRow {
  final String id;
  final String categoryId;
  final String name;
  final String description;
  final double basePrice;
  final int durationMinutes;
  final String? imageUrl;
  final int warrantyDays;
  final String? whatIncluded;
  final bool requiresInspection;
  final bool supportsEmergency;
  final double minAdvancePercent;

  const ServiceRow({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.durationMinutes,
    this.imageUrl,
    this.warrantyDays = 0,
    this.whatIncluded,
    this.requiresInspection = false,
    this.supportsEmergency = false,
    this.minAdvancePercent = 10,
  });

  factory ServiceRow.fromJson(Map<String, dynamic> json) => ServiceRow(
        id: json['id'] as String,
        categoryId: json['category_id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        basePrice: (json['base_price'] as num).toDouble(),
        durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 60,
        imageUrl: json['image_url'] as String?,
        warrantyDays: (json['warranty_days'] as num?)?.toInt() ?? 0,
        whatIncluded: json['what_included'] as String?,
        requiresInspection: json['requires_inspection'] as bool? ?? false,
        supportsEmergency: json['supports_emergency'] as bool? ?? false,
        minAdvancePercent: ((json['min_advance_percent'] as num?) ?? 10).toDouble(),
      );
}
