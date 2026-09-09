// Maps the additive live `products` columns (unit / discount_price /
// is_available / stock_quantity / track_inventory) that the Home
// "Products For You" carousel and every other catalog surface now surface,
// plus the VendorRow enrichment fields behind the "Popular Stores Near You"
// card decorations. Pure data-shape tests — no Supabase client.

import 'package:flutter_test/flutter_test.dart';
import 'package:snapbee_customer_app/data/repositories/product_repository.dart';
import 'package:snapbee_customer_app/data/repositories/vendor_repository.dart';
import 'package:snapbee_customer_app/screens/home/widgets/product_model.dart';

void main() {
  group('ProductRow.fromJson', () {
    test('maps unit / discount_price / stock from a full row', () {
      final row = ProductRow.fromJson({
        'id': 'p1',
        'name': 'Aashirvaad Atta',
        'price': 320,
        'category': 'Grocery',
        'vendor_id': 'v1',
        'image_urls': ['https://cdn.example/atta.jpg'],
        'unit': '5 kg',
        'discount_price': 289,
        'is_available': true,
        'stock_quantity': 12,
        'track_inventory': true,
      });

      expect(row.unit, '5 kg');
      expect(row.discountPrice, 289);
      expect(row.primaryImageUrl, 'https://cdn.example/atta.jpg');
      expect(row.inStock, isTrue);
      expect(row.displayPrice, '₹289');
    });

    test('discountPrice getter ignores a non-discount value', () {
      final row = ProductRow.fromJson({
        'id': 'p2',
        'name': 'Milk',
        'price': 30,
        'category': 'Grocery',
        'vendor_id': 'v1',
        'discount_price': 30, // equal to MRP => not a discount
      });
      expect(row.discountPrice, isNull);
    });

    test('out of stock when inventory is tracked and quantity is 0', () {
      final row = ProductRow.fromJson({
        'id': 'p3',
        'name': 'Eggs',
        'price': 90,
        'category': 'Grocery',
        'vendor_id': 'v1',
        'is_available': true,
        'stock_quantity': 0,
        'track_inventory': true,
      });
      expect(row.inStock, isFalse);
    });

    test('in stock when inventory is not tracked, even with null quantity', () {
      final row = ProductRow.fromJson({
        'id': 'p4',
        'name': 'Salt',
        'price': 20,
        'category': 'Grocery',
        'vendor_id': 'v1',
        'is_available': true,
        'track_inventory': false,
      });
      expect(row.inStock, isTrue);
    });

    test('is_available = false forces out of stock', () {
      final row = ProductRow.fromJson({
        'id': 'p5',
        'name': 'Paneer',
        'price': 80,
        'category': 'Grocery',
        'vendor_id': 'v1',
        'is_available': false,
        'track_inventory': false,
      });
      expect(row.inStock, isFalse);
    });

    test('tolerates the stripped-down (base-columns) row shape', () {
      final row = ProductRow.fromJson({
        'id': 'p6',
        'name': 'Rice',
        'price': 500,
        'category': 'Grocery',
        'vendor_id': 'v1',
      });
      expect(row.unit, '');
      expect(row.discountPrice, isNull);
      expect(row.inStock, isTrue); // defaults: available, not tracked
    });
  });

  group('ProductModel.fromRow', () {
    test('carries unit, discount and stock through to the UI model', () {
      final model = ProductModel.fromRow(ProductRow.fromJson({
        'id': 'p1',
        'name': 'Aashirvaad Atta',
        'price': 320,
        'category': 'Grocery',
        'vendor_id': 'v1',
        'unit': '5 kg',
        'discount_price': 289,
        'is_available': true,
        'stock_quantity': 0,
        'track_inventory': true,
      }));

      expect(model.unit, '5 kg');
      expect(model.currentPrice, 289);
      expect(model.oldPrice, 320);
      expect(model.hasDiscount, isTrue);
      expect(model.discountPercent, 10); // (320-289)/320 = 9.7 -> 10
      expect(model.inStock, isFalse);
      expect(model.vendorId, 'v1');
    });
  });

  group('VendorRow enrichment fields', () {
    test('hasOffer / hasRating gate on real values', () {
      const bare = VendorRow(id: 'v1', name: 'Local Store');
      expect(bare.hasOffer, isFalse);
      expect(bare.hasRating, isFalse);

      final enriched = bare.copyWith(
        offerPercent: 20,
        deliveryEnabled: true,
        ratingAvg: 4.5,
        ratingCount: 8,
      );
      expect(enriched.hasOffer, isTrue);
      expect(enriched.offerPercent, 20);
      expect(enriched.hasRating, isTrue);
      expect(enriched.ratingAvg, 4.5);
      expect(enriched.ratingCount, 8);
      expect(enriched.deliveryEnabled, isTrue);
    });

    test('a 0% offer and 0 reviews are not shown', () {
      const v = VendorRow(
        id: 'v1',
        name: 'Local Store',
        offerPercent: 0,
        ratingAvg: 0,
        ratingCount: 0,
      );
      expect(v.hasOffer, isFalse);
      expect(v.hasRating, isFalse);
    });
  });
}
