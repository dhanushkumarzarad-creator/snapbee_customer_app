import 'package:flutter/material.dart';

import '../../../core/design/snapbee_design.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../widgets/catalog_image.dart';

/// A single category tile in the 3-column grid, matching 02_Categories.png:
/// a rounded pastel card, a ~square image area (Admin-uploaded image,
/// `BoxFit.contain`, icon fallback), the category name, and a circular
/// arrow button in the bottom-right corner.
///
/// No count line is shown — the reference's "1,250+ products" numbers have
/// no real backend source, so per the brief they are omitted rather than
/// invented.
class CategoryGridCard extends StatelessWidget {
  final CategoryRow category;

  /// Index into [SnapBeeColors.pastelCycle] for the card tint.
  final int tintIndex;
  final VoidCallback? onTap;

  const CategoryGridCard({
    super.key,
    required this.category,
    required this.tintIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tint = SnapBeeColors.pastelFor(tintIndex);
    final accent = _accentFor(tintIndex);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(18),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area — the wide upper part of the card, image on tint.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                child: _CategoryImage(
                  url: category.imageUrl,
                  fallbackIcon: _iconFor(category.name),
                  accent: accent,
                ),
              ),
            ),
            // Name + arrow row (fixed height so a 2-line name never clips
            // or collides with the arrow).
            SizedBox(
              height: 44,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 8, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        category.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: SnapBeeText.title.copyWith(
                          fontSize: 12.5,
                          height: 1.12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: SnapBeeColors.surface,
                        shape: BoxShape.circle,
                        boxShadow: SnapBeeShadows.soft,
                      ),
                      child: Icon(Icons.chevron_right_rounded,
                          size: 18, color: accent),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _accentFor(int i) {
    const cycle = [
      SnapBeeColors.orange,
      SnapBeeColors.success,
      SnapBeeColors.danger,
      SnapBeeColors.platinum,
      SnapBeeColors.info,
      SnapBeeColors.warn,
    ];
    return cycle[i % cycle.length];
  }

  static IconData _iconFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('restaurant') || n.contains('food')) {
      return Icons.restaurant_rounded;
    }
    if (n.contains('grocery') || n.contains('stapl')) {
      return Icons.local_grocery_store_rounded;
    }
    if (n.contains('meat') || n.contains('fish') || n.contains('seafood')) {
      return Icons.set_meal_rounded;
    }
    if (n.contains('fruit') || n.contains('veget')) return Icons.eco_rounded;
    if (n.contains('bakery') || n.contains('cake')) return Icons.bakery_dining_rounded;
    if (n.contains('electronic')) return Icons.devices_rounded;
    if (n.contains('personal care') || n.contains('beauty')) {
      return Icons.spa_rounded;
    }
    if (n.contains('home') || n.contains('kitchen')) return Icons.chair_rounded;
    if (n.contains('baby')) return Icons.child_friendly_rounded;
    if (n.contains('pet')) return Icons.pets_rounded;
    if (n.contains('health') || n.contains('wellness') || n.contains('pharma')) {
      return Icons.medical_services_rounded;
    }
    if (n.contains('flower') || n.contains('gift')) return Icons.card_giftcard_rounded;
    if (n.contains('beverage') || n.contains('drink')) return Icons.local_cafe_rounded;
    if (n.contains('dairy') || n.contains('egg')) return Icons.egg_rounded;
    if (n.contains('snack')) return Icons.fastfood_rounded;
    return Icons.category_rounded;
  }
}

class _CategoryImage extends StatelessWidget {
  final String? url;
  final IconData fallbackIcon;
  final Color accent;

  const _CategoryImage({
    required this.url,
    required this.fallbackIcon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final hasUrl = (url ?? '').trim().isNotEmpty;
    return Center(
      child: hasUrl
          ? CatalogImage(
              source: url,
              fit: BoxFit.contain,
              placeholderIcon: fallbackIcon,
            )
          : Icon(fallbackIcon, size: 42, color: accent.withValues(alpha: 0.85)),
    );
  }
}
