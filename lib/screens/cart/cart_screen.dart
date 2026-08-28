import 'package:flutter/material.dart';

import '../../data/cart/cart_store.dart';
import '../checkout/checkout_screen.dart';
import 'models/cart_model.dart';
import 'widgets/bill_summary_card.dart';
import 'widgets/cart_item_card.dart';

/// Premium cart screen for the SnapBee Customer App — modeled after
/// Blinkit / Zepto / Swiggy Instamart carts.
///
/// Defaults to the real, app-wide [CartStore] (and stays live-synced with
/// it via a listener) — every entry point across the app pushes a bare
/// `CartScreen()`. [initialItems] stays as an escape hatch for widget
/// tests/previews: passing it opts out of the global store entirely, so
/// this screen's own mutations only ever touch its local list.
class CartScreen extends StatefulWidget {
  final List<CartItemModel>? initialItems;
  final CartCalculator calculator;
  final VoidCallback? onCheckout;
  final VoidCallback? onStartShopping;

  const CartScreen({
    super.key,
    this.initialItems,
    this.calculator = const CartCalculator(),
    this.onCheckout,
    this.onStartShopping,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late List<CartItemModel> _items;

  /// False only when [CartScreen.initialItems] was explicitly passed
  /// (widget tests/previews) — otherwise this screen is the real, global
  /// cart and stays synced with [CartStore].
  bool get _usesGlobalStore => widget.initialItems == null;

  @override
  void initState() {
    super.initState();
    _items = List<CartItemModel>.from(
      widget.initialItems ?? CartStore.instance.items,
    );
    if (_usesGlobalStore) {
      CartStore.instance.addListener(_onStoreChanged);
    }
  }

  void _onStoreChanged() {
    if (!mounted) return;
    setState(() {
      _items = List<CartItemModel>.from(CartStore.instance.items);
    });
  }

  @override
  void dispose() {
    if (_usesGlobalStore) {
      CartStore.instance.removeListener(_onStoreChanged);
    }
    super.dispose();
  }

  List<CartItemModel> get _activeItems =>
      _items.where((i) => !i.savedForLater).toList();

  List<CartItemModel> get _savedItems =>
      _items.where((i) => i.savedForLater).toList();

  bool get _isEmpty => _activeItems.isEmpty;

  void _updateQuantity(CartItemModel item, int quantity) {
    if (_usesGlobalStore) {
      CartStore.instance.updateQuantity(item.id, quantity);
      return;
    }
    setState(() {
      if (quantity <= 0) {
        _items.removeWhere((i) => i.id == item.id);
      } else {
        final index = _items.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          _items[index] = _items[index].copyWith(quantity: quantity);
        }
      }
    });
  }

  void _removeItem(CartItemModel item) {
    if (_usesGlobalStore) {
      CartStore.instance.removeItem(item.id);
    } else {
      setState(() {
        _items.removeWhere((i) => i.id == item.id);
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} removed from cart'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleSaveForLater(CartItemModel item, bool saved) {
    if (_usesGlobalStore) {
      CartStore.instance.setSavedForLater(item.id, saved);
      return;
    }
    setState(() {
      final index = _items.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _items[index] = _items[index].copyWith(savedForLater: saved);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final calculator = widget.calculator;
    final itemTotal = calculator.itemTotal(_activeItems);
    final bill = calculator.computeBill(_activeItems);
    final mrpSavings = calculator.totalMrpSavings(_activeItems);
    final freeDeliveryRemaining = calculator.amountToFreeDelivery(itemTotal);
    final freeDeliveryProgress = calculator.freeDeliveryProgress(itemTotal);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'My Cart${_activeItems.isNotEmpty ? ' (${_activeItems.length})' : ''}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        scrolledUnderElevation: 1,
      ),
      body: SafeArea(
        child: _isEmpty
            ? _EmptyCartState(onStartShopping: widget.onStartShopping)
            : ListView(
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  FreeDeliveryProgressBar(
                    progress: freeDeliveryProgress,
                    amountRemaining: freeDeliveryRemaining,
                  ),
                  const SizedBox(height: 8),
                  ..._activeItems.map(
                    (item) => CartItemCard(
                      item: item,
                      onQuantityChanged: (q) => _updateQuantity(item, q),
                      onRemove: () => _removeItem(item),
                      onSaveForLater: () => _toggleSaveForLater(item, true),
                    ),
                  ),
                  const SizedBox(height: 8),
                  BillSummaryCard(bill: bill, mrpSavings: mrpSavings),
                  if (_savedItems.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _SavedForLaterSection(
                      items: _savedItems,
                      onMoveToCart: (item) => _toggleSaveForLater(item, false),
                      onRemove: _removeItem,
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
      ),
      bottomNavigationBar: _isEmpty
          ? null
          : _CheckoutBar(
              grandTotal: bill.grandTotal,
              itemCount: _activeItems.fold(0, (sum, i) => sum + i.quantity),
              onCheckout:
                  widget.onCheckout ??
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CheckoutScreen(items: _activeItems, bill: bill),
                    ),
                  ),
            ),
    );
  }

}

/// Slim progress bar nudging the customer toward the free-delivery
/// threshold ("Add items worth ₹52 more for FREE delivery").
class FreeDeliveryProgressBar extends StatelessWidget {
  final double progress;
  final double amountRemaining;

  const FreeDeliveryProgressBar({
    super.key,
    required this.progress,
    required this.amountRemaining,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool unlocked = amountRemaining <= 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: unlocked
            ? const Color(0xFF2E7D32).withValues(alpha: 0.08)
            : theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                unlocked
                    ? Icons.check_circle_rounded
                    : Icons.local_shipping_rounded,
                size: 16,
                color: unlocked
                    ? const Color(0xFF2E7D32)
                    : theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  unlocked
                      ? "You've unlocked FREE delivery!"
                      : 'Add items worth \u20b9${amountRemaining.toStringAsFixed(0)} more for FREE delivery',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: unlocked
                        ? const Color(0xFF2E7D32)
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surface,
              valueColor: AlwaysStoppedAnimation<Color>(
                unlocked ? const Color(0xFF2E7D32) : theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class _SavedForLaterSection extends StatelessWidget {
  final List<CartItemModel> items;
  final ValueChanged<CartItemModel> onMoveToCart;
  final ValueChanged<CartItemModel> onRemove;

  const _SavedForLaterSection({
    required this.items,
    required this.onMoveToCart,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Text(
            'Saved for Later (${items.length})',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ...items.map(
          (item) => CartItemCard(
            item: item,
            onRemove: () => onRemove(item),
            onMoveToCart: () => onMoveToCart(item),
          ),
        ),
      ],
    );
  }
}

/// Empty-cart placeholder with a call-to-action to start shopping.
class _EmptyCartState extends StatelessWidget {
  final VoidCallback? onStartShopping;

  const _EmptyCartState({this.onStartShopping});

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
                Icons.shopping_cart_outlined,
                size: 54,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Your cart is empty',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Looks like you haven\'t added\nanything to your cart yet.',
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

/// Bottom sticky bar with grand total + item count and the checkout CTA.
class _CheckoutBar extends StatelessWidget {
  final double grandTotal;
  final int itemCount;
  final VoidCallback? onCheckout;

  const _CheckoutBar({
    required this.grandTotal,
    required this.itemCount,
    this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '\u20b9${grandTotal.toStringAsFixed(0)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '$itemCount item${itemCount == 1 ? '' : 's'} \u2022 TOTAL',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: onCheckout,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Proceed to Checkout',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
