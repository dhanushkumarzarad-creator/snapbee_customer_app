import 'package:flutter/material.dart';
import 'package:snapbee_customer_app/core/constants/app_colors.dart';
import '../../../widgets/catalog_image.dart';

/// A single featured/nearby store shown in the "Popular Stores Near
/// You" rail.
class FeaturedStore {
  final String name;
  final double rating;
  final String prepTimeLabel;
  final double freeDeliveryAbove;
  final int discountPercent;
  final String? imageUrl;
  final IconData fallbackIcon;

  const FeaturedStore({
    required this.name,
    required this.rating,
    required this.prepTimeLabel,
    required this.freeDeliveryAbove,
    this.discountPercent = 0,
    this.imageUrl,
    this.fallbackIcon = Icons.storefront_rounded,
  });
}

/// "Popular Stores Near You" section: header + "See All", followed by
/// a horizontally scrollable rail of store cards — cover image with a
/// green discount ribbon, name, star rating + prep time, and a green
/// "Free delivery above ₹X" line.
class FeaturedStoreWidget extends StatelessWidget {
  final String title;
  final List<FeaturedStore> stores;
  final VoidCallback? onSeeAll;
  final ValueChanged<int>? onStoreTap;

  const FeaturedStoreWidget({
    super.key,
    this.title = 'Popular Stores Near You',
    this.stores = const [
      FeaturedStore(
        name: 'Fresh Mart',
        rating: 4.6,
        prepTimeLabel: '30-40 mins',
        freeDeliveryAbove: 299,
        discountPercent: 25,
        fallbackIcon: Icons.storefront_rounded,
      ),
      FeaturedStore(
        name: 'Meat House',
        rating: 4.5,
        prepTimeLabel: '25-35 mins',
        freeDeliveryAbove: 199,
        discountPercent: 20,
        fallbackIcon: Icons.set_meal_rounded,
      ),
      FeaturedStore(
        name: 'Kovai Café',
        rating: 4.7,
        prepTimeLabel: '20-30 mins',
        freeDeliveryAbove: 249,
        discountPercent: 15,
        fallbackIcon: Icons.local_pizza_rounded,
      ),
    ],
    this.onSeeAll,
    this.onStoreTap,
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
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: stores.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final store = stores[index];
              return _StoreCard(
                store: store,
                onTap: () => onStoreTap?.call(index),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StoreCard extends StatelessWidget {
  final FeaturedStore store;
  final VoidCallback? onTap;

  const _StoreCard({required this.store, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 168,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.5,
                  child: Container(
                    color: AppColors.cardGrey,
                    child: store.imageUrl != null
                        ? CatalogImage(
                            source: store.imageUrl,
                            fit: BoxFit.cover,
                            placeholderIcon: store.fallbackIcon,
                          )
                        : Icon(
                            store.fallbackIcon,
                            size: 40,
                            color: AppColors.textSecondary,
                          ),
                  ),
                ),
                if (store.discountPercent > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.discountBadge,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${store.discountPercent}%\nOFF',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 15,
                        color: AppColors.ratingStar,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        store.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          store.prepTimeLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Free delivery above \u20b9${store.freeDeliveryAbove.toStringAsFixed(0)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentGreen,
                    ),
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
