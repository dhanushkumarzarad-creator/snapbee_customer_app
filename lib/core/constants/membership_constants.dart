// ============================================================================
// membership_constants.dart
// ----------------------------------------------------------------------------
// The completed-orders thresholds that define each SnapBee Club tier. These
// are the APPROVED order-based membership tiers shown across the customer-app
// reference designs (SnapBee Club + Membership Club Card):
//
//   Bronze    — starting / default tier (0 – 9 completed orders)
//   Silver    — 10 completed orders     (10 – 49)
//   Gold      — 50 completed orders     (50 – 199)
//   Platinum  — 200 completed orders    (200+)
//
// Only completed orders count; cancelled / refunded / failed orders do not.
// Tier upgrades happen automatically once the threshold is reached and are
// never lost once earned. The app uses these numbers to render "progress to
// next tier" without a round trip.
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
  static const int silverMin = 10;
  static const int goldMin = 50;
  static const int platinumMin = 200;

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
