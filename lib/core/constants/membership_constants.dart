// ============================================================================
// membership_constants.dart
// ----------------------------------------------------------------------------
// The completed-orders thresholds that define each membership tier. These
// mirror the thresholds baked into the `trg_customers_membership_tier`
// database trigger (see database/schema.sql) — the DB is the source of
// truth for the actual tier, but the app needs the same numbers to render
// "Progress to next membership" without a round trip.
// ============================================================================

enum MembershipTier { bronze, silver, gold, platinum }

extension MembershipTierX on MembershipTier {
  String get label {
    switch (this) {
      case MembershipTier.bronze:
        return 'Bronze';
      case MembershipTier.silver:
        return 'Silver';
      case MembershipTier.gold:
        return 'Gold';
      case MembershipTier.platinum:
        return 'Platinum';
    }
  }

  static MembershipTier fromString(String value) {
    switch (value.toLowerCase()) {
      case 'silver':
        return MembershipTier.silver;
      case 'gold':
        return MembershipTier.gold;
      case 'platinum':
        return MembershipTier.platinum;
      case 'bronze':
      default:
        return MembershipTier.bronze;
    }
  }
}

class MembershipThresholds {
  MembershipThresholds._();

  // Inclusive lower bound of completed orders required for each tier.
  static const int silverMin = 6;
  static const int goldMin = 26;
  static const int platinumMin = 101;

  static MembershipTier tierForCompletedOrders(int completedOrders) {
    if (completedOrders >= platinumMin) return MembershipTier.platinum;
    if (completedOrders >= goldMin) return MembershipTier.gold;
    if (completedOrders >= silverMin) return MembershipTier.silver;
    return MembershipTier.bronze;
  }

  /// Returns null when already at the highest tier (Platinum).
  static MembershipTier? nextTier(MembershipTier current) {
    switch (current) {
      case MembershipTier.bronze:
        return MembershipTier.silver;
      case MembershipTier.silver:
        return MembershipTier.gold;
      case MembershipTier.gold:
        return MembershipTier.platinum;
      case MembershipTier.platinum:
        return null;
    }
  }

  /// Orders still needed to reach the next tier; 0 when already Platinum.
  static int ordersToNextTier(int completedOrders) {
    final current = tierForCompletedOrders(completedOrders);
    switch (current) {
      case MembershipTier.bronze:
        return (silverMin - completedOrders).clamp(0, silverMin);
      case MembershipTier.silver:
        return (goldMin - completedOrders).clamp(0, goldMin);
      case MembershipTier.gold:
        return (platinumMin - completedOrders).clamp(0, platinumMin);
      case MembershipTier.platinum:
        return 0;
    }
  }

  /// 0.0–1.0 progress within the current tier's band, for progress bars.
  static double progressWithinTier(int completedOrders) {
    final current = tierForCompletedOrders(completedOrders);
    late final int bandStart;
    late final int bandEnd;
    switch (current) {
      case MembershipTier.bronze:
        bandStart = 0;
        bandEnd = silverMin;
        break;
      case MembershipTier.silver:
        bandStart = silverMin;
        bandEnd = goldMin;
        break;
      case MembershipTier.gold:
        bandStart = goldMin;
        bandEnd = platinumMin;
        break;
      case MembershipTier.platinum:
        return 1.0;
    }
    final span = (bandEnd - bandStart).toDouble();
    final progress = (completedOrders - bandStart).toDouble();
    return (progress / span).clamp(0.0, 1.0);
  }
}
