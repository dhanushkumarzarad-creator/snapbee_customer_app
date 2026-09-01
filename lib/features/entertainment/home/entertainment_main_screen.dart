import 'package:flutter/material.dart';

import '../bookings/my_entertainment_bookings_screen.dart';
import '../events/events_screen.dart';
import '../movies/movies_home_screen.dart';
import '../parks/amusement_parks_screen.dart';
import '../theme/entertainment_colors.dart';

/// Entertainment sector entry — separate business vertical from Daily
/// Essentials, Services and Travel. Launch scope: Movies, Events, Amusement
/// Parks.
class EntertainmentMainScreen extends StatelessWidget {
  const EntertainmentMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EntertainmentColors.background,
      appBar: AppBar(
        title: const Text('Entertainment'),
        backgroundColor: EntertainmentColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.receipt_long), tooltip: 'My Bookings', onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyEntertainmentBookingsScreen()))),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _OptionCard(icon: Icons.movie, title: 'Movies', subtitle: 'City, theatre, seat selection with a 5-minute hold.', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MoviesHomeScreen()))),
            const SizedBox(height: 16),
            _OptionCard(icon: Icons.event, title: 'Events', subtitle: 'Concerts, exhibitions, workshops and more.', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EventsScreen()))),
            const SizedBox(height: 16),
            _OptionCard(icon: Icons.attractions, title: 'Amusement Parks', subtitle: 'Adult, child, senior and VIP tickets.', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AmusementParksScreen()))),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _OptionCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade300)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(radius: 26, backgroundColor: EntertainmentColors.primaryLight, child: Icon(icon, color: EntertainmentColors.primary)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
