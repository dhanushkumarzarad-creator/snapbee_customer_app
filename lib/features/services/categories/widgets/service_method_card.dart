import 'package:flutter/material.dart';

import '../../models/service_method.dart';
import '../../theme/service_colors.dart';

/// Customer-facing card for one bookable delivery method (NEW Services
/// Master Method architecture). Shows only customer-friendly information —
/// name, icon, short definition, price, duration, availability, relevant
/// charges, booking requirements — and never any internal QC / admin-review
/// / status / risk terminology (the RPC does not expose those and this
/// widget has nothing else to render).
///
/// An unavailable method is still shown (greyed, "Currently Unavailable",
/// not tappable) so the customer knows it exists and can come back — unless
/// it was hidden outright server-side (outside the method's own radius), in
/// which case this widget is simply never built for it.
class ServiceMethodCard extends StatelessWidget {
  final ServiceMethodRow method;

  /// Called only when [ServiceMethodRow.isAvailable] is true.
  final VoidCallback? onBook;

  const ServiceMethodCard({super.key, required this.method, this.onBook});

  static const Map<String, IconData> _iconByCode = {
    'store_pickup': Icons.storefront_outlined,
    'store_delivery': Icons.local_shipping_outlined,
    'appointment_booking': Icons.event_available_outlined,
    'home_visit': Icons.home_outlined,
    'instant_on_demand': Icons.bolt_outlined,
    'pickup_and_drop': Icons.sync_alt_outlined,
    'multi_step_workflow': Icons.account_tree_outlined,
    'subscription': Icons.autorenew_outlined,
    'lead_generation': Icons.contact_phone_outlined,
    'hybrid': Icons.dashboard_customize_outlined,
    'walk_in': Icons.directions_walk_outlined,
  };

  IconData get _icon => _iconByCode[method.methodCode] ?? Icons.build_outlined;

  @override
  Widget build(BuildContext context) {
    final available = method.isAvailable;
    final enabled = available && onBook != null;

    return Opacity(
      opacity: available ? 1 : 0.6,
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onBook : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: available ? ServiceColors.primaryBlueLight : ServiceColors.chipGrey,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _icon,
                        size: 20,
                        color: available ? ServiceColors.primaryBlue : ServiceColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            method.methodName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: ServiceColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          _AvailabilityPill(available: available, label: method.availabilityLabel),
                        ],
                      ),
                    ),
                    if (enabled) const Icon(Icons.chevron_right, color: ServiceColors.textSecondary),
                  ],
                ),
                if (method.definition.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    method.definition,
                    style: const TextStyle(fontSize: 12.5, color: ServiceColors.textSecondary, height: 1.35),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (method.priceLabel != null)
                      _MetaChip(icon: Icons.payments_outlined, label: method.priceLabel!),
                    if (method.durationLabel != null)
                      _MetaChip(icon: Icons.schedule, label: method.durationLabel!),
                    if (method.radiusKm != null)
                      _MetaChip(
                        icon: Icons.place_outlined,
                        label: 'Within ${method.radiusKm!.toStringAsFixed(0)} km',
                      ),
                    if (method.requiresStaff)
                      const _MetaChip(icon: Icons.engineering_outlined, label: 'Technician visit'),
                  ],
                ),
                if (method.hasBookingRequirements) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, size: 14, color: ServiceColors.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Before booking: ${method.bookingRequirementsText}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: ServiceColors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvailabilityPill extends StatelessWidget {
  final bool available;
  final String label;

  const _AvailabilityPill({required this.available, required this.label});

  @override
  Widget build(BuildContext context) {
    final Color fg = available ? ServiceColors.accentGreen : ServiceColors.accentRed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(available ? Icons.check_circle : Icons.pause_circle_filled, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ServiceColors.cardGrey,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: ServiceColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11.5, color: ServiceColors.textPrimary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
