// ============================================================================
// catalog_coverage_filter.dart — browse-time "hide out-of-coverage vendors"
// gate, shared by the Daily Essentials product repository and the Services
// catalog repository.
// ----------------------------------------------------------------------------
// Given a list of rows that each carry a vendor id, drop the ones the
// browsing customer is not allowed to see, per the vendor's configured
// coverage mode (india / state / district / radius). All four modes are
// evaluated SERVER-SIDE by the coverage RPC — this class only:
//   1. asks [CustomerCoverageContext] for the customer's location signal,
//   2. asks the RPC (via [_lookup]) for the covered id set for that signal,
//   3. keeps rows whose vendor id is in that set.
//
// Fail-OPEN (returns the list unchanged) when:
//   - the customer has no usable location signal (permission denied / off /
//     under `flutter test`) — nothing to evaluate against; or
//   - the RPC isn't deployed yet ([_lookup] returns null).
// A real empty covered set is honoured: every vendor row is dropped. The
// existing server-side checkout coverage check stays the hard gate either
// way.
// ============================================================================

import '../../core/location/customer_coverage_context.dart';
import 'coverage_repository.dart';

/// Looks up the covered vendor-id set for a customer location signal.
/// Returns null when the backing RPC is not deployed (fail-open marker).
typedef CoveredIdLookup = Future<Set<String>?> Function(CoverageSignal signal);

class CatalogCoverageFilter {
  CatalogCoverageFilter(
    this._lookup, {
    CustomerCoverageContext? context,
  }) : _context = context ?? CustomerCoverageContext.instance;

  /// Daily Essentials wiring: `vendor_ids_in_coverage`.
  factory CatalogCoverageFilter.forVendors(
    CoverageRepository coverage, {
    CustomerCoverageContext? context,
  }) {
    return CatalogCoverageFilter(
      (s) => coverage.fetchCoveredVendorIds(
        lat: s.lat,
        lng: s.lng,
        state: s.state,
        district: s.district,
      ),
      context: context,
    );
  }

  /// Services wiring: `service_vendor_ids_in_coverage`.
  factory CatalogCoverageFilter.forServiceVendors(
    CoverageRepository coverage, {
    CustomerCoverageContext? context,
  }) {
    return CatalogCoverageFilter(
      (s) => coverage.fetchCoveredServiceVendorIds(
        lat: s.lat,
        lng: s.lng,
        state: s.state,
        district: s.district,
        pincode: s.pincode,
      ),
      context: context,
    );
  }

  final CoveredIdLookup _lookup;
  final CustomerCoverageContext _context;

  /// Filters [rows] to the vendors the browsing customer may see.
  /// [vendorIdOf] extracts a row's vendor id; a row whose id is empty is
  /// kept (coverage can't be evaluated for it — and checkout still blocks a
  /// vendorless product on its own).
  Future<List<T>> apply<T>(
    List<T> rows,
    String Function(T row) vendorIdOf,
  ) async {
    if (rows.isEmpty) return rows;

    final signal = await _context.resolve();
    if (signal.isEmpty) return rows; // no location -> cannot evaluate

    final Set<String>? covered;
    try {
      covered = await _lookup(signal);
    } catch (_) {
      // Any transport error resolving coverage must not blank a listing.
      return rows;
    }
    if (covered == null) return rows; // RPC not deployed -> fail open

    return [
      for (final row in rows)
        if (vendorIdOf(row).isEmpty || covered.contains(vendorIdOf(row))) row,
    ];
  }
}
