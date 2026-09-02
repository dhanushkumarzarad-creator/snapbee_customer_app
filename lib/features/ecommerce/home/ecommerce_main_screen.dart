import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/ecommerce_cart_store.dart';
import '../data/ecommerce_repository.dart';
import '../orders/ecommerce_orders_screen.dart';
import '../product/ecommerce_product_screen.dart';
import '../cart/ecommerce_cart_screen.dart';
import '../theme/ecommerce_colors.dart';

/// E-Commerce sector entry — separate business vertical from Daily
/// Essentials, Services, Travel and Entertainment (see
/// TRAVEL_ENTERTAINMENT_ARCHITECTURE.md's app-boundary pattern; E-Commerce
/// follows the same "own tables/RPCs, shared infra only" rule). General
/// merchandise with product variants — distinct from Daily Essentials'
/// grocery/no-variant model even though both are "product commerce".
class EcommerceMainScreen extends StatefulWidget {
  const EcommerceMainScreen({super.key});

  @override
  State<EcommerceMainScreen> createState() => _EcommerceMainScreenState();
}

class _EcommerceMainScreenState extends State<EcommerceMainScreen> {
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
    return Scaffold(
      backgroundColor: EcommerceColors.background,
      appBar: AppBar(
        title: const Text('E-Commerce'),
        backgroundColor: EcommerceColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.receipt_long), tooltip: 'My Orders', onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EcommerceOrdersScreen()))),
          Stack(
            children: [
              IconButton(icon: const Icon(Icons.shopping_cart), tooltip: 'Cart', onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EcommerceCartScreen()))),
              if (EcommerceCartStore.instance.itemCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: CircleAvatar(radius: 8, backgroundColor: EcommerceColors.accent, child: Text('${EcommerceCartStore.instance.itemCount}', style: const TextStyle(fontSize: 10, color: Colors.white))),
                ),
            ],
          ),
        ],
      ),
      body: _categories == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search products',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: EcommerceColors.cardGrey,
                    ),
                    onSubmitted: (_) => _filterByCategory(_selectedCategoryId),
                  ),
                ),
                if (_categories!.isNotEmpty)
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: const Text('All'), selected: _selectedCategoryId == null, onSelected: (_) => _filterByCategory(null))),
                        ..._categories!.map((c) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(label: Text(c['name'] as String), selected: _selectedCategoryId == c['id'], onSelected: (_) => _filterByCategory(c['id'] as String)),
                            )),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Expanded(
                  child: (_products?.isEmpty ?? true)
                      ? const Center(child: Text('No products found.'))
                      : GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.72),
                          itemCount: _products!.length,
                          itemBuilder: (context, i) {
                            final p = _products![i];
                            final vendorName = (p['ecommerce_vendors'] as Map?)?['business_name'] ?? '';
                            final price = p['discount_price'] ?? p['base_price'];
                            return InkWell(
                              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EcommerceProductScreen(productId: p['id'] as String))),
                              child: Card(
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: Container(color: EcommerceColors.cardGrey, alignment: Alignment.center, child: const Icon(Icons.shopping_bag, size: 40, color: EcommerceColors.primary))),
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(p['name'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                                          Text(vendorName as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: EcommerceColors.textSecondary)),
                                          Text('₹$price', style: const TextStyle(fontWeight: FontWeight.bold, color: EcommerceColors.primary)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
