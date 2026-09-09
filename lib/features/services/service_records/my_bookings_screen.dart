import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/services_booking_repository.dart';
import '../models/service_booking.dart';
import '../theme/service_colors.dart';
import '../tracking/booking_detail_screen.dart';
import 'my_enquiries_screen.dart';
import 'recurring_plans_screen.dart';

/// Section 5 of the Services spec: a dedicated Services order/history
/// experience ("Service Orders"), separate from Daily Essentials'
/// order_history — upcoming, active, completed, and cancelled bookings as
/// filterable tabs over one real `fetchMyBookings()` query (RLS already
/// scopes it to the signed-in customer, so no client-side customer
/// filtering is needed, only status bucketing). Lives inside
/// ServicesMainScreen's IndexedStack, mirroring how Daily Essentials'
/// OrdersScreen lives inside MainScreen — no bottom nav of its own here.
class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> with SingleTickerProviderStateMixin {
  final _repo = ServicesBookingRepository(Supabase.instance.client);
  late final TabController _tabController = TabController(length: 4, vsync: this);
  bool _isLoading = true;
  List<ServiceBookingRow> _bookings = const [];

  static const _upcoming = {ServiceBookingStatus.pending, ServiceBookingStatus.vendorAccepted, ServiceBookingStatus.technicianAssigned};
  static const _active = {
    ServiceBookingStatus.enRoute,
    ServiceBookingStatus.arrived,
    ServiceBookingStatus.workStarted,
    ServiceBookingStatus.workInProgress,
    ServiceBookingStatus.completionPending,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final bookings = await _repo.fetchMyBookings();
    if (!mounted) return;
    setState(() {
      _bookings = bookings;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = _bookings.where((b) => _upcoming.contains(b.status)).toList();
    final active = _bookings.where((b) => _active.contains(b.status)).toList();
    final completed = _bookings.where((b) => b.status == ServiceBookingStatus.completed).toList();
    final cancelled = _bookings.where((b) => b.status == ServiceBookingStatus.cancelled).toList();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: ServiceColors.headerBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: ServiceColors.textPrimary),
        title: const Text('Service Orders', style: TextStyle(color: ServiceColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.forum_outlined),
            tooltip: 'My enquiries',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyEnquiriesScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.event_repeat_outlined),
            tooltip: 'Recurring plans',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RecurringPlansScreen()),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: ServiceColors.primaryBlueDark,
          unselectedLabelColor: ServiceColors.textSecondary,
          indicatorColor: ServiceColors.primaryBlue,
          tabs: [
            Tab(text: 'Upcoming (${upcoming.length})'),
            Tab(text: 'Active (${active.length})'),
            Tab(text: 'Completed (${completed.length})'),
            Tab(text: 'Cancelled (${cancelled.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _BookingList(bookings: upcoming, onRefresh: _load, emptyText: 'No upcoming bookings.'),
                _BookingList(bookings: active, onRefresh: _load, emptyText: 'No active jobs right now.'),
                _BookingList(bookings: completed, onRefresh: _load, emptyText: 'No completed bookings yet.'),
                _BookingList(bookings: cancelled, onRefresh: _load, emptyText: 'No cancelled bookings.'),
              ],
            ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final List<ServiceBookingRow> bookings;
  final Future<void> Function() onRefresh;
  final String emptyText;

  const _BookingList({required this.bookings, required this.onRefresh, required this.emptyText});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(child: Text(emptyText));
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: booking.isEmergency ? const Icon(Icons.warning_amber_rounded, color: Colors.red) : null,
              title: Text(booking.serviceName, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${booking.id} · ${booking.status.label}'),
              trailing: Text('₹${booking.quotedPrice.toStringAsFixed(0)}'),
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => BookingDetailScreen(bookingId: booking.id)));
                onRefresh();
              },
            ),
          );
        },
      ),
    );
  }
}
