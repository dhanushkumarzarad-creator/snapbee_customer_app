import 'package:flutter/material.dart';
import 'product_card_widget.dart';
import 'product_model.dart';

/// Horizontally scrolling "Trending products" section for the Customer app
/// home screen.
///
/// Card width is derived from the available screen width rather than a
/// hardcoded constant, so the layout adapts cleanly across phones, tablets,
/// and Flutter Web (wide browser windows).
class TrendingProductsWidget extends StatelessWidget {
  final String title;
  final List<ProductModel>? products;
  final ValueChanged<ProductModel>? onProductTap;
  final ValueChanged<ProductModel>? onAddPressed;
  final VoidCallback? onSeeAllPressed;

  const TrendingProductsWidget({
    super.key,
    this.title = 'Trending products',
    this.products,
    this.onProductTap,
    this.onAddPressed,
    this.onSeeAllPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Null = still loading or the catalog fetch failed; empty = loaded but
    // nothing trending. Either way, render nothing rather than a hardcoded
    // sample list.
    final items = products ?? const <ProductModel>[];
    final theme = Theme.of(context);

    if (items.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive card width: a fraction of the available width, clamped
        // between sensible min/max bounds so cards don't become too
        // cramped on small phones or absurdly large on wide web viewports.
        final availableWidth = constraints.maxWidth;
        final cardWidth = (availableWidth * 0.4).clamp(150.0, 220.0);
        final listHeight = cardWidth * 1.75;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (onSeeAllPressed != null)
                    TextButton(
                      onPressed: onSeeAllPressed,
                      child: const Text('See all'),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 4),
            SizedBox(
              height: listHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final product = items[index];
                  return ProductCardWidget(
                    product: product,
                    width: cardWidth,
                    onTap: onProductTap == null
                        ? null
                        : () => onProductTap!(product),
                    onAddPressed: onAddPressed == null
                        ? null
                        : () => onAddPressed!(product),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
