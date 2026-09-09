import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapbee_customer_app/data/repositories/wishlist_repository.dart';
import 'package:snapbee_customer_app/screens/wishlist/models/wishlist_model.dart';
import 'package:snapbee_customer_app/screens/wishlist/wishlist_screen.dart';

class _FakeWishlist implements WishlistSource {
  _FakeWishlist(this._items);
  List<WishlistItemModel> _items;
  final List<String> removed = [];
  Object? throwOnFetch;

  @override
  Future<List<WishlistItemModel>> fetchWishlist() async {
    if (throwOnFetch != null) throw throwOnFetch!;
    return _items;
  }

  @override
  Future<Set<String>> fetchWishlistedProductIds() async =>
      _items.map((i) => i.productId).toSet();

  @override
  Future<void> add(String productId) async {}

  @override
  Future<void> remove(String productId) async {
    removed.add(productId);
    _items = _items.where((i) => i.productId != productId).toList();
  }
}

WishlistItemModel _item(String id) => WishlistItemModel(
      id: 'w-$id',
      productId: 'p-$id',
      name: 'Product $id',
      imageUrl: '',
      storeName: 'Some Store',
      unit: '1 pc',
      price: 100,
      inStock: true,
      addedAt: DateTime(2026, 1, 1),
      vendorId: 'v1',
    );

void main() {
  testWidgets('loads and lists saved products from the repository', (tester) async {
    final fake = _FakeWishlist([_item('1'), _item('2')]);
    await tester.pumpWidget(MaterialApp(home: WishlistScreen(source: fake)));
    await tester.pumpAndSettle();

    expect(find.text('Product 1'), findsOneWidget);
    expect(find.text('Product 2'), findsOneWidget);
    expect(find.text('2 Items'), findsOneWidget);
  });

  testWidgets('empty repository shows the empty state', (tester) async {
    await tester.pumpWidget(MaterialApp(home: WishlistScreen(source: _FakeWishlist([]))));
    await tester.pumpAndSettle();

    expect(find.text('Your wishlist is empty'), findsOneWidget);
  });

  testWidgets('a signed-out customer is told to sign in', (tester) async {
    final fake = _FakeWishlist([])..throwOnFetch = WishlistUnavailableException();
    await tester.pumpWidget(MaterialApp(home: WishlistScreen(source: fake)));
    await tester.pumpAndSettle();

    expect(find.text('Sign in to use your wishlist.'), findsOneWidget);
  });

  testWidgets('removing an item calls the repository', (tester) async {
    final fake = _FakeWishlist([_item('1')]);
    await tester.pumpWidget(MaterialApp(home: WishlistScreen(source: fake)));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Remove from wishlist').first);
    await tester.pumpAndSettle();

    expect(fake.removed, ['p-1']);
    expect(find.text('Your wishlist is empty'), findsOneWidget);
  });
}
