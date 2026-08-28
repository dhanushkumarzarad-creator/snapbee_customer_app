import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/cart/cart_store.dart';
import '../../data/repositories/offer_repository.dart';
import 'app_colors.dart';
import 'offer_models.dart';
import 'widgets/offer_app_bar.dart';
import 'widgets/offer_banner_carousel.dart';
import 'widgets/quick_offers_row.dart';
import 'widgets/special_offers_section.dart';
import '../home/widgets/product_model.dart' as home_product;
import '../products/product_details_screen.dart';

/// "Offer Zone" tab — live data from [OfferRepository]:
///   - hero banners  <- cms_banners (customer-readable active/in-window rows)
///   - special offers <- products with a real discount_price
///   - offers row     <- coupons (customer-readable active/in-window rows)
///
/// Each section is hidden when it has no data, so an empty backend shows a
/// single honest "no offers" state rather than fabricated content.
class OfferZoneScreen extends StatefulWidget {
  const OfferZoneScreen({super.key, this.repository});

  /// Injectable for tests; defaults to the real Supabase-backed repository.
  final OfferSource? repository;

  @override
  State<OfferZoneScreen> createState() => _OfferZoneScreenState();
}

class _OfferZoneScreenState extends State<OfferZoneScreen> {
  late final OfferSource _repo =
      widget.repository ?? OfferRepository(Supabase.instance.client);

  bool _loading = true;
  Object? _error;
  List<OfferBannerModel> _banners = const [];
  List<SpecialOfferProduct> _specialOffers = const [];
  List<QuickOfferModel> _coupons = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _repo.fetchHeroBanners(),
        _repo.fetchSpecialOffers(),
        _repo.fetchCoupons(),
      ]);
      if (!mounted) return;
      setState(() {
        _banners = results[0] as List<OfferBannerModel>;
        _specialOffers = results[1] as List<SpecialOfferProduct>;
        _coupons = results[2] as List<QuickOfferModel>;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  bool get _isEmpty =>
      _banners.isEmpty && _specialOffers.isEmpty && _coupons.isEmpty;

  void _openProductDetails(SpecialOfferProduct product) {
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
            unit: product.unit,
            vendorId: product.vendorId,
          ),
        ),
      ),
    );
  }

  void _addToCart(SpecialOfferProduct product) {
    if (product.vendorId.isEmpty) {
      _snack('This item can\'t be added right now.');
      return;
    }
    final result = CartStore.instance.addItem(
      productId: product.id,
      name: product.name,
      imageUrl: product.imageUrl,
      unit: product.unit,
      price: product.offerPrice,
      originalPrice: product.oldPrice,
      vendorId: product.vendorId,
    );
    if (result == CartAddResult.vendorConflict) {
      _confirmReplaceCart(product);
      return;
    }
    _snack('${product.name} added to cart');
  }

  Future<void> _confirmReplaceCart(SpecialOfferProduct product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start a new cart?'),
        content: const Text(
          'Your cart has items from a different store. Adding this item '
          'will clear your current cart.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear cart & add'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    CartStore.instance.replaceWithItem(
      productId: product.id,
      name: product.name,
      imageUrl: product.imageUrl,
      unit: product.unit,
      price: product.offerPrice,
      originalPrice: product.oldPrice,
      vendorId: product.vendorId,
    );
    _snack('${product.name} added to cart');
  }

  Future<void> _copyCoupon(QuickOfferModel offer) async {
    await Clipboard.setData(ClipboardData(text: offer.title));
    _snack('Coupon "${offer.title}" copied — apply it in your cart.');
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const OfferAppBar(title: 'Offer Zone'),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _RetryState(onRetry: _load);
    }
    if (_isEmpty) {
      return const _NoOffersState();
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          if (_banners.isNotEmpty) ...[
            OfferBannerCarousel(banners: _banners, height: 190),
            const SizedBox(height: 24),
          ],
          if (_specialOffers.isNotEmpty) ...[
            SpecialOffersSection(
              products: _specialOffers,
              onProductTap: _openProductDetails,
              onAddTap: _addToCart,
            ),
            const SizedBox(height: 16),
          ],
          if (_coupons.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Coupons', style: AppTextStyles.sectionTitle),
            ),
            const SizedBox(height: 10),
            QuickOffersRow(offers: _coupons, onTap: _copyCoupon),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _NoOffersState extends StatelessWidget {
  const _NoOffersState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      // Scrollable so RefreshIndicator still works on the empty state.
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.28),
        Icon(Icons.local_offer_outlined,
            size: 56, color: Colors.grey.shade400),
        const SizedBox(height: 16),
        const Center(
          child: Text('No offers right now',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text('Check back soon for deals and coupons.',
              style: TextStyle(color: Colors.grey.shade600)),
        ),
      ],
    );
  }
}

class _RetryState extends StatelessWidget {
  const _RetryState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey.shade500),
          const SizedBox(height: 12),
          const Text("Couldn't load offers"),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
