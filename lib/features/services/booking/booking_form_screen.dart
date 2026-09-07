import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:latlong2/latlong.dart';

import '../../../core/map/location_picker_screen.dart';
import '../../../core/map/osm_map.dart';
import '../../../core/map/picked_location.dart';
import '../data/services_booking_repository.dart';
import '../models/recurring_service_plan.dart';
import '../models/service.dart';
import '../models/service_method.dart';
import '../service_records/my_bookings_screen.dart';
import '../theme/service_colors.dart';
import 'method_booking_fields.dart';

/// Standard + emergency booking creation, now METHOD-AWARE (NEW Services
/// Master Method architecture). The chosen [method]'s `methodCode` drives
/// a [MethodBookingPlan] that decides which parts of this form show —
/// preferred date, time slot, and the address label — and which
/// `p_location_type` the booking uses. [MethodBookingFields] renders the
/// method-specific inputs (pickup branch, drop address, plan frequency,
/// enquiry contact, workflow stages, ...); those values are folded into
/// `p_customer_notes` as a labelled block the provider + Services Admin
/// read. `configId` still links the booking to the exact live method
/// configuration, which `create_service_booking` re-validates server-side.
///
/// A precise map location is collected on every flow because
/// `service_bookings.lat/lng` are NOT NULL - for a store / appointment /
/// enquiry method it is framed as "your location (nearest branch)".
class BookingFormScreen extends StatefulWidget {
  final ServiceRow service;
  final ServiceMethodRow? method;

  const BookingFormScreen({super.key, required this.service, this.method});

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _repo = ServicesBookingRepository(Supabase.instance.client);
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  late final MethodBookingPlan _plan = MethodBookingPlan.forCode(widget.method?.methodCode);
  Map<String, dynamic> _methodIntake = {};

  /// Set only from the map picker - a real confirmed coordinate.
  double? _lat;
  double? _lng;

  DateTime? _preferredDate;
  String _timeSlot = 'morning';
  bool _isEmergency = false;
  bool _isRecurring = false;
  String _recurringFrequency = 'monthly';
  XFile? _emergencyPhoto;
  Uint8List? _emergencyPhotoBytes;
  bool _isUploadingPhoto = false;
  bool _isSubmitting = false;
  String? _submitError;

  bool get _isSubscription => widget.method?.methodCode == 'subscription';

