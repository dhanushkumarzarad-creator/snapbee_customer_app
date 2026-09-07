import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/invoicing/invoice.dart';
import '../../../core/invoicing/invoice_button.dart';
import '../chat/service_chat_screen.dart';
import '../complaints/complaint_form_sheet.dart';
import '../data/services_booking_repository.dart';
import '../disputes/dispute_form_sheet.dart';
import '../booking/extra_work_response_sheet.dart';
import '../models/recurring_service_plan.dart';
import '../models/service_booking.dart';
import '../models/service_invoice.dart';
import '../models/service_quotation.dart';
import '../models/service_warranty.dart';
import '../payments/payment_summary_widget.dart';
import '../quotation/quotation_response_sheet.dart';
import '../reviews/review_sheet.dart';
import '../warranty/warranty_claim_sheet.dart';

/// The full booking lifecycle hub — status timeline, arrival/completion OTP
/// (readable by the customer only — the technician generates it but never
/// sees it, see services_module_v2.sql's `mark_service_en_route`), pending
/// quotation/extra-work approval, payment summary, warranty + claims,
/// review, and complaint/dispute entry points. Reloads the booking (not
/// just local state) after every action, since server-side status/fields
/// may have changed underneath this screen.
class BookingDetailScreen extends StatefulWidget {
  final String bookingId;

  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final _repo = ServicesBookingRepository(Supabase.instance.client);

  ServiceBookingRow? _booking;
  ServiceQuotation? _quotation;
  List<ServiceExtraWorkRequest> _extraWork = const [];
  ServiceWarranty? _warranty;
  List<WarrantyClaim> _warrantyClaims = const [];
  Map<String, dynamic>? _existingReview;
  ServiceInvoice? _invoice;
  bool _isLoading = true;
  bool _isBusy = false;
  String? _error;

  static const _steps = ['Booked', 'Confirmed', 'Assigned', 'En Route', 'Arrived', 'Started', 'In Progress', 'Confirming', 'Completed'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final booking = await _repo.fetchBooking(widget.bookingId);
    if (!mounted) return;
    if (booking == null) {
      setState(() {
        _isLoading = false;
        _error = 'This booking could not be loaded.';
      });
      return;
    }

    final completed = booking.status == ServiceBookingStatus.completed;
    final results = await Future.wait([
      _repo.fetchPendingQuotation(widget.bookingId),
      _repo.fetchExtraWorkRequests(widget.bookingId),
      _repo.fetchWarranty(widget.bookingId),
      completed ? _repo.fetchExistingReview(widget.bookingId) : Future.value(null),
      completed ? _repo.fetchInvoice(widget.bookingId) : Future.value(null),
    ]);
    final warranty = results[2] as ServiceWarranty?;
    final claims = warranty == null ? <WarrantyClaim>[] : await _repo.fetchWarrantyClaims(warranty.id);

    if (!mounted) return;
    setState(() {
      _booking = booking;
      _quotation = results[0] as ServiceQuotation?;
      _extraWork = results[1] as List<ServiceExtraWorkRequest>;
      _warranty = warranty;
      _warrantyClaims = claims;
      _existingReview = results[3] as Map<String, dynamic>?;
      _invoice = results[4] as ServiceInvoice?;
      _isLoading = false;
    });
  }

