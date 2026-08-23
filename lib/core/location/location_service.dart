import 'package:geolocator/geolocator.dart';

/// A real device-GPS coordinate pair — never fabricated. No geocoding/maps
/// API key exists anywhere in this monorepo, so this is deliberately just
/// raw coordinates, not a reverse-geocoded street address.
class LocationResult {
  final double latitude;
  final double longitude;

  const LocationResult({required this.latitude, required this.longitude});
}

/// Thrown for every real failure mode of capturing a device location —
/// checkout catches this and shows [message] directly, no raw platform
/// exception text leaking into the UI.
class LocationException implements Exception {
  final String message;
  const LocationException(this.message);

  @override
  String toString() => message;
}

/// Thin wrapper around `geolocator` — same package/version
/// snapbee_delivery already depends on for the same reason (a real
/// customer_lat/customer_lng is a hard requirement of
/// `compute_delivery_quote`/`place_customer_order`).
class LocationService {
  Future<LocationResult> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException(
        'Turn on location services to check delivery availability.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException(
        'Location permission is required to check delivery availability.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'Location permission is permanently denied. Enable it from your '
        'device settings to continue.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on LocationServiceDisabledException {
      throw const LocationException(
        'Turn on location services to check delivery availability.',
      );
    } catch (_) {
      throw const LocationException(
        'Could not detect your location. Please try again.',
      );
    }
  }
}
