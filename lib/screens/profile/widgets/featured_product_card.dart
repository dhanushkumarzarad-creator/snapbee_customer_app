import 'package:flutter/material.dart';
import '../category_models.dart';
import '../snapbee_theme.dart';

/// Product card for the "Featured Products" horizontal scroller.
///
/// Fixed width so it behaves predictably inside a horizontal ListView
/// (avoids the classic "unbounded width" RenderFlex crash).
class FeaturedProductCard extends StatelessWidget {
  final FeaturedProductModel product;
  final VoidCallback? onTap;

  const FeaturedProductCard({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    final discount = product.discountPercent;

    return SizedBox(
      width: 150,
      child: Material(
        color: SnapBeeColors.cardBackground,
        borderRadius: BorderRadius.circular(SnapBeeRadii.card),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(SnapBeeRadii.card),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(SnapBeeRadii.card),
              boxShadow: const [
                BoxShadow(
                  color: SnapBeeColors.shadow,
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image + discount badge
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(SnapBeeRadii.card),
                      ),
                      child: AspectRatio(
                        aspectRatio: 1.1,
                        child: Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: SnapBeeColors.unselectedChip,
                            child: const Icon(
                              Icons.image_not_supported,
                              color: SnapBeeColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (discount != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: SnapBeeColors.discountBadge,
                            borderRadius: BorderRadius.circular(
                              SnapBeeRadii.badge,
                            ),
                          ),
                          child: Text(
                            '$discount% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: SnapBeeColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.unit,
                        style: const TextStyle(
                          fontSize: 11,
                          color: SnapBeeColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 13,
                            color: SnapBeeColors.rating,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            product.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: SnapBeeColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '₹${product.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: SnapBeeColors.primaryDark,
                            ),
                          ),
                          if (product.mrp != null) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '₹${product.mrp!.toStringAsFixed(0)}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: SnapBeeColors.textSecondary,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