  Future<void> _cancel() async {
    setState(() {
      _isBusy = true;
      _error = null;
    });
    try {
      await _repo.cancelBooking(widget.bookingId);
      if (!mounted) return;
      Navigator.pop(context);
    } on ServicesException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _isBusy = false;
      });
    }
  }

  Future<void> _confirmCompletion() async {
    final booking = _booking;
    if (booking?.completionOtp == null) return;
    setState(() {
      _isBusy = true;
      _error = null;
    });
    try {
      await _repo.confirmCompletion(bookingId: widget.bookingId, otp: booking!.completionOtp!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Work confirmed as complete.')));
      await _load();
    } on ServicesException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _reschedule() async {
    final booking = _booking;
    if (booking == null) return;
    final result = await showModalBottomSheet<({DateTime date, String slot})>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RescheduleSheet(
        initialDate: booking.preferredDate,
        initialSlot: booking.preferredTimeSlot,
      ),
    );
    if (result == null) return;
    setState(() {
      _isBusy = true;
      _error = null;
    });
    try {
      await _repo.rescheduleBooking(
        bookingId: widget.bookingId,
        newDate: result.date,
        newTimeSlot: result.slot,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking rescheduled.')));
      await _load();
    } on ServicesException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  /// Turns a completed service into a recurring / AMC plan. Reuses the same
  /// `recurring_service_plans` insert (customer-self RLS, no RPC) the booking
  /// form uses — the service, address and location come from this booking.
  Future<void> _startRepeatPlan() async {
    final booking = _booking;
    if (booking == null || !booking.canStartRepeatPlan) return;
    if (booking.lat == null || booking.lng == null) {
      setState(() => _error = 'This booking has no saved location, so a recurring plan cannot be created from it.');
      return;
    }
    final result = await showModalBottomSheet<({String frequency, DateTime nextRun})>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RepeatPlanSheet(firstBookingDate: booking.preferredDate),
    );
    if (result == null) return;
    setState(() {
      _isBusy = true;
      _error = null;
    });
    try {
      await _repo.createRecurringPlan(
        serviceId: booking.serviceId,
        address: booking.address,
        lat: booking.lat!,
        lng: booking.lng!,
        frequency: result.frequency,
        preferredTimeSlot: booking.preferredTimeSlot,
        nextRunDate: result.nextRun,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recurring plan set up. Manage it under Recurring plans.')),
      );
    } on ServicesException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _respondToQuotation(bool approve) async {
    if (_quotation == null) return;
    setState(() => _isBusy = true);
    try {
      await _repo.respondToQuotation(quotationId: _quotation!.id, approve: approve);
      await _load();
    } on ServicesException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _respondToExtraWork(ServiceExtraWorkRequest request, bool approve) async {
    setState(() => _isBusy = true);
    try {
      await _repo.respondToExtraWork(requestId: request.id, approve: approve);
      await _load();
    } on ServicesException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _openReview() async {
    final result = await showReviewSheet(context);
    if (result == null || !mounted) return;
    try {
      await _repo.submitReview(bookingId: widget.bookingId, rating: result.$1, reviewText: result.$2);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thanks for your review!')));
      await _load();
    } on ServicesException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _openWarrantyClaim() async {
    if (_warranty == null) return;
    final description = await showWarrantyClaimSheet(context);
    if (description == null || !mounted) return;
    try {
      await _repo.raiseWarrantyClaim(warrantyId: _warranty!.id, description: description);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Warranty claim submitted.')));
      await _load();
    } on ServicesException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _openComplaint() async {
    final result = await showComplaintFormSheet(context);
    if (result == null || !mounted) return;
    try {
      await _repo.raiseComplaint(bookingId: widget.bookingId, category: result.$1, description: result.$2);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complaint submitted.')));
    } on ServicesException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _openDispute() async {
    final result = await showDisputeFormSheet(context);
    if (result == null || !mounted) return;
    try {
      await _repo.raiseDispute(bookingId: widget.bookingId, disputeType: result.$1, description: result.$2);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dispute submitted.')));
    } on ServicesException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final booking = _booking;
    if (booking == null) {
      return Scaffold(appBar: AppBar(title: const Text('Booking')), body: Center(child: Text(_error ?? 'Not found')));
    }

    final step = booking.status.timelineStep;
    final showArrivalOtp = booking.arrivalOtp != null && booking.status == ServiceBookingStatus.enRoute;
    final showCompletionOtp = booking.completionOtp != null && booking.status == ServiceBookingStatus.completionPending;
    final pendingExtraWork = _extraWork.where((r) => r.isPendingCustomerApproval).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(booking.id),
        actions: [
          if (booking.status != ServiceBookingStatus.cancelled)
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              tooltip: 'Chat with your provider',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ServiceChatScreen(bookingId: booking.id, title: booking.serviceName),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(booking.serviceName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('₹${booking.quotedPrice.toStringAsFixed(0)}'),
            const SizedBox(height: 20),

            if (booking.status == ServiceBookingStatus.cancelled)
              const Row(children: [
                Icon(Icons.cancel, color: Colors.red),
                SizedBox(width: 8),
                Text('This booking was cancelled', style: TextStyle(color: Colors.red)),
              ])
            else if (step != null)
              _Timeline(currentStep: step, steps: _steps),

            if (_quotation != null) ...[
              const SizedBox(height: 16),
              _ActionRequiredCard(
                title: 'Quotation ready for your approval',
                subtitle: '₹${_quotation!.totalAmount.toStringAsFixed(0)} total',
                busy: _isBusy,
                onTap: () async {
                  final approve = await showQuotationResponseSheet(context, _quotation!);
                  if (approve != null) await _respondToQuotation(approve);
                },
              ),
            ] else if (pendingExtraWork.isNotEmpty) ...[
              const SizedBox(height: 16),
              _ActionRequiredCard(
                title: 'Extra work needs your approval',
                subtitle: '₹${pendingExtraWork.first.price.toStringAsFixed(0)} · ${pendingExtraWork.first.description}',
                busy: _isBusy,
                onTap: () async {
                  final approve = await showExtraWorkResponseSheet(context, pendingExtraWork.first);
                  if (approve != null) await _respondToExtraWork(pendingExtraWork.first, approve);
                },
              ),
            ],

            if (showArrivalOtp) ...[
              const SizedBox(height: 20),
              _OtpCard(label: 'Arrival OTP', otp: booking.arrivalOtp!, hint: 'Read this to your technician on arrival.'),
            ],
            if (showCompletionOtp) ...[
              const SizedBox(height: 20),
              _OtpCard(
                label: 'Completion OTP',
                otp: booking.completionOtp!,
                hint: 'Your technician has marked the job done. Confirm below once you\'re satisfied with the work.',
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isBusy ? null : _confirmCompletion,
                  child: _isBusy
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Confirm work is complete'),
                ),
              ),
            ],

            const SizedBox(height: 20),
            const Text('Address', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(booking.address),
            const SizedBox(height: 12),
            Text('Preferred: ${booking.preferredDate.day}/${booking.preferredDate.month}/${booking.preferredDate.year}, ${booking.preferredTimeSlot}'),

            if (booking.customerNotes != null && booking.customerNotes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Your notes', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(booking.customerNotes!),
            ],

            if (booking.vendorName != null || booking.technicianName != null) ...[
              const SizedBox(height: 20),
              const Text('Provider', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              if (booking.vendorName != null) Text(booking.vendorName!),
              if (booking.technicianName != null) Text('Technician: ${booking.technicianName!}'),
            ],

            const SizedBox(height: 20),
            PaymentSummaryWidget(booking: booking),

            if (_invoice != null) ...[
              const SizedBox(height: 16),
              _InvoiceCard(invoice: _invoice!),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: InvoiceActionButton(
                  vertical: InvoiceVertical.services,
                  sourceId: widget.bookingId,
                  label: 'Invoice PDF · print · share',
                  dense: false,
                ),
              ),
            ],

            if (_warranty != null && _warranty!.isActive) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Warranty', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text('${_warranty!.durationDays} days'
                          '${_warranty!.expiresAt != null ? ' · expires ${_warranty!.expiresAt!.day}/${_warranty!.expiresAt!.month}/${_warranty!.expiresAt!.year}' : ''}'),
                      if (_warrantyClaims.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        for (final claim in _warrantyClaims) Text('• ${claim.status}: ${claim.description}', style: const TextStyle(fontSize: 12)),
                      ],
                      const SizedBox(height: 10),
                      OutlinedButton(onPressed: _openWarrantyClaim, child: const Text('Raise Warranty Claim')),
                    ],
                  ),
                ),
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],

            const SizedBox(height: 24),
            if (booking.status == ServiceBookingStatus.pending ||
                booking.status == ServiceBookingStatus.vendorAccepted)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isBusy ? null : _reschedule,
                  icon: const Icon(Icons.event_repeat_outlined, size: 18),
                  label: const Text('Reschedule'),
                ),
              ),
            if (booking.status.isCancellable) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isBusy ? null : _cancel,
                  child: _isBusy
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Cancel Booking'),
                ),
              ),
            ],

            if (booking.status == ServiceBookingStatus.completed)
              if (_existingReview != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 6),
                    Text('You rated ${_existingReview!['rating']}/5'),
                  ]),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _openReview, child: const Text('Rate & Review'))),
                ),

            if (booking.canStartRepeatPlan)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Card(
                  color: const Color(0xFFF0FDF4),
                  child: ListTile(
                    leading: const Icon(Icons.event_repeat_outlined, color: Colors.green),
                    title: const Text('Repeat this service', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Set up a recurring / AMC plan from this booking'),
                    trailing: _isBusy
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.chevron_right),
                    onTap: _isBusy ? null : _startRepeatPlan,
                  ),
                ),
              ),

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextButton(onPressed: _openComplaint, child: const Text('Raise a Complaint'))),
                Expanded(child: TextButton(onPressed: _openDispute, child: const Text('Raise a Dispute'))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRequiredCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool busy;
  final VoidCallback onTap;

  const _ActionRequiredCard({required this.title, required this.subtitle, required this.busy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFEFF6FF),
      child: ListTile(
        leading: const Icon(Icons.notifications_active_outlined, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.chevron_right),
        onTap: busy ? null : onTap,
      ),
    );
  }
}

