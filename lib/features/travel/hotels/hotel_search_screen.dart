import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/travel_repository.dart';
import '../theme/travel_colors.dart';
import 'hotel_rooms_screen.dart';

/// Travel -> Hotels -> Location -> Search -> Hotel results.
class HotelSearchScreen extends StatefulWidget {
  const HotelSearchScreen({super.key});

  @override
  State<HotelSearchScreen> createState() => _HotelSearchScreenState();
}

class _HotelSearchScreenState extends State<HotelSearchScreen> {
  final _repo = TravelRepository(Supabase.instance.client);
  final _city = TextEditingController();
  List<Map<String, dynamic>>? _results;
  bool _loading = false;
  String? _error;

  Future<void> _search() async {
    if (_city.text.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final hotels = await _repo.searchHotels(city: _city.text.trim());
      setState(() {
        _results = hotels;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Search failed: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TravelColors.background,
      appBar: AppBar(title: const Text('Hotels'), backgroundColor: TravelColors.primary, foregroundColor: Colors.white),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _city, decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_city)))),
                const SizedBox(width: 8),
                FilledButton(style: FilledButton.styleFrom(backgroundColor: TravelColors.primary), onPressed: _search, child: const Text('Search')),
              ],
            ),
          ),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null) Padding(padding: const EdgeInsets.all(16), child: Text(_error!, style: const TextStyle(color: Colors.red))),
          if (_results != null)
            Expanded(
              child: _results!.isEmpty
                  ? const Center(child: Text('No hotels found in this city yet.'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _results!.length,
                      itemBuilder: (context, i) {
                        final h = _results![i];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.hotel, color: TravelColors.primary),
                            title: Text(h['name'] as String),
                            subtitle: Text('${h['city']} · ${h['star_rating'] ?? '—'}★ · ${h['source']}'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => HotelRoomsScreen(hotel: h))),
                          ),
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }
}
