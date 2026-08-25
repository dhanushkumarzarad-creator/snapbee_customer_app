import 'package:flutter/material.dart';

import '../models/service_booking.dart';

/// Read-only payment display — advance/remaining amounts and paid status.
/// Deliberately no "I've paid" button here: cash-collection confirmation is
/// a technician action (`record_service_payment`, called from
/// snapbee_services_technician), not a customer self-report, so this widget
/// never fabricates a payment action this app can't actually perform.
class PaymentSummaryWidget extends StatelessWidget {
  final ServiceBookingRow booking;

  const PaymentSummaryWidget({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Payment', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            _row('Advance (${booking.advancePercent.toStringAsFixed(0)}%)', booking.advanceAmount, booking.advancePaid),
            if (booking.isEmergency && booking.emergencyCharge > 0) ...[
              const SizedBox(height: 6),
              _plainRow('Emergency charge', booking.emergencyCharge),
            ],
            if (booking.remainingAmount > 0) ...[
              const SizedBox(height: 6),
              _row('Remaining balance', booking.remainingAmount, booking.remainingPaid),
            ],
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Status: ', style: TextStyle(color: Colors.grey)),
                Text(
                  booking.paymentStatus[0].toUpperCase() + booking.paymentStatus.substring(1),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Cash collected by your technician on-site.', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, double amount, bool paid) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text('₹${amount.toStringAsFixed(0)}'),
        const SizedBox(width: 8),
        Icon(paid ? Icons.check_circle : Icons.schedule, size: 16, color: paid ? Colors.green : Colors.orange),
      ],
    );
  }

  Widget _plainRow(String label, double amount) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text('₹${amount.toStringAsFixed(0)}'),
      ],
    );
  }
}
