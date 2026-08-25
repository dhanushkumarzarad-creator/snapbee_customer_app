import 'package:flutter/material.dart';

/// Escalates a complaint (or raises a dispute directly) — collects a
/// dispute type + description. Returns `(disputeType, description)` via
/// [Navigator.pop], or null if cancelled.
Future<(String, String)?> showDisputeFormSheet(BuildContext context) {
  const types = ['Payment dispute', 'Work quality dispute', 'Cancellation dispute', 'Other'];
  var selectedType = types.first;
  final controller = TextEditingController();

  return showModalBottomSheet<(String, String)>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Raise a dispute', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(labelText: 'Dispute type', border: OutlineInputBorder()),
                  items: [for (final t in types) DropdownMenuItem(value: t, child: Text(t))],
                  onChanged: (v) => setSheetState(() => selectedType = v ?? selectedType),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 3,
                  onChanged: (_) => setSheetState(() {}),
                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Describe the dispute in detail'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        controller.text.trim().isEmpty ? null : () => Navigator.pop(context, (selectedType, controller.text.trim())),
                    child: const Text('Submit Dispute'),
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}
