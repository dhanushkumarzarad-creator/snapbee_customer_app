import 'package:flutter/material.dart';
import '../wishlist/wishlist_screen.dart';
import 'dummy_category_data.dart';
import 'category_models.dart';
import 'snapbee_theme.dart';

import 'widgets/category_sidebar_item.dart';
import 'widgets/featured_product_card.dart';
import 'widgets/subcategory_card.dart';
import 'widgets/snapbee_bottom_nav.dart';

/// Redesigned Categories screen.
///
/// Layout: top app bar -> search bar -> split view (category rail on the
/// left, selected category's content on the right) -> existing bottom nav.
///
/// Responsive: the rail width and the sub-category grid's column count
/// both adapt via [LayoutBuilder] so the screen holds up on phones,
/// tablets, and web without any RenderFlex overflow.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final List<CategoryModel> _categories = MockCategoriesData.categories;
  late String _selectedCategoryId = _categories.first.id;

  CategoryModel get _selectedCategory =>
      _categories.firstWhere((c) => c.id == _selectedCategoryId);

  void _selectCategory(String id) {
    if (id == _selectedCategoryId) return;
    setState(() => _selectedCategoryId = id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SnapBeeColors.scaffoldBackground,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 8),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final sidebarFraction =
                      SnapBeeBreakpoints.sidebarFraction(constraints.maxWidth);
                  final sidebarWidth = constraints.maxWidth * sidebarFraction;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: sidebarWidth,
                        height: constraints.maxHeight,
                        child: _buildCategoryRail(),
                      ),
                      Expanded(
                        child: _buildCategoryContent(constraints.maxWidth),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const SnapBeeBottomNav(currentIndex: 1),
    );
  }

  // ---------------------------------------------------------------------
  // App bar
  // ---------------------------------------------------------------------
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: SnapBeeColors.textPrimary),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: const Text(
        'Categories',
        style: TextStyle(
          color: SnapBeeColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none,
              color: SnapBeeColors.textPrimary),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.favorite_border,
              color: SnapBeeColors.textPrimary),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WishlistScreen(),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined,
              color: SnapBeeColors.textPrimary),
          onPressed: () {},
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Search bar
  // ---------------------------------------------------------------------
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SnapBeeSpacing.screenPadding,
      ),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(SnapBeeRadii.searchBar),
          boxShadow: const [
            BoxShadow(
              color: SnapBeeColors.shadow,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: const TextField(
          decoration: InputDecoration(
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: SnapBeeColors.textSecondary),
            hintText: 'Search products, categories...',
            hintStyle: TextStyle(color: SnapBeeColors.textSecondary),
            contentPadding: EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Left rail
  // ---------------------------------------------------------------------
  Widget _buildCategoryRail() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return CategorySidebarItem(
          category: category,
          isSelected: category.id == _selectedCategoryId,
          onTap: () => _selectCategory(category.id),
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // Right content — animated fade+slide on category switch
  // ---------------------------------------------------------------------
  Widget _buildCategoryContent(double totalWidth) {
    final crossAxisCount = totalWidth >= SnapBeeBreakpoints.desktop
        ? 4
        : totalWidth >= SnapBeeBreakpoints.tablet
            ? 3
            : 2;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(0.04, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: SingleChildScrollView(
        key: ValueKey(_selectedCategoryId),
        padding: const EdgeInsets.fromLTRB(12, 4, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedCategory.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: SnapBeeColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildFeaturedProductsSection(),
            const SizedBox(height: 24),
            _buildSubCategoriesSection(crossAxisCount),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedProductsSection() {
    final products = _selectedCategory.featuredProducts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Featured Products',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: SnapBeeColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: SnapBeeColors.primaryDark,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (products.isEmpty)
          const _EmptyState(message: 'No featured products yet')
        else
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: SnapBeeSpacing.cardGap),
              itemBuilder: (context, index) {
                return FeaturedProductCard(product: products[index]);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSubCategoriesSection(int crossAxisCount) {
    final subCategories = _selectedCategory.subCategories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sub Categories',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: SnapBeeColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (subCategories.isEmpty)
          const _EmptyState(message: 'No sub categories yet')
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: subCategories.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: SnapBeeSpacing.cardGap,
              mainAxisSpacing: SnapBeeSpacing.cardGap,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (context, index) {
              return SubCategoryCard(subCategory: subCategories[index]);
            },
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: SnapBeeColors.textSecondary),
        ),
      ),
    );
  }
}
