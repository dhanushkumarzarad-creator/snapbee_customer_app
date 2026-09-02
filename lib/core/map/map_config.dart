// ============================================================================
// map_config.dart — the ONE place the map/geocoding providers are configured.
// ----------------------------------------------------------------------------
// SnapBee uses OpenStreetMap: free raster tiles + the Nominatim geocoder.
// There is no API key and no paid service. To move to a self-hosted or
// commercial OSM stack later, change the constants here only — no screen,
// widget or repository imports a provider URL directly.
//
// OSM tile-usage policy (https://operations.osmfoundation.org/policies/tiles/)
// and the Nominatim usage policy both require an identifying User-Agent and
// forbid heavy / bulk / per-keystroke use. This app honours that: tiles are
// the standard OSM raster server, geocoding runs only on an explicit search
// submit or a debounced map-idle reverse lookup, never on every keystroke.
// ============================================================================

/// Provider-agnostic map configuration. Swap any field for a self-hosted OSM
/// deployment without touching UI code.
class MapConfig {
  const MapConfig._();

  /// Raster XYZ tile template. Standard OpenStreetMap server. For scale,
  /// point this at your own tile server or a commercial OSM tile provider —
  /// nothing else changes.
  static const String tileUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Shown as required attribution on every rendered map.
  static const String tileAttribution = '© OpenStreetMap contributors';

  static const String tileAttributionUrl = 'https://www.openstreetmap.org/copyright';

  static const double tileMaxZoom = 19;

  /// Nominatim base URL (OSM's geocoder). Self-host or use a paid mirror for
  /// production traffic — the [NominatimGeocodingService] only appends
  /// `/search` and `/reverse`.
  static const String nominatimBaseUrl = 'https://nominatim.openstreetmap.org';

  /// Sent as `User-Agent` to both the tile server and Nominatim, as their
  /// usage policies require. This is an identifier, NOT a secret or key.
  static const String userAgent = 'SnapBeeCustomerApp/1.0 (+https://snapbee.app)';

  /// `userAgentPackageName` for flutter_map's [TileLayer].
  static const String tilePackageName = 'app.snapbee.customer';

  /// Neutral starting view (approx. centre of India) used ONLY before a real
  /// device location or a picked point is available. Never persisted, never
  /// sent anywhere, never treated as a real customer location.
  static const double fallbackLat = 20.5937;
  static const double fallbackLng = 78.9629;
  static const double fallbackZoom = 4;

  /// Zoom the picker snaps to once it has a concrete point.
  static const double focusZoom = 16.5;
}
