import 'package:flutter/material.dart';

import '../../../core/design/snapbee_design.dart';
import '../../../data/repositories/category_repository.dart';

/// One chip in the Categories top selector. `key` drives the content query
/// in [CategoryScreen]; `vertical` is null for the Daily Essentials filters
/// (all / food / grocery / meat) and set for the four vertical filters.
class CategoryChipSpec {
  final String key;
  final String label;
  final IconData icon;
  final String? vertical;

  const CategoryChipSpec(this.key, this.label, this.icon, {this.vertical});
}

/// The exact selector structure from 02_Categories.png:
/// ALL | FOOD | GROCERY | MEAT | SERVICES | TRAVEL | ENTERTAINMENT | E-COMMERCE
const List<CategoryChipSpec> kCategoryChips = [
  CategoryChipSpec('all', 'All', Icons.grid_view_rounded),
  CategoryChipSpec('food', 'Food', Icons.restaurant_rounded),
  CategoryChipSpec('grocery', 'Grocery', Icons.local_grocery_store_rounded),
  CategoryChipSpec('meat', 'Meat', Icons.set_meal_rounded),
  CategoryChipSpec('services', 'Services', Icons.handyman_rounded,
      vertical: 'services'),
  CategoryChipSpec('travel', 'Travel', Icons.directions_bus_filled_rounded,
      vertical: 'travel'),
  CategoryChipSpec('entertainment', 'Entertainment', Icons.local_activity_rounded,
      vertical: 'entertainment'),
  CategoryChipSpec('ecommerce', 'E-Commerce', Icons.shopping_bag_rounded,
      vertical: 'ecommerce'),
];

/// The FOOD / GROCERY / MEAT chips each map to one Daily Essentials main
/// category, matched by name. Exact (case-insensitive) match against these
/// aliases wins; a `contains` match is the fallback.
const Map<String, List<String>> kCategoryChipAliases = {
  'food': ['food', 'foods', 'restaurants', 'restaurant'],
  'grocery': ['grocery', 'groceries'],
  'meat': ['meat', 'meats', 'fresh meat'],
};

/// Resolves a food/grocery/meat [chipKey] to a single main category from
/// [mains]. Returns null when nothing matches — the caller then shows an
/// honest empty state rather than an unrelated category.
CategoryRow? resolveMainForChip(List<CategoryRow> mains, String chipKey) {
  final wanted = kCategoryChipAliases[chipKey];
  if (wanted == null) return null;
  for (final alias in wanted) {
    for (final m in mains) {
      if (m.name.trim().toLowerCase() == alias) return m;
    }
  }
  for (final m in mains) {
    final n = m.name.toLowerCase();
    if (wanted.any((a) => n.contains(a))) return m;
  }
  return null;
}

/// Horizontally scrolling rounded-card chip row. Selected chip gets an
/// orange border + orange tint fill + orange icon/label; unselected chips
/// are white with a hairline border and a soft shadow — matching the
/// reference.
class CategorySelector extends StatelessWidget {
  final String selectedKey;
  final ValueChanged<CategoryChipSpec> onSelected;

  const CategorySelector({
    super.key,
    required this.selectedKey,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(SnapBeeSpacing.gutter, 4, SnapBeeSpacing.gutter, 6),
        itemCount: kCategoryChips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final chip = kCategoryChips[i];
          final selected = chip.key == selectedKey;
          return _Chip(
            chip: chip,
            selected: selected,
            onTap: () => onSelected(chip),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final CategoryChipSpec chip;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({required this.chip, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fg = selected ? SnapBeeColors.orange : SnapBeeColors.inkSoft;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 82,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? SnapBeeColors.orangeTint : SnapBeeColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? SnapBeeColors.orange : SnapBeeColors.hairline,
            width: selected ? 1.6 : 1,
          ),
          boxShadow: selected ? null : SnapBeeShadows.soft,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(chip.icon, size: 26, color: fg),
            const SizedBox(height: 6),
            Text(
              chip.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? SnapBeeColors.orange : SnapBeeColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
