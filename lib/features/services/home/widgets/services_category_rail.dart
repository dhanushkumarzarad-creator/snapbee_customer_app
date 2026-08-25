import 'package:flutter/material.dart';

import '../../models/service_category.dart';
import '../../theme/service_colors.dart';

/// Structurally identical to Daily Essentials' `CategoryGridWidget`
/// ("Shop by Category" — header + "See All", horizontal rail of rounded
/// square thumbnails), blue-themed, driven by real `service_categories`
/// rows (admin-managed, same as `fetchCategories()` already used
/// elsewhere in this feature — never hardcoded).
class ServicesCategoryRail extends StatelessWidget {
  final String title;
  final List<ServiceCategoryRow> categories;
  final bool isLoading;
  final VoidCallback? onSeeAll;
  final ValueChanged<ServiceCategoryRow>? onCategoryTap;

  const ServicesCategoryRail({
    super.key,
    this.title = 'Service Categories',
    required this.categories,
    this.isLoading = false,
    this.onSeeAll,
    this.onCategoryTap,
  });

  static const Map<String, IconData> _iconByName = {
    'ac_unit': Icons.ac_unit,
    'water_drop': Icons.water_drop,
    'electrical_services': Icons.electrical_services,
    'plumbing': Icons.plumbing,
    'cleaning_services': Icons.cleaning_services,
    'handyman': Icons.handyman,
    'more_horiz': Icons.more_horiz,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ServiceColors.textPrimary)),
              InkWell(
                onTap: onSeeAll,
                child: const Row(
                  children: [
                    Text('See All', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ServiceColors.textSecondary)),
                    Icon(Icons.chevron_right, size: 18, color: ServiceColors.textSecondary),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 128,
          child: isLoading
              ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)))
              : categories.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('No service categories available yet.', style: TextStyle(color: ServiceColors.textSecondary)),
                      ),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        return _CategorySquare(
                          category: category,
                          icon: _iconByName[category.iconName ?? ''] ?? Icons.build_outlined,
                          onTap: () => onCategoryTap?.call(category),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _CategorySquare extends StatelessWidget {
  final ServiceCategoryRow category;
  final IconData icon;
  final VoidCallback? onTap;

  const _CategorySquare({required this.category, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 84,
        child: Column(
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: ServiceColors.primaryBlueLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ServiceColors.divider),
              ),
              child: Icon(icon, size: 32, color: ServiceColors.primaryBlue),
            ),
            const SizedBox(height: 6),
            Text(
              category.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ServiceColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
