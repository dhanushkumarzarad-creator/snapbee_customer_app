import 'dart:math';

/// A per-attempt idempotency key for booking-creation RPCs (Travel trip/
/// hotel, Entertainment event/park). Generate ONCE when a booking attempt
/// starts (e.g. in `initState`, not inside the submit handler) and reuse
/// the SAME value if the call is retried after a timeout — the backend
/// RPC returns the already-created booking instead of creating a
/// duplicate. Never reuse a key across two different booking intents.
String generateIdempotencyKey() {
  final rand = Random.secure();
  final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
