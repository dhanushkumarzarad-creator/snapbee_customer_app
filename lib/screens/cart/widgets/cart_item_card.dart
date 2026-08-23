import 'package:flutter/material.dart';

import '../models/cart_model.dart';

/// A single product row in the cart — image, name, unit, price/MRP with
/// discount badge, a +/- quantity stepper, and remove / save-for-later
/// actions. Styled after Blinkit/Zepto/Instamart cart rows.
class CartItemCard extends StatelessWidget {
  final CartItemModel item;
  final ValueChanged<int>? onQuantityChanged;
  final VoidCallback? onRemove;
  final VoidCallback? onSaveForLater;
  final VoidCallback? onMoveToCart;

  const CartItemCard({
    super.key,
    required this.item,
    this.onQuantityChanged,
    this.onRemove,
    this.onSaveForLater,
    this.onMoveToCart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProductImage(
            imageUrl: item.imageUrl,
            discountPercent: item.discountPercent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.unit,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    Text(
                      '\u20b9${item.price.toStringAsFixed(0)}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (item.hasDiscount)
                      Text(
                        '\u20b9${(item.originalPrice ?? item.price).toStringAsFixed(0)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (item.savedForLater)
                      TextButton(
                        onPressed: onMoveToCart,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Move to cart'),
                      )
                    else
                      QuantitySelector(
                        quantity: item.quantity,
                        maxQuantity: item.maxQuantity,
                        onChanged: onQuantityChanged,
                      ),
                    if (!item.savedForLater && onSaveForLater != null)
                      TextButton.icon(
                        onPressed: onSaveForLater,
                        icon: const Icon(
                          Icons.bookmark_border_rounded,
                          size: 16,
                        ),
                        label: const Text('Save for later'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: colorScheme.onSurfaceVariant,
                          textStyle: theme.textTheme.labelSmall,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: Icon(
              Icons.close_rounded,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
            tooltip: 'Remove',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

/// Product thumbnail with a small discount ribbon overlay when applicable.
class _ProductImage extends StatelessWidget {
  final String imageUrl;
  final int discountPercent;

  const _ProductImage({required this.imageUrl, required this.discountPercent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 72,
            height: 72,
            color: theme.colorScheme.surfaceContainerHighest,
            child: imageUrl.isEmpty
                ? Icon(
                    Icons.image_not_supported_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 24,
                  )
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.image_not_supported_outlined,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                  ),
          ),
        ),
        if (discountPercent > 0)
          Positioned(
            left: 0,
            right: 0,
            bottom: -2,
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 2),
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Text(
                '$discountPercent% OFF',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Reusable +/- quantity stepper used in the cart (and reusable on
/// product listing/detail screens too).
class QuantitySelector extends StatelessWidget {
  final int quantity;
  final int maxQuantity;
  final int minQuantity;
  final ValueChanged<int>? onChanged;

  const QuantitySelector({
    super.key,
    required this.quantity,
    this.maxQuantity = 10,
    this.minQuantity = 0,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            onTap: quantity > minQuantity
                ? () => onChanged?.call(quantity - 1)
                : null,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            onTap: quantity < maxQuantity
                ? () => onChanged?.call(quantity + 1)
                : null,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 28,
        height: 32,
        child: Icon(
          icon,
          size: 16,
          color: onTap == null
              ? colorScheme.onPrimary.withValues(alpha: 0.4)
              : colorScheme.onPrimary,
        ),
      ),
    );
  }
}
