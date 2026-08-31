/// One `recurring_service_plans` row (services_module_v2.sql SECTION 15 +
/// supabase/recurring_service_plans_generator.sql for the address/slot
/// columns). Created / paused / cancelled straight through the existing
/// `recurring_service_plans_customer_self_*` RLS — no RPC. The Services
/// Admin "Generate due bookings" action turns due plans into real
/// bookings.
class RecurringServicePlan {
  final String id;
  final String serviceId;
  final String? serviceName;
  final String frequency; // weekly | biweekly | monthly | quarterly | custom
  final int? customIntervalDays;
  final bool isAmc;
  final DateTime nextRunDate;
  final String status; // active | paused | cancelled
  final String? preferredTimeSlot;

  const RecurringServicePlan({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.frequency,
    required this.customIntervalDays,
    required this.isAmc,
    required this.nextRunDate,
    required this.status,
    required this.preferredTimeSlot,
  });

  bool get isActive => status == 'active';
  bool get isPaused => status == 'paused';
  bool get isCancelled => status == 'cancelled';

  /// First run date for a plan started from a booking on [from]. Mirrors the
  /// `case p.frequency` interval math in
  /// `supabase/recurring_service_plans_generator.sql` so the app and the
  /// server agree on the cadence. Used by both the booking form and the
  /// "repeat this completed service" flow.
  static DateTime nextRunAfter(DateTime from, String frequency, {int? customIntervalDays}) {
    final d = DateTime(from.year, from.month, from.day);
    return switch (frequency) {
      'weekly' => d.add(const Duration(days: 7)),
      'biweekly' => d.add(const Duration(days: 14)),
      'quarterly' => DateTime(d.year, d.month + 3, d.day),
      'custom' => d.add(Duration(days: customIntervalDays ?? 30)),
      _ => DateTime(d.year, d.month + 1, d.day), // monthly (default)
    };
  }

  String get frequencyLabel => switch (frequency) {
        'weekly' => 'Every week',
        'biweekly' => 'Every 2 weeks',
        'monthly' => 'Every month',
        'quarterly' => 'Every 3 months',
        'custom' => 'Every ${customIntervalDays ?? '—'} days',
        _ => frequency,
      };

  factory RecurringServicePlan.fromJson(Map<String, dynamic> json) {
    final service = json['services'] as Map<String, dynamic>?;
    return RecurringServicePlan(
      id: json['id'] as String,
      serviceId: json['service_id'] as String,
      serviceName: service?['name'] as String?,
      frequency: json['frequency'] as String? ?? 'monthly',
      customIntervalDays: (json['custom_interval_days'] as num?)?.toInt(),
      isAmc: json['is_amc'] as bool? ?? false,
      nextRunDate: DateTime.parse(json['next_run_date'] as String),
      status: json['status'] as String? ?? 'active',
      preferredTimeSlot: json['preferred_time_slot'] as String?,
    );
  }
}
