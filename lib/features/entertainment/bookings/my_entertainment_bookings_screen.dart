import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/entertainment_repository.dart';
import '../theme/entertainment_colors.dart';

/// Combined booking history across Movies / Events / Amusement Parks —
/// each retains its own category and booking ID (MOV-/EVT-/AMP-), matching
/// the "Profile -> Booking History shows ALL bookings category-wise" spec
/// requirement for the Entertainment sector specifically.
class MyEntertainmentBookingsScreen extends StatefulWidget {
  const MyEntertainmentBookingsScreen({super.key});

  @override
  State<MyEntertainmentBookingsScreen> createState() => _MyEntertainmentBookingsScreenState();
}

class _MyEntertainmentBookingsScreenState extends State<MyEntertainmentBookingsScreen> {
  final _repo = EntertainmentRepository(Supabase.instance.client);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: EntertainmentColors.background,
        appBar: AppBar(
          title: const Text('My Bookings'),
          backgroundColor: EntertainmentColors.primary,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [Tab(text: 'Movies'), Tab(text: 'Events'), Tab(text: 'Parks')],
          ),
        ),
        body: TabBarView(
          children: [
            _MovieBookingsList(repo: _repo),
            _EventBookingsList(repo: _repo),
            _ParkBookingsList(repo: _repo),
          ],
        ),
      ),
    );
  }
}

class _MovieBookingsList extends StatelessWidget {
  final EntertainmentRepository repo;
  const _MovieBookingsList({required this.repo});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: repo.myMovieBookings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final rows = snapshot.data ?? [];
        if (rows.isEmpty) return const Center(child: Text('No movie bookings yet.'));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rows.length,
          itemBuilder: (context, i) {
            final b = rows[i];
            return Card(
              child: ListTile(
                title: Text(b['id'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${b['seat_count']} seat(s) · ₹${b['total_amount']}'),
                trailing: Chip(label: Text(b['status'] as String)),
              ),
            );
          },
        );
      },
    );
  }
}

class _EventBookingsList extends StatelessWidget {
  final EntertainmentRepository repo;
  const _EventBookingsList({required this.repo});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: repo.myEventBookings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final rows = snapshot.data ?? [];
        if (rows.isEmpty) return const Center(child: Text('No event bookings yet.'));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rows.length,
          itemBuilder: (context, i) {
            final b = rows[i];
            final title = (b['entertainment_events'] as Map?)?['title'] ?? '';
            return Card(
              child: ListTile(
                title: Text(b['id'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('$title · ₹${b['total_amount']}'),
                trailing: Chip(label: Text(b['status'] as String)),
              ),
            );
          },
        );
      },
    );
  }
}

class _ParkBookingsList extends StatelessWidget {
  final EntertainmentRepository repo;
  const _ParkBookingsList({required this.repo});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: repo.myParkBookings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final rows = snapshot.data ?? [];
        if (rows.isEmpty) return const Center(child: Text('No amusement park bookings yet.'));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rows.length,
          itemBuilder: (context, i) {
            final b = rows[i];
            final name = (b['amusement_parks'] as Map?)?['name'] ?? '';
            return Card(
              child: ListTile(
                title: Text(b['id'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('$name · ${b['visit_date']} · ₹${b['total_amount']}'),
                trailing: Chip(label: Text(b['status'] as String)),
              ),
            );
          },
        );
      },
    );
  }
}
