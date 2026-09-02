// Browse-time coverage filtering — the customer-app side of
// vendor_coverage_config.sql / services_coverage_config.sql.
//
// The four coverage modes (india / state / district / radius) are evaluated
// SERVER-SIDE by the RPC; here the RPC is represented by [_modeLookup], which
// reproduces each mode's decision so the test can prove the Dart filter
// keeps in-coverage vendors, hides out-of-coverage vendors, and fails open
// in the two safe cases (no location signal, RPC not deployed).

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:snapbee_customer_app/core/location/customer_coverage_context.dart';
import 'package:snapbee_customer_app/core/location/location_service.dart';
import 'package:snapbee_customer_app/core/map/geocoding_service.dart';
import 'package:snapbee_customer_app/data/repositories/catalog_coverage_filter.dart';

class _Row {
  const _Row(this.id, this.vendorId);
  final String id;
  final String vendorId;
}

const _vendorA = 'vendor-a';
const _vendorB = 'vendor-b';

// Bengaluru MG Road — the branch/area pin for the radius case.
const _branchLat = 12.9747;
const _branchLng = 77.6094;

double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLng = (lng2 - lng1) * math.pi / 180;
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(lat1 * math.pi / 180) *
          math.cos(lat2 * math.pi / 180) *
          math.pow(math.sin(dLng / 2), 2);
  return r * 2 * math.asin(math.sqrt(a));
}

/// Stand-in for the coverage RPC. Vendor A is configured with [mode];
/// vendor B is never in coverage (so it must always be filtered out).
CoveredIdLookup _modeLookup(String mode) {
  return (CoverageSignal s) async {
    final inCoverage = switch (mode) {
      'india' => true,
      'state' => (s.state ?? '').toLowerCase() == 'karnataka',
      'district' => (s.district ?? '').toLowerCase() == 'bengaluru urban',
      'radius' => s.hasGeo &&
          _haversineKm(_branchLat, _branchLng, s.lat!, s.lng!) <= 5.0,
      _ => false,
    };
    return {if (inCoverage) _vendorA};
  };
}

class _StubLocationService implements LocationService {
  _StubLocationService({this.fix, this.error});
  final LocationResult? fix;
  final LocationException? error;

  @override
  Future<LocationResult> getCurrentLocation() async {
    if (error != null) throw error!;
    return fix!;
  }
}

class _StubGeocoding implements GeocodingService {
  _StubGeocoding(this._address);
  final GeoAddress _address;

  @override
  Future<List<GeoPlace>> search(String query, {int limit = 6}) async => const [];
  @override
  Future<String?> reverse(double lat, double lng) async => _address.displayName;
  @override
  Future<GeoAddress> reverseDetailed(double lat, double lng) async => _address;
}

CustomerCoverageContext _contextAt({
  double? lat,
  double? lng,
  String? state,
  String? district,
  String? pincode,
  bool denied = false,
}) {
  return CustomerCoverageContext(
    locationService: denied
        ? _StubLocationService(error: const LocationException('denied'))
        : _StubLocationService(
            fix: LocationResult(latitude: lat ?? 0, longitude: lng ?? 0),
          ),
    geocoding: _StubGeocoding(GeoAddress(
      displayName: 'here',
      state: state,
      district: district,
      pincode: pincode,
    )),
  );
}

Future<List<String>> _visibleVendorIds(
  CatalogCoverageFilter filter,
) async {
  final rows = await filter.apply(
    const [_Row('p1', _vendorA), _Row('p2', _vendorB)],
    (r) => r.vendorId,
  );
  return rows.map((r) => r.vendorId).toList();
}

