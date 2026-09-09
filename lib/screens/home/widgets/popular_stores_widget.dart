import 'package:flutter/material.dart';

import '../../../core/design/snapbee_design.dart';
import '../../../data/repositories/vendor_repository.dart';
import '../../../widgets/catalog_image.dart';

/// "Popular Stores Near You" — a horizontally scrolling row of real,
/// customer-visible Daily Essentials stores ([VendorRepository.
/// fetchCustomerVisibleStores], RLS + coverage filtered). Tapping a card
/// opens the store's real page.
///
/// The reference screen decorates each card with a discount badge, a star
/// rating, an ETA and a delivery condition. Of those, offer % (green badge),
/// a star rating and a "delivery available" flag are backed by real,
/// customer-readable tables (`vendor_delivery_settings`, `de_order_reviews`)
/// and are shown only when that data actually exists. Daily Essentials still
/// has no delivery-ETA source, so no "x mins" line is shown rather than a
/// fabricated one. The row renders nothing until real stores load.
class PopularStoresWidget extends StatelessWidget {
  final List<VendorRow>? stores;
  final ValueChanged<VendorRow>? onStoreTap;
  final VoidCallback? onSeeAll;

  const PopularStoresWidget({
    super.key,
    required this.stores,
    this.onStoreTap,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    // stores == null  -> still loading: render nothing yet (no flicker).
    // stores == []     -> loaded, none customer-visible in this area: keep
    //                     the section (the reference always shows it) with
    //                     an honest empty state instead of a fake list.
    if (stores == null) return const SizedBox.shrink();
    final items = stores!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SnapBeeSectionHeader(
          title: 'Popular Stores Near You',
          onAction: items.isEmpty ? null : onSeeAll,
        ),
        if (items.isEmpty)
          const _StoresEmptyState()
        else
        SizedBox(
          height: 206,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(
                SnapBeeSpacing.gutter, 2, SnapBeeSpacing.gutter, 4),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final store = items[index];
              return _StoreCard(
                store: store,
                onTap: onStoreTap == null ? null : () => onStoreTap!(store),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StoreCard extends StatelessWidget {
  final VendorRow store;
  final VoidCallback? onTap;

  const _StoreCard({required this.store, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SnapBeeSpacing.rTile),
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: SnapBeeColors.surface,
          borderRadius: BorderRadius.circular(SnapBeeSpacing.rTile),
          boxShadow: SnapBeeShadows.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 108,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CatalogImage(
                    source: store.displayImageUrl,
                    fit: BoxFit.cover,
                    placeholderIcon: Icons.storefront_outlined,
                  ),
                  if (store.hasOffer)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _OfferBadge(percent: store.offerPercent!),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SnapBeeText.title,
                  ),
                  const SizedBox(height: 4),
                  // ⭐ rating (real, when reviews exist) + area on one line —
                  // the compact 2-line card the reference uses.
                  Row(
                    children: [
                      if (store.hasRating) ...[
                        const Icon(Icons.star_rounded,
                            size: 14, color: SnapBeeColors.star),
                        const SizedBox(width: 3),
                        Text(
                          store.ratingAvg!.toStringAsFixed(1),
                          style: SnapBeeText.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: SnapBeeColors.ink,
                          ),
                        ),
                        Text('  ·  ', style: SnapBeeText.caption),
                      ] else ...[
                        const Icon(Icons.location_on_outlined,
                            size: 13, color: SnapBeeColors.inkFaint),
                        const SizedBox(width: 3),
                      ],
                      Expanded(
                        child: Text(
                          store.areaLabel.isEmpty
                              ? 'Daily Essentials store'
                              : store.areaLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SnapBeeText.caption,
                        ),
                      ),
                    ],
                  ),
                  if (store.deliveryEnabled == true) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.delivery_dining_outlined,
                            size: 13, color: SnapBeeColors.success),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            'Delivery available',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SnapBeeText.caption.copyWith(
                              color: SnapBeeColors.success,
                              fontWeight: FontWeight.w600,
                            ),
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

/// Honest, compact empty state — shown once the vendor fetch resolves with
/// no customer-visible store in the browsing area (RLS + coverage). Kept to
/// one row so Home doesn't grow unnecessarily, and mirrors the "Products
/// For You" empty state.
class _StoresEmptyState extends StatelessWidget {
  const _StoresEmptyState();

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
              Icons.storefront_outlined,
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
                Text('No stores near you yet', style: SnapBeeText.title),
                const SizedBox(height: 2),
                Text(
                  "We couldn't find stores serving your area right now. "
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

/// Green "N% OFF" pill, matching the reference store-card badge. Only shown
/// when a real `vendor_delivery_settings.offer_percent` backs it.
class _OfferBadge extends StatelessWidget {
  final double percent;

  const _OfferBadge({required this.percent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: SnapBeeColors.success,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${percent.toStringAsFixed(0)}% OFF',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
