import 'package:flutter/material.dart';
import 'package:snapbee_customer_app/core/constants/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/cart/cart_store.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../category/category_screen.dart';
import '../category/featured_products_screen.dart';
import '../notification/notification_screen.dart';
import 'widgets/home_header.dart';
import 'widgets/search_bar_widget.dart';
import 'widgets/service_tabs_widget.dart';
import 'widgets/hero_banner_widget.dart';
import 'widgets/quick_actions_widget.dart';
import 'widgets/category_grid_widget.dart';
import 'widgets/featured_store_widget.dart';
import 'widgets/trending_products_widget.dart';
import 'widgets/flash_sale_widget.dart';
import 'widgets/product_model.dart';
import '../cart/cart_screen.dart';
import '../products/product_details_screen.dart';
import '../search/search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _categoryRepo = CategoryRepository(Supabase.instance.client);
  final _productRepo = ProductRepository(Supabase.instance.client);

  int _bannerPage = 0;
  List<CategoryItem>? _categories;
  List<ProductModel>? _trendingProducts;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
    // The header's cart badge previously showed a hardcoded "2" regardless
    // of real cart contents (HomeHeader.cartItemCount defaulted to 2 and
    // was never overridden here) — rebuild on real CartStore changes so it
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
    // Categories and trending products are independent dashboard sections —
    // Admin-managed categories must still render even when the product
    // catalog fetch fails (e.g. products isn't customer-readable yet), and
    // vice versa. A shared try/catch previously coupled them, so a products
    // failure was silently hiding real, successfully-fetched categories.
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
      // Leave null; CategoryGridWidget shows its own loading/empty state
      // rather than any hard-coded category list.
    }

    try {
      final products = await _productRepo.fetchAll(limit: 10);
      if (!mounted) return;
      setState(() {
        _trendingProducts = [for (final p in products) ProductModel.fromRow(p)];
      });
    } catch (_) {
      // Leave null; TrendingProductsWidget keeps its own built-in defaults.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeHeader(
                cartItemCount: CartStore.instance.activeItemCount,
                onLocationTap: () {},

                onNotificationTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationScreen(),
                    ),
                  );
                },

                onCartTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartScreen()),
                  );
                },
              ),

              SearchBarWidget(
                readOnly: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchScreen()),
                ),
                onScanTap: () {},
              ),

              ServiceTabsWidget(onTabTap: (index) {}),

              const SizedBox(height: 4),

              HeroBannerWidget(
                currentPage: _bannerPage,
                onCtaTap: () {
                  setState(() {
                    _bannerPage = (_bannerPage + 1) % 3;
                  });
                },
              ),

              const SizedBox(height: 16),

              QuickActionsWidget(onActionTap: (index) {}),

              const SizedBox(height: 22),

              CategoryGridWidget(
                categories: _categories ?? const [],
                isLoading: _categories == null,
                onSeeAll: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CategoryScreen(),
                  ),
                ),
                onCategoryTap: (index) => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CategoryScreen(),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              FeaturedStoreWidget(onSeeAll: () {}, onStoreTap: (index) {}),

              const SizedBox(height: 20),

              TrendingProductsWidget(
                products: _trendingProducts,
                onProductTap: (product) => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProductDetailsScreen(product: product),
                  ),
                ),
                onSeeAllPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FeaturedProductsScreen(),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              FlashSaleWidget(
                onShopTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FeaturedProductsScreen(),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