void main() {
  group('india coverage', () {
    test('vendor is visible even far from any branch', () async {
      final filter = CatalogCoverageFilter(
        _modeLookup('india'),
        context: _contextAt(lat: 28.6139, lng: 77.2090), // New Delhi
      );
      expect(await _visibleVendorIds(filter), [_vendorA]); // B still hidden
    });
  });

  group('state coverage', () {
    test('visible for a customer in the serviced state', () async {
      final filter = CatalogCoverageFilter(
        _modeLookup('state'),
        context: _contextAt(lat: 12.97, lng: 77.59, state: 'Karnataka'),
      );
      expect(await _visibleVendorIds(filter), [_vendorA]);
    });

    test('hidden for a customer in a different state', () async {
      final filter = CatalogCoverageFilter(
        _modeLookup('state'),
        context: _contextAt(lat: 9.93, lng: 76.26, state: 'Kerala'),
      );
      expect(await _visibleVendorIds(filter), isEmpty);
    });
  });

  group('district coverage', () {
    test('visible for a customer in the serviced district', () async {
      final filter = CatalogCoverageFilter(
        _modeLookup('district'),
        context: _contextAt(
            lat: 12.97, lng: 77.59, district: 'Bengaluru Urban'),
      );
      expect(await _visibleVendorIds(filter), [_vendorA]);
    });

    test('hidden for a customer in a different district', () async {
      final filter = CatalogCoverageFilter(
        _modeLookup('district'),
        context: _contextAt(lat: 12.29, lng: 76.63, district: 'Mysuru'),
      );
      expect(await _visibleVendorIds(filter), isEmpty);
    });
  });

  group('radius coverage', () {
    test('visible for a customer inside the delivery radius', () async {
      final filter = CatalogCoverageFilter(
        _modeLookup('radius'),
        context: _contextAt(lat: 12.9900, lng: 77.6100), // ~1.7 km away
      );
      expect(await _visibleVendorIds(filter), [_vendorA]);
    });

    test('hidden for a customer outside the delivery radius', () async {
      final filter = CatalogCoverageFilter(
        _modeLookup('radius'),
        context: _contextAt(lat: 19.0760, lng: 72.8777), // Mumbai
      );
      expect(await _visibleVendorIds(filter), isEmpty);
    });
  });

  group('fail-open safety', () {
    test('no location signal -> list returned unchanged, RPC never called', () async {
      var lookupCalls = 0;
      final filter = CatalogCoverageFilter(
        (s) async {
          lookupCalls++;
          return <String>{};
        },
        context: _contextAt(denied: true),
      );
      expect(await _visibleVendorIds(filter), [_vendorA, _vendorB]);
      expect(lookupCalls, 0);
    });

    test('RPC not deployed (null) -> list returned unchanged', () async {
      final filter = CatalogCoverageFilter(
        (s) async => null,
        context: _contextAt(lat: 12.97, lng: 77.59),
      );
      expect(await _visibleVendorIds(filter), [_vendorA, _vendorB]);
    });

    test('a transport error resolving coverage -> list returned unchanged', () async {
      final filter = CatalogCoverageFilter(
        (s) async => throw StateError('boom'),
        context: _contextAt(lat: 12.97, lng: 77.59),
      );
      expect(await _visibleVendorIds(filter), [_vendorA, _vendorB]);
    });
  });

  group('strict filtering', () {
    test('a real empty covered set hides every vendor row', () async {
      final filter = CatalogCoverageFilter(
        (s) async => <String>{},
        context: _contextAt(lat: 12.97, lng: 77.59),
      );
      expect(await _visibleVendorIds(filter), isEmpty);
    });

    test('a row with no vendor id is always kept', () async {
      final filter = CatalogCoverageFilter(
        (s) async => <String>{},
        context: _contextAt(lat: 12.97, lng: 77.59),
      );
      final rows = await filter.apply(
        const [_Row('p1', ''), _Row('p2', _vendorA)],
        (r) => r.vendorId,
      );
      expect(rows.map((r) => r.id), ['p1']);
    });

    test('an empty input list is returned as-is', () async {
      final filter = CatalogCoverageFilter(
        (s) async => <String>{},
        context: _contextAt(lat: 1, lng: 1),
      );
      expect(await filter.apply(const <_Row>[], (r) => r.vendorId), isEmpty);
    });
  });
}
