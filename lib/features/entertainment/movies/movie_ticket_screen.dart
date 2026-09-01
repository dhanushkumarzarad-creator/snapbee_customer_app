import 'package:flutter/material.dart';

import '../theme/entertainment_colors.dart';

/// The ticket: booking ID, movie, theatre, screen, date, show time, seats,
/// amount, payment status, source.
class MovieTicketScreen extends StatelessWidget {
  final String bookingId;
  final Map<String, dynamic> show;
  final int seatCount;
  final num totalAmount;
  const MovieTicketScreen({super.key, required this.bookingId, required this.show, required this.seatCount, required this.totalAmount});

  @override
  Widget build(BuildContext context) {
    final movie = (show['movies'] as Map?)?['title'] ?? 'Movie';
    return Scaffold(
      backgroundColor: EntertainmentColors.background,
      appBar: AppBar(title: const Text('Ticket'), backgroundColor: EntertainmentColors.primary, foregroundColor: Colors.white),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: EntertainmentColors.primary, size: 56),
                  const SizedBox(height: 12),
                  Text('Booking confirmed', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(bookingId, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const Divider(height: 32),
                  _row('Movie', '$movie'),
                  _row('Date', '${show['show_date']}'),
                  _row('Time', '${show['show_time']}'),
                  _row('Seats', '$seatCount'),
                  _row('Amount', '₹$totalAmount'),
                  _row('Source', 'SNAPBEE'),
                  const SizedBox(height: 20),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: EntertainmentColors.primary),
                    onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: EntertainmentColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
