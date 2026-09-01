import 'package:flutter/material.dart';

import '../booking/trip_booking_screen.dart';
import '../booking/trip_bookings_screen.dart';
import '../hotels/hotel_bookings_screen.dart';
import '../hotels/hotel_search_screen.dart';
import '../theme/travel_colors.dart';

/// Travel sector entry — separate business vertical from Daily Essentials
/// and Services (see TRAVEL_ENTERTAINMENT_ARCHITECTURE.md). Launch scope:
/// Trip/Vehicle Rental + Hotels. Bus/Train/Flight are deliberately absent.
class TravelMainScreen extends StatelessWidget {
  const TravelMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TravelColors.background,
      appBar: AppBar(
        title: const Text('Travel'),
        backgroundColor: TravelColors.primary,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'My Bookings',
            onSelected: (i) {
              if (i == 0) Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TripBookingsScreen()));
              if (i == 1) Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HotelBookingsScreen()));
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 0, child: Text('My Trips')),
              PopupMenuItem(value: 1, child: Text('My Hotel Bookings')),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _TravelOptionCard(
              icon: Icons.directions_car_filled,
              title: 'Trip / Vehicle Rental',
              subtitle: 'College trips, family trips, outstation rentals, with or without driver.',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TripBookingScreen())),
            ),
            const SizedBox(height: 16),
            _TravelOptionCard(
              icon: Icons.hotel,
              title: 'Hotels',
              subtitle: 'Search and book rooms by city and dates.',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HotelSearchScreen())),
            ),
          ],
        ),
      ),
    );
  }
}

class _TravelOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _TravelOptionCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade300)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(radius: 26, backgroundColor: TravelColors.primaryLight, child: Icon(icon, color: TravelColors.primary)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
