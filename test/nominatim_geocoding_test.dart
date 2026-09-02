import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:snapbee_customer_app/core/map/geocoding_service.dart';

/// Unit coverage for [NominatimGeocodingService] — response parsing, empty
/// results, and every failure mode mapping to a typed [GeocodingException].
/// Uses http's MockClient; no real network.
void main() {
  group('NominatimGeocodingService.search', () {
    test('parses a jsonv2 result array into GeoPlace list', () async {
      final svc = NominatimGeocodingService(
        client: MockClient((req) async {
          expect(req.url.host, 'nominatim.openstreetmap.org');
          expect(req.url.path, '/search');
          expect(req.url.queryParameters['q'], 'MG Road');
          expect(req.headers['User-Agent'], isNotEmpty);
          return http.Response(
            '[{"lat":"12.9747","lon":"77.6094","display_name":"MG Road, Bengaluru"},'
            '{"lat":"18.9256","lon":"72.8311","display_name":"MG Road, Mumbai"}]',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final results = await svc.search('MG Road');

      expect(results, hasLength(2));
      expect(results.first.label, 'MG Road, Bengaluru');
      expect(results.first.lat, closeTo(12.9747, 1e-6));
      expect(results.first.lng, closeTo(77.6094, 1e-6));
    });

    test('empty query returns [] without hitting the network', () async {
      var called = false;
      final svc = NominatimGeocodingService(
        client: MockClient((_) async {
          called = true;
          return http.Response('[]', 200);
        }),
      );
      expect(await svc.search('   '), isEmpty);
      expect(called, isFalse);
    });

    test('empty result array is a normal no-matches state, not an error', () async {
      final svc = NominatimGeocodingService(
        client: MockClient((_) async => http.Response('[]', 200)),
      );
      expect(await svc.search('zzzznowhere'), isEmpty);
    });

    test('skips malformed rows (missing lat/lon/name)', () async {
      final svc = NominatimGeocodingService(
        client: MockClient((_) async => http.Response(
              '[{"lat":"1.0","lon":"2.0","display_name":"Good"},'
              '{"lon":"2.0","display_name":"No lat"},'
              '{"lat":"1.0","lon":"2.0"}]',
              200,
            )),
      );
      final r = await svc.search('x');
      expect(r, hasLength(1));
      expect(r.single.label, 'Good');
    });

    test('non-200 throws GeocodingException', () async {
      final svc = NominatimGeocodingService(
        client: MockClient((_) async => http.Response('rate limited', 429)),
      );
      expect(() => svc.search('x'), throwsA(isA<GeocodingException>()));
    });

    test('transport failure throws GeocodingException', () async {
      final svc = NominatimGeocodingService(
        client: MockClient((_) async => throw const _NetDown()),
      );
      expect(() => svc.search('x'), throwsA(isA<GeocodingException>()));
    });

    test('invalid JSON body yields [] rather than a crash', () async {
      final svc = NominatimGeocodingService(
        client: MockClient((_) async => http.Response('<html>oops</html>', 200)),
      );
      expect(await svc.search('x'), isEmpty);
    });
  });

  group('NominatimGeocodingService.reverse', () {
    test('returns display_name for a coordinate', () async {
      final svc = NominatimGeocodingService(
        client: MockClient((req) async {
          expect(req.url.path, '/reverse');
          expect(req.url.queryParameters['lat'], '12.9747');
          expect(req.url.queryParameters['lon'], '77.6094');
          return http.Response('{"display_name":"12, MG Road, Bengaluru 560001"}', 200);
        }),
      );
      expect(await svc.reverse(12.9747, 77.6094), '12, MG Road, Bengaluru 560001');
    });

    test('missing display_name returns null', () async {
      final svc = NominatimGeocodingService(
        client: MockClient((_) async => http.Response('{"error":"Unable to geocode"}', 200)),
      );
      expect(await svc.reverse(0, 0), isNull);
    });

    test('non-200 throws GeocodingException', () async {
      final svc = NominatimGeocodingService(
        client: MockClient((_) async => http.Response('', 500)),
      );
      expect(() => svc.reverse(1, 1), throwsA(isA<GeocodingException>()));
    });
  });
}

class _NetDown implements Exception {
  const _NetDown();
}
