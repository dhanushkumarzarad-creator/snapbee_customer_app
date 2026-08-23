import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../cart/cart_screen.dart';
import 'featured_products_screen.dart';
import 'models/category_model.dart';
import 'widgets/category_sidebar_item.dart';
import 'widgets/featured_product_card.dart';
import 'widgets/subcategory_card.dart';
import '../wishlist/wishlist_screen.dart';
import '../home/widgets/product_model.dart' as home_product;
import '../products/product_details_screen.dart';
import '../products/product_list_screen.dart';
import '../search/search_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _categoryRepo = CategoryRepository(Supabase.instance.client);
  final _productRepo = ProductRepository(Supabase.instance.client);

  int selectedIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;
  List<CategoryModel> _categories = const [];

  @override
  void initState() {
    super.initState();
    _loadTopLevelCategories();
  }

  Future<void> _loadTopLevelCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final topLevel = await _categoryRepo.fetchTopLevelCategories();
      final categories = <CategoryModel>[];
      for (final row in topLevel) {
        categories.add(await _buildCategoryModel(row));
      }
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<CategoryModel> _buildCategoryModel(CategoryRow row) async {
    final subcategoryRows = await _categoryRepo.fetchSubcategories(row.id);
    final categoryNames = [row.name, ...subcategoryRows.map((s) => s.name)];

    // Featured products are a secondary enrichment of the category list, not
    // the category list itself — a products-fetch failure (e.g. products
    // isn't customer-readable yet) shouldn't take down category loading,
    // same convention as home_screen.dart's catalog fetch.
    List<ProductRow> productRows;
    try {
      productRows = await _productRepo.fetchByCategoryNames(categoryNames);
    } catch (_) {
      productRows = const [];
    }

    return CategoryModel(
      id: row.id,
      name: row.name,
      image: row.imageUrl ?? '',
      color: '#F1F1F1',
      featuredProducts: [
        for (final p in productRows)
          ProductModel(
            id: p.id,
            name: p.name,
            image: p.primaryImageUrl ?? '',
            price: p.displayPrice,
            priceValue: p.discountPrice ?? p.price,
            vendorId: p.vendorId,
          ),
      ],
      subCategories: [
        for (final s in subcategoryRows)
          SubCategoryModel(name: s.name, image: s.imageUrl ?? ''),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  'Could not load categories.\n$_errorMessage',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loadTopLevelCategories,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_categories.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No categories available yet.')),
      );
    }

    final category =
        _categories[selectedIndex.clamp(0, _categories.length - 1)];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              color: const Color(0xFFFFF3DD),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                children: [
                  // Title + Icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Categories",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const WishlistScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.favorite_border),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CartScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.shopping_cart_outlined),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Search Bar
                  Material(
                    elevation: 1.5,
                    shadowColor: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SearchScreen(),
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: Colors.grey),
                            SizedBox(width: 10),
                            Text(
                              "Search products",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // White Content
            Expanded(
              child: Row(
                children: [
                  // Left Sidebar
                  Container(
                    width: 110,
                    color: Colors.white,
                    child: ListView.builder(
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        return SizedBox(
                          height: 100,
                          child: CategorySidebarItem(
                            category: _categories[index],
                            isSelected: selectedIndex == index,
                            onTap: () {
                              setState(() {
                                selectedIndex = index;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),

                  // Right Side
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      child: ListView(
                        children: [
                          // All Products Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "All Products",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const FeaturedProductsScreen(),
                                    ),
                                  );
                                },
                                child: const Text("View All"),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Horizontal Product List
                          SizedBox(
                            height: 165,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: category.featuredProducts.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (context, index) {
                                final product =
                                    category.featuredProducts[index];
                                return FeaturedProductCard(
                                  product: product,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ProductDetailsScreen(
                                            product: home_product.ProductModel(
                                              id: product.id,
                                              name: product.name,
                                              imageAssetPath: product.image,
                                              currentPrice: product.priceValue,
                                              vendorId: product.vendorId,
                                            ),
                                          ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 24),

                          const Text(
                            "Shop by Category",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 12),

                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: category.subCategories.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 0.95,
                                ),
                            itemBuilder: (context, index) {
                              final subCategory = category.subCategories[index];
                              return SubCategoryCard(
                                subCategory: subCategory,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductListScreen(
                                      categoryName: subCategory.name,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
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
