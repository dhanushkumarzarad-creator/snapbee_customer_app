import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../offer_models.dart';

/// A single store card used inside the "Store Offers" horizontal list.
class StoreOfferCard extends StatelessWidget {
  final StoreOfferModel store;
  final VoidCallback? onTap;
  final VoidCallback? onBookmarkTap;

  const StoreOfferCard({
    super.key,
    required this.store,
    this.onTap,
    this.onBookmarkTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadii.medium),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.small),
              child: Image.network(
                store.logoUrl,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 64,
                  height: 64,
                  color: AppColors.lightOrange,
                ),
              ),
            ),
            const SizedBox(width: 10),
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
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: onBookmarkTap,
                        child: Icon(
                          store.isBookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          size: 18,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      ...List.generate(5, (i) {
                        return Icon(
                          i < store.rating.round()
                              ? Icons.star
                              : Icons.star_border,
                          size: 13,
                          color: AppColors.starGold,
                        );
                      }),
                      const SizedBox(width: 4),
                      Text(
                        store.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 12,
                        color: AppColors.textGrey,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        store.deliveryTime,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textGrey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('•', style: TextStyle(color: Colors.grey.shade400)),
                      const SizedBox(width: 8),
                      Text(
                        'Near ${store.distance}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                  if (store.isVerified) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: const [
                        Icon(
                          Icons.verified,
                          size: 13,
                          color: AppColors.verifiedGreen,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Verified',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.verifiedGreen,
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
