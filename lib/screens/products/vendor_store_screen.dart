import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/design/snapbee_design.dart';
import '../../data/repositories/product_repository.dart';
import '../cart/cart_screen.dart';
import '../home/widgets/product_card_widget.dart';
import '../home/widgets/product_model.dart';
import 'product_details_screen.dart';

/// Vendor / Store Details — a real store page built from the vendor's live
/// products (`ProductRepository.fetchByVendorId`). Reached from a product
/// card and from a past order. Reviews aren't wired for Daily Essentials
/// yet, so that section shows an honest empty state rather than fabricated
/// testimonials.
class VendorStoreScreen extends StatefulWidget {
  final String vendorId;
  final String vendorName;

  const VendorStoreScreen({
    super.key,
    required this.vendorId,
    this.vendorName = 'Store',
  });

  @override
  State<VendorStoreScreen> createState() => _VendorStoreScreenState();
}

class _VendorStoreScreenState extends State<VendorStoreScreen> {
  final _repo = ProductRepository(Supabase.instance.client);

  bool _loading = true;
  String? _error;
  List<ProductModel> _products = const [];
  int _tab = 0; // 0 Products, 1 About, 2 Reviews

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
      final rows = await _repo.fetchByVendorId(widget.vendorId);
      if (!mounted) return;
      setState(() {
        _products = [for (final r in rows) ProductModel.fromRow(r)];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SnapBeeColors.scaffold,
      appBar: SnapBeeAppBar(
        subtitle: 'Daily Essentials',
        trailing: Padding(
          padding: const EdgeInsets.only(right: 4),
          child: IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: SnapBeeColors.ink),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            // ---- Store banner -------------------------------------------
            Container(
              margin: const EdgeInsets.fromLTRB(SnapBeeSpacing.gutter, 6, SnapBeeSpacing.gutter, 6),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: SnapBeeColors.heroGradient,
                borderRadius: BorderRadius.circular(SnapBeeSpacing.rCard),
              ),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.storefront_rounded, color: SnapBeeColors.orange, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(child: Text(widget.vendorName, style: SnapBeeText.h2, overflow: TextOverflow.ellipsis)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: SnapBeeColors.successFill, borderRadius: BorderRadius.circular(SnapBeeSpacing.rPill)),
                              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.verified_rounded, size: 12, color: Color(0xFF1F7A3D)),
                                SizedBox(width: 3),
                                Text('Verified', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF1F7A3D))),
                              ]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _loading ? 'Loading catalogue…' : '${_products.length} products available',
                          style: SnapBeeText.body.copyWith(fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ---- Trust strip ------------------------------------------
            Container(
              margin: SnapBeeSpacing.screenH,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: SnapBeeColors.mint, borderRadius: BorderRadius.circular(SnapBeeSpacing.rTile)),
              child: const Row(
                children: [
                  _Trust(Icons.eco_rounded, 'Fresh\nProducts'),
                  _Trust(Icons.verified_user_rounded, 'Quality\nAssured'),
                  _Trust(Icons.local_shipping_rounded, 'On-Time\nDelivery'),
                  _Trust(Icons.sell_rounded, 'Best\nPrices'),
                ],
              ),
            ),

            const SizedBox(height: 6),
            SnapBeeFilterChips(
              labels: const ['Products', 'About', 'Reviews'],
              selectedIndex: _tab,
              icons: const [Icons.grid_view_rounded, Icons.info_outline_rounded, Icons.star_border_rounded],
              onSelected: (i) => setState(() => _tab = i),
            ),
            const SizedBox(height: 10),

            if (_tab == 0) _productsTab(),
            if (_tab == 1) _aboutTab(),
            if (_tab == 2) _reviewsTab(),
          ],
        ),
      ),
      bottomNavigationBar: SnapBeeBottomBar(
        actions: [
          SnapBeePrimaryButton(
            label: 'Shop Now',
            icon: Icons.arrow_forward_rounded,
            onPressed: _products.isEmpty ? null : () => setState(() => _tab = 0),
          ),
        ],
      ),
    );
  }

  Widget _productsTab() {
    if (_loading) return const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()));
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const Icon(Icons.error_outline, size: 40, color: SnapBeeColors.inkFaint),
          const SizedBox(height: 10),
          Text("Couldn't load this store's products.", style: SnapBeeText.body, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          SnapBeeOutlineButton(label: 'Retry', expand: false, onPressed: _load),
        ]),
      );
    }
    if (_products.isEmpty) {
      return const SnapBeeEmptyState(
        mascot: SnapBeeMascots.shopping,
        title: 'No products listed yet',
        message: 'This store has no items available in your area right now.',
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(SnapBeeSpacing.gutter, 0, SnapBeeSpacing.gutter, 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.66,
      ),
      itemCount: _products.length,
      itemBuilder: (context, i) => ProductCardWidget(
        product: _products[i],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: _products[i])),
        ),
      ),
    );
  }

  Widget _aboutTab() {
    return SnapBeeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About ${widget.vendorName}', style: SnapBeeText.title),
          const SizedBox(height: 8),
          Text(
            'A verified SnapBee partner store serving daily essentials in your '
            'area. Prices, availability and delivery times are shown live at '
            'checkout based on your location.',
            style: SnapBeeText.body,
          ),
          const SizedBox(height: 14),
          const Row(children: [
            Icon(Icons.local_shipping_outlined, size: 18, color: SnapBeeColors.inkSoft),
            SizedBox(width: 8),
            Text('Delivery charges are calculated at checkout', style: SnapBeeText.caption),
          ]),
          const SizedBox(height: 8),
          const Row(children: [
            Icon(Icons.verified_user_outlined, size: 18, color: SnapBeeColors.inkSoft),
            SizedBox(width: 8),
            Text('Quality-checked, FSSAI-compliant catalogue', style: SnapBeeText.caption),
          ]),
        ],
      ),
    );
  }

  Widget _reviewsTab() {
    return const SnapBeeEmptyState(
      mascot: SnapBeeMascots.notification,
      title: 'No reviews yet',
      message: 'Store reviews will appear here once customers start rating their orders.',
    );
  }
}

class _Trust extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Trust(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: SnapBeeColors.success, size: 20),
          const SizedBox(height: 5),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF1F7A3D), height: 1.15)),
        ],
      ),
    );
  }
}
