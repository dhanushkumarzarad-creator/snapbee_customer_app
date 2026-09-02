// ============================================================================
// geocoding_service.dart — forward + reverse geocoding behind an interface.
// ----------------------------------------------------------------------------
// [GeocodingService] is the abstraction the picker (and the coverage
// resolver) depend on. The concrete [NominatimGeocodingService] talks to
// OSM's Nominatim over plain HTTPS with the User-Agent its usage policy
// requires (see map_config.dart). Swapping in a different provider (self-
// hosted Nominatim, Pelias, a paid geocoder) means writing one more
// implementation of this interface — no UI change.
//
// PRODUCTION HARDENING baked in here (Nominatim usage policy: <= 1 req/s,
// identify yourself, cache aggressively, never per-keystroke):
//   - one process-wide request LOCK + a >= 1100 ms min interval, so bursts
//     of concurrent lookups from different screens are serialised and
//     rate-limited below the policy ceiling;
//   - an in-memory time-boxed LRU cache for both search and reverse results;
//   - a hard per-request timeout;
//   - every failure mapped to a typed [GeocodingException] with a user-safe
//     message; an empty result list is a normal "no matches" state.
// The picker adds debounce on top (reverse only on map-idle, search only on
// explicit submit).
// ============================================================================

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'map_config.dart';

/// One geocoded place — enough to label it and move the map to it.
class GeoPlace {
  final String label;
  final double lat;
  final double lng;

  const GeoPlace({required this.label, required this.lat, required this.lng});
}

/// A reverse-geocoded address split into the parts the coverage model needs
/// (`state` / `district`) plus the full display string. Any field may be
/// null when Nominatim doesn't return it.
class GeoAddress {
  final String? displayName;
  final String? state;
  final String? district;
  final String? city;
  final String? pincode;

  const GeoAddress({
    this.displayName,
    this.state,
    this.district,
    this.city,
    this.pincode,
  });

  bool get isEmpty =>
      displayName == null &&
      state == null &&
      district == null &&
      city == null &&
      pincode == null;
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

  /// Reverse geocode a coordinate to a structured [GeoAddress] (state /
  /// district / city / pincode + display name).
  Future<GeoAddress> reverseDetailed(double lat, double lng);
}

/// Tiny time-boxed LRU. Only touched from the geocoding service's
/// single-flight code path, so it needs no locking of its own.
class _LruCache<V> {
  _LruCache({required this.maxEntries, required this.ttl});

  final int maxEntries;
  final Duration ttl;
  final _map = <String, _Entry<V>>{};

  V? get(String key) {
    final e = _map.remove(key);
    if (e == null) return null;
    if (DateTime.now().difference(e.storedAt) > ttl) return null;
    _map[key] = e; // re-insert as most-recently-used
    return e.value;
  }

  void put(String key, V value) {
    _map.remove(key);
    _map[key] = _Entry(value, DateTime.now());
    while (_map.length > maxEntries) {
      _map.remove(_map.keys.first);
    }
  }

  void clear() => _map.clear();
}

class _Entry<V> {
  _Entry(this.value, this.storedAt);
  final V value;
  final DateTime storedAt;
}

class NominatimGeocodingService implements GeocodingService {
  NominatimGeocodingService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  static const _timeout = Duration(seconds: 12);
  static const _minInterval = Duration(milliseconds: 1100); // Nominatim: <=1/s
  static const _headers = {
    'User-Agent': MapConfig.userAgent,
    'Accept': 'application/json',
  };

  // Process-wide so several screens can't collectively exceed the rate.
  static DateTime _lastRequestAt = DateTime.fromMillisecondsSinceEpoch(0);
  static Future<void> _gate = Future.value();

  static final _searchCache = _LruCache<List<GeoPlace>>(
      maxEntries: 120, ttl: const Duration(minutes: 10));
  static final _reverseCache = _LruCache<GeoAddress>(
      maxEntries: 120, ttl: const Duration(minutes: 30));

  /// Clears the process-wide caches and the shared rate-limit gate. Tests
  /// only — every other caller wants the caches to persist across instances.
  @visibleForTesting
  static void debugResetSharedState() {
    _searchCache.clear();
    _reverseCache.clear();
    _lastRequestAt = DateTime.fromMillisecondsSinceEpoch(0);
    _gate = Future.value();
  }

  /// Serialises callers and enforces the min interval between real requests.
  Future<http.Response> _rateLimitedGet(Uri uri) {
    final completer = Completer<http.Response>();
    _gate = _gate.then((_) async {
      final since = DateTime.now().difference(_lastRequestAt);
      if (since < _minInterval) {
        await Future<void>.delayed(_minInterval - since);
      }
      try {
        final res = await _client.get(uri, headers: _headers).timeout(_timeout);
        _lastRequestAt = DateTime.now();
        completer.complete(res);
      } catch (e, st) {
        _lastRequestAt = DateTime.now();
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  @override
  Future<List<GeoPlace>> search(String query, {int limit = 6}) async {
    final q = query.trim();
    if (q.isEmpty) return const [];

    final cacheKey = 'q=${q.toLowerCase()}&n=$limit';
    final cached = _searchCache.get(cacheKey);
    if (cached != null) return cached;

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
      res = await _rateLimitedGet(uri);
    } on TimeoutException {
      throw const GeocodingException(
          'Location search timed out. Check your connection and try again.');
    } catch (_) {
      throw const GeocodingException(
          'Could not reach the location search service.');
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
    _searchCache.put(cacheKey, places);
    return places;
  }

  @override
  Future<String?> reverse(double lat, double lng) async =>
      (await reverseDetailed(lat, lng)).displayName;

  @override
  Future<GeoAddress> reverseDetailed(double lat, double lng) async {
    // Round the cache key to ~11 m so tiny map jitter reuses one result.
    final cacheKey = '${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}';
    final cached = _reverseCache.get(cacheKey);
    if (cached != null) return cached;

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
      res = await _rateLimitedGet(uri);
    } on TimeoutException {
      throw const GeocodingException('Address lookup timed out.');
    } catch (_) {
      throw const GeocodingException(
          'Could not reach the address lookup service.');
    }

    if (res.statusCode != 200) {
      throw const GeocodingException('Address lookup is unavailable right now.');
    }

    final decoded = _decode(res.body);
    if (decoded is! Map) return const GeoAddress();

    final name = (decoded['display_name'] as String?)?.trim();
    final addr = decoded['address'];
    final result = GeoAddress(
      displayName: (name != null && name.isNotEmpty) ? name : null,
      state: _pick(addr, const ['state']),
      district: _pick(addr, const [
        'state_district',
        'county',
        'district',
        'city_district',
      ]),
      city: _pick(addr, const ['city', 'town', 'village', 'municipality']),
      pincode: _pick(addr, const ['postcode']),
    );
    _reverseCache.put(cacheKey, result);
    return result;
  }

  static String? _pick(Object? address, List<String> keys) {
    if (address is! Map) return null;
    for (final k in keys) {
      final v = address[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  static Object? _decode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }
}
