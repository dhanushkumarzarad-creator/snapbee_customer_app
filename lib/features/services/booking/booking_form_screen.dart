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
import '../service_records/my_bookings_screen.dart';

/// Standard + emergency booking creation. Inspection-required services are
/// booked exactly like a standard service — `create_service_booking`
/// itself opens the inspection record server-side (services_module_v2.sql,
/// `create_service_booking`'s own `if v_service.requires_inspection`
/// branch) — this screen doesn't need to know the difference beyond
/// showing the "starts with an inspection" notice already on the detail
/// screen. A "Repeat this service" toggle also creates a
/// `recurring_service_plans` row (weekly/biweekly/monthly/quarterly) whose
/// due bookings Services Admin generates; AMC and scheduled/ASAP booking
/// types are still not surfaced here.
class BookingFormScreen extends StatefulWidget {
  final ServiceRow service;

  const BookingFormScreen({super.key, required this.service});

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _repo = ServicesBookingRepository(Supabase.instance.client);
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  /// Set only from the map picker — a real confirmed coordinate.
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

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _openLocationPicker() async {
    final picked = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initial: (_lat == null || _lng == null)
              ? null
              : PickedLocation(
                  latitude: _lat!,
                  longitude: _lng!,
                  address: _addressController.text.trim(),
                ),
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
    final picked = await showDatePicker(context: context, initialDate: now, firstDate: now, lastDate: now.add(const Duration(days: 60)));
    if (picked != null && mounted) setState(() => _preferredDate = picked);
  }

  /// Reads bytes once, right after picking — `Uint8List` + `Image.memory`
  /// is this app's established cross-platform convention (see
  /// customer_repository.dart's `Uint8ListSource`), never `dart:io File` /
  /// `Image.file`, which doesn't work on the web build this app also
  /// targets (a real bug caught and fixed before this ever shipped).
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

  Future<void> _submit() async {
    if (_lat == null || _lng == null) {
      setState(() => _submitError = 'Please share your location to continue.');
      return;
    }
    if (_addressController.text.trim().isEmpty) {
      setState(() => _submitError = 'Please enter your address.');
      return;
    }
    if (_preferredDate == null) {
      setState(() => _submitError = 'Please choose a preferred date.');
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
        address: _addressController.text.trim(),
        lat: _lat!,
        lng: _lng!,
        preferredDate: _preferredDate!,
        preferredTimeSlot: _timeSlot,
        bookingType: _isEmergency ? 'emergency' : 'one_time',
        isEmergency: _isEmergency,
        emergencyProblemMedia: mediaUrls,
        customerNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      if (_isRecurring && !_isEmergency) {
        try {
          await _repo.createRecurringPlan(
            serviceId: widget.service.id,
            address: _addressController.text.trim(),
            lat: _lat!,
            lng: _lng!,
            frequency: _recurringFrequency,
            preferredTimeSlot: _timeSlot,
            nextRunDate: RecurringServicePlan.nextRunAfter(_preferredDate!, _recurringFrequency),
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
          content: Text(_isRecurring && !_isEmergency
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
    return Scaffold(
      appBar: AppBar(title: const Text('Book Service')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(widget.service.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('₹${widget.service.basePrice.toStringAsFixed(0)}', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),

          if (widget.service.supportsEmergency) ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Emergency booking', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Faster priority handling — an emergency charge applies.'),
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

          const Text('Address', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: _addressController,
            maxLines: 2,
            decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'House no., street, area, landmark'),
          ),
          const SizedBox(height: 8),
          if (_lat == null || _lng == null)
            OutlinedButton.icon(
              onPressed: _openLocationPicker,
              icon: const Icon(Icons.map_outlined, size: 18),
              label: const Text('Set service location on map'),
            )
          else ...[
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
          ],

          const SizedBox(height: 24),
          const Text('Preferred Date', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(_preferredDate == null ? 'Select a date' : '${_preferredDate!.day}/${_preferredDate!.month}/${_preferredDate!.year}'),
          ),

          const SizedBox(height: 24),
          const Text('Preferred Time', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final slot in _timeSlots)
                ChoiceChip(label: Text(slot.$2), selected: _timeSlot == slot.$1, onSelected: (_) => setState(() => _timeSlot = slot.$1)),
            ],
          ),

          if (!_isEmergency) ...[
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
                items: [
                  for (final o in _recurringOptions) DropdownMenuItem(value: o.$1, child: Text(o.$2)),
                ],
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
            Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_submitError!, style: const TextStyle(color: Colors.red))),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: (_isSubmitting || _isUploadingPhoto) ? null : _submit,
              child: (_isSubmitting || _isUploadingPhoto)
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Confirm Booking'),
            ),
          ),
        ],
      ),
    );
  }
}
