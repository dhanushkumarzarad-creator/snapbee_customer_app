import 'package:flutter/material.dart';

/// Collects a complaint category + description. Returns
/// `(category, description)` via [Navigator.pop], or null if cancelled.
Future<(String, String)?> showComplaintFormSheet(BuildContext context) {
  const categories = ['Service quality', 'Behavior', 'Pricing', 'No-show', 'Other'];
  var selectedCategory = categories.first;
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
                const Text('Raise a complaint', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                  items: [for (final c in categories) DropdownMenuItem(value: c, child: Text(c))],
                  onChanged: (v) => setSheetState(() => selectedCategory = v ?? selectedCategory),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 3,
                  onChanged: (_) => setSheetState(() {}),
                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'What happened?'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.text.trim().isEmpty
                        ? null
                        : () => Navigator.pop(context, (selectedCategory, controller.text.trim())),
                    child: const Text('Submit Complaint'),
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