class _OtpCard extends StatelessWidget {
  final String label;
  final String otp;
  final String hint;

  const _OtpCard({required this.label, required this.otp, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFFFF3DD), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(otp, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 4, color: Color(0xFFFF9100))),
          const SizedBox(height: 4),
          Text(hint, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  final int currentStep;
  final List<String> steps;

  const _Timeline({required this.currentStep, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 8,
      children: [
        for (var i = 0; i < steps.length; i++)
          Chip(
            label: Text(steps[i], style: const TextStyle(fontSize: 10)),
            avatar: Icon(i <= currentStep ? Icons.check_circle : Icons.radio_button_unchecked,
                color: i <= currentStep ? Colors.green : Colors.grey, size: 14),
            backgroundColor: i == currentStep ? const Color(0xFFFFF3DD) : null,
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}

/// Date + time-slot picker for rescheduling a not-yet-assigned booking.
/// Pops `(date, slot)` or null.
class _RescheduleSheet extends StatefulWidget {
  final DateTime initialDate;
  final String initialSlot;

  const _RescheduleSheet({required this.initialDate, required this.initialSlot});

  @override
  State<_RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<_RescheduleSheet> {
  static const _slots = ['morning', 'afternoon', 'evening', 'asap'];
  late DateTime _date = widget.initialDate.isBefore(DateTime.now())
      ? DateTime.now().add(const Duration(days: 1))
      : widget.initialDate;
  late String _slot = _slots.contains(widget.initialSlot) ? widget.initialSlot : 'morning';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Reschedule booking', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: Text('${_date.day}/${_date.month}/${_date.year}'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _slot,
              decoration: const InputDecoration(labelText: 'Time slot', border: OutlineInputBorder()),
              items: [
                for (final s in _slots) DropdownMenuItem(value: s, child: Text(s[0].toUpperCase() + s.substring(1))),
              ],
              onChanged: (v) => setState(() => _slot = v ?? _slot),
            ),
            const SizedBox(height: 8),
            const Text(
              'You can reschedule until a technician is assigned. After that, use the chat or cancel and rebook.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, (date: _date, slot: _slot)),
                    child: const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Pick a cadence + first run date for a recurring / AMC plan started from a
/// completed booking. Returns `(frequency, nextRun)`; the time slot comes
/// from the source booking. The `nextRun` default matches
/// `RecurringServicePlan.nextRunAfter` and the server's cadence math.
class _RepeatPlanSheet extends StatefulWidget {
  final DateTime firstBookingDate;

  const _RepeatPlanSheet({required this.firstBookingDate});

  @override
  State<_RepeatPlanSheet> createState() => _RepeatPlanSheetState();
}

class _RepeatPlanSheetState extends State<_RepeatPlanSheet> {
  static const _options = [
    ('weekly', 'Every week'),
    ('biweekly', 'Every 2 weeks'),
    ('monthly', 'Every month'),
    ('quarterly', 'Every 3 months'),
  ];

  String _frequency = 'monthly';
  late DateTime _nextRun = _defaultNextRun('monthly');

  static DateTime _defaultNextRun(String frequency) {
    final base = DateTime.now();
    final computed = RecurringServicePlan.nextRunAfter(base, frequency);
    // never in the past
    return computed.isBefore(base) ? base.add(const Duration(days: 1)) : computed;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextRun,
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _nextRun = picked);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Repeat this service', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _frequency,
              decoration: const InputDecoration(labelText: 'How often', border: OutlineInputBorder()),
              items: [for (final o in _options) DropdownMenuItem(value: o.$1, child: Text(o.$2))],
              onChanged: (v) => setState(() {
                _frequency = v ?? _frequency;
                _nextRun = _defaultNextRun(_frequency);
              }),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: Text('First run: ${_nextRun.day}/${_nextRun.month}/${_nextRun.year}'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bookings are created automatically by SnapBee on each run date. '
              'Pause or cancel any time under Recurring plans.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, (frequency: _frequency, nextRun: _nextRun)),
                    child: const Text('Set up plan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The itemised `service_invoices` row raised on completion. Shows only the
/// customer-facing lines (subtotal / parts / extra work / discount / tax /
/// total) — platform fee and commission are internal and not part of what
/// the customer pays.
class _InvoiceCard extends StatelessWidget {
  final ServiceInvoice invoice;

  const _InvoiceCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    Widget row(String label, double amount, {bool bold = false}) {
      final style = bold ? const TextStyle(fontWeight: FontWeight.w700) : null;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label, style: style), Text('₹${amount.toStringAsFixed(0)}', style: style)],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Invoice', style: TextStyle(fontWeight: FontWeight.w700)),
                Text(invoice.invoiceNumber, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            row('Service', invoice.subtotal),
            if (invoice.partsTotal > 0) row('Parts', invoice.partsTotal),
            if (invoice.extraWorkTotal > 0) row('Extra work', invoice.extraWorkTotal),
            if (invoice.discountAmount > 0) row('Discount', -invoice.discountAmount),
            row('Tax', invoice.taxAmount),
            const Divider(height: 16),
            row('Total', invoice.totalAmount, bold: true),
          ],
        ),
      ),
    );
  }
}
