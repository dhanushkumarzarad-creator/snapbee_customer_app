import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/services_booking_repository.dart';
import '../theme/service_colors.dart';

/// Lead Generation method — the customer's own enquiries
/// (service_leads, RLS-scoped to them by service_leads_customer_select).
/// Read-only: the provider moves each enquiry through its status.
class MyEnquiriesScreen extends StatefulWidget {
  const MyEnquiriesScreen({super.key});

  @override
  State<MyEnquiriesScreen> createState() => _MyEnquiriesScreenState();
}

class _MyEnquiriesScreenState extends State<MyEnquiriesScreen> {
  final _repo = ServicesBookingRepository(Supabase.instance.client);
  bool _loading = true;
  List<Map<String, dynamic>> _leads = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final leads = await _repo.fetchMyLeads();
    if (!mounted) return;
    setState(() {
      _leads = leads;
      _loading = false;
    });
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'submitted':
        return 'Sent — awaiting a response';
      case 'contacted':
        return 'The provider has been in touch';
      case 'quoted':
        return 'You have a quote to review';
      case 'converted':
      case 'closed_won':
        return 'Booked';
      case 'closed_lost':
        return 'Closed';
      default:
        return s.replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ServiceColors.headerBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: ServiceColors.textPrimary),
        title: const Text('My Enquiries',
            style: TextStyle(color: ServiceColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _leads.isEmpty
              ? const Center(child: Text('You have not sent any enquiries yet.'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _leads.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final l = _leads[i];
                      final service = (l['services'] as Map?)?['name'] as String?;
                      final status = (l['status'] ?? 'submitted').toString();
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: ServiceColors.cardGrey),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(service ?? 'Service enquiry',
                                style: const TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text((l['requirement'] ?? '').toString(),
                                style: const TextStyle(fontSize: 13, color: ServiceColors.textSecondary)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.info_outline, size: 15, color: ServiceColors.primaryBlue),
                                const SizedBox(width: 6),
                                Expanded(child: Text(_statusLabel(status), style: const TextStyle(fontSize: 12.5))),
                              ],
                            ),
                            if ((l['vendor_notes'] ?? '').toString().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text('Provider note: ${l['vendor_notes']}',
                                  style: const TextStyle(fontSize: 12, color: ServiceColors.textSecondary)),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
