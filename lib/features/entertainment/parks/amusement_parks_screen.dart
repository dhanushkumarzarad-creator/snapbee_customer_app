import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/idempotency.dart';
import '../data/entertainment_repository.dart';
import '../theme/entertainment_colors.dart';

/// Park -> Date -> Ticket Type -> Quantity -> Payment -> Confirmation.
class AmusementParksScreen extends StatefulWidget {
  const AmusementParksScreen({super.key});

  @override
  State<AmusementParksScreen> createState() => _AmusementParksScreenState();
}

class _AmusementParksScreenState extends State<AmusementParksScreen> {
  final _repo = EntertainmentRepository(Supabase.instance.client);
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.listActiveParks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EntertainmentColors.background,
      appBar: AppBar(title: const Text('Amusement Parks'), backgroundColor: EntertainmentColors.primary, foregroundColor: Colors.white),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Failed to load: ${snapshot.error}'));
          final parks = snapshot.data ?? [];
          if (parks.isEmpty) return const Center(child: Text('No parks onboarded yet.'));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: parks.length,
            itemBuilder: (context, i) {
              final p = parks[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.attractions, color: EntertainmentColors.primary),
                  title: Text(p['name'] as String),
                  subtitle: Text(p['city'] as String),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openPark(context, p),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openPark(BuildContext context, Map<String, dynamic> park) async {
    final ticketTypes = await _repo.listParkTicketTypes(park['id'] as String);
    if (!context.mounted) return;
    if (ticketTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No ticket types configured for this park yet.')));
      return;
    }
    final quantities = {for (final t in ticketTypes) t['id'] as String: 0};
    DateTime visitDate = DateTime.now().add(const Duration(days: 1));
    final idempotencyKey = generateIdempotencyKey();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setState) {
          num total = 0;
          for (final t in ticketTypes) {
            total += (t['price'] as num) * (quantities[t['id']] ?? 0);
          }
          return Padding(
            padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(park['name'] as String, style: Theme.of(sheetContext).textTheme.titleLarge),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Visit date: ${visitDate.day}/${visitDate.month}/${visitDate.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(context: sheetContext, initialDate: visitDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                    if (picked != null) setState(() => visitDate = picked);
                  },
                ),
                ...ticketTypes.map((t) {
                  return ListTile(
                    title: Text((t['name'] as String).toUpperCase()),
                    subtitle: Text('₹${t['price']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.remove), onPressed: () => setState(() => quantities[t['id']] = (quantities[t['id']]! - 1).clamp(0, 99))),
                        Text('${quantities[t['id']]}'),
                        IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() => quantities[t['id']] = quantities[t['id']]! + 1)),
                      ],
                    ),
                  );
                }),
                const Divider(),
                Text('Total: ₹$total', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: EntertainmentColors.primary),
                  onPressed: total <= 0
                      ? null
                      : () async {
                          final items = quantities.entries.where((e) => e.value > 0).map((e) => {'ticket_type_id': e.key, 'quantity': e.value}).toList();
                          try {
                            final bookingId = await _repo.bookPark(parkId: park['id'] as String, visitDate: visitDate, items: items, idempotencyKey: idempotencyKey);
                            if (sheetContext.mounted) Navigator.pop(sheetContext);
                            if (context.mounted) {
                              showDialog(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text('Booked!'),
                                  content: Text('Booking ID: $bookingId'),
                                  actions: [FilledButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('OK'))],
                                ),
                              );
                            }
                          } catch (err) {
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking failed: $err')));
                          }
                        },
                  child: const Text('Book tickets'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
