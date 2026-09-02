import 'package:flutter_test/flutter_test.dart';
import 'package:snapbee_customer_app/core/location/customer_coverage_context.dart';
import 'package:snapbee_customer_app/core/location/location_service.dart';
import 'package:snapbee_customer_app/core/map/geocoding_service.dart';

class _FakeLocationService implements LocationService {
  _FakeLocationService({this.fix, this.error});

  LocationResult? fix;
  LocationException? error;
  int calls = 0;

  @override
  Future<LocationResult> getCurrentLocation() async {
    calls++;
    if (error != null) throw error!;
    return fix ?? const LocationResult(latitude: 0, longitude: 0);
  }
}

class _FakeGeocoding implements GeocodingService {
  _FakeGeocoding({this.detailed, this.throwOnReverse = false});

  GeoAddress? detailed;
  bool throwOnReverse;
  int reverseCalls = 0;

  @override
  Future<List<GeoPlace>> search(String query, {int limit = 6}) async => const [];

  @override
  Future<String?> reverse(double lat, double lng) async =>
      (await reverseDetailed(lat, lng)).displayName;

  @override
  Future<GeoAddress> reverseDetailed(double lat, double lng) async {
    reverseCalls++;
    if (throwOnReverse) {
      throw const GeocodingException('Address lookup is unavailable right now.');
    }
    return detailed ?? const GeoAddress();
  }
}

void main() {
  test('fails open with an empty signal when the device has no location', () async {
    final loc = _FakeLocationService(
      error: const LocationException('Location permission is required.'),
    );
    final geo = _FakeGeocoding();
    final ctx = CustomerCoverageContext(locationService: loc, geocoding: geo);

    final signal = await ctx.resolve();

    expect(signal.isEmpty, isTrue);
    expect(signal.lat, isNull);
    expect(geo.reverseCalls, 0, reason: 'no fix -> no reverse geocode');
  });

  test('returns lat/lng plus reverse-geocoded state/district/pincode', () async {
    final loc = _FakeLocationService(
      fix: const LocationResult(latitude: 12.9747, longitude: 77.6094),
    );
    final geo = _FakeGeocoding(
      detailed: const GeoAddress(
        displayName: 'MG Road, Bengaluru',
        state: 'Karnataka',
        district: 'Bengaluru Urban',
        pincode: '560001',
      ),
    );
    final ctx = CustomerCoverageContext(locationService: loc, geocoding: geo);

    final signal = await ctx.resolve();

    expect(signal.lat, closeTo(12.9747, 1e-6));
    expect(signal.lng, closeTo(77.6094, 1e-6));
    expect(signal.state, 'Karnataka');
    expect(signal.district, 'Bengaluru Urban');
    expect(signal.pincode, '560001');
    expect(signal.isEmpty, isFalse);
  });

  test('a reverse-geocode failure still yields the bare coordinate', () async {
    final loc = _FakeLocationService(
      fix: const LocationResult(latitude: 19.0760, longitude: 72.8777),
    );
    final ctx = CustomerCoverageContext(
      locationService: loc,
      geocoding: _FakeGeocoding(throwOnReverse: true),
    );

    final signal = await ctx.resolve();

    expect(signal.hasGeo, isTrue);
    expect(signal.lat, closeTo(19.0760, 1e-6));
    expect(signal.state, isNull);
    expect(signal.district, isNull);
  });

  test('caches the fix — a second resolve() does not re-hit the device', () async {
    final loc = _FakeLocationService(
      fix: const LocationResult(latitude: 1, longitude: 2),
    );
    final ctx = CustomerCoverageContext(locationService: loc, geocoding: _FakeGeocoding());

    await ctx.resolve();
    await ctx.resolve();

    expect(loc.calls, 1);
  });

  test('concurrent resolve() calls share a single acquisition', () async {
    final loc = _FakeLocationService(
      fix: const LocationResult(latitude: 1, longitude: 2),
    );
    final ctx = CustomerCoverageContext(locationService: loc, geocoding: _FakeGeocoding());

    await Future.wait([ctx.resolve(), ctx.resolve(), ctx.resolve()]);

    expect(loc.calls, 1);
  });

  test('refresh() drops the cache and re-acquires', () async {
    final loc = _FakeLocationService(
      fix: const LocationResult(latitude: 1, longitude: 2),
    );
    final ctx = CustomerCoverageContext(locationService: loc, geocoding: _FakeGeocoding());

    await ctx.resolve();
    await ctx.refresh();

    expect(loc.calls, 2);
  });
}
