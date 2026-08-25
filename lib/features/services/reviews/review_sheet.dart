import 'package:flutter/material.dart';

/// Collects a star rating + optional review text. Returns
/// `(rating, reviewText)` via [Navigator.pop], or null if cancelled.
Future<(int, String?)?> showReviewSheet(BuildContext context) {
  int rating = 5;
  final textController = TextEditingController();
  return showModalBottomSheet<(int, String?)>(
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
                const Text('Rate this service', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(5, (index) {
                    final starValue = index + 1;
                    return IconButton(
                      icon: Icon(starValue <= rating ? Icons.star : Icons.star_border, color: Colors.amber),
                      onPressed: () => setSheetState(() => rating = starValue),
                    );
                  }),
                ),
                TextField(
                  controller: textController,
                  maxLines: 3,
                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Share your experience (optional)'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(
                      context,
                      (rating, textController.text.trim().isEmpty ? null : textController.text.trim()),
                    ),
                    child: const Text('Submit Review'),
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
