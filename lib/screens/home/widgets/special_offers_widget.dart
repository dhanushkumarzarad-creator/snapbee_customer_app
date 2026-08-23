import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// A single discounted product shown in the Special Offers rail.
class OfferProduct {
  final String name;
  final double price;
  final double? originalPrice;
  final String? imageUrl;
  final IconData fallbackIcon;

  const OfferProduct({
    required this.name,
    required this.price,
    this.originalPrice,
    this.imageUrl,
    this.fallbackIcon = Icons.shopping_bag_outlined,
  });
}

/// "Special Offers" section: header + "View All", followed by a
/// horizontally scrollable rail of product cards, each with an image,
/// name, discounted price, struck-through original price, and a
/// circular "+" add-to-basket button.
class SpecialOffersWidget extends StatelessWidget {
  final List<OfferProduct> products;
  final VoidCallback? onViewAll;
  final void Function(int index)? onAddTap;
  final void Function(int index)? onProductTap;

  const SpecialOffersWidget({
    super.key,
    this.products = const [
      OfferProduct(
        name: 'Apple',
        price: 80,
        originalPrice: 100,
        fallbackIcon: Icons.apple,
      ),
      OfferProduct(
        name: 'Chicken Biriyani',
        price: 100,
        originalPrice: 150,
        fallbackIcon: Icons.rice_bowl,
      ),
      OfferProduct(
        name: 'Sunflower Oil',
        price: 120,
        originalPrice: 150,
        fallbackIcon: Icons.liquor,
      ),
      OfferProduct(
        name: 'Orange Juice',
        price: 50,
        originalPrice: 80,
        fallbackIcon: Icons.local_drink,
      ),
    ],
    this.onViewAll,
    this.onAddTap,
    this.onProductTap,
  });

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
              const Text(
                'Special Offers',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              InkWell(
                onTap: onViewAll,
                child: const Row(
                  children: [
                    Icon(
                      Icons.grid_view_rounded,
                      size: 16,
                      color: AppColors.textPrimary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final product = products[index];
              return _OfferCard(
                product: product,
                onTap: () => onProductTap?.call(index),
                onAddTap: () => onAddTap?.call(index),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _OfferCard extends StatelessWidget {
  final OfferProduct product;
  final VoidCallback? onTap;
  final VoidCallback? onAddTap;

  const _OfferCard({required this.product, this.onTap, this.onAddTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.3,
              child: Container(
                color: AppColors.cardGrey,
                child: product.imageUrl != null
                    ? Image.network(product.imageUrl!, fit: BoxFit.cover)
                    : Icon(
                        product.fallbackIcon,
                        size: 40,
                        color: AppColors.textSecondary,
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          children: [
                            Text(
                              '\u20b9${product.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryOrangeDark,
                              ),
                            ),
                            if (product.originalPrice != null)
                              Text(
                                '\u20b9${product.originalPrice!.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.strikePrice,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: onAddTap,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryOrange,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
