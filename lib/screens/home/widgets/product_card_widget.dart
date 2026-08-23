import 'package:flutter/material.dart';
import '../../../widgets/catalog_image.dart';
import 'product_model.dart';

/// A reusable, Material 3 product card used across the Customer app —
/// trending lists, category grids, search results, etc.
///
/// Sizing is driven entirely by the parent's constraints (via
/// [LayoutBuilder]/[width]) rather than any hardcoded device width, so the
/// same widget scales correctly on phones, tablets, and Flutter Web.
class ProductCardWidget extends StatelessWidget {
  final ProductModel product;

  /// Optional explicit width (e.g. when used inside a horizontal
  /// ListView.builder that wants a fixed card width). When omitted, the
  /// card expands to fill its parent's available width — ideal for grids.
  final double? width;

  final VoidCallback? onTap;
  final VoidCallback? onAddPressed;

  const ProductCardWidget({
    super.key,
    required this.product,
    this.width,
    this.onTap,
    this.onAddPressed,
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
                _ProductImage(product: product),
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

  const _ProductImage({required this.product});

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
          '\u20B9${product.currentPrice.toStringAsFixed(0)}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
          ),
        ),
        if (product.hasDiscount)
          Text(
            '\u20B9${product.oldPrice!.toStringAsFixed(0)}',
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
