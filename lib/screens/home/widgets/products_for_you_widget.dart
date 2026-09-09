import 'package:flutter/material.dart';

import '../../../core/design/snapbee_design.dart';
import 'product_card_widget.dart';
import 'product_model.dart';

/// "Products For You" — a horizontally scrolling carousel of real Daily
/// Essentials catalog products ([ProductRepository.fetchAll]: active-status
/// and browse-time coverage filtered). Sits directly below "Popular Stores
/// Near You" on Home and deliberately shares that section's
/// [SnapBeeSectionHeader] + horizontal-strip visual language so it reads as
/// native to the existing design.
///
///  * [products] null  → still loading (shows a small spinner)
///  * [products] empty → loaded, nothing available in the customer's area
///    (shows an honest empty state — never a hardcoded sample list)
class ProductsForYouWidget extends StatelessWidget {
  final List<ProductModel>? products;
  final bool isLoading;
  final VoidCallback? onSeeAll;
  final ValueChanged<ProductModel>? onProductTap;
  final ValueChanged<ProductModel>? onAdd;

  const ProductsForYouWidget({
    super.key,
    required this.products,
    this.isLoading = false,
    this.onSeeAll,
    this.onProductTap,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final items = products ?? const <ProductModel>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SnapBeeSectionHeader(
          title: 'Products For You',
          onAction: onSeeAll,
        ),
        if (isLoading)
          const SizedBox(
            height: 120,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (items.isEmpty)
          const _ProductsEmptyState()
        else
          LayoutBuilder(
            builder: (context, constraints) {
              // Responsive card width, same approach the trending row used —
              // a fraction of the available width, clamped so cards stay
              // readable on small phones and don't balloon on wide web.
              final cardWidth =
                  (constraints.maxWidth * 0.4).clamp(150.0, 200.0);
              final listHeight = cardWidth * 1.75;

              return SizedBox(
                height: listHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(
                    SnapBeeSpacing.gutter,
                    2,
                    SnapBeeSpacing.gutter,
                    4,
                  ),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final product = items[index];
                    return ProductCardWidget(
                      product: product,
                      width: cardWidth,
                      onTap: onProductTap == null
                          ? null
                          : () => onProductTap!(product),
                      onAddPressed:
                          onAdd == null ? null : () => onAdd!(product),
                    );
                  },
                ),
              );
            },
          ),
      ],
    );
  }
}

/// Honest, compact empty state — shown only once the catalog fetch has
/// resolved with no customer-visible products. Kept to a single row so the
/// Home page doesn't grow unnecessarily.
class _ProductsEmptyState extends StatelessWidget {
  const _ProductsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        SnapBeeSpacing.gutter,
        2,
        SnapBeeSpacing.gutter,
        4,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: SnapBeeColors.surface,
        borderRadius: BorderRadius.circular(SnapBeeSpacing.rTile),
        border: Border.all(color: SnapBeeColors.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: SnapBeeColors.orangeTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_basket_outlined,
              color: SnapBeeColors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('No products available yet', style: SnapBeeText.title),
                const SizedBox(height: 2),
                Text(
                  "We couldn't find products in your area right now. "
                  'Check back soon.',
                  style: SnapBeeText.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