  /// One key per screen instance, reused across any retry of THIS booking
  /// attempt - same pattern as checkout_screen.dart's _idempotencyKey.
  final String _idempotencyKey = List<int>.generate(
    16,
    (_) => Random.secure().nextInt(256),
  ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  @override
  void initState() {
    super.initState();
    // Methods with no slot (walk-in / instant / enquiry) still need a
    // NOT NULL preferred_date - default it to today.
    if (!_plan.needsDate) _preferredDate = DateTime.now();
    if (_isSubscription) _isRecurring = true;
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onMethodIntake(Map<String, dynamic> values) {
    setState(() {
      _methodIntake = values;
      if (_isSubscription) {
        final f = (values['plan_frequency'] ?? '').toString();
        _recurringFrequency = switch (f) {
          'weekly' => 'weekly',
          'fortnightly' || 'biweekly' => 'biweekly',
          'quarterly' => 'quarterly',
          _ => 'monthly',
        };
      }
    });
  }

  Future<void> _openLocationPicker() async {
    final picked = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initial: (_lat == null || _lng == null)
              ? null
              : PickedLocation(latitude: _lat!, longitude: _lng!, address: _addressController.text.trim()),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _lat = picked.latitude;
      _lng = picked.longitude;
      if (picked.address.isNotEmpty) _addressController.text = picked.address;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked =
        await showDatePicker(context: context, initialDate: now, firstDate: now, lastDate: now.add(const Duration(days: 60)));
    if (picked != null && mounted) setState(() => _preferredDate = picked);
  }

  Future<void> _pickEmergencyPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 80);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _emergencyPhoto = picked;
      _emergencyPhotoBytes = bytes;
    });
  }

  Future<String?> _uploadEmergencyPhoto() async {
    if (_emergencyPhoto == null || _emergencyPhotoBytes == null) return null;
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return null;
    setState(() => _isUploadingPhoto = true);
    try {
      final path = '$userId/${DateTime.now().millisecondsSinceEpoch}_${_emergencyPhoto!.name}';
      await client.storage.from('service-media').uploadBinary(
            path,
            _emergencyPhotoBytes!,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
      return client.storage.from('service-media').getPublicUrl(path);
    } catch (_) {
      return null;
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  String? _missingRequiredMethodField() {
    final code = widget.method?.methodCode;
    bool has(String k) => (_methodIntake[k]?.toString().trim().isNotEmpty ?? false);
    switch (code) {
      case 'instant_on_demand':
        if (!has('urgency')) return 'Please describe what you need.';
        break;
      case 'pickup_and_drop':
        if (!has('drop_address')) return 'Please enter the drop-off address.';
        break;
      case 'multi_step_workflow':
        if (!has('scope_note')) return 'Please describe the problem / scope.';
        break;
      case 'lead_generation':
        if (!has('requirement')) return 'Please describe what you need.';
        if (!has('contact_phone')) return 'Please enter a contact number.';
        break;
      case 'subscription':
        if (!has('plan_frequency')) return 'Please choose a plan frequency.';
        break;
      case 'hybrid':
        if (!has('first_part')) return 'Please choose which part happens first.';
        break;
    }
    return null;
  }

  /// Address string for the booking row (service_bookings.address is
  /// NOT NULL). For a method that needs no location an empty field is
  /// fine — we send a short method tag instead of a fake address.
  String _addressText() {
    final t = _addressController.text.trim();
    if (t.isNotEmpty) return t;
    final m = widget.method;
    return m == null ? 'N/A' : '(${m.methodName})';
  }

  Future<void> _submit() async {
    if (_plan.needsServiceAddress) {
      if (_lat == null || _lng == null) {
        setState(() => _submitError = 'Please share your location to continue.');
        return;
      }
      if (_addressController.text.trim().isEmpty) {
        setState(() => _submitError = 'Please enter your address.');
        return;
      }
    }
    if (_plan.needsDate && _preferredDate == null) {
      setState(() => _submitError = 'Please choose a preferred date.');
      return;
    }
    final methodError = _missingRequiredMethodField();
    if (methodError != null) {
      setState(() => _submitError = methodError);
      return;
    }
    if (_isEmergency && _emergencyPhoto == null) {
      setState(() => _submitError = 'Please attach a photo of the problem for an emergency booking.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      List<String>? mediaUrls;
      if (_isEmergency) {
        final url = await _uploadEmergencyPhoto();
        if (url == null) {
          setState(() {
            _submitError = 'Could not upload your photo. Please check your connection and try again.';
            _isSubmitting = false;
          });
          return;
        }
        mediaUrls = [url];
      }

      await _repo.createBooking(
        serviceId: widget.service.id,
        address: _addressText(),
        lat: _lat,
        lng: _lng,
        preferredDate: _preferredDate ?? DateTime.now(),
        preferredTimeSlot: _timeSlot,
        bookingType: _isEmergency ? 'emergency' : 'one_time',
        locationType: _plan.locationType,
        isEmergency: _isEmergency,
        emergencyProblemMedia: mediaUrls,
        customerNotes: _composeNotes(),
        idempotencyKey: _idempotencyKey,
        vendorId: widget.method?.vendorId,
        vendorMethodConfigId: widget.method?.configId,
      );
      if (_isRecurring && !_isEmergency) {
        try {
          await _repo.createRecurringPlan(
            serviceId: widget.service.id,
            address: _addressText(),
            lat: _lat ?? 0,
            lng: _lng ?? 0,
            frequency: _recurringFrequency,
            preferredTimeSlot: _timeSlot,
            nextRunDate: RecurringServicePlan.nextRunAfter(_preferredDate ?? DateTime.now(), _recurringFrequency),
          );
        } on ServicesException catch (planError) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(planError.message)));
          }
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.method?.methodCode == 'lead_generation'
              ? 'Enquiry sent - the provider will contact you.'
              : (_isRecurring && !_isEmergency)
                  ? 'Booking confirmed and a recurring plan was set up.'
                  : 'Booking confirmed! We are finding a provider for you.'),
        ),
      );
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MyBookingsScreen()));
    } on ServicesException catch (error) {
      if (!mounted) return;
      setState(() {
        _submitError = error.message;
        _isSubmitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitError = 'Something went wrong. Please try again.';
        _isSubmitting = false;
      });
    }
  }

  /// Free-text note = method line + method-specific intake block + the
  /// customer's own typed note. `p_vendor_method_config_id` still carries
  /// the structural link; this is the human-readable context.
  String? _composeNotes() {
    final parts = <String>[];
    final method = widget.method;
    if (method != null) {
      parts.add('Requested method: ${method.methodName} - ${method.vendorName}');
      if (_methodIntake.isNotEmpty) {
        parts.add('-- ${method.methodName} details --');
        _methodIntake.forEach((k, v) {
          if (v == null || v.toString().trim().isEmpty) return;
          parts.add('${_prettyKey(k)}: $v');
        });
      }
    }
    final typed = _notesController.text.trim();
    if (typed.isNotEmpty) parts.add(typed);
    return parts.isEmpty ? null : parts.join('\n');
  }

  String _prettyKey(String k) =>
      k.replaceAll('_', ' ').replaceFirstMapped(RegExp(r'^\w'), (m) => m.group(0)!.toUpperCase());

  static const _recurringOptions = [
    ('weekly', 'Every week'),
    ('biweekly', 'Every 2 weeks'),
    ('monthly', 'Every month'),
    ('quarterly', 'Every 3 months'),
  ];

  static const _timeSlots = [
    ('morning', 'Morning (8 AM - 12 PM)'),
    ('afternoon', 'Afternoon (12 PM - 4 PM)'),
    ('evening', 'Evening (4 PM - 8 PM)'),
  ];

  @override
  Widget build(BuildContext context) {
    final method = widget.method;
    return Scaffold(
      appBar: AppBar(title: Text(method?.methodCode == 'lead_generation' ? 'Send Enquiry' : 'Book Service')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(widget.service.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('₹${widget.service.basePrice.toStringAsFixed(0)}', style: const TextStyle(color: Colors.grey)),

          if (method != null) ...[
            const SizedBox(height: 16),
            _SelectedMethodBanner(method: method),
            MethodBookingFields(method: method, onChanged: _onMethodIntake),
          ],

          const SizedBox(height: 24),

          if (widget.service.supportsEmergency && _plan.needsServiceAddress) ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Emergency booking', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Faster priority handling - an emergency charge applies.'),
              value: _isEmergency,
              onChanged: (v) => setState(() => _isEmergency = v),
            ),
            if (_isEmergency) ...[
              const SizedBox(height: 8),
              const Text('Photo of the problem (required)', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (_emergencyPhotoBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(_emergencyPhotoBytes!, height: 140, width: double.infinity, fit: BoxFit.cover),
                )
              else
                OutlinedButton.icon(
                  onPressed: _pickEmergencyPhoto,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Take a photo'),
                ),
              if (_emergencyPhoto != null)
                TextButton(onPressed: _pickEmergencyPhoto, child: const Text('Retake photo')),
            ],
            const SizedBox(height: 16),
          ],

          if (_plan.needsServiceAddress || _addressController.text.isNotEmpty || method != null) ...[
          Text(
            _plan.needsServiceAddress ? '${_plan.addressLabel} *' : 'Branch / location (optional)',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _addressController,
            maxLines: 2,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: _plan.needsServiceAddress
                  ? 'House no., street, area, landmark'
                  : 'e.g. the outlet you will visit',
            ),
          ),
          const SizedBox(height: 8),
          if (_lat != null && _lng != null) ...[
            StaticLocationMap(point: LatLng(_lat!, _lng!), height: 140),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.check_circle, size: 16, color: Colors.green),
              const SizedBox(width: 6),
              Expanded(
                child: Text('${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}',
                    style: const TextStyle(color: Colors.green, fontSize: 12)),
              ),
              TextButton.icon(
                onPressed: _openLocationPicker,
                icon: const Icon(Icons.edit_location_alt_outlined, size: 16),
                label: const Text('Change'),
              ),
            ]),
          ] else
            OutlinedButton.icon(
              onPressed: _openLocationPicker,
              icon: const Icon(Icons.map_outlined, size: 18),
              label: Text(_plan.needsServiceAddress
                  ? 'Set location on map'
                  : 'Add a location (optional)'),
            ),
          ],

          if (_plan.needsDate) ...[
            const SizedBox(height: 24),
            const Text('Preferred Date', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(_preferredDate == null
                  ? 'Select a date'
                  : '${_preferredDate!.day}/${_preferredDate!.month}/${_preferredDate!.year}'),
            ),
          ],

          if (_plan.needsTimeSlot) ...[
            const SizedBox(height: 24),
            const Text('Preferred Time', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final slot in _timeSlots)
                  ChoiceChip(
                    label: Text(slot.$2),
                    selected: _timeSlot == slot.$1,
                    onSelected: (_) => setState(() => _timeSlot = slot.$1),
                  ),
              ],
            ),
          ],

          if (_isSubscription) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ServiceColors.primaryBlueLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'A recurring plan (${_recurringFrequency == 'biweekly' ? 'every 2 weeks' : 'every $_recurringFrequency'}) '
                'will be created along with this first visit.',
                style: const TextStyle(fontSize: 12.5),
              ),
            ),
          ] else if (!_isEmergency && _plan.needsDate) ...[
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Repeat this service', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Also set up a recurring plan from this booking', style: TextStyle(fontSize: 12.5)),
              value: _isRecurring,
              onChanged: (v) => setState(() => _isRecurring = v),
            ),
            if (_isRecurring)
              DropdownButtonFormField<String>(
                initialValue: _recurringFrequency,
                decoration: const InputDecoration(labelText: 'Frequency', border: OutlineInputBorder()),
                items: [for (final o in _recurringOptions) DropdownMenuItem(value: o.$1, child: Text(o.$2))],
                onChanged: (v) => setState(() => _recurringFrequency = v ?? _recurringFrequency),
              ),
          ],

          const SizedBox(height: 24),
          const Text('Notes (optional)', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'e.g. AC not cooling, model XYZ'),
          ),

          const SizedBox(height: 24),
          if (_submitError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_submitError!, style: const TextStyle(color: Colors.red)),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: (_isSubmitting || _isUploadingPhoto) ? null : _submit,
              child: (_isSubmitting || _isUploadingPhoto)
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(method?.methodCode == 'lead_generation' ? 'Send Enquiry' : 'Confirm Booking'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Read-only summary of the delivery method the customer picked on the
/// previous screen.
class _SelectedMethodBanner extends StatelessWidget {
  final ServiceMethodRow method;

  const _SelectedMethodBanner({required this.method});

  static const Map<String, IconData> _iconByCode = {
    'store_pickup': Icons.storefront_outlined,
    'store_delivery': Icons.local_shipping_outlined,
    'appointment_booking': Icons.event_available_outlined,
    'home_visit': Icons.home_outlined,
    'instant_on_demand': Icons.bolt_outlined,
    'pickup_and_drop': Icons.sync_alt_outlined,
    'multi_step_workflow': Icons.account_tree_outlined,
    'subscription': Icons.autorenew_outlined,
    'lead_generation': Icons.contact_phone_outlined,
    'hybrid': Icons.dashboard_customize_outlined,
    'walk_in': Icons.directions_walk_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ServiceColors.primaryBlueLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ServiceColors.primaryBlue.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_iconByCode[method.methodCode] ?? Icons.build_outlined, size: 18, color: ServiceColors.primaryBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  method.methodName,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: ServiceColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('with ${method.vendorName}', style: const TextStyle(fontSize: 12, color: ServiceColors.textSecondary)),
          if (method.definition.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(method.definition, style: const TextStyle(fontSize: 12.5, height: 1.35)),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              if (method.priceLabel != null)
                Text(method.priceLabel!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              if (method.durationLabel != null)
                Text('~ ${method.durationLabel!}',
                    style: const TextStyle(fontSize: 12, color: ServiceColors.textSecondary)),
            ],
          ),
          if (method.hasBookingRequirements) ...[
            const SizedBox(height: 8),
            Text('Before booking: ${method.bookingRequirementsText}',
                style: const TextStyle(fontSize: 11.5, color: ServiceColors.textSecondary, height: 1.3)),
          ],
        ],
      ),
    );
  }
}
