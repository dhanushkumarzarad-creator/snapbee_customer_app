import 'package:flutter/material.dart';

import '../../../core/design/snapbee_design.dart';
import '../bookings/my_entertainment_bookings_screen.dart';
import '../events/events_screen.dart';
import '../movies/movies_home_screen.dart';
import '../parks/amusement_parks_screen.dart';
import '../theme/entertainment_colors.dart';

/// Entertainment sector entry — separate business vertical from Daily
/// Essentials, Services and Travel. Launch scope: Movies, Events, Amusement
/// Parks.
///
/// Restyled to the shared premium SnapBee design language; the sector accent
/// stays Entertainment's own violet/magenta and every navigation target is
/// unchanged.
class EntertainmentMainScreen extends StatelessWidget {
  const EntertainmentMainScreen({super.key});

  static const _accent = EntertainmentColors.primary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SnapBeeColors.scaffold,
      appBar: const SnapBeeAppBar(subtitle: 'Entertainment'),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const SnapBeePageHeader(
            icon: Icons.local_activity_rounded,
            title: 'Entertainment',
            subtitle: 'Movies, events and parks — book your seat',
            tint: _accent,
          ),
          const SnapBeeHeroCard(
            tag: 'Entertainment',
            titleTop: 'Book Now,',
            titleAccent: 'Enjoy More!',
            subtitle: 'Movie tickets, live events and park passes',
            mascot: SnapBeeMascots.club,
            scriptAccent: 'Great Shows\nGreat Times!',
          ),

          const SnapBeeSectionHeader(title: 'Explore Entertainment', actionLabel: null),
          _EntOptionCard(
            icon: Icons.movie_rounded,
            title: 'Movies',
            subtitle: 'City, theatre and seat selection with a 5-minute hold.',
            accent: _accent,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MoviesHomeScreen())),
          ),
          _EntOptionCard(
            icon: Icons.event_rounded,
            title: 'Events',
            subtitle: 'Concerts, exhibitions, workshops and more.',
            accent: EntertainmentColors.accent,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EventsScreen())),
          ),
          _EntOptionCard(
            icon: Icons.attractions_rounded,
            title: 'Amusement Parks',
            subtitle: 'Adult, child, senior and VIP tickets.',
            accent: SnapBeeColors.success,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AmusementParksScreen())),
          ),

          const SnapBeeSectionHeader(title: 'My Bookings', actionLabel: null),
          SnapBeeQuickActionRail(
            actions: [
              SnapBeeQuickAction(
                icon: Icons.confirmation_num_rounded,
                label: 'My Tickets',
                color: _accent,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyEntertainmentBookingsScreen())),
              ),
              SnapBeeQuickAction(icon: Icons.movie_filter_rounded, label: 'Now Showing', color: EntertainmentColors.accent, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MoviesHomeScreen()))),
              SnapBeeQuickAction(icon: Icons.support_agent_rounded, label: 'Help', color: SnapBeeColors.warn, onTap: () {}),
            ],
          ),

          const SnapBeePromoFooter(
            title: 'More Fun, Fewer Queues.',
            subtitle: 'Book your entertainment with SnapBee.',
            scriptAccent: 'Enjoy More\nStress Less!',
          ),
        ],
      ),
    );
  }
}

class _EntOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  const _EntOptionCard({
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
