import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../offer_models.dart';
import 'offer_banner_carousel.dart';

/// "Offer Banners" section: heading + large promotional banner carousel.
class OfferBannersSection extends StatelessWidget {
  final List<OfferBannerModel> banners;
  final ValueChanged<OfferBannerModel>? onBannerTap;

  const OfferBannersSection({
    super.key,
    required this.banners,
    this.onBannerTap,
  });

  @override
  Widget build(BuildContext context) {
    if (banners.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Offer Banners', style: AppTextStyles.sectionTitle),
        ),
        const SizedBox(height: 12),
        OfferBannerCarousel(
          banners: banners,
          height: 170,
          onBannerTap: onBannerTap,
        ),
      ],
    );
  }
}
