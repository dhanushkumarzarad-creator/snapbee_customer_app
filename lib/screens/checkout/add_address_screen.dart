import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/design/snapbee_design.dart';
import '../../core/map/location_picker_screen.dart';
import '../../core/map/osm_map.dart';
import '../../core/map/picked_location.dart';
import '../../data/repositories/address_repository.dart';
import 'package:latlong2/latlong.dart';

/// The composed result of the Add New Address form, returned to the caller
/// (checkout uses [location]/[formatted]; the address book uses
/// [addressId]).
class AddressResult {
  final PickedLocation location;
  final String formatted;
  final String label; // Home / Work / …
  final String? addressId; // the persisted customer_addresses row id

  const AddressResult({
    required this.location,
    required this.formatted,
    required this.label,
    this.addressId,
  });
}

/// Add / Edit Address (reference 33 / 11) — a structured delivery-address
/// form on top of the existing OSM map picker. On save it persists to the
/// real `customer_addresses` table via [AddressRepository.saveAddress]
/// (the `save_customer_address` RPC), then returns an [AddressResult] so
/// checkout can also use the just-saved location immediately. The pin
/// always comes from a real map confirmation — never fabricated.
class AddAddressScreen extends StatefulWidget {
  final PickedLocation? initial;
  final String? initialName;
  final String? initialPhone;
  final CustomerAddress? editing;

