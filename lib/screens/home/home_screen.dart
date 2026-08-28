import 'package:flutter/material.dart';
import 'package:snapbee_customer_app/core/constants/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/cart/cart_store.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../category/category_screen.dart';
import '../category/featured_products_screen.dart';
import '../../widgets/customer_home_header.dart';
import '../../widgets/customer_search_bar.dart';
import '../notification/notification_screen.dart';
import 'widgets/service_tabs_widget.dart';
import 'widgets/hero_banner_widget.dart';
import 'widgets/category_grid_widget.dart';
import 'widgets/trending_products_widget.dart';
import 'widgets/product_model.dart';
import '../cart/cart_screen.dart';
import '../products/product_details_screen.dart';
import '../search/search_screen.dart';
import '../../features/services/services_main_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _categoryRepo = CategoryRepository(Supabase.instance.client);
  final _productRepo = ProductRepository(Supabase.instance.client);

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
      // Leave null; TrendingProductsWidget renders nothing until real
      // products load — it never falls back to sample data.
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
              CustomerHomeHeader(
                backgroundColor: AppColors.creamBackground,
                textPrimaryColor: AppColors.textPrimary,
                textSecondaryColor: AppColors.textSecondary,
                iconColor: const Color.fromARGB(255, 219, 128, 0),
                onLocationTap: () {},
                actions: [
                  HeaderAction(
                    icon: Icons.notifications_none_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationScreen(),
                        ),
                      );
                    },
                  ),
                  HeaderAction(
                    icon: Icons.shopping_cart_outlined,
                    badgeCount: CartStore.instance.activeItemCount,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CartScreen()),
                      );
                    },
                  ),
                ],
              ),

              CustomerSearchBar(
                backgroundColor: AppColors.creamBackground,
                textPrimaryColor: AppColors.textPrimary,
                textSecondaryColor: AppColors.textSecondary,
                readOnly: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchScreen()),
                ),
                onScanTap: () {},
              ),

              ServiceTabsWidget(
                onTabTap: (index) {
                  // Index 1 = "Services" (home services: AC repair,
                  // plumbing, electrician, cleaning, etc.) — the only tab
                  // with a real destination today. Travel/Entertainment/
                  // E-Commerce (2-4) stay no-ops; they're not built yet and
                  // out of scope here.
                  if (index == 1) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ServicesMainScreen()),
                    );
                  }
                },
              ),

              const SizedBox(height: 4),

              HeroBannerWidget(
                onCtaTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CategoryScreen()),
                ),
              ),

              const SizedBox(height: 16),

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

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
