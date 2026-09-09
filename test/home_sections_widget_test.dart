// Widget-level checks for the two Home commerce rows:
//   * "Products For You"  -> ProductCardWidget: unit, MRP strike-through,
//     discount badge, out-of-stock overlay, wishlist heart + Add callback.
//   * "Popular Stores Near You" -> PopularStoresWidget: real offer badge,
//     rating and delivery line only when the VendorRow carries them, and
//     the store tap opens the details flow.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapbee_customer_app/data/repositories/vendor_repository.dart';
import 'package:snapbee_customer_app/screens/home/widgets/popular_stores_widget.dart';
import 'package:snapbee_customer_app/screens/home/widgets/product_card_widget.dart';
import 'package:snapbee_customer_app/screens/home/widgets/product_model.dart';
import 'package:snapbee_customer_app/screens/home/widgets/products_for_you_widget.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  group('ProductCardWidget', () {
    const discounted = ProductModel(
      id: 'p1',
      name: 'Aashirvaad Atta',
      imageAssetPath: '',
      currentPrice: 289,
      oldPrice: 320,
      unit: '5 kg',
      inStock: true,
      vendorId: 'v1',
    );

    testWidgets('shows unit, MRP strike-through and discount badge',
        (tester) async {
      await tester.pumpWidget(_host(
        const SizedBox(
          width: 180,
          child: ProductCardWidget(product: discounted, storeName: 'Local Store'),
        ),
      ));

      expect(find.text('5 kg'), findsOneWidget);
      expect(find.text('₹289'), findsOneWidget);
      expect(find.text('₹320'), findsOneWidget);
      expect(find.text('10% OFF'), findsOneWidget);
      expect(find.text('Local Store'), findsOneWidget);
    });

    testWidgets('out-of-stock product shows the overlay', (tester) async {
      await tester.pumpWidget(_host(
        const SizedBox(
          width: 180,
          child: ProductCardWidget(
            product: ProductModel(
              id: 'p2',
              name: 'Eggs',
              imageAssetPath: '',
              currentPrice: 90,
              inStock: false,
              vendorId: 'v1',
            ),
          ),
        ),
      ));
      expect(find.text('Out of stock'), findsOneWidget);
    });

    testWidgets('wishlist heart appears only with a callback and toggles',
        (tester) async {
      var toggled = 0;
      await tester.pumpWidget(_host(
        SizedBox(
          width: 180,
          child: ProductCardWidget(
            product: discounted,
            isWishlisted: false,
            onWishlistToggle: () => toggled++,
          ),
        ),
      ));

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      await tester.tap(find.byIcon(Icons.favorite_border));
      expect(toggled, 1);
    });

    testWidgets('no heart when no wishlist callback is wired', (tester) async {
      await tester.pumpWidget(_host(
        const SizedBox(
          width: 180,
          child: ProductCardWidget(product: discounted),
        ),
      ));
      expect(find.byIcon(Icons.favorite_border), findsNothing);
      expect(find.byIcon(Icons.favorite), findsNothing);
    });

    testWidgets('Add button routes through onAddPressed', (tester) async {
      var added = 0;
      await tester.pumpWidget(_host(
        SizedBox(
          width: 180,
          child: ProductCardWidget(
            product: discounted,
            onAddPressed: () => added++,
          ),
        ),
      ));
      await tester.tap(find.text('ADD'));
      expect(added, 1);
    });
  });

  group('ProductsForYouWidget', () {
    testWidgets('renders an honest empty state, never sample data',
        (tester) async {
      await tester.pumpWidget(_host(
        const ProductsForYouWidget(products: []),
      ));
      expect(find.text('Products For You'), findsOneWidget);
      expect(find.text('No products available yet'), findsOneWidget);
    });

    testWidgets('shows a spinner while products are still loading',
        (tester) async {
      await tester.pumpWidget(_host(
        const ProductsForYouWidget(products: null, isLoading: true),
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('PopularStoresWidget', () {
    testWidgets('renders offer badge, rating and delivery line from real data',
        (tester) async {
      await tester.pumpWidget(_host(
        PopularStoresWidget(
          stores: const [
            VendorRow(
              id: 'v1',
              name: 'Local Store',
              city: 'Dharmapuri',
              offerPercent: 20,
              deliveryEnabled: true,
              ratingAvg: 4.5,
              ratingCount: 8,
            ),
          ],
        ),
      ));

      expect(find.text('Popular Stores Near You'), findsOneWidget);
      expect(find.text('Local Store'), findsOneWidget);
      expect(find.text('20% OFF'), findsOneWidget);
      expect(find.text('4.5'), findsOneWidget);
      expect(find.text('Dharmapuri'), findsOneWidget);
      expect(find.text('Delivery available'), findsOneWidget);
    });

    testWidgets('a bare vendor shows name + area only, no fabricated badges',
        (tester) async {
      await tester.pumpWidget(_host(
        PopularStoresWidget(
          stores: const [
            VendorRow(id: 'v2', name: 'Corner Mart', city: 'Salem'),
          ],
        ),
      ));
      expect(find.text('Corner Mart'), findsOneWidget);
      expect(find.text('Salem'), findsOneWidget);
      expect(find.textContaining('% OFF'), findsNothing);
      expect(find.text('Delivery available'), findsNothing);
    });

    testWidgets('loaded-but-empty keeps the section with an honest empty state',
        (tester) async {
      await tester.pumpWidget(_host(
        const PopularStoresWidget(stores: []),
      ));
      expect(find.text('Popular Stores Near You'), findsOneWidget);
      expect(find.text('No stores near you yet'), findsOneWidget);
    });

    testWidgets('still-loading (null) renders nothing yet', (tester) async {
      await tester.pumpWidget(_host(
        const PopularStoresWidget(stores: null),
      ));
      expect(find.text('Popular Stores Near You'), findsNothing);
    });

    testWidgets('tapping a store card fires onStoreTap', (tester) async {
      VendorRow? tapped;
      await tester.pumpWidget(_host(
        PopularStoresWidget(
          stores: const [VendorRow(id: 'v1', name: 'Local Store')],
          onStoreTap: (v) => tapped = v,
        ),
      ));
      await tester.tap(find.text('Local Store'));
      expect(tapped?.id, 'v1');
    });
  });
}
