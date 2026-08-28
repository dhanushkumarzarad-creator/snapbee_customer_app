import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/cart/cart_store.dart';
import '../../data/repositories/wishlist_repository.dart';
import 'models/wishlist_model.dart';
import 'widgets/wishlist_item_card.dart';

/// The customer's saved products, backed by [WishlistRepository]
/// (`customer_wishlists`). Real load / remove / move-to-cart — no more
/// local sample data.
class WishlistScreen extends StatefulWidget {
  final void Function(WishlistItemModel item)? onOpenProduct;
  final VoidCallback? onStartShopping;

  /// Injectable for tests; defaults to the real Supabase-backed repository.
  final WishlistSource? source;

  const WishlistScreen({
    super.key,
    this.onOpenProduct,
    this.onStartShopping,
    this.source,
  });

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  late final WishlistSource _repo =
      widget.source ?? WishlistRepository(Supabase.instance.client);

  bool _loading = true;
  Object? _error;
  List<WishlistItemModel> _items = const [];

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
      final items = await _repo.fetchWishlist();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  bool get _isEmpty => _items.isEmpty;

  int get _inStockCount => _items.where((i) => i.inStock).length;

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _removeItem(WishlistItemModel item) async {
    final previous = _items;
    setState(() => _items = _items.where((i) => i.id != item.id).toList());
    try {
      await _repo.remove(item.productId);
      _snack('${item.name} removed from wishlist');
    } catch (error) {
      if (!mounted) return;
      setState(() => _items = previous);
      _snack('Could not remove ${item.name}: $error');
    }
  }

  /// Adds the item to the real cart (single-vendor: refuses to mix
  /// stores), then drops it from the wishlist.
  Future<void> _moveToCart(WishlistItemModel item) async {
    if (!item.inStock) {
      _snack('${item.name} is out of stock.');
      return;
    }
    if (item.vendorId.isEmpty) {
      _snack('${item.name} can\'t be added right now.');
      return;
    }
    final result = CartStore.instance.addItem(
      productId: item.productId,
      name: item.name,
      imageUrl: item.imageUrl,
      unit: item.unit,
      price: item.price,
      originalPrice: item.originalPrice,
      vendorId: item.vendorId,
    );
    if (result == CartAddResult.vendorConflict) {
      _snack('Your cart already has items from another store.');
      return;
    }
    final previous = _items;
    setState(() => _items = _items.where((i) => i.id != item.id).toList());
    try {
      await _repo.remove(item.productId);
      _snack('${item.name} moved to cart');
    } catch (_) {
      // The item is in the cart; leaving it in the wishlist too is the
      // safe failure — just restore and tell the user.
      if (!mounted) return;
      setState(() => _items = previous);
      _snack('${item.name} added to cart (still in your wishlist).');
    }
  }

  Future<void> _moveAllToCart() async {
    for (final item in _items.where((i) => i.inStock).toList()) {
      await _moveToCart(item);
    }
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

    if (confirmed != true) return;
    final previous = _items;
    setState(() => _items = const []);
    try {
      for (final item in previous) {
        await _repo.remove(item.productId);
      }
      _snack('Wishlist cleared');
    } catch (error) {
      if (!mounted) return;
      setState(() => _items = previous);
      _snack('Could not clear the wishlist: $error');
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
          if (!_isEmpty && !_loading && _error == null)
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
      body: SafeArea(child: _body(theme)),
    );
  }

  Widget _body(ThemeData theme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      final isAuth = _error is WishlistUnavailableException;
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 44, color: theme.colorScheme.outline),
              const SizedBox(height: 12),
              Text(
                isAuth ? 'Sign in to use your wishlist.' : "Couldn't load your wishlist.",
                textAlign: TextAlign.center,
              ),
              if (!isAuth) ...[
                const SizedBox(height: 12),
                OutlinedButton(onPressed: _load, child: const Text('Retry')),
              ],
            ],
          ),
        ),
      );
    }
    if (_isEmpty) {
      return _EmptyWishlistState(onStartShopping: widget.onStartShopping);
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth >= 720;
          final content = ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            children: [
              if (_inStockCount > 0)
                _MoveAllToCartBar(count: _inStockCount, onMoveAll: _moveAllToCart),
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
    );
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
        // 2.35 clipped the card content by ~30px; 2.0 gives it room.
        childAspectRatio: 2.0,
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
