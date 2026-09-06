import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/invoicing/invoice.dart';
import '../../../core/invoicing/invoice_button.dart';
import '../data/travel_repository.dart';
import '../theme/travel_colors.dart';

/// Booking history + cancellation for trip/vehicle-rental bookings.
class TripBookingsScreen extends StatefulWidget {
  const TripBookingsScreen({super.key});

  @override
  State<TripBookingsScreen> createState() => _TripBookingsScreenState();
}

class _TripBookingsScreenState extends State<TripBookingsScreen> {
  final _repo = TravelRepository(Supabase.instance.client);
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.myTripBookings();
  }

  void _reload() => setState(() => _future = _repo.myTripBookings());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TravelColors.background,
      appBar: AppBar(title: const Text('My Trips'), backgroundColor: TravelColors.primary, foregroundColor: Colors.white),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Failed to load: ${snapshot.error}'));
          final bookings = snapshot.data ?? [];
          if (bookings.isEmpty) return const Center(child: Text('No trips booked yet.'));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, i) {
              final b = bookings[i];
              final typeName = (b['travel_vehicle_types'] as Map?)?['name'] ?? '';
              final status = b['status'] as String;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(b['id'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Chip(label: Text(status)),
                      ]),
                      const SizedBox(height: 6),
                      Text('${b['pickup_location']} → ${b['destination_location']}'),
                      Text('$typeName · ${b['start_date']} → ${b['end_date']}'),
                      Text('Total: ₹${b['total_amount']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          InvoiceActionButton(
                            vertical: InvoiceVertical.travelTrip,
                            sourceId: b['id'] as String,
                          ),
                          if (status == 'confirmed' || status == 'driver_assigned')
                            TextButton(
                              onPressed: () => _cancel(b['id'] as String),
                              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _cancel(String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel this trip?'),
        content: const Text('A cancellation fee may apply per policy. Refund will be calculated automatically.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Yes, cancel')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final result = await _repo.cancelTripBooking(bookingId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cancelled. Refund: ₹${result['refund_amount']}')));
      _reload();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cancellation failed: $e')));
    }
  }
}
