import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:snapbee_customer_app/core/location/location_service.dart';

/// Fakes the platform channel `geolocator` talks to, so
/// [LocationService] can be exercised without a real device/browser GPS —
/// same technique already used for `image_picker` in the sibling
/// snapbee_vendor app's delivery-evidence tests.
class _FakeGeolocatorPlatform extends GeolocatorPlatform
    with MockPlatformInterfaceMixin {
  bool serviceEnabled = true;
  LocationPermission permission = LocationPermission.denied;
  LocationPermission? permissionAfterRequest;
  Position? position;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async {
    permission = permissionAfterRequest ?? permission;
    return permission;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    final result = position;
    if (result == null) {
      throw Exception('no fake position configured');
    }
    return result;
  }
}

Position _fakePosition({double lat = 12.9716, double lng = 77.5946}) {
  return Position(
    latitude: lat,
    longitude: lng,
    timestamp: DateTime(2026, 1, 1),
    accuracy: 5,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}

void main() {
  late _FakeGeolocatorPlatform fake;
  late GeolocatorPlatform original;

  setUp(() {
    original = GeolocatorPlatform.instance;
    fake = _FakeGeolocatorPlatform();
    GeolocatorPlatform.instance = fake;
  });

  tearDown(() {
    GeolocatorPlatform.instance = original;
  });

  group('LocationService', () {
    test('throws a friendly message when location services are off', () async {
      fake.serviceEnabled = false;

      expect(
        () => LocationService().getCurrentLocation(),
        throwsA(
          isA<LocationException>().having(
            (e) => e.message,
            'message',
            contains('location services'),
          ),
        ),
      );
    });

    test('requests permission when initially denied, then proceeds once granted', () async {
      fake.serviceEnabled = true;
      fake.permission = LocationPermission.denied;
      fake.permissionAfterRequest = LocationPermission.whileInUse;
      fake.position = _fakePosition(lat: 13.0, lng: 77.6);

      final result = await LocationService().getCurrentLocation();

      expect(result.latitude, 13.0);
      expect(result.longitude, 77.6);
    });

    test('throws a friendly message when permission stays denied after requesting', () async {
      fake.serviceEnabled = true;
      fake.permission = LocationPermission.denied;
      fake.permissionAfterRequest = LocationPermission.denied;

      expect(
        () => LocationService().getCurrentLocation(),
        throwsA(
          isA<LocationException>().having(
            (e) => e.message,
            'message',
            contains('permission is required'),
          ),
        ),
      );
    });

    test('throws a friendly message when permission is permanently denied', () async {
      fake.serviceEnabled = true;
      fake.permission = LocationPermission.deniedForever;

      expect(
        () => LocationService().getCurrentLocation(),
        throwsA(
          isA<LocationException>().having(
            (e) => e.message,
            'message',
            contains('permanently denied'),
          ),
        ),
      );
    });

    test('returns the real captured coordinates when already permitted', () async {
      fake.serviceEnabled = true;
      fake.permission = LocationPermission.always;
      fake.position = _fakePosition(lat: 28.6139, lng: 77.2090);

      final result = await LocationService().getCurrentLocation();

      expect(result.latitude, 28.6139);
      expect(result.longitude, 77.2090);
    });
  });
}
