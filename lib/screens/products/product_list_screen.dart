import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/design/snapbee_design.dart';
import '../../data/repositories/product_repository.dart';
import '../cart/cart_screen.dart';
import '../home/widgets/product_card_widget.dart';
import '../home/widgets/product_model.dart';
import '../search/search_screen.dart';
import 'product_details_screen.dart';

/// Category product listing (reference 06) — a category's live products in
/// the premium SnapBee shell. Sort options reorder the already-loaded list
/// client-side; no data path changes.
class ProductListScreen extends StatefulWidget {
  final String categoryName;

  const ProductListScreen({super.key, required this.categoryName});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

enum _Sort { relevance, priceLow, priceHigh, nameAz }

class _ProductListScreenState extends State<ProductListScreen> {
  final _productRepo = ProductRepository(Supabase.instance.client);

  bool _isLoading = true;
  String? _errorMessage;
  List<ProductModel> _products = const [];
  _Sort _sort = _Sort.relevance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final rows = await _productRepo.fetchByCategoryName(widget.categoryName, limit: 50);
      if (!mounted) return;
      setState(() {
        _products = [for (final row in rows) ProductModel.fromRow(row)];
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

  List<ProductModel> get _sorted {
    final list = [..._products];
    switch (_sort) {
      case _Sort.priceLow:
        list.sort((a, b) => a.currentPrice.compareTo(b.currentPrice));
      case _Sort.priceHigh:
        list.sort((a, b) => b.currentPrice.compareTo(a.currentPrice));
      case _Sort.nameAz:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case _Sort.relevance:
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SnapBeeColors.scaffold,
      appBar: SnapBeeAppBar(
        subtitle: 'Daily Essentials',
        trailing: Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.search, color: SnapBeeColors.ink),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
              ),
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: SnapBeeColors.ink),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(top: false, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 44, color: SnapBeeColors.inkFaint),
              const SizedBox(height: 12),
              Text('Could not load products.', style: SnapBeeText.body, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              SnapBeeOutlineButton(label: 'Retry', expand: false, onPressed: _load),
            ],
          ),
        ),
      );
    }

    final items = _sorted;
    return Column(
      children: [
        SnapBeePageHeader(
          icon: Icons.grid_view_rounded,
          title: widget.categoryName,
          subtitle: _isLoading ? 'Loading…' : '${items.length} products',
        ),
        const SnapBeeHeroCard(
          titleTop: 'Fresh Picks,',
          titleAccent: 'Great Prices!',
          subtitle: 'Farm fresh • Naturally healthy',
          mascot: SnapBeeMascots.shopping,
          scriptAccent: 'Freshness Brings\nHappiness!',
          margin: EdgeInsets.fromLTRB(SnapBeeSpacing.gutter, 0, SnapBeeSpacing.gutter, 8),
        ),
        SnapBeeFilterChips(
          labels: const ['Relevance', 'Price: Low', 'Price: High', 'Name A–Z'],
          selectedIndex: _sort.index,
          icons: const [Icons.auto_awesome_rounded, Icons.arrow_upward_rounded, Icons.arrow_downward_rounded, Icons.sort_by_alpha_rounded],
          onSelected: (i) => setState(() => _sort = _Sort.values[i]),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: items.isEmpty
              ? const SnapBeeEmptyState(
                  mascot: SnapBeeMascots.shopping,
                  title: 'No products here yet',
                  message: 'This category has no items available in your area right now.',
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(SnapBeeSpacing.gutter, 0, SnapBeeSpacing.gutter, 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.66,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) => ProductCardWidget(
                    product: items[index],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProductDetailsScreen(product: items[index])),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
