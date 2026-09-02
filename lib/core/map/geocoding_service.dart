// ============================================================================
// geocoding_service.dart — forward + reverse geocoding behind an interface.
// ----------------------------------------------------------------------------
// [GeocodingService] is the abstraction the picker depends on. The concrete
// [NominatimGeocodingService] talks to OSM's Nominatim over plain HTTPS with
// the User-Agent its usage policy requires (see map_config.dart). Swapping in
// a different provider (self-hosted Nominatim, Pelias, a paid geocoder) means
// writing one more implementation of this interface — no UI change.
//
// Every real failure mode maps to a typed [GeocodingException] with a
// user-safe message; the picker shows that and stays usable (the map still
// works without geocoding). An empty result list is a normal "no matches"
// state, never an error.
// ============================================================================

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'map_config.dart';

/// One geocoded place — enough to label it and move the map to it.
class GeoPlace {
  final String label;
  final double lat;
  final double lng;

  const GeoPlace({required this.label, required this.lat, required this.lng});
}

class GeocodingException implements Exception {
  final String message;
  const GeocodingException(this.message);
  @override
  String toString() => message;
}

abstract class GeocodingService {
  /// Free-text place search. Returns `[]` for no matches (not an error).
  Future<List<GeoPlace>> search(String query, {int limit = 6});

  /// Reverse geocode a coordinate to a human address string, or `null` if
  /// the provider has nothing for that point.
  Future<String?> reverse(double lat, double lng);
}

class NominatimGeocodingService implements GeocodingService {
  NominatimGeocodingService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  static const _timeout = Duration(seconds: 12);
  static const _headers = {
    'User-Agent': MapConfig.userAgent,
    'Accept': 'application/json',
  };

  @override
  Future<List<GeoPlace>> search(String query, {int limit = 6}) async {
    final q = query.trim();
    if (q.isEmpty) return const [];

    final uri = Uri.parse('${MapConfig.nominatimBaseUrl}/search').replace(
      queryParameters: {
        'q': q,
        'format': 'jsonv2',
        'addressdetails': '1',
        'limit': '$limit',
      },
    );

    final http.Response res;
    try {
      res = await _client.get(uri, headers: _headers).timeout(_timeout);
    } on TimeoutException {
      throw const GeocodingException('Location search timed out. Check your connection and try again.');
    } catch (_) {
      throw const GeocodingException('Could not reach the location search service.');
    }

    if (res.statusCode != 200) {
      throw const GeocodingException('Location search is unavailable right now.');
    }

    final decoded = _decode(res.body);
    if (decoded is! List) return const [];

    final places = <GeoPlace>[];
    for (final item in decoded) {
      if (item is! Map) continue;
      final lat = double.tryParse('${item['lat']}');
      final lon = double.tryParse('${item['lon']}');
      final name = (item['display_name'] as String?)?.trim();
      if (lat == null || lon == null || name == null || name.isEmpty) continue;
      places.add(GeoPlace(label: name, lat: lat, lng: lon));
    }
    return places;
  }

  @override
  Future<String?> reverse(double lat, double lng) async {
    final uri = Uri.parse('${MapConfig.nominatimBaseUrl}/reverse').replace(
      queryParameters: {
        'lat': '$lat',
        'lon': '$lng',
        'format': 'jsonv2',
        'addressdetails': '1',
        'zoom': '18',
      },
    );

    final http.Response res;
    try {
      res = await _client.get(uri, headers: _headers).timeout(_timeout);
    } on TimeoutException {
      throw const GeocodingException('Address lookup timed out.');
    } catch (_) {
      throw const GeocodingException('Could not reach the address lookup service.');
    }

    if (res.statusCode != 200) {
      throw const GeocodingException('Address lookup is unavailable right now.');
    }

    final decoded = _decode(res.body);
    if (decoded is! Map) return null;
    final name = (decoded['display_name'] as String?)?.trim();
    return (name != null && name.isNotEmpty) ? name : null;
  }

  static Object? _decode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }
}
