import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapbee_customer_app/data/repositories/offer_repository.dart';
import 'package:snapbee_customer_app/screens/offers/offer_models.dart';
import 'package:snapbee_customer_app/screens/offers/offers_screen.dart';

class _FakeOfferSource implements OfferSource {
  _FakeOfferSource({this.banners = const [], this.offers = const [], this.coupons = const []});

  final List<OfferBannerModel> banners;
  final List<SpecialOfferProduct> offers;
  final List<QuickOfferModel> coupons;

  @override
  Future<List<OfferBannerModel>> fetchHeroBanners({int limit = 6}) async => banners;

  @override
  Future<List<SpecialOfferProduct>> fetchSpecialOffers({int limit = 12}) async => offers;

  @override
  Future<List<QuickOfferModel>> fetchCoupons({int limit = 10}) async => coupons;
}

void main() {
  testWidgets('renders coupon + special-offer sections from live data', (tester) async {
    final source = _FakeOfferSource(
      banners: const [
        OfferBannerModel(id: 'b1', imageUrl: 'https://example.com/b.png', title: 'Big Sale'),
      ],
      offers: const [
        SpecialOfferProduct(
          id: 'p1',
          name: 'Discounted Rice',
          imageUrl: '',
          offerPrice: 80,
          oldPrice: 100,
          vendorId: 'v1',
          unit: 'kg',
        ),
      ],
      coupons: const [
        QuickOfferModel(id: 'c1', title: 'SAVE10', tagText: '10% OFF', iconAsset: ''),
      ],
    );

    await tester.pumpWidget(MaterialApp(home: OfferZoneScreen(repository: source)));
    await tester.pumpAndSettle();

    expect(find.text('Discounted Rice'), findsOneWidget);
    expect(find.text('No offers right now'), findsNothing);

    // The premium redesign adds a hero card above the feed, so the Coupons
    // section can start below the test viewport's fold — scroll it in first.
    await tester.scrollUntilVisible(
      find.text('Coupons'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Coupons'), findsOneWidget);
    expect(find.text('SAVE10'), findsOneWidget);
  });

  testWidgets('shows the honest empty state when the backend has no offers', (tester) async {
    await tester.pumpWidget(MaterialApp(home: OfferZoneScreen(repository: _FakeOfferSource())));
    await tester.pumpAndSettle();

    expect(find.text('No offers right now'), findsOneWidget);
  });
}
