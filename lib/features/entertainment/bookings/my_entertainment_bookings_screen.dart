import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/invoicing/invoice.dart';
import '../../../core/invoicing/invoice_button.dart';
import '../data/entertainment_repository.dart';
import '../theme/entertainment_colors.dart';

/// Combined booking history across Movies / Events / Amusement Parks —
/// each retains its own category and booking ID (MOV-/EVT-/AMP-), matching
/// the "Profile -> Booking History shows ALL bookings category-wise" spec
/// requirement for the Entertainment sector specifically.
///
/// Phase 9: customer-facing cancellation for all three booking types (the
/// cancel_*_booking RPCs already existed; only the movie one had UI). A
/// `confirmed` booking can be cancelled; the server computes the refund per
/// the entertainment cancellation policy and returns `refund_amount`.
class MyEntertainmentBookingsScreen extends StatefulWidget {
  const MyEntertainmentBookingsScreen({super.key});

  @override
  State<MyEntertainmentBookingsScreen> createState() =>
      _MyEntertainmentBookingsScreenState();
}

class _MyEntertainmentBookingsScreenState
    extends State<MyEntertainmentBookingsScreen> {
  final _repo = EntertainmentRepository(Supabase.instance.client);
  int _reloadTick = 0;

  void _reload() => setState(() => _reloadTick++);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: EntertainmentColors.background,
        appBar: AppBar(
          title: const Text('My Bookings'),
          backgroundColor: EntertainmentColors.primary,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [Tab(text: 'Movies'), Tab(text: 'Events'), Tab(text: 'Parks')],
          ),
        ),
        body: TabBarView(
          children: [
            _BookingsList(
              key: ValueKey('movies-$_reloadTick'),
              future: _repo.myMovieBookings(),
              emptyText: 'No movie bookings yet.',
              vertical: InvoiceVertical.movie,
              subtitle: (b) => '${b['seat_count']} seat(s) · ₹${b['total_amount']}',
              onCancel: (id) => _cancel(
                  () => _repo.cancelMovieBooking(id), id),
            ),
            _BookingsList(
              key: ValueKey('events-$_reloadTick'),
              future: _repo.myEventBookings(),
              emptyText: 'No event bookings yet.',
              vertical: InvoiceVertical.event,
              subtitle: (b) =>
                  '${(b['entertainment_events'] as Map?)?['title'] ?? ''} · ₹${b['total_amount']}',
              onCancel: (id) => _cancel(
                  () => _repo.cancelEventBooking(id), id),
            ),
            _BookingsList(
              key: ValueKey('parks-$_reloadTick'),
              future: _repo.myParkBookings(),
              emptyText: 'No amusement park bookings yet.',
              vertical: InvoiceVertical.amusementPark,
              subtitle: (b) =>
                  '${(b['amusement_parks'] as Map?)?['name'] ?? ''} · ${b['visit_date']} · ₹${b['total_amount']}',
              onCancel: (id) => _cancel(
                  () => _repo.cancelParkBooking(id), id),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancel(
      Future<Map<String, dynamic>> Function() action, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel this booking?'),
        content: const Text(
            'A cancellation fee may apply per policy. Refund will be '
            'calculated automatically.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('No')),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Yes, cancel')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final result = await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Cancelled. Refund: ₹${result['refund_amount']}')));
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Cancellation failed: $e')));
      }
    }
  }
}

class _BookingsList extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> future;
  final String emptyText;
  final InvoiceVertical vertical;
  final String Function(Map<String, dynamic>) subtitle;
  final void Function(String id) onCancel;

  const _BookingsList({
    super.key,
    required this.future,
    required this.emptyText,
    required this.vertical,
    required this.subtitle,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Failed to load: ${snapshot.error}'));
        }
        final rows = snapshot.data ?? [];
        if (rows.isEmpty) return Center(child: Text(emptyText));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rows.length,
          itemBuilder: (context, i) {
            final b = rows[i];
            final id = b['id'] as String;
            final status = b['status'] as String? ?? '';
            return Card(
              child: Column(
                children: [
                  ListTile(
                    title:
                        Text(id, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(subtitle(b)),
                    trailing: Chip(label: Text(status)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: Row(
                      children: [
                        InvoiceActionButton(vertical: vertical, sourceId: id),
                        const Spacer(),
                        if (status == 'confirmed')
                          TextButton(
                            onPressed: () => onCancel(id),
                            child: const Text('Cancel booking',
                                style: TextStyle(color: Colors.red)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
