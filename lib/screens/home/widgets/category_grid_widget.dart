import 'package:flutter/material.dart';
import 'package:snapbee_customer_app/core/constants/app_colors.dart';
import '../../../widgets/catalog_image.dart';

/// A single browsable category, e.g. Restaurants, Grocery, Fresh Meat.
class CategoryItem {
  final String label;
  final String? imageUrl;
  final IconData fallbackIcon;

  const CategoryItem({
    required this.label,
    this.imageUrl,
    this.fallbackIcon = Icons.category_outlined,
  });
}

/// "Shop by Category" section: header with a "See All" action,
/// followed by a horizontally scrollable row of rounded-square
/// category thumbnails with a label underneath each.
class CategoryGridWidget extends StatelessWidget {
  final String title;
  final List<CategoryItem> categories;
  final bool isLoading;
  final VoidCallback? onSeeAll;
  final ValueChanged<int>? onCategoryTap;

  const CategoryGridWidget({
    super.key,
    this.title = 'Shop by Category',
    required this.categories,
    this.isLoading = false,
    this.onSeeAll,
    this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: title, onSeeAll: onSeeAll),
        const SizedBox(height: 12),
        SizedBox(
          height: 128,
          child: isLoading
              ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : categories.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'No categories available yet.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
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
                      item: category,
                      onTap: () => onCategoryTap?.call(index),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Shared section header row ("Title" left, "See All ›" right) used
/// by both Shop by Category and Popular Stores Near You.
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          InkWell(
            onTap: onSeeAll,
            child: const Row(
              children: [
                Text(
                  'See All',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySquare extends StatelessWidget {
  final CategoryItem item;
  final VoidCallback? onTap;

  const _CategorySquare({required this.item, this.onTap});

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
                color: AppColors.cardGrey,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              clipBehavior: Clip.antiAlias,
              child: item.imageUrl != null
                  ? CatalogImage(
                      source: item.imageUrl,
                      fit: BoxFit.cover,
                      placeholderIcon: item.fallbackIcon,
                    )
                  : Icon(
                      item.fallbackIcon,
                      size: 34,
                      color: AppColors.textSecondary,
                    ),
            ),
            const SizedBox(height: 6),
            Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
