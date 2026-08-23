import 'package:flutter_test/flutter_test.dart';
import 'package:snapbee_customer_app/data/cart/cart_store.dart';

void main() {
  // CartStore is a singleton (real, app-wide state) — reset it before each
  // test so cases don't leak into one another.
  setUp(() => CartStore.instance.clear());

  group('CartStore', () {
    test('addItem adds a new line and reports added', () {
      final result = CartStore.instance.addItem(
        productId: 'p1',
        name: 'Milk',
        imageUrl: '',
        unit: '1 L',
        price: 66,
        vendorId: 'vendor-a',
      );

      expect(result, CartAddResult.added);
      expect(CartStore.instance.activeItemCount, 1);
      expect(CartStore.instance.vendorId, 'vendor-a');
    });

    test('adding the same product again merges quantity instead of duplicating', () {
      CartStore.instance.addItem(
        productId: 'p1',
        name: 'Milk',
        imageUrl: '',
        unit: '1 L',
        price: 66,
        vendorId: 'vendor-a',
        quantity: 2,
      );
      CartStore.instance.addItem(
        productId: 'p1',
        name: 'Milk',
        imageUrl: '',
        unit: '1 L',
        price: 66,
        vendorId: 'vendor-a',
        quantity: 3,
      );

      expect(CartStore.instance.items.length, 1);
      expect(CartStore.instance.items.single.quantity, 5);
    });

    test('adding a product from a different vendor is refused, not silently mixed', () {
      CartStore.instance.addItem(
        productId: 'p1',
        name: 'Milk',
        imageUrl: '',
        unit: '1 L',
        price: 66,
        vendorId: 'vendor-a',
      );

      final result = CartStore.instance.addItem(
        productId: 'p2',
        name: 'Bread',
        imageUrl: '',
        unit: '400 g',
        price: 40,
        vendorId: 'vendor-b',
      );

      expect(result, CartAddResult.vendorConflict);
      expect(CartStore.instance.items.length, 1);
      expect(CartStore.instance.vendorId, 'vendor-a');
    });

    test('replaceWithItem clears the existing cart and starts a new one', () {
      CartStore.instance.addItem(
        productId: 'p1',
        name: 'Milk',
        imageUrl: '',
        unit: '1 L',
        price: 66,
        vendorId: 'vendor-a',
      );

      CartStore.instance.replaceWithItem(
        productId: 'p2',
        name: 'Bread',
        imageUrl: '',
        unit: '400 g',
        price: 40,
        vendorId: 'vendor-b',
      );

      expect(CartStore.instance.items.length, 1);
      expect(CartStore.instance.vendorId, 'vendor-b');
      expect(CartStore.instance.items.single.productId, 'p2');
    });

    test('updateQuantity to zero removes the item', () {
      CartStore.instance.addItem(
        productId: 'p1',
        name: 'Milk',
        imageUrl: '',
        unit: '1 L',
        price: 66,
        vendorId: 'vendor-a',
      );
      final cartItemId = CartStore.instance.items.single.id;

      CartStore.instance.updateQuantity(cartItemId, 0);

      expect(CartStore.instance.isEmpty, isTrue);
    });

    test('setSavedForLater moves an item out of activeItems without removing it', () {
      CartStore.instance.addItem(
        productId: 'p1',
        name: 'Milk',
        imageUrl: '',
        unit: '1 L',
        price: 66,
        vendorId: 'vendor-a',
      );
      final cartItemId = CartStore.instance.items.single.id;

      CartStore.instance.setSavedForLater(cartItemId, true);

      expect(CartStore.instance.isEmpty, isTrue);
      expect(CartStore.instance.items.length, 1);
      // A saved-for-later cart no longer pins the cart to a vendor —
      // exactly what lets a later addItem() for a different store succeed
      // instead of reporting a conflict against an item nobody is
      // actively buying anymore.
      expect(CartStore.instance.vendorId, isNull);
    });

    test('clear empties the cart, e.g. after a successful order placement', () {
      CartStore.instance.addItem(
        productId: 'p1',
        name: 'Milk',
        imageUrl: '',
        unit: '1 L',
        price: 66,
        vendorId: 'vendor-a',
      );

      CartStore.instance.clear();

      expect(CartStore.instance.isEmpty, isTrue);
      expect(CartStore.instance.items, isEmpty);
      expect(CartStore.instance.vendorId, isNull);
    });

    test('notifies listeners on mutation', () {
      var notifications = 0;
      void listener() => notifications++;
      CartStore.instance.addListener(listener);

      CartStore.instance.addItem(
        productId: 'p1',
        name: 'Milk',
        imageUrl: '',
        unit: '1 L',
        price: 66,
        vendorId: 'vendor-a',
      );

      expect(notifications, 1);
      CartStore.instance.removeListener(listener);
    });
  });
}
