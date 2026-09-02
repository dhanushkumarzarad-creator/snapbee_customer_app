// Real unit tests for EcommerceCartStore's business logic — not
// "assert true" placeholders. Exercises the single-vendor-cart rule,
// quantity merging, removal, and subtotal math directly.
import 'package:flutter_test/flutter_test.dart';
import 'package:snapbee_customer_app/features/ecommerce/data/ecommerce_cart_store.dart';

void main() {
  late EcommerceCartStore store;

  setUp(() {
    store = EcommerceCartStore.instance;
    store.clear();
  });

  test('addItem adds a new line and computes subtotal correctly', () {
    final result = store.addItem(EcommerceCartItem(
      productId: 'p1',
      productName: 'Widget',
      vendorId: 'v1',
      vendorName: 'Store A',
      unitPrice: 100,
      quantity: 2,
    ));
    expect(result, EcommerceCartAddResult.added);
    expect(store.itemCount, 2);
    expect(store.subtotal, 200);
  });

  test('addItem merges quantity into an existing line for the same product+variant', () {
    store.addItem(EcommerceCartItem(productId: 'p1', productName: 'Widget', vendorId: 'v1', vendorName: 'Store A', unitPrice: 100, quantity: 2));
    store.addItem(EcommerceCartItem(productId: 'p1', productName: 'Widget', vendorId: 'v1', vendorName: 'Store A', unitPrice: 100, quantity: 3));
    expect(store.items.length, 1);
    expect(store.items.first.quantity, 5);
    expect(store.subtotal, 500);
  });

  test('different variants of the same product are separate lines', () {
    store.addItem(EcommerceCartItem(productId: 'p1', variantId: 'red', productName: 'Shirt', vendorId: 'v1', vendorName: 'Store A', unitPrice: 100, quantity: 1));
    store.addItem(EcommerceCartItem(productId: 'p1', variantId: 'blue', productName: 'Shirt', vendorId: 'v1', vendorName: 'Store A', unitPrice: 100, quantity: 1));
    expect(store.items.length, 2);
  });

  test('addItem from a different vendor is rejected as a conflict, cart unchanged', () {
    store.addItem(EcommerceCartItem(productId: 'p1', productName: 'Widget', vendorId: 'v1', vendorName: 'Store A', unitPrice: 100, quantity: 1));
    final result = store.addItem(EcommerceCartItem(productId: 'p2', productName: 'Gadget', vendorId: 'v2', vendorName: 'Store B', unitPrice: 50, quantity: 1));
    expect(result, EcommerceCartAddResult.vendorConflict);
    expect(store.items.length, 1);
    expect(store.vendorId, 'v1');
  });

  test('replaceWithItem clears the cart and starts a new vendor cart', () {
    store.addItem(EcommerceCartItem(productId: 'p1', productName: 'Widget', vendorId: 'v1', vendorName: 'Store A', unitPrice: 100, quantity: 1));
    store.replaceWithItem(EcommerceCartItem(productId: 'p2', productName: 'Gadget', vendorId: 'v2', vendorName: 'Store B', unitPrice: 50, quantity: 2));
    expect(store.items.length, 1);
    expect(store.vendorId, 'v2');
    expect(store.subtotal, 100);
  });

  test('updateQuantity to zero removes the line', () {
    store.addItem(EcommerceCartItem(productId: 'p1', productName: 'Widget', vendorId: 'v1', vendorName: 'Store A', unitPrice: 100, quantity: 1));
    final key = store.items.first.lineKey;
    store.updateQuantity(key, 0);
    expect(store.isEmpty, true);
  });

  test('removeItem removes only the targeted line', () {
    store.addItem(EcommerceCartItem(productId: 'p1', productName: 'Widget', vendorId: 'v1', vendorName: 'Store A', unitPrice: 100, quantity: 1));
    store.addItem(EcommerceCartItem(productId: 'p1', variantId: 'red', productName: 'Widget', vendorId: 'v1', vendorName: 'Store A', unitPrice: 100, quantity: 1));
    final firstKey = store.items.first.lineKey;
    store.removeItem(firstKey);
    expect(store.items.length, 1);
    expect(store.items.first.lineKey, isNot(firstKey));
  });

  test('empty cart has null vendorId and zero subtotal', () {
    expect(store.vendorId, isNull);
    expect(store.subtotal, 0);
    expect(store.isEmpty, true);
  });
}
