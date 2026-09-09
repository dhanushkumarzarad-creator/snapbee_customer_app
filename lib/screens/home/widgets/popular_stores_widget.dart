import 'package:flutter/material.dart';

import '../../../core/design/snapbee_design.dart';
import '../../../data/repositories/vendor_repository.dart';
import '../../../widgets/catalog_image.dart';

/// "Popular Stores Near You" — a horizontally scrolling row of real,
/// customer-visible Daily Essentials stores ([VendorRepository.
/// fetchCustomerVisibleStores], coverage-filtered). Tapping a card opens the
/// store's real page.
///
/// The reference screen decorates each card with a discount badge, a star
/// rating and an ETA. Daily Essentials has no rating / ETA / delivery-
/// threshold data source yet (same reason `ProductModel.rating` stays 0 and
/// `VendorStoreScreen` shows an honest empty reviews state), so this card
/// shows only real fields — store name and area — instead of fabricating
/// those numbers. It renders nothing until real stores load, exactly like
/// the trending row it replaces.
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
    final items = stores ?? const <VendorRow>[];
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SnapBeeSectionHeader(
          title: 'Popular Stores Near You',
          onAction: onSeeAll,
        ),
        SizedBox(
          height: 186,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(SnapBeeSpacing.gutter, 2, SnapBeeSpacing.gutter, 4),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 112,
              width: double.infinity,
              child: CatalogImage(
                source: store.displayImageUrl,
                fit: BoxFit.cover,
                placeholderIcon: Icons.storefront_outlined,
              ),
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
                    style: SnapBeeText.title,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: SnapBeeColors.inkFaint),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          store.areaLabel.isEmpty ? 'Daily Essentials store' : store.areaLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SnapBeeText.caption,
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
