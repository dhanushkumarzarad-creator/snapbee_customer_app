import 'package:flutter/foundation.dart';

import '../../screens/cart/models/cart_model.dart';

/// Result of [CartStore.addItem] — lets the caller decide how to react.
/// [vendorConflict] means the cart already holds a different vendor's
/// items and nothing was added; the caller should ask the customer to
/// confirm clearing the cart before calling [CartStore.replaceWithItem].
enum CartAddResult { added, vendorConflict }

/// Real, session-scoped shopping cart shared across the whole app.
///
/// In-memory only — no `cart_items` table exists or is needed: the real
/// order-placement RPC (`place_customer_order`, called from
/// checkout_repository.dart) takes cart contents inline as a
/// `product_id`+`quantity` list and recomputes price/weight/etc. itself
/// from `products` — nothing about an in-progress cart needs to survive a
/// lost app session. Restarting the app clears the cart, same as most
/// quick-commerce apps' baseline behavior.
///
/// Deliberately single-vendor: `place_customer_order` resolves ONE branch
/// for the whole order, so a cart can never hold items from two different
/// vendors. [addItem] enforces this by construction (reports a conflict
/// instead of silently mixing vendors) rather than letting it surface as a
/// confusing failure at checkout.
class CartStore extends ChangeNotifier {
  CartStore._();

  static final CartStore instance = CartStore._();

  final List<CartItemModel> _items = [];

  List<CartItemModel> get items => List.unmodifiable(_items);

  List<CartItemModel> get activeItems =>
      _items.where((i) => !i.savedForLater).toList();

  bool get isEmpty => activeItems.isEmpty;

  int get activeItemCount =>
      activeItems.fold(0, (sum, i) => sum + i.quantity);

  /// The single vendor every active item in the cart belongs to, or null
  /// when the cart has no active items. Checkout reads this to resolve a
  /// delivery branch.
  String? get vendorId =>
      activeItems.isEmpty ? null : activeItems.first.vendorId;

  /// Adds [quantity] of a product to the cart, merging into an existing
  /// line if that product is already present. Refuses (returns
  /// [CartAddResult.vendorConflict], mutates nothing) when the cart already
  /// holds a different vendor's items — call [replaceWithItem] instead
  /// once the customer confirms starting a new cart.
  CartAddResult addItem({
    required String productId,
    required String name,
    required String imageUrl,
    required String unit,
    required double price,
    required String vendorId,
    double? originalPrice,
    int quantity = 1,
  }) {
    final currentVendor = this.vendorId;
    if (currentVendor != null && currentVendor != vendorId) {
      return CartAddResult.vendorConflict;
    }
    _upsert(
      productId: productId,
      name: name,
      imageUrl: imageUrl,
      unit: unit,
      price: price,
      vendorId: vendorId,
      originalPrice: originalPrice,
      quantity: quantity,
    );
    notifyListeners();
    return CartAddResult.added;
  }

  /// Clears the cart and adds this single item — the confirmed outcome of
  /// a [CartAddResult.vendorConflict].
  void replaceWithItem({
    required String productId,
    required String name,
    required String imageUrl,
    required String unit,
    required double price,
    required String vendorId,
    double? originalPrice,
    int quantity = 1,
  }) {
    _items.clear();
    _upsert(
      productId: productId,
      name: name,
      imageUrl: imageUrl,
      unit: unit,
      price: price,
      vendorId: vendorId,
      originalPrice: originalPrice,
      quantity: quantity,
    );
    notifyListeners();
  }

  void _upsert({
    required String productId,
    required String name,
    required String imageUrl,
    required String unit,
    required double price,
    required String vendorId,
    double? originalPrice,
    int quantity = 1,
  }) {
    final existingIndex = _items.indexWhere(
      (i) => i.productId == productId && !i.savedForLater,
    );
    if (existingIndex != -1) {
      final existing = _items[existingIndex];
      _items[existingIndex] = existing.copyWith(
        quantity: (existing.quantity + quantity).clamp(1, existing.maxQuantity),
      );
      return;
    }
    _items.add(
      CartItemModel(
        id: '${productId}_${DateTime.now().microsecondsSinceEpoch}',
        productId: productId,
        name: name,
        imageUrl: imageUrl,
        unit: unit,
        price: price,
        originalPrice: originalPrice,
        vendorId: vendorId,
        quantity: quantity,
      ),
    );
  }

  void updateQuantity(String cartItemId, int quantity) {
    if (quantity <= 0) {
      _items.removeWhere((i) => i.id == cartItemId);
    } else {
      final index = _items.indexWhere((i) => i.id == cartItemId);
      if (index != -1) {
        _items[index] = _items[index].copyWith(quantity: quantity);
      }
    }
    notifyListeners();
  }

  void removeItem(String cartItemId) {
    _items.removeWhere((i) => i.id == cartItemId);
    notifyListeners();
  }

  void setSavedForLater(String cartItemId, bool saved) {
    final index = _items.indexWhere((i) => i.id == cartItemId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(savedForLater: saved);
      notifyListeners();
    }
  }

  /// Called after a successful `place_customer_order` — the order now
  /// lives in Supabase, nothing left to hold locally.
  void clear() {
    _items.clear();
    notifyListeners();
  }
}
