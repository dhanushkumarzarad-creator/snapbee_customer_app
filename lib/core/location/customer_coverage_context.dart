// ============================================================================
// customer_coverage_context.dart — the ONE browse-time customer location
// signal used to filter out-of-coverage vendors / products / service
// providers before they are ever shown (home, category, list, search).
// ----------------------------------------------------------------------------
// Reuses the EXISTING infrastructure only:
//   - device GPS via [LocationService] (geolocator) — the same wrapper
//     checkout already uses for `place_customer_order`;
//   - reverse geocoding via the [GeocodingService] abstraction (Nominatim)
//     — the same hardened service the map picker uses, to turn the fix into
//     a state / district for the `state` / `district` coverage modes.
// No new location stack, no map-provider change, no API key.
//
// It NEVER throws. When the device has no usable location (permission
// denied, services off, running under `flutter test`), `resolve()` returns
// an empty [CoverageSignal] and callers fail OPEN — browse listings are
// shown unfiltered and the existing server-side checkout coverage check
// (`compute_delivery_quote` / `place_customer_order`) stays the hard gate.
// A real fix, once obtained, is cached process-wide for [ttl] so every
// screen shares one GPS acquisition + one reverse-geocode.
// ============================================================================

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../map/geocoding_service.dart';
import 'location_service.dart';

/// The customer's browse-time location, in the shape the coverage RPCs
/// (`vendor_ids_in_coverage` / `service_vendor_ids_in_coverage`) expect.
/// Any field may be null.
@immutable
class CoverageSignal {
  final double? lat;
  final double? lng;
  final String? state;
  final String? district;
  final String? pincode;

  const CoverageSignal({
    this.lat,
    this.lng,
    this.state,
    this.district,
    this.pincode,
  });

  static const empty = CoverageSignal();

  bool get hasGeo => lat != null && lng != null;

  /// True when there is nothing to filter by at all — callers treat this as
  /// "cannot evaluate coverage, show everything".
  bool get isEmpty =>
      lat == null &&
      lng == null &&
      (state == null || state!.trim().isEmpty) &&
      (district == null || district!.trim().isEmpty) &&
      (pincode == null || pincode!.trim().isEmpty);
}

class CustomerCoverageContext {
  CustomerCoverageContext({
    LocationService? locationService,
    GeocodingService? geocoding,
    this.ttl = const Duration(minutes: 15),
  })  : _location = locationService ?? LocationService(),
        _geocoding = geocoding ?? NominatimGeocodingService();

  /// Process-wide shared instance the repositories read. Overridable in tests
  /// via [debugOverrideInstance] / [debugReset].
  static CustomerCoverageContext instance = CustomerCoverageContext();

  @visibleForTesting
  static void debugOverrideInstance(CustomerCoverageContext value) =>
      instance = value;

  @visibleForTesting
  static void debugReset() => instance = CustomerCoverageContext();

  final LocationService _location;
  final GeocodingService _geocoding;
  final Duration ttl;

  CoverageSignal? _cached;
  DateTime _cachedAt = DateTime.fromMillisecondsSinceEpoch(0);
  Future<CoverageSignal>? _inFlight;

  bool get _fresh =>
      _cached != null && DateTime.now().difference(_cachedAt) < ttl;

  /// The current signal — cached fix if fresh, otherwise one acquisition
  /// shared by all concurrent callers. Never throws.
  Future<CoverageSignal> resolve() {
    if (_fresh) return Future.value(_cached);
    final pending = _inFlight;
    if (pending != null) return pending;

    final future = _acquire();
    _inFlight = future;
    future.whenComplete(() {
      if (identical(_inFlight, future)) _inFlight = null;
    });
    return future;
  }

  /// Drop the cache and re-acquire from the device now (e.g. the customer
  /// tapped a "use my location" affordance).
  Future<CoverageSignal> refresh() {
    _cached = null;
    _inFlight = null;
    return resolve();
  }

  Future<CoverageSignal> _acquire() async {
    CoverageSignal signal = CoverageSignal.empty;
    try {
      final fix = await _location.getCurrentLocation();
      signal = CoverageSignal(lat: fix.latitude, lng: fix.longitude);
      try {
        final addr =
            await _geocoding.reverseDetailed(fix.latitude, fix.longitude);
        signal = CoverageSignal(
          lat: fix.latitude,
          lng: fix.longitude,
          state: _clean(addr.state),
          district: _clean(addr.district),
          pincode: _clean(addr.pincode),
        );
      } catch (_) {
        // Reverse geocode is best-effort — a bare coordinate still drives
        // the `radius` coverage mode.
      }
    } catch (_) {
      // No device location available — fail open.
      signal = CoverageSignal.empty;
    }
    _cached = signal;
    _cachedAt = DateTime.now();
    return signal;
  }

  static String? _clean(String? v) {
    final t = v?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }
}
