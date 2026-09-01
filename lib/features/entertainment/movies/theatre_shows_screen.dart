import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/entertainment_repository.dart';
import '../theme/entertainment_colors.dart';
import 'seat_selection_screen.dart';

/// Theatre -> Movie -> Date -> Show.
class TheatreShowsScreen extends StatefulWidget {
  final Map<String, dynamic> theatre;
  const TheatreShowsScreen({super.key, required this.theatre});

  @override
  State<TheatreShowsScreen> createState() => _TheatreShowsScreenState();
}

class _TheatreShowsScreenState extends State<TheatreShowsScreen> {
  final _repo = EntertainmentRepository(Supabase.instance.client);
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.listShowsForTheatre(widget.theatre['id'] as String);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EntertainmentColors.background,
      appBar: AppBar(title: Text(widget.theatre['name'] as String), backgroundColor: EntertainmentColors.primary, foregroundColor: Colors.white),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Failed to load shows: ${snapshot.error}'));
          final shows = snapshot.data ?? [];
          if (shows.isEmpty) return const Center(child: Text('No shows scheduled at this theatre yet.'));

          // Group by movie -> date, so the customer picks Movie then Show time.
          final byMovie = <String, List<Map<String, dynamic>>>{};
          for (final s in shows) {
            final title = (s['movies'] as Map?)?['title'] as String? ?? 'Movie';
            byMovie.putIfAbsent(title, () => []).add(s);
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: byMovie.entries.map((entry) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: entry.value.map((show) {
                          return ActionChip(
                            label: Text('${show['show_date']} · ${show['show_time']}'),
                            backgroundColor: EntertainmentColors.primaryLight,
                            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SeatSelectionScreen(show: show))),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
