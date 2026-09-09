import 'package:flutter/material.dart';

import '../../../core/design/snapbee_design.dart';
import '../booking/trip_booking_screen.dart';
import '../booking/trip_bookings_screen.dart';
import '../hotels/hotel_bookings_screen.dart';
import '../hotels/hotel_search_screen.dart';
import '../theme/travel_colors.dart';

/// Travel sector entry — separate business vertical from Daily Essentials
/// and Services (see TRAVEL_ENTERTAINMENT_ARCHITECTURE.md). Launch scope:
/// Trip/Vehicle Rental + Hotels. Bus/Train/Flight are deliberately absent.
///
/// Restyled to the shared premium SnapBee design language (same header,
/// hero card, section headers, cards and promo footer as every other
/// vertical); the sector accent stays Travel's own teal-green and every
/// navigation target is unchanged.
class TravelMainScreen extends StatelessWidget {
  const TravelMainScreen({super.key});

  static const _accent = TravelColors.primary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SnapBeeColors.scaffold,
      appBar: const SnapBeeAppBar(subtitle: 'Travel'),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const SnapBeePageHeader(
            icon: Icons.flight_takeoff_rounded,
            title: 'Travel with SnapBee',
            subtitle: 'Trips, rentals and stays — booked in minutes',
            tint: _accent,
          ),
          const SnapBeeHeroCard(
            tag: 'Travel',
            titleTop: 'Go Further,',
            titleAccent: 'Worry Less!',
            subtitle: 'Vehicle rentals and hotels for every journey',
            mascot: SnapBeeMascots.scooter,
            scriptAccent: 'Happy Trips\nHappy You!',
          ),

          const SnapBeeSectionHeader(title: 'What would you like to book?', actionLabel: null),
          _VerticalOptionCard(
            icon: Icons.directions_car_filled_rounded,
            title: 'Trip / Vehicle Rental',
            subtitle: 'College trips, family trips, outstation rentals — with or without a driver.',
            accent: _accent,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TripBookingScreen())),
          ),
          _VerticalOptionCard(
            icon: Icons.hotel_rounded,
            title: 'Hotels',
            subtitle: 'Search and book rooms by city and dates.',
            accent: _accent,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HotelSearchScreen())),
          ),

          const SnapBeeSectionHeader(title: 'My Bookings', actionLabel: null),
          SnapBeeQuickActionRail(
            actions: [
              SnapBeeQuickAction(
                icon: Icons.map_rounded,
                label: 'My Trips',
                color: _accent,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TripBookingsScreen())),
              ),
              SnapBeeQuickAction(
                icon: Icons.hotel_rounded,
                label: 'Hotel Bookings',
                color: SnapBeeColors.info,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HotelBookingsScreen())),
              ),
              SnapBeeQuickAction(
                icon: Icons.support_agent_rounded,
                label: 'Travel Help',
                color: SnapBeeColors.warn,
                onTap: () {},
              ),
            ],
          ),

          const SnapBeePromoFooter(
            title: 'Every Journey, Made Simple.',
            subtitle: 'Book trips and stays with SnapBee.',
            scriptAccent: 'Safe Travels\nHappier You!',
          ),
        ],
      ),
    );
  }
}

class _VerticalOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  const _VerticalOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SnapBeeCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: accent, size: 25),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: SnapBeeText.title),
                const SizedBox(height: 3),
                Text(subtitle, style: SnapBeeText.caption),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: SnapBeeColors.inkFaint),
        ],
      ),
    );
  }
}
