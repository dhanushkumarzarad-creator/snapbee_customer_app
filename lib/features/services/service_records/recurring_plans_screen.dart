import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/services_booking_repository.dart';
import '../models/recurring_service_plan.dart';

/// The customer's recurring / AMC service plans — pause, resume or cancel.
/// Bookings are generated from active plans by Services Admin's "Generate
/// due bookings" action; this screen only manages the plan itself.
class RecurringPlansScreen extends StatefulWidget {
  const RecurringPlansScreen({super.key});

  @override
  State<RecurringPlansScreen> createState() => _RecurringPlansScreenState();
}

class _RecurringPlansScreenState extends State<RecurringPlansScreen> {
  final _repo = ServicesBookingRepository(Supabase.instance.client);
  List<RecurringServicePlan> _plans = const [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final plans = await _repo.fetchMyRecurringPlans();
    if (!mounted) return;
    setState(() {
      _plans = plans;
      _loading = false;
    });
  }

  Future<void> _setStatus(RecurringServicePlan plan, String status) async {
    setState(() => _busy = true);
    try {
      await _repo.setRecurringPlanStatus(plan.id, status);
      await _load();
    } on ServicesException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recurring plans')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _plans.isEmpty
              ? RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    children: const [
                      SizedBox(height: 200),
                      Center(child: Text('No recurring plans yet.')),
                      SizedBox(height: 8),
                      Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Turn on "Repeat this service" when you book to create one.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _plans.length,
                    itemBuilder: (context, i) {
                      final p = _plans[i];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      p.serviceName ?? 'Service',
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  _StatusChip(status: p.status),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('${p.isAmc ? 'AMC · ' : ''}${p.frequencyLabel}',
                                  style: const TextStyle(color: Colors.grey, fontSize: 12.5)),
                              if (!p.isCancelled)
                                Text(
                                  'Next: ${p.nextRunDate.day}/${p.nextRunDate.month}/${p.nextRunDate.year}'
                                  '${p.preferredTimeSlot == null ? '' : ' · ${p.preferredTimeSlot}'}',
                                  style: const TextStyle(color: Colors.grey, fontSize: 12.5),
                                ),
                              if (!p.isCancelled) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    if (p.isActive)
                                      OutlinedButton(
                                        onPressed: _busy ? null : () => _setStatus(p, 'paused'),
                                        child: const Text('Pause'),
                                      )
                                    else
                                      OutlinedButton(
                                        onPressed: _busy ? null : () => _setStatus(p, 'active'),
                                        child: const Text('Resume'),
                                      ),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: _busy ? null : () => _setStatus(p, 'cancelled'),
                                      child: const Text('Cancel plan'),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'active' => Colors.green,
      'paused' => Colors.orange,
      _ => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
      child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
