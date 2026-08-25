import 'package:flutter/material.dart';

import '../models/service_quotation.dart';

/// Same approve/reject pattern as [showQuotationResponseSheet], for a
/// technician-identified extra-work request (Section 11 of the Services
/// spec). Only ever shown for `isPendingCustomerApproval` requests — ones
/// the policy engine routed to `ai_auto`/`admin` never reach the customer
/// for a decision.
Future<bool?> showExtraWorkResponseSheet(BuildContext context, ServiceExtraWorkRequest request) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Additional work requested', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(request.description),
            const SizedBox(height: 12),
            Text('₹${request.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context, false), child: const Text('Decline'))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Approve'))),
              ],
            ),
          ],
        ),
      );
    },
  );
}
