import 'package:flutter_test/flutter_test.dart';
import 'package:snapbee_customer_app/features/services/categories/service_detail_screen.dart';
import 'package:snapbee_customer_app/features/services/models/service_vendor.dart';

ServiceVendorListing _provider({
  required double rating,
  required int count,
  double price = 500,
}) =>
    ServiceVendorListing(
      vendorId: 'v-$rating-$count',
      businessName: 'Test Provider',
      businessType: 'business',
      ratingAvg: rating,
      ratingCount: count,
      price: price,
    );

void main() {
  group('weightedProviderRating', () {
    test('returns null for an empty provider list — no fabricated 0.0 average', () {
      expect(weightedProviderRating(const []), isNull);
    });

    test('returns null when every provider has zero ratings yet', () {
      final providers = [_provider(rating: 0, count: 0), _provider(rating: 0, count: 0)];
      expect(weightedProviderRating(providers), isNull);
    });

    test('a single rated provider returns exactly its own average', () {
      final result = weightedProviderRating([_provider(rating: 4.5, count: 10)]);
      expect(result!.average, 4.5);
      expect(result.totalCount, 10);
    });

    test('weights by rating_count so a high-volume provider dominates a low-volume one', () {
      // 200 ratings at 5.0 vs 1 rating at 1.0 should land close to 5.0, not a plain 3.0 average.
      final result = weightedProviderRating([
        _provider(rating: 5.0, count: 200),
        _provider(rating: 1.0, count: 1),
      ]);
      expect(result!.totalCount, 201);
      expect(result.average, closeTo(4.98, 0.01));
    });

    test('unrated providers (rating_count 0) are excluded from the average entirely', () {
      final result = weightedProviderRating([
        _provider(rating: 4.0, count: 5),
        _provider(rating: 0, count: 0),
      ]);
      expect(result!.average, 4.0);
      expect(result.totalCount, 5);
    });
  });
}
