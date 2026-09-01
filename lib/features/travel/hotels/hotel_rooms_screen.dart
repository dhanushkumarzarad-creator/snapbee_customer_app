import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/idempotency.dart';
import '../data/travel_repository.dart';
import '../theme/travel_colors.dart';
import 'hotel_bookings_screen.dart';

/// Hotel details -> Room types -> Dates/Guests -> Book. Booking history for
/// hotels is combined with My Trips is out of scope here — hotel bookings
/// live in their own list surfaced from Profile > Booking History (booking
/// category filter), not duplicated here; this screen just books.
class HotelRoomsScreen extends StatefulWidget {
  final Map<String, dynamic> hotel;
  const HotelRoomsScreen({super.key, required this.hotel});

  @override
  State<HotelRoomsScreen> createState() => _HotelRoomsScreenState();
}

class _HotelRoomsScreenState extends State<HotelRoomsScreen> {
  final _repo = TravelRepository(Supabase.instance.client);
  late Future<List<Map<String, dynamic>>> _future;
  DateTime _checkIn = DateTime.now().add(const Duration(days: 1));
  DateTime _checkOut = DateTime.now().add(const Duration(days: 2));
  final int _guests = 2;
  bool _booking = false;
  // One idempotency key per room (not one for the whole screen) — this
  // screen lists multiple bookable rooms, and a retry must only replay
  // the SAME room's booking intent, never a different room's.
  final Map<String, String> _idempotencyKeys = {};

  String _idempotencyKeyFor(String roomId) => _idempotencyKeys.putIfAbsent(roomId, generateIdempotencyKey);

  @override
  void initState() {
    super.initState();
    _future = _repo.listHotelRooms(widget.hotel['id'] as String);
  }

  Future<void> _pickDates() async {
    final range = await showDateRangePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)), initialDateRange: DateTimeRange(start: _checkIn, end: _checkOut));
    if (range != null) {
      setState(() {
        _checkIn = range.start;
        _checkOut = range.end;
      });
    }
  }

  Future<void> _book(Map<String, dynamic> room) async {
    setState(() => _booking = true);
    try {
      final roomId = room['id'] as String;
      final bookingId = await _repo.createHotelBooking(
        roomId: roomId,
        checkIn: _checkIn,
        checkOut: _checkOut,
        roomsCount: 1,
        guestsCount: _guests,
        idempotencyKey: _idempotencyKeyFor(roomId),
      );
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Hotel booked!'),
          content: Text('Booking ID: $bookingId'),
          actions: [FilledButton(onPressed: () => Navigator.pop(dialogContext), style: FilledButton.styleFrom(backgroundColor: TravelColors.primary), child: const Text('OK'))],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HotelBookingsScreen()), (r) => r.isFirst);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking failed: $e')));
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TravelColors.background,
      appBar: AppBar(title: Text(widget.hotel['name'] as String), backgroundColor: TravelColors.primary, foregroundColor: Colors.white),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.hotel['description'] as String? ?? '', style: const TextStyle(color: TravelColors.textSecondary)),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  tileColor: TravelColors.cardGrey,
                  title: Text('${_checkIn.day}/${_checkIn.month} → ${_checkOut.day}/${_checkOut.month}  ·  $_guests guests'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickDates,
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: Text('Failed to load rooms: ${snapshot.error}'));
                final rooms = snapshot.data ?? [];
                if (rooms.isEmpty) return const Center(child: Text('No room types configured yet.'));
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: rooms.length,
                  itemBuilder: (context, i) {
                    final r = rooms[i];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r['room_type'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('Up to ${r['max_occupancy']} guests · ₹${r['base_price']}/night'),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton(
                                style: FilledButton.styleFrom(backgroundColor: TravelColors.primary),
                                onPressed: _booking ? null : () => _book(r),
                                child: _booking ? const CircularProgressIndicator(color: Colors.white) : const Text('Book this room'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
