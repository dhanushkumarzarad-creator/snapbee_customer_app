import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/design/snapbee_design.dart';
import '../data/ecommerce_cart_store.dart';
import '../data/ecommerce_repository.dart';
import '../orders/ecommerce_orders_screen.dart';
import '../product/ecommerce_product_screen.dart';
import '../cart/ecommerce_cart_screen.dart';
import '../theme/ecommerce_colors.dart';

/// E-Commerce sector entry — separate business vertical from Daily
/// Essentials, Services, Travel and Entertainment. General merchandise with
/// product variants.
///
/// Restyled to the shared premium SnapBee design language (header, hero,
/// filter chips, product cards, promo footer); the sector accent stays
/// E-Commerce's own indigo and every repository call / filter / cart
/// interaction is unchanged.
class EcommerceMainScreen extends StatefulWidget {
  const EcommerceMainScreen({super.key});

  @override
  State<EcommerceMainScreen> createState() => _EcommerceMainScreenState();
}

class _EcommerceMainScreenState extends State<EcommerceMainScreen> {
  static const _accent = EcommerceColors.primary;

  final _repo = EcommerceRepository(Supabase.instance.client);
  List<Map<String, dynamic>>? _categories;
  List<Map<String, dynamic>>? _products;
  String? _selectedCategoryId;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    EcommerceCartStore.instance.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    EcommerceCartStore.instance.removeListener(_onCartChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onCartChanged() => setState(() {});

  Future<void> _load() async {
    final categories = await _repo.listCategories();
    final products = await _repo.listProducts();
    if (!mounted) return;
    setState(() {
      _categories = categories;
      _products = products;
    });
  }

  Future<void> _filterByCategory(String? categoryId) async {
    setState(() => _selectedCategoryId = categoryId);
    final products = await _repo.listProducts(categoryId: categoryId, query: _searchController.text);
    if (!mounted) return;
    setState(() => _products = products);
  }

  @override
  Widget build(BuildContext context) {
    final cats = _categories;
    final chipLabels = <String>['All', for (final c in cats ?? const []) c['name'] as String];
    final selectedChip = _selectedCategoryId == null
        ? 0
        : (cats?.indexWhere((c) => c['id'] == _selectedCategoryId) ?? -1) + 1;

    return Scaffold(
      backgroundColor: SnapBeeColors.scaffold,
      appBar: SnapBeeAppBar(
        subtitle: 'E-Commerce',
        trailing: Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.receipt_long_rounded, color: SnapBeeColors.ink),
                tooltip: 'My Orders',
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EcommerceOrdersScreen())),
              ),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined, color: SnapBeeColors.ink),
                    tooltip: 'Cart',
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EcommerceCartScreen())),
                  ),
                  if (EcommerceCartStore.instance.itemCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: SnapBeeColors.danger, shape: BoxShape.circle),
                        child: Text(
                          '${EcommerceCartStore.instance.itemCount}',
                          style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: cats == null
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(
                  child: SnapBeeHeroCard(
                    tag: 'E-Commerce',
                    titleTop: 'Everything You Want,',
                    titleAccent: 'Delivered.',
                    subtitle: 'Electronics, fashion, home & more with real variants',
                    mascot: SnapBeeMascots.shopping,
                    scriptAccent: 'Shop Smart\nLive Better!',
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(SnapBeeSpacing.gutter, 4, SnapBeeSpacing.gutter, 10),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search products',
                        hintStyle: const TextStyle(color: SnapBeeColors.inkFaint),
                        prefixIcon: const Icon(Icons.search, color: SnapBeeColors.inkFaint),
                        filled: true,
                        fillColor: SnapBeeColors.surface,
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(SnapBeeSpacing.rField),
                          borderSide: const BorderSide(color: SnapBeeColors.hairline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(SnapBeeSpacing.rField),
                          borderSide: const BorderSide(color: _accent),
                        ),
                      ),
                      onSubmitted: (_) => _filterByCategory(_selectedCategoryId),
                    ),
                  ),
                ),
                if (chipLabels.length > 1)
                  SliverToBoxAdapter(
                    child: SnapBeeFilterChips(
                      labels: chipLabels,
                      selectedIndex: selectedChip < 0 ? 0 : selectedChip,
                      accent: _accent,
                      onSelected: (i) => _filterByCategory(i == 0 ? null : cats[i - 1]['id'] as String),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                if (_products?.isEmpty ?? true)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: SnapBeeEmptyState(
                      mascot: SnapBeeMascots.search,
                      title: 'No products found',
                      message: 'Try a different search or category.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(SnapBeeSpacing.gutter, 0, SnapBeeSpacing.gutter, 20),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.68,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _ProductCard(
                          data: _products![i],
                          accent: _accent,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => EcommerceProductScreen(productId: _products![i]['id'] as String)),
                          ),
                        ),
                        childCount: _products!.length,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color accent;
  final VoidCallback onTap;

  const _ProductCard({required this.data, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final vendorName = (data['ecommerce_vendors'] as Map?)?['business_name'] ?? '';
    final price = data['discount_price'] ?? data['base_price'];
    final mrp = data['base_price'];
    final hasDiscount = data['discount_price'] != null && mrp != null && data['discount_price'] != mrp;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: SnapBeeColors.surface,
          borderRadius: BorderRadius.circular(SnapBeeSpacing.rTile),
          boxShadow: SnapBeeShadows.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: accent.withValues(alpha: 0.06),
                child: Icon(Icons.shopping_bag_rounded, size: 44, color: accent.withValues(alpha: 0.7)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['name'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: SnapBeeText.title),
                  if ((vendorName as String).isNotEmpty)
                    Text(vendorName, maxLines: 1, overflow: TextOverflow.ellipsis, style: SnapBeeText.caption),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('₹$price', style: SnapBeeText.price.copyWith(color: accent)),
                      if (hasDiscount) ...[
                        const SizedBox(width: 6),
                        Text('₹$mrp', style: const TextStyle(fontSize: 11, color: SnapBeeColors.strike, decoration: TextDecoration.lineThrough)),
                      ],
                    ],
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
