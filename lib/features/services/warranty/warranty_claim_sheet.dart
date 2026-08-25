import 'package:flutter/material.dart';

/// Collects the claim description. Returns the text via [Navigator.pop],
/// or null if cancelled.
Future<String?> showWarrantyClaimSheet(BuildContext context) {
  final controller = TextEditingController();
  return showModalBottomSheet<String>(
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
                const Text('Raise a warranty claim', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 3,
                  onChanged: (_) => setSheetState(() {}),
                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Describe the issue you\'re facing again'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.text.trim().isEmpty ? null : () => Navigator.pop(context, controller.text.trim()),
                    child: const Text('Submit Claim'),
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
