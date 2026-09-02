import 'package:flutter/foundation.dart';

/// One cart line — a specific product (and variant, if any) at a quantity.
class EcommerceCartItem {
  final String productId;
  final String? variantId;
  final String productName;
  final String? variantLabel;
  final String vendorId;
  final String vendorName;
  final num unitPrice;
  int quantity;

  EcommerceCartItem({
    required this.productId,
    this.variantId,
    required this.productName,
    this.variantLabel,
    required this.vendorId,
    required this.vendorName,
    required this.unitPrice,
    required this.quantity,
  });

  String get lineKey => '$productId|${variantId ?? ''}';
  num get lineTotal => unitPrice * quantity;
}

enum EcommerceCartAddResult { added, vendorConflict }

/// Real, session-scoped shopping cart for the E-Commerce sector —
/// deliberately its own store (not shared with Daily Essentials'
/// CartStore, even though the shape rhymes) since the two verticals'
/// business logic must stay separate. In-memory only, same posture as
/// Daily Essentials' cart: checkout converts it into a real
/// ecommerce_orders row (one order per vendor) via create_ecommerce_order,
/// which recomputes price/stock itself — nothing about an in-progress
/// cart needs to survive a lost session.
class EcommerceCartStore extends ChangeNotifier {
  EcommerceCartStore._();
  static final EcommerceCartStore instance = EcommerceCartStore._();

  final List<EcommerceCartItem> _items = [];

  List<EcommerceCartItem> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;
  int get itemCount => _items.fold(0, (sum, i) => sum + i.quantity);
  num get subtotal => _items.fold(0, (sum, i) => sum + i.lineTotal);
  String? get vendorId => _items.isEmpty ? null : _items.first.vendorId;
  String? get vendorName => _items.isEmpty ? null : _items.first.vendorName;

  EcommerceCartAddResult addItem(EcommerceCartItem item) {
    if (_items.isNotEmpty && _items.first.vendorId != item.vendorId) {
      return EcommerceCartAddResult.vendorConflict;
    }
    final existingIndex = _items.indexWhere((i) => i.lineKey == item.lineKey);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += item.quantity;
    } else {
      _items.add(item);
    }
    notifyListeners();
    return EcommerceCartAddResult.added;
  }

  void replaceWithItem(EcommerceCartItem item) {
    _items.clear();
    _items.add(item);
    notifyListeners();
  }

  void updateQuantity(String lineKey, int quantity) {
    final index = _items.indexWhere((i) => i.lineKey == lineKey);
    if (index < 0) return;
    if (quantity <= 0) {
      _items.removeAt(index);
    } else {
      _items[index].quantity = quantity;
    }
    notifyListeners();
  }

  void removeItem(String lineKey) {
    _items.removeWhere((i) => i.lineKey == lineKey);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
