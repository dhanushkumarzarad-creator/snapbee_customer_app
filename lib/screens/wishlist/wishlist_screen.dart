import 'package:flutter/material.dart';

import 'models/wishlist_model.dart';
import 'widgets/wishlist_item_card.dart';

/// Premium wishlist screen for the SnapBee Customer App — modeled after
/// Blinkit / Zepto / Swiggy Instamart saved-items screens.
///
/// Wire this up to real data by passing [initialItems] from your
/// Supabase-backed wishlist provider/bloc and handling [onMoveToCart] /
/// [onMoveAllToCart]. Falls back to sample data for previewing.
class WishlistScreen extends StatefulWidget {
  final List<WishlistItemModel>? initialItems;
  final void Function(WishlistItemModel item)? onMoveToCart;
  final void Function(List<WishlistItemModel> items)? onMoveAllToCart;
  final void Function(WishlistItemModel item)? onOpenProduct;
  final VoidCallback? onStartShopping;

  const WishlistScreen({
    super.key,
    this.initialItems,
    this.onMoveToCart,
    this.onMoveAllToCart,
    this.onOpenProduct,
    this.onStartShopping,
  });

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  late List<WishlistItemModel> _items;

  @override
  void initState() {
    super.initState();
    _items = List<WishlistItemModel>.from(
      widget.initialItems ?? _sampleItems(),
    );
  }

  bool get _isEmpty => _items.isEmpty;

  int get _inStockCount => _items.where((i) => i.inStock).length;

  void _removeItem(WishlistItemModel item) {
    setState(() => _items.removeWhere((i) => i.id == item.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} removed from wishlist'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _moveToCart(WishlistItemModel item) {
    setState(() => _items.removeWhere((i) => i.id == item.id));
    widget.onMoveToCart?.call(item);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} moved to cart'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _moveAllToCart() {
    final moved = _items.where((i) => i.inStock).toList();
    if (moved.isEmpty) return;

    setState(() {
      _items.removeWhere((i) => i.inStock);
    });
    widget.onMoveAllToCart?.call(moved);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${moved.length} item${moved.length == 1 ? '' : 's'} moved to cart',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _confirmClearWishlist() async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear wishlist?'),
        content: Text(
          'This will remove all ${_items.length} saved items. This action cannot be undone.',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _items.clear());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wishlist cleared'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Wishlist${_items.isNotEmpty ? ' (${_items.length})' : ''}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        scrolledUnderElevation: 1,
        actions: [
          if (!_isEmpty)
            TextButton(
              onPressed: _confirmClearWishlist,
              child: Text(
                'Clear All',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.error,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: _isEmpty
            ? _EmptyWishlistState(onStartShopping: widget.onStartShopping)
            : LayoutBuilder(
                builder: (context, constraints) {
                  final bool isWide = constraints.maxWidth >= 720;
                  final content = ListView(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    children: [
                      if (_inStockCount > 0)
                        _MoveAllToCartBar(
                          count: _inStockCount,
                          onMoveAll: _moveAllToCart,
                        ),
                      const SizedBox(height: 4),
                      if (isWide)
                        _ResponsiveGrid(
                          items: _items,
                          onMoveToCart: _moveToCart,
                          onRemove: _removeItem,
                          onOpenProduct: widget.onOpenProduct,
                        )
                      else
                        ..._items.map(
                          (item) => WishlistItemCard(
                            item: item,
                            onMoveToCart: () => _moveToCart(item),
                            onRemove: () => _removeItem(item),
                            onTap: widget.onOpenProduct == null
                                ? null
                                : () => widget.onOpenProduct!(item),
                          ),
                        ),
                    ],
                  );

                  if (!isWide) return content;

                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: content,
                    ),
                  );
                },
              ),
      ),
    );
  }

  List<WishlistItemModel> _sampleItems() {
    final now = DateTime.now();
    return [
      WishlistItemModel(
        id: 'w1',
        productId: 'p1',
        name: 'Nestle Everyday Dairy Whitener',
        imageUrl: '',
        storeName: 'SnapBee Daily Essentials',
        unit: '400 g Pack',
        price: 178,
        originalPrice: 210,
        addedAt: now.subtract(const Duration(hours: 2)),
      ),
      WishlistItemModel(
        id: 'w2',
        productId: 'p2',
        name: 'Philips Air Fryer HD9200',
        imageUrl: '',
        storeName: 'SnapBee Electronics',
        unit: '4.1 L',
        price: 5999,
        originalPrice: 7495,
        addedAt: now.subtract(const Duration(days: 1)),
      ),
      WishlistItemModel(
        id: 'w3',
        productId: 'p3',
        name: 'Himalaya Neem Face Wash',
        imageUrl: '',
        storeName: 'SnapBee Pharmacy',
        unit: '150 ml',
        price: 145,
        addedAt: now.subtract(const Duration(days: 2)),
      ),
      WishlistItemModel(
        id: 'w4',
        productId: 'p4',
        name: 'Boat Rockerz 450 Headphones',
        imageUrl: '',
        storeName: 'SnapBee Electronics',
        unit: 'Wireless',
        price: 1299,
        originalPrice: 1990,
        inStock: false,
        addedAt: now.subtract(const Duration(days: 4)),
      ),
    ];
  }
}

/// Prompt bar offering to move all in-stock wishlist items to the cart
/// in a single tap.
class _MoveAllToCartBar extends StatelessWidget {
  final int count;
  final VoidCallback onMoveAll;

  const _MoveAllToCartBar({required this.count, required this.onMoveAll});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            Icons.shopping_bag_rounded,
            size: 18,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$count item${count == 1 ? '' : 's'} ready to move to cart',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            onPressed: onMoveAll,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Move All to Cart'),
          ),
        ],
      ),
    );
  }
}

/// Wide-screen (tablet/desktop) layout: lays wishlist cards out in a
/// two-column grid instead of a single-column list.
class _ResponsiveGrid extends StatelessWidget {
  final List<WishlistItemModel> items;
  final ValueChanged<WishlistItemModel> onMoveToCart;
  final ValueChanged<WishlistItemModel> onRemove;
  final void Function(WishlistItemModel item)? onOpenProduct;

  const _ResponsiveGrid({
    required this.items,
    required this.onMoveToCart,
    required this.onRemove,
    this.onOpenProduct,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.35,
        mainAxisSpacing: 0,
        crossAxisSpacing: 0,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return WishlistItemCard(
          item: item,
          onMoveToCart: () => onMoveToCart(item),
          onRemove: () => onRemove(item),
          onTap: onOpenProduct == null ? null : () => onOpenProduct!(item),
        );
      },
    );
  }
}

/// Empty-wishlist placeholder with a call-to-action to start shopping.
class _EmptyWishlistState extends StatelessWidget {
  final VoidCallback? onStartShopping;

  const _EmptyWishlistState({this.onStartShopping});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.5,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                size: 54,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Your wishlist is empty',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the heart icon on any product\nto save it here for later.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed:
                  onStartShopping ?? () => Navigator.of(context).maybePop(),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Start Shopping'),
            ),
          ],
        ),
      ),
    );
  }
}