  const AddAddressScreen({
    super.key,
    this.initial,
    this.initialName,
    this.initialPhone,
    this.editing,
  });

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _repo = AddressRepository(Supabase.instance.client);
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.editing?.recipientName ?? widget.initialName ?? '');
  late final _phone = TextEditingController(text: widget.editing?.phone ?? widget.initialPhone ?? '');
  late final _house = TextEditingController(text: widget.editing?.house ?? '');
  late final _street = TextEditingController(text: widget.editing?.street ?? '');
  late final _landmark = TextEditingController(text: widget.editing?.landmark ?? '');
  late final _city = TextEditingController(text: widget.editing?.city ?? '');
  late final _pincode = TextEditingController(text: widget.editing?.pincode ?? '');
  late final _instructions = TextEditingController(text: widget.editing?.deliveryInstructions ?? '');

  PickedLocation? _location;
  int _type = 0;
  bool _isDefault = false;
  bool _saving = false;
  static const _types = ['Home', 'Work', "Parents'", 'Other'];
  static const _dbTags = ['home', 'work', 'parents', 'other'];
  static const _typeIcons = [Icons.home_rounded, Icons.work_rounded, Icons.favorite_rounded, Icons.place_rounded];

  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _location = PickedLocation(latitude: e.latitude, longitude: e.longitude, address: e.formattedAddress);
      _isDefault = e.isDefault;
      final ti = _dbTags.indexOf(e.tag);
      if (ti >= 0) _type = ti;
    } else {
      _location = widget.initial;
      if (widget.initial != null && widget.initial!.address.isNotEmpty) {
        _street.text = widget.initial!.address;
      }
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _house, _street, _landmark, _city, _pincode, _instructions]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickOnMap() async {
    final picked = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(initial: _location),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _location = picked;
      if (picked.address.isNotEmpty && _street.text.trim().isEmpty) {
        _street.text = picked.address;
      }
    });
  }

  Future<void> _save() async {
    if (_location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set your location on the map first.')),
      );
      return;
    }
    if (!_form.currentState!.validate()) return;

    final parts = [
      _house.text.trim(),
      _street.text.trim(),
      if (_landmark.text.trim().isNotEmpty) 'Near ${_landmark.text.trim()}',
      _city.text.trim(),
      if (_pincode.text.trim().isNotEmpty) _pincode.text.trim(),
    ].where((p) => p.isNotEmpty).join(', ');

    setState(() => _saving = true);
    try {
      final id = await _repo.saveAddress(
        addressId: widget.editing?.id,
        label: _types[_type].replaceAll("'", ''),
        tag: _dbTags[_type],
        recipientName: _name.text.trim().isEmpty ? null : _name.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        house: _house.text.trim().isEmpty ? null : _house.text.trim(),
        street: _street.text.trim().isEmpty ? null : _street.text.trim(),
        landmark: _landmark.text.trim().isEmpty ? null : _landmark.text.trim(),
        city: _city.text.trim().isEmpty ? null : _city.text.trim(),
        pincode: _pincode.text.trim().isEmpty ? null : _pincode.text.trim(),
        latitude: _location!.latitude,
        longitude: _location!.longitude,
        formattedAddress: parts.isEmpty ? _location!.address : parts,
        deliveryInstructions: _instructions.text.trim().isEmpty ? null : _instructions.text.trim(),
        isDefault: _isDefault,
      );
      if (!mounted) return;
      Navigator.of(context).pop(AddressResult(
        location: _location!,
        formatted: parts.isEmpty ? _location!.address : parts,
        label: _types[_type],
        addressId: id,
      ));
    } on AddressException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = _location;
    return Scaffold(
      backgroundColor: SnapBeeColors.scaffold,
      appBar: SnapBeeAppBar(
        subtitle: 'Daily Essentials',
        trailing: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: SnapBeePillButton(label: 'Use Current Location', icon: Icons.my_location_rounded, onTap: _pickOnMap),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              SnapBeePageHeader(
                icon: Icons.add_location_alt_rounded,
                title: _isEdit ? 'Edit Address' : 'Add New Address',
                subtitle: 'Tell us where to deliver your order',
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(SnapBeeSpacing.gutter, 6, SnapBeeSpacing.gutter, 6),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: SnapBeeColors.cream, borderRadius: BorderRadius.circular(SnapBeeSpacing.rCard)),
                child: Row(
                  children: [
                    const SnapBeeMascotImage(asset: SnapBeeMascots.location, height: 58),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Set Your Location', style: SnapBeeText.h2),
                          Text('Add your address for faster, smoother deliveries.', style: SnapBeeText.caption),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Map preview
              Padding(
                padding: SnapBeeSpacing.screenH,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(SnapBeeSpacing.rTile),
                  child: Stack(
                    children: [
                      if (loc != null)
                        StaticLocationMap(point: LatLng(loc.latitude, loc.longitude), height: 150)
                      else
                        Container(
                          height: 150,
                          color: SnapBeeColors.chipFill,
                          child: const Center(child: Icon(Icons.map_outlined, size: 34, color: SnapBeeColors.inkFaint)),
                        ),
                      Positioned(
                        left: 10,
                        bottom: 10,
                        child: Material(
                          color: SnapBeeColors.surface,
                          borderRadius: BorderRadius.circular(SnapBeeSpacing.rPill),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(SnapBeeSpacing.rPill),
                            onTap: _pickOnMap,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.place_rounded, size: 15, color: SnapBeeColors.orange),
                                SizedBox(width: 5),
                                Text('Select on Map', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: SnapBeeColors.orange)),
                              ]),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              _field(_name, 'Full Name', Icons.person_outline_rounded, required: true),
              _field(_phone, 'Mobile Number', Icons.phone_outlined, keyboard: TextInputType.phone, required: true),
              Row(children: [
                Expanded(child: _field(_house, 'House / Flat No.', Icons.home_outlined, required: true)),
                Expanded(child: _field(_street, 'Street / Area', Icons.signpost_outlined, required: true)),
              ]),
              _field(_landmark, 'Landmark (optional)', Icons.apartment_outlined),
              Row(children: [
                Expanded(child: _field(_city, 'City', Icons.location_city_outlined, required: true)),
                Expanded(child: _field(_pincode, 'Pincode', Icons.pin_drop_outlined, keyboard: TextInputType.number, required: true)),
              ]),

              Padding(
                padding: const EdgeInsets.fromLTRB(SnapBeeSpacing.gutter, 12, SnapBeeSpacing.gutter, 6),
                child: Text('Address Type', style: SnapBeeText.label),
              ),
              Padding(
                padding: SnapBeeSpacing.screenH,
                child: Row(
                  children: [
                    for (var i = 0; i < _types.length; i++) ...[
                      if (i != 0) const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _type = i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _type == i ? SnapBeeColors.orangeTint : SnapBeeColors.surface,
                              borderRadius: BorderRadius.circular(SnapBeeSpacing.rTile),
                              border: Border.all(color: _type == i ? SnapBeeColors.orange : SnapBeeColors.hairline),
                            ),
                            child: Column(
                              children: [
                                Icon(_typeIcons[i], size: 18, color: _type == i ? SnapBeeColors.orange : SnapBeeColors.inkSoft),
                                const SizedBox(height: 4),
                                Text(_types[i], style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: _type == i ? SnapBeeColors.orangeDark : SnapBeeColors.inkSoft)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _field(_instructions, 'Delivery instructions (optional)', Icons.notes_outlined, maxLines: 2),

              Padding(
                padding: const EdgeInsets.fromLTRB(SnapBeeSpacing.gutter, 4, SnapBeeSpacing.gutter, 0),
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _isDefault,
                  onChanged: (v) => setState(() => _isDefault = v),
                  title: Text('Set as default address', style: SnapBeeText.title),
                  subtitle: Text('Use this address by default at checkout', style: SnapBeeText.caption),
                ),
              ),

              const SizedBox(height: 12),
              Padding(
                padding: SnapBeeSpacing.screenH,
                child: SnapBeePrimaryButton(
                  label: _saving ? 'Saving…' : 'Save Address',
                  icon: Icons.check_rounded,
                  onPressed: _saving ? null : _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    bool required = false,
    TextInputType? keyboard,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(SnapBeeSpacing.gutter, 6, SnapBeeSpacing.gutter, 6),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        maxLines: maxLines,
        validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 19, color: SnapBeeColors.inkFaint),
          filled: true,
          fillColor: SnapBeeColors.surface,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(SnapBeeSpacing.rField), borderSide: const BorderSide(color: SnapBeeColors.hairline)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(SnapBeeSpacing.rField), borderSide: const BorderSide(color: SnapBeeColors.hairline)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(SnapBeeSpacing.rField), borderSide: const BorderSide(color: SnapBeeColors.orange)),
        ),
      ),
    );
  }
}
