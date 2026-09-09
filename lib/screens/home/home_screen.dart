import 'package:flutter/material.dart';
import 'package:snapbee_customer_app/core/constants/app_colors.dart';
import 'package:snapbee_customer_app/core/design/snapbee_design.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/cart/cart_store.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/vendor_repository.dart';
import '../category/category_screen.dart';
import '../category/featured_products_screen.dart';
import '../../widgets/customer_home_header.dart';
import '../../widgets/customer_search_bar.dart';
import '../notification/notification_screen.dart';
import 'widgets/service_tabs_widget.dart';
import 'widgets/hero_banner_widget.dart';
import 'widgets/home_quick_actions.dart';
import 'widgets/category_grid_widget.dart';
import 'widgets/popular_stores_widget.dart';
import 'widgets/products_for_you_widget.dart';
import 'widgets/product_model.dart';
import 'widgets/club_join_banner_widget.dart';
import '../cart/cart_screen.dart';
import '../products/product_details_screen.dart';
import '../products/vendor_store_screen.dart';
import '../search/search_screen.dart';
import '../offers/offers_screen.dart';
import '../../features/profile/snapbee_club_screen.dart';
import '../../features/profile/referrals_screen.dart';
import '../../features/services/services_main_screen.dart';
import '../../features/travel/home/travel_main_screen.dart';
import '../../features/entertainment/home/entertainment_main_screen.dart';
import '../../features/ecommerce/home/ecommerce_main_screen.dart';

