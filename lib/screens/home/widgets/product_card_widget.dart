import 'package:flutter/material.dart';
import '../../../widgets/catalog_image.dart';
import 'product_model.dart';

/// A reusable, Material 3 product card used across the Customer app —
/// trending lists, category grids, search results, "Products For You" on
/// Home, etc.
///
/// Sizing is driven entirely by the parent's constraints (via
/// [LayoutBuilder]/[width]) rather than any hardcoded device width, so the
/// same widget scales correctly on phones, tablets, and Flutter Web.
///
/// Every extra affordance is opt-in so the existing call sites are
/// unaffected:
///  * [storeName]        — shows a small store-name line (Home passes the
///                         real vendor name; other surfaces omit it).
///  * [onWishlistToggle] — when non-null, a heart button is drawn over the
///                         image and [isWishlisted] paints its filled state.
class ProductCardWidget extends StatelessWidget {
  final ProductModel product;

  /// Optional explicit width (e.g. when used inside a horizontal
  /// ListView.builder that wants a fixed card width). When omitted, the
  /// card expands to fill its parent's available width — ideal for grids.
  final double? width;

  /// Optional vendor/store label shown under the unit line.
  final String? storeName;

  /// Whether this product is currently in the customer's wishlist. Only
  /// used when [onWishlistToggle] is provided.
  final bool isWishlisted;

  final VoidCallback? onTap;
  final VoidCallback? onAddPressed;

  /// When non-null, a wishlist/favourite heart is shown on the image and
  /// this is called when the customer taps it.
  final VoidCallback? onWishlistToggle;

  const ProductCardWidget({
    super.key,
    required this.product,
    this.width,
    this.storeName,
    this.isWishlisted = false,
    this.onTap,
    this.onAddPressed,
    this.onWishlistToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: width,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _ProductImage(
                  product: product,
                  isWishlisted: isWishlisted,
                  onWishlistToggle: onWishlistToggle,
                ),
                const SizedBox(height: 8),
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (product.unit.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    product.unit,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if ((storeName ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.storefront_outlined,
                        size: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          storeName!.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                _RatingRow(rating: product.rating, count: product.ratingCount),
                const SizedBox(height: 6),
                _PriceRow(product: product),
                const SizedBox(height: 8),
                _AddButton(onPressed: onAddPressed),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final ProductModel product;
  final bool isWishlisted;
  final VoidCallback? onWishlistToggle;

  const _ProductImage({
    required this.product,
    this.isWishlisted = false,
    this.onWishlistToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox.expand(
                child: CatalogImage(
                  source: product.imageAssetPath,
                  placeholderIcon: Icons.image_not_supported_outlined,
                ),
              ),
            ),
          ),

          if (product.hasDiscount)
            Positioned(
              top: 6,
              left: 6,
              child: _DiscountBadge(percent: product.discountPercent),
            ),

          if (onWishlistToggle != null)
            Positioned(
              top: 4,
              right: 4,
              child: _WishlistButton(
                isWishlisted: isWishlisted,
                onTap: onWishlistToggle!,
              ),
            ),

          if (!product.inStock)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.45),
                child: Center(
                  child: Text(
                    'Out of stock',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WishlistButton extends StatelessWidget {
  final bool isWishlisted;
  final VoidCallback onTap;

  const _WishlistButton({required this.isWishlisted, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(
            isWishlisted ? Icons.favorite : Icons.favorite_border,
            size: 16,
            color: isWishlisted
                ? colorScheme.error
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _DiscountBadge extends StatelessWidget {
  final int percent;

  const _DiscountBadge({required this.percent});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.error,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$percent% OFF',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onError,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  final double rating;
  final int count;
  const _RatingRow({required this.rating, required this.count});

  @override
  Widget build(BuildContext context) {
    if (rating <= 0) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: 16, color: Colors.amber.shade700),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (count > 0) ...[
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '($count)',
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  final ProductModel product;
  const _PriceRow({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        Text(
          '₹${product.currentPrice.toStringAsFixed(0)}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
          ),
        ),
        if (product.hasDiscount)
          Text(
            '₹${product.oldPrice!.toStringAsFixed(0)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              decoration: TextDecoration.lineThrough,
              decorationColor: colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const _AddButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 34,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'ADD',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
      ),
    );
  }
}
