import 'package:flutter/material.dart';
import '../offer_models.dart';
import 'section_header.dart';
import 'special_offer_card.dart';

/// "Special Offers" section: heading + View All + horizontal product list.
class SpecialOffersSection extends StatelessWidget {
  final List<SpecialOfferProduct> products;
  final VoidCallback? onViewAllTap;
  final ValueChanged<SpecialOfferProduct>? onProductTap;
  final ValueChanged<SpecialOfferProduct>? onAddTap;

  const SpecialOffersSection({
    super.key,
    required this.products,
    this.onViewAllTap,
    this.onProductTap,
    this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Special Offers', onViewAllTap: onViewAllTap),
        const SizedBox(height: 12),
        SizedBox(
          // Card's natural height is ~196 at default text scale; 190 clipped it.
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return SpecialOfferCard(
                product: product,
                onTap: () => onProductTap?.call(product),
                onAddTap: () => onAddTap?.call(product),
              );
            },
          ),
        ),
      ],
    );
  }
}