/// Daily Essentials Home / Dashboard (reference screen 01). Renders, top to
/// bottom: location + brand header, search, the five sector shortcuts, the
/// promotional hero, a quick-action rail, "Shop by Category", "Popular
/// Stores Near You", "Products For You" and a "Join SnapBee Club" banner.
/// Every data section reads live catalog/vendor data through the existing
/// repositories and degrades to an honest empty state — nothing here is
/// sample data.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _categoryRepo = CategoryRepository(Supabase.instance.client);
  final _vendorRepo = VendorRepository(Supabase.instance.client);
  final _productRepo = ProductRepository(Supabase.instance.client);

  List<CategoryItem>? _categories;
  List<VendorRow>? _stores;
  List<ProductModel>? _products;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
    // The header's cart badge previously showed a hardcoded "2" regardless
    // of real cart contents — rebuild on real CartStore changes so it
    // reflects the actual cart instead.
    CartStore.instance.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    CartStore.instance.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadCatalog() async {
    // Categories and stores are independent dashboard sections — each must
    // still render when the other's fetch fails, so they get their own
    // try/catch and each leaves its state null (its widget shows a loading
    // or empty state) rather than falling back to any hard-coded list.
    try {
      final categories = await _categoryRepo.fetchTopLevelCategories();
      if (!mounted) return;
      setState(() {
        _categories = [
          for (final c in categories)
            CategoryItem(label: c.name, imageUrl: c.imageUrl),
        ];
      });
    } catch (_) {
      // Leave null; CategoryGridWidget shows its own loading/empty state.
    }

    try {
      final stores = await _vendorRepo.fetchCustomerVisibleStores(limit: 12);
      if (!mounted) return;
      setState(() => _stores = stores);
    } catch (_) {
      // Leave null; PopularStoresWidget renders nothing until real stores
      // load — it never falls back to sample data.
    }

    try {
      final rows = await _productRepo.fetchAll(limit: 12);
      if (!mounted) return;
      setState(() {
        _products = [for (final row in rows) ProductModel.fromRow(row)];
      });
    } catch (_) {
      // Leave null; ProductsForYouWidget keeps showing its loading state
      // rather than fabricating a catalog.
    }
  }

  void _push(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Adds a product straight from the Home carousel through the same
  /// [CartStore] path every other surface uses (product details, offers,
  /// wishlist). Refuses items with no real `vendor_id` and honours the
  /// single-vendor cart rule with the standard "start a new cart?" prompt.
  void _addProductToCart(ProductModel product) {
    if (product.vendorId.isEmpty) {
      _showSnack('This item is not available for delivery right now.');
      return;
    }

    final result = CartStore.instance.addItem(
      productId: product.id,
      name: product.name,
      imageUrl: product.imageAssetPath,
      unit: product.unit,
      price: product.currentPrice,
      originalPrice: product.oldPrice,
      vendorId: product.vendorId,
    );

    if (result == CartAddResult.vendorConflict) {
      _confirmReplaceCart(product);
      return;
    }
    _showSnack('${product.name} added to cart');
  }

  Future<void> _confirmReplaceCart(ProductModel product) async {
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
      imageUrl: product.imageAssetPath,
      unit: product.unit,
      price: product.currentPrice,
      originalPrice: product.oldPrice,
      vendorId: product.vendorId,
    );
    _showSnack('${product.name} added to cart');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        // Mobile-first: the reference is a phone layout, so on a wider
        // viewport (tablet / desktop Chrome) the content stays a centred
        // mobile-width column instead of stretching edge to edge.
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              CustomerHomeHeader(
                backgroundColor: AppColors.creamBackground,
                textPrimaryColor: AppColors.textPrimary,
                textSecondaryColor: AppColors.textSecondary,
                iconColor: const Color.fromARGB(255, 219, 128, 0),
                onLocationTap: () {},
                centerWidget: const SnapBeeWordmark(
                  size: 21,
                  subtitle: 'Local Needs  •  Faster Life',
                ),
                actions: [
                  HeaderAction(
                    icon: Icons.notifications_none_rounded,
                    onTap: () => _push(const NotificationScreen()),
                  ),
                  HeaderAction(
                    icon: Icons.shopping_cart_outlined,
                    badgeCount: CartStore.instance.activeItemCount,
                    onTap: () => _push(const CartScreen()),
                  ),
                ],
              ),

              CustomerSearchBar(
                backgroundColor: AppColors.creamBackground,
                textPrimaryColor: AppColors.textPrimary,
                textSecondaryColor: AppColors.textSecondary,
                readOnly: true,
                onTap: () => _push(const SearchScreen()),
                onScanTap: () {},
              ),

              ServiceTabsWidget(
                onTabTap: (index) {
                  // Index 1 = Services, 2 = Travel, 3 = Entertainment,
                  // 4 = E-Commerce — all real destinations now.
                  switch (index) {
                    case 1:
                      _push(const ServicesMainScreen());
                      break;
                    case 2:
                      _push(const TravelMainScreen());
                      break;
                    case 3:
                      _push(const EntertainmentMainScreen());
                      break;
                    case 4:
                      _push(const EcommerceMainScreen());
                      break;
                  }
                },
              ),

              const SizedBox(height: 4),

              HeroBannerWidget(
                onCtaTap: () => _push(const CategoryScreen()),
              ),

              const SizedBox(height: 4),

              HomeQuickActions(
                onTopOffers: () => _push(const OfferZoneScreen()),
                onNearMe: () => _push(const CategoryScreen()),
                onFreeDelivery: () => _push(const OfferZoneScreen()),
                onClub: () => _push(const SnapBeeClubScreen()),
                onRefer: () => _push(const ReferralsScreen()),
              ),

              const SizedBox(height: 14),

              CategoryGridWidget(
                categories: _categories ?? const [],
                isLoading: _categories == null,
                onSeeAll: () => _push(const CategoryScreen()),
                onCategoryTap: (index) => _push(const CategoryScreen()),
              ),

              const SizedBox(height: 20),

              PopularStoresWidget(
                stores: _stores,
                onSeeAll: () => _push(const CategoryScreen()),
                onStoreTap: (store) => _push(
                  VendorStoreScreen(vendorId: store.id, vendorName: store.name),
                ),
              ),

              const SizedBox(height: 20),

              ProductsForYouWidget(
                products: _products,
                isLoading: _products == null,
                onSeeAll: () => _push(const FeaturedProductsScreen()),
                onProductTap: (product) =>
                    _push(ProductDetailsScreen(product: product)),
                onAdd: _addProductToCart,
              ),

              const SizedBox(height: 6),

              ClubJoinBannerWidget(
                onJoin: () => _push(const SnapBeeClubScreen()),
              ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
