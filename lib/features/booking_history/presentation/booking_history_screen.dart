import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/booking_history_repository.dart';

const Map<String, String> _categoryLabels = {
  'daily_essentials': 'Daily Essentials',
  'services': 'Services',
  'travel_trip': 'Travel — Trip',
  'travel_hotel': 'Travel — Hotel',
  'movie': 'Movie',
  'event': 'Event',
  'amusement_park': 'Amusement Park',
};

const Map<String, IconData> _categoryIcons = {
  'daily_essentials': Icons.shopping_bag,
  'services': Icons.build,
  'travel_trip': Icons.directions_car,
  'travel_hotel': Icons.hotel,
  'movie': Icons.movie,
  'event': Icons.event,
  'amusement_park': Icons.attractions,
};

const Map<String, Color> _categoryColors = {
  'daily_essentials': Color(0xFFF7941D),
  'services': Color(0xFF1E6FE0),
  'travel_trip': Color(0xFF0B6E4F),
  'travel_hotel': Color(0xFF0B6E4F),
  'movie': Color(0xFF6A2FB0),
  'event': Color(0xFF6A2FB0),
  'amusement_park': Color(0xFF6A2FB0),
};

/// Profile -> Booking History: ALL bookings, category-wise, each keeping
/// its own category label and booking ID — a filterable list over
/// get_my_booking_history(), not a merged business workflow.
class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  final _repo = BookingHistoryRepository(Supabase.instance.client);
  late Future<List<Map<String, dynamic>>> _future;
  String? _categoryFilter;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking History')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Failed to load: ${snapshot.error}'));
          final all = snapshot.data ?? [];
          if (all.isEmpty) return const Center(child: Text('No bookings yet across any SnapBee service.'));

          final categories = all.map((r) => r['category'] as String).toSet().toList()..sort();
          final filtered = _categoryFilter == null ? all : all.where((r) => r['category'] == _categoryFilter).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(label: const Text('All'), selected: _categoryFilter == null, onSelected: (_) => setState(() => _categoryFilter = null)),
                      ),
                      ...categories.map((c) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(label: Text(_categoryLabels[c] ?? c), selected: _categoryFilter == c, onSelected: (_) => setState(() => _categoryFilter = c)),
                          )),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final b = filtered[i];
                    final category = b['category'] as String;
                    final color = _categoryColors[category] ?? Colors.grey;
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.12), child: Icon(_categoryIcons[category] ?? Icons.receipt, color: color)),
                        title: Text(b['booking_id'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${_categoryLabels[category] ?? category} · ${b['event_date'] ?? ''} · ${b['provider_or_source'] ?? ''}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('₹${b['amount']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(b['status'] as String? ?? '', style: TextStyle(fontSize: 12, color: color)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
