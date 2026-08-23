import 'package:flutter/material.dart';
import 'package:snapbee_customer_app/core/constants/app_colors.dart';

/// A single nearby/available vendor store.
class NearbyStore {
  final String name;
  final double rating;
  final String etaLabel;
  final String distanceLabel;
  final bool verified;
  final String? logoUrl;

  const NearbyStore({
    required this.name,
    required this.rating,
    required this.etaLabel,
    required this.distanceLabel,
    this.verified = false,
    this.logoUrl,
  });
}

/// "Available Stores" section: header + "View All", followed by a
/// horizontally scrollable rail of store cards showing a logo, name,
/// star rating, ETA + distance, and a verified badge when applicable.
class NearbyStoreWidget extends StatelessWidget {
  final List<NearbyStore> stores;
  final VoidCallback? onViewAll;
  final void Function(int index)? onStoreTap;

  const NearbyStoreWidget({
    super.key,
    this.stores = const [
      NearbyStore(
        name: "Angel's Grocery Store",
        rating: 4.0,
        etaLabel: '15-30 Min',
        distanceLabel: 'Near 1.5 KM',
        verified: true,
      ),
      NearbyStore(
        name: 'Grocery Store',
        rating: 4.5,
        etaLabel: '20-35 Min',
        distanceLabel: 'Near 2.2 KM',
        verified: true,
      ),
    ],
    this.onViewAll,
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
              const Text(
                'Available Stores',
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
          height: 128,
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
  final NearbyStore store;
  final VoidCallback? onTap;

  const _StoreCard({required this.store, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cardGrey,
              ),
              clipBehavior: Clip.antiAlias,
              child: store.logoUrl != null
                  ? Image.network(store.logoUrl!, fit: BoxFit.cover)
                  : const Icon(
                      Icons.storefront,
                      size: 30,
                      color: AppColors.textSecondary,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          store.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.bookmark_border,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(5, (i) {
                      final filled = i < store.rating.floor();
                      return Icon(
                        filled ? Icons.star : Icons.star_border,
                        size: 15,
                        color: AppColors.accentGreen,
                      );
                    }),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        store.etaLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '|',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        store.distanceLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (store.verified) ...[
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Icon(
                          Icons.verified,
                          size: 14,
                          color: AppColors.accentGreen,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Verified',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
