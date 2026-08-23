import 'package:flutter/material.dart';
import '../offer_models.dart';
import 'section_header.dart';
import 'store_offer_card.dart';

/// "Store Offers" section: heading + View All + horizontal store list.
class StoreOffersSection extends StatelessWidget {
  final List<StoreOfferModel> stores;
  final VoidCallback? onViewAllTap;
  final ValueChanged<StoreOfferModel>? onStoreTap;
  final ValueChanged<StoreOfferModel>? onBookmarkTap;

  const StoreOffersSection({
    super.key,
    required this.stores,
    this.onViewAllTap,
    this.onStoreTap,
    this.onBookmarkTap,
  });

  @override
  Widget build(BuildContext context) {
    if (stores.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Store Offers', onViewAllTap: onViewAllTap),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: stores.length,
            itemBuilder: (context, index) {
              final store = stores[index];
              return StoreOfferCard(
                store: store,
                onTap: () => onStoreTap?.call(store),
                onBookmarkTap: () => onBookmarkTap?.call(store),
              );
            },
          ),
        ),
      ],
    );
  }
}
