// The Offer Zone's special-offers list is a customer-facing product browse
// surface, so OfferRepository.fetchSpecialOffers routes its rows through the
// same shared CatalogCoverageFilter the rest of the catalogue uses
// (Home / category / list / search). The filter internals are covered by
// catalog_coverage_filter_test.dart; this pins the exact row type
// (SpecialOfferProduct) and vendor-id extractor OfferRepository passes in,
// plus the fail-open contract.

import 'package:flutter_test/flutter_test.dart';
import 'package:snapbee_customer_app/core/location/customer_coverage_context.dart';
import 'package:snapbee_customer_app/core/location/location_service.dart';
import 'package:snapbee_customer_app/core/map/geocoding_service.dart';
import 'package:snapbee_customer_app/data/repositories/catalog_coverage_filter.dart';
import 'package:snapbee_customer_app/screens/offers/offer_models.dart';

class _StubLocation implements LocationService {
  _StubLocation({this.fix, this.error});
  final LocationResult? fix;
  final LocationException? error;
  @override
  Future<LocationResult> getCurrentLocation() async {
    if (error != null) throw error!;
    return fix!;
  }
}

class _StubGeocoding implements GeocodingService {
  @override
  Future<List<GeoPlace>> search(String q, {int limit = 6}) async => const [];
  @override
  Future<String?> reverse(double lat, double lng) async => null;
  @override
  Future<GeoAddress> reverseDetailed(double lat, double lng) async =>
      const GeoAddress();
}

SpecialOfferProduct _offer(String id, String vendorId) => SpecialOfferProduct(
      id: id,
      name: id,
      imageUrl: '',
      offerPrice: 80,
      oldPrice: 100,
      vendorId: vendorId,
      unit: 'kg',
    );

CustomerCoverageContext _ctx({bool denied = false}) => CustomerCoverageContext(
      locationService: denied
          ? _StubLocation(error: const LocationException('denied'))
          : _StubLocation(
              fix: const LocationResult(latitude: 12.97, longitude: 77.59)),
      geocoding: _StubGeocoding(),
    );

const _rows = [
  SpecialOfferProduct(
      id: 'p-in',
      name: 'p-in',
      imageUrl: '',
      offerPrice: 80,
      oldPrice: 100,
      vendorId: 'vendor-in',
      unit: 'kg'),
  SpecialOfferProduct(
      id: 'p-out',
      name: 'p-out',
      imageUrl: '',
      offerPrice: 80,
      oldPrice: 100,
      vendorId: 'vendor-out',
      unit: 'kg'),
];

void main() {
  test('drops special offers whose vendor is outside coverage', () async {
    final filter = CatalogCoverageFilter(
      (s) async => {'vendor-in'},
      context: _ctx(),
    );
    final visible = await filter.apply(_rows, (p) => p.vendorId);
    expect(visible.map((p) => p.id), ['p-in']);
  });

  test('keeps every special offer when the RPC is not deployed (null)', () async {
    final filter = CatalogCoverageFilter((s) async => null, context: _ctx());
    final visible = await filter.apply(_rows, (p) => p.vendorId);
    expect(visible.map((p) => p.id), ['p-in', 'p-out']);
  });

  test('keeps every special offer when there is no location signal', () async {
    var lookupCalls = 0;
    final filter = CatalogCoverageFilter(
      (s) async {
        lookupCalls++;
        return <String>{};
      },
      context: _ctx(denied: true),
    );
    final visible = await filter.apply(_rows, (p) => p.vendorId);
    expect(visible.map((p) => p.id), ['p-in', 'p-out']);
    expect(lookupCalls, 0);
  });

  test('a special offer with no vendor id is always kept', () async {
    final filter = CatalogCoverageFilter((s) async => <String>{}, context: _ctx());
    final visible = await filter.apply(
      [_offer('free', ''), _offer('gated', 'vendor-out')],
      (p) => p.vendorId,
    );
    expect(visible.map((p) => p.id), ['free']);
  });
}
