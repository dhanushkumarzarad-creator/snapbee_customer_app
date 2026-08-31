import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/services_booking_repository.dart';
import '../models/service_notification.dart';
import '../tracking/booking_detail_screen.dart';

String _formatWhen(DateTime dt) {
  final l = dt.toLocal();
  final hh = l.hour.toString().padLeft(2, '0');
  final mm = l.minute.toString().padLeft(2, '0');
  return '${l.day}/${l.month}/${l.year} · $hh:$mm';
}

/// The customer's Services notification feed — chat replies, booking status
/// changes and "quotation ready" alerts, all written by the
/// `service_notifications` triggers. Reached from the bell on the Services
/// home header. Empty until `supabase/service_notifications.sql` is applied.
class ServiceNotificationsScreen extends StatefulWidget {
  const ServiceNotificationsScreen({super.key});

  @override
  State<ServiceNotificationsScreen> createState() => _ServiceNotificationsScreenState();
}

class _ServiceNotificationsScreenState extends State<ServiceNotificationsScreen> {
  final _repo = ServicesBookingRepository(Supabase.instance.client);
  List<ServiceNotification> _items = const [];
  bool _loading = true;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _load();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    if (_channel != null) Supabase.instance.client.removeChannel(_channel!);
    super.dispose();
  }

  Future<void> _load() async {
    final items = await _repo.fetchNotifications();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  void _subscribeRealtime() {
    _channel = Supabase.instance.client
        .channel('service_notifications:customer')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'service_notifications',
          callback: (_) {
            if (mounted) _load();
          },
        )
        .subscribe();
  }

  int get _unread => _items.where((n) => !n.isRead).length;

  Future<void> _markAllRead() async {
    await _repo.markNotificationsRead(_items.where((n) => !n.isRead).map((n) => n.id).toList());
    await _load();
  }

  IconData _icon(String kind) => switch (kind) {
        'chat' => Icons.chat_bubble_outline,
        'quotation' => Icons.request_quote_outlined,
        _ => Icons.event_note_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_unread > 0) TextButton(onPressed: _markAllRead, child: const Text('Mark all read')),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(children: const [SizedBox(height: 220), Center(child: Text('No notifications yet.'))]),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 4),
                    itemBuilder: (context, i) {
                      final n = _items[i];
                      return Card(
                        margin: EdgeInsets.zero,
                        color: n.isRead ? null : const Color(0xFFEFF6FF),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFEFF6FF),
                            child: Icon(_icon(n.kind), color: Colors.blue, size: 20),
                          ),
                          title: Text(
                            n.title,
                            style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${n.body == null ? '' : '${n.body}\n'}${_formatWhen(n.createdAt)}',
                          ),
                          isThreeLine: n.body != null,
                          trailing: n.bookingId == null ? null : const Icon(Icons.chevron_right),
                          onTap: () async {
                            if (!n.isRead) await _repo.markNotificationsRead([n.id]);
                            if (!context.mounted) return;
                            if (n.bookingId != null) {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BookingDetailScreen(bookingId: n.bookingId!),
                                ),
                              );
                            }
                            _load();
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
