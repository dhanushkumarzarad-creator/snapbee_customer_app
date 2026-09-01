import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/entertainment_repository.dart';
import '../theme/entertainment_colors.dart';
import 'theatre_shows_screen.dart';

/// Entertainment -> Movies -> City -> Theatre.
class MoviesHomeScreen extends StatefulWidget {
  const MoviesHomeScreen({super.key});

  @override
  State<MoviesHomeScreen> createState() => _MoviesHomeScreenState();
}

class _MoviesHomeScreenState extends State<MoviesHomeScreen> {
  final _repo = EntertainmentRepository(Supabase.instance.client);
  List<String> _cities = [];
  String? _selectedCity;
  List<Map<String, dynamic>>? _theatres;
  bool _loadingCities = true;
  bool _loadingTheatres = false;

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    final cities = await _repo.listCities();
    setState(() {
      _cities = cities;
      _loadingCities = false;
    });
  }

  Future<void> _selectCity(String city) async {
    setState(() {
      _selectedCity = city;
      _loadingTheatres = true;
    });
    final theatres = await _repo.listTheatresInCity(city);
    setState(() {
      _theatres = theatres;
      _loadingTheatres = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EntertainmentColors.background,
      appBar: AppBar(title: const Text('Movies'), backgroundColor: EntertainmentColors.primary, foregroundColor: Colors.white),
      body: _loadingCities
          ? const Center(child: CircularProgressIndicator())
          : _cities.isEmpty
              ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No theatres onboarded yet.', textAlign: TextAlign.center)))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 8,
                        children: _cities.map((c) => ChoiceChip(label: Text(c), selected: c == _selectedCity, selectedColor: EntertainmentColors.primaryLight, onSelected: (_) => _selectCity(c))).toList(),
                      ),
                    ),
                    if (_loadingTheatres) const Center(child: CircularProgressIndicator()),
                    if (_theatres != null)
                      Expanded(
                        child: _theatres!.isEmpty
                            ? const Center(child: Text('No theatres in this city.'))
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _theatres!.length,
                                itemBuilder: (context, i) {
                                  final t = _theatres![i];
                                  return Card(
                                    child: ListTile(
                                      leading: const Icon(Icons.theaters, color: EntertainmentColors.primary),
                                      title: Text(t['name'] as String),
                                      subtitle: Text(t['address'] as String? ?? ''),
                                      trailing: const Icon(Icons.chevron_right),
                                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TheatreShowsScreen(theatre: t))),
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
