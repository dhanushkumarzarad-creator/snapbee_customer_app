/// The result of the map location picker: a real coordinate the user
/// confirmed on the map, plus the address text for that point (reverse-
/// geocoded, then optionally edited by the user). Never fabricated — the
/// coordinate always comes from device GPS, a Nominatim search hit, or a
/// deliberate map drag.
class PickedLocation {
  final double latitude;
  final double longitude;

  /// Human address. May be the reverse-geocoded string, the user's edited
  /// version of it, or empty if geocoding was unavailable and the user
  /// typed nothing.
  final String address;

  const PickedLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}
