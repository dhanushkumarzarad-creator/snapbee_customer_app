import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/ecommerce_cart_store.dart';
import '../data/ecommerce_repository.dart';
import '../theme/ecommerce_colors.dart';

class EcommerceProductScreen extends StatefulWidget {
  final String productId;
  const EcommerceProductScreen({super.key, required this.productId});

  @override
  State<EcommerceProductScreen> createState() => _EcommerceProductScreenState();
}

class _EcommerceProductScreenState extends State<EcommerceProductScreen> {
  final _repo = EcommerceRepository(Supabase.instance.client);
  Map<String, dynamic>? _product;
  List<Map<String, dynamic>> _variants = [];
  List<Map<String, dynamic>> _reviews = [];
  Map<String, dynamic>? _selectedVariant;
  int _quantity = 1;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final product = await _repo.getProduct(widget.productId);
    final variants = product?['has_variants'] == true ? await _repo.listVariants(widget.productId) : <Map<String, dynamic>>[];
    final reviews = await _repo.listReviews(widget.productId);
    if (!mounted) return;
    setState(() {
      _product = product;
      _variants = variants;
      _selectedVariant = variants.isNotEmpty ? variants.firstWhere((v) => (v['stock_quantity'] as int) > 0, orElse: () => variants.first) : null;
      _reviews = reviews;
      _loading = false;
    });
  }

  void _addToCart() {
    final p = _product!;
    final vendorId = p['vendor_id'] as String;
    final vendorName = (p['ecommerce_vendors'] as Map?)?['business_name'] as String? ?? '';
    final unitPrice = _selectedVariant != null
        ? (_selectedVariant!['price_override'] ?? p['discount_price'] ?? p['base_price'])
        : (p['discount_price'] ?? p['base_price']);

    final item = EcommerceCartItem(
      productId: p['id'] as String,
      variantId: _selectedVariant?['id'] as String?,
      productName: p['name'] as String,
      variantLabel: _selectedVariant?['variant_label'] as String?,
      vendorId: vendorId,
      vendorName: vendorName,
      unitPrice: unitPrice as num,
      quantity: _quantity,
    );

    final result = EcommerceCartStore.instance.addItem(item);
    if (result == EcommerceCartAddResult.vendorConflict) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Start a new cart?'),
          content: Text('Your cart has items from ${EcommerceCartStore.instance.vendorName}. Adding this will clear it.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: EcommerceColors.primary),
              onPressed: () {
                EcommerceCartStore.instance.replaceWithItem(item);
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart')));
              },
              child: const Text('Start new cart'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final p = _product;
    if (p == null) return const Scaffold(body: Center(child: Text('Product not found.')));

    final inStock = p['has_variants'] == true ? (_selectedVariant != null && (_selectedVariant!['stock_quantity'] as int) > 0) : (p['stock_quantity'] as int) > 0;

    return Scaffold(
      backgroundColor: EcommerceColors.background,
      appBar: AppBar(title: Text(p['name'] as String), backgroundColor: EcommerceColors.primary, foregroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(height: 220, color: EcommerceColors.cardGrey, alignment: Alignment.center, child: const Icon(Icons.shopping_bag, size: 64, color: EcommerceColors.primary)),
          const SizedBox(height: 16),
          Text(p['name'] as String, style: Theme.of(context).textTheme.titleLarge),
          Text((p['ecommerce_vendors'] as Map?)?['business_name'] as String? ?? '', style: const TextStyle(color: EcommerceColors.textSecondary)),
          const SizedBox(height: 8),
          Row(children: [
            if (p['discount_price'] != null) ...[
              Text('₹${p['discount_price']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: EcommerceColors.primary)),
              const SizedBox(width: 8),
              Text('₹${p['base_price']}', style: const TextStyle(decoration: TextDecoration.lineThrough, color: EcommerceColors.textSecondary)),
            ] else
              Text('₹${p['base_price']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: EcommerceColors.primary)),
          ]),
          const SizedBox(height: 8),
          Text(p['description'] as String? ?? '', style: const TextStyle(color: EcommerceColors.textSecondary)),
          if (_variants.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Options', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _variants.map((v) {
                final selected = _selectedVariant?['id'] == v['id'];
                final outOfStock = (v['stock_quantity'] as int) <= 0;
                return ChoiceChip(
                  label: Text(v['variant_label'] as String, style: TextStyle(decoration: outOfStock ? TextDecoration.lineThrough : null)),
                  selected: selected,
                  selectedColor: EcommerceColors.primaryLight,
                  onSelected: outOfStock ? null : (_) => setState(() => _selectedVariant = v),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 16),
          Row(children: [
            const Text('Quantity:'),
            const Spacer(),
            IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null),
            Text('$_quantity'),
            IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => setState(() => _quantity++)),
          ]),
          if (!inStock) const Padding(padding: EdgeInsets.only(top: 8), child: Text('Out of stock', style: TextStyle(color: Colors.red))),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: EcommerceColors.primary, padding: const EdgeInsets.symmetric(vertical: 16)),
            onPressed: inStock ? _addToCart : null,
            child: const Text('Add to cart'),
          ),
          const Divider(height: 32),
          Text('Reviews (${_reviews.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_reviews.isEmpty) const Text('No reviews yet.', style: TextStyle(color: EcommerceColors.textSecondary)),
          ..._reviews.map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: List.generate(5, (i) => Icon(i < (r['rating'] as num) ? Icons.star : Icons.star_border, size: 14, color: EcommerceColors.ratingStar))),
                  const SizedBox(width: 8),
                  Expanded(child: Text(r['review_text'] as String? ?? '')),
                ]),
              )),
        ],
      ),
    );
  }
}
