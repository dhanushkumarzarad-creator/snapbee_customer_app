import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'dummy_offer_data.dart';
import 'offer_models.dart';

import 'widgets/offer_app_bar.dart';
import 'widgets/offer_banner_carousel.dart';
import 'widgets/offer_banners_section.dart';
import 'widgets/quick_offers_row.dart';
import 'widgets/special_offers_section.dart';
import 'widgets/store_offers_section.dart';
import '../home/widgets/product_model.dart' as home_product;
import '../products/product_details_screen.dart';

/// Full "Offer Zone" screen for the SnapBee customer app.
///
/// Wire this up to real repositories by replacing the DummyOfferData
/// references below with your Supabase-backed data sources — every
/// section widget only depends on the plain model classes in
/// lib/models/offer_models.dart, so swapping data sources needs no
/// changes to the widgets themselves.
class OfferZoneScreen extends StatelessWidget {
  const OfferZoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const OfferAppBar(title: 'Offer Zone'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            // 1. Hero Offer Banner
            OfferBannerCarousel(
              banners: DummyOfferData.heroBanners,
              height: 190,
              onBannerTap: (banner) {
                // TODO: navigate to the banner's linked offer/product.
              },
            ),
            const SizedBox(height: 24),

            // 2. Special Offers
            SpecialOffersSection(
              products: DummyOfferData.specialOffers,
              onViewAllTap: () {
                // TODO: navigate to full special-offers listing.
              },
              onProductTap: (product) => _openProductDetails(context, product),
              onAddTap: (product) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${product.name} added to cart')),
                );
              },
            ),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 1,
              color: Colors.grey.shade200,
            ),
            const SizedBox(height: 16),

            // 3. Offers row
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Offers', style: AppTextStyles.sectionTitle),
            ),
            const SizedBox(height: 10),
            QuickOffersRow(
              offers: DummyOfferData.quickOffers,
              onTap: (offer) {
                // TODO: navigate to the relevant offers listing.
              },
            ),
            const SizedBox(height: 15),

            // 4. Store Offers
            StoreOffersSection(
              stores: DummyOfferData.storeOffers,
              onViewAllTap: () {
                // TODO: navigate to full store-offers listing.
              },
              onStoreTap: (store) {
                // TODO: open store page.
              },
              onBookmarkTap: (store) {
                // TODO: toggle bookmark for this store.
              },
            ),
            const SizedBox(height: 15),

            // 5. Offer Banners
            OfferBannersSection(
              banners: DummyOfferData.promoBanners,
              onBannerTap: (banner) {
                // TODO: navigate to the banner's linked offer/product.
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),

      // 6. Existing SnapBee bottom nav — swap the placeholder below
      // for your app's real shared bottom nav widget.
    );
  }

  void _openProductDetails(BuildContext context, SpecialOfferProduct product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(
          product: home_product.ProductModel(
            id: product.id,
            name: product.name,
            imageAssetPath: product.imageUrl,
            currentPrice: product.offerPrice,
            oldPrice: product.oldPrice,
          ),
        ),
      ),
    );
  }
}
