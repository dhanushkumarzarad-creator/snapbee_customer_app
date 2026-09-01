import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/travel_repository.dart';
import '../theme/travel_colors.dart';
import 'trip_bookings_screen.dart';

/// Single-page trip/vehicle-rental booking flow: Pickup -> Destination ->
/// Start/End date -> Passengers -> Vehicle type -> Vehicle -> Driver option
/// -> live price (compute_travel_trip_price) -> Book (create_travel_trip_booking).
/// Matches the spec flow; kept on one scrollable page rather than a
/// multi-screen wizard so every field stays visible while the price updates.
class TripBookingScreen extends StatefulWidget {
  const TripBookingScreen({super.key});

  @override
  State<TripBookingScreen> createState() => _TripBookingScreenState();
}

class _TripBookingScreenState extends State<TripBookingScreen> {
  final _repo = TravelRepository(Supabase.instance.client);
  final _pickup = TextEditingController();
  final _destination = TextEditingController();
  final _purpose = TextEditingController();

  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 2));
  int _passengers = 4;
  bool _withDriver = true;

  List<Map<String, dynamic>> _vehicleTypes = [];
  String? _selectedVehicleTypeId;
  List<Map<String, dynamic>> _vehicles = [];
  String? _selectedVehicleId;
  Map<String, dynamic>? _priceBreakdown;

  bool _loadingTypes = true;
  bool _loadingVehicles = false;
  bool _loadingPrice = false;
  bool _booking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVehicleTypes();
  }

  Future<void> _loadVehicleTypes() async {
    try {
      final types = await _repo.listActiveVehicleTypes();
      setState(() {
        _vehicleTypes = types;
        _loadingTypes = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load vehicle types: $e';
        _loadingTypes = false;
      });
    }
  }

  Future<void> _onVehicleTypeSelected(String typeId) async {
    setState(() {
      _selectedVehicleTypeId = typeId;
      _selectedVehicleId = null;
      _priceBreakdown = null;
      _loadingVehicles = true;
    });
    try {
      final vehicles = await _repo.listAvailableVehicles(vehicleTypeId: typeId);
      setState(() {
        _vehicles = vehicles;
        _loadingVehicles = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load vehicles: $e';
        _loadingVehicles = false;
      });
    }
  }

  Future<void> _onVehicleSelected(String vehicleId) async {
    setState(() {
      _selectedVehicleId = vehicleId;
      _loadingPrice = true;
    });
    await _recomputePrice();
  }

  Future<void> _recomputePrice() async {
    if (_selectedVehicleId == null || _selectedVehicleTypeId == null) return;
    final vehicle = _vehicles.firstWhere((v) => v['id'] == _selectedVehicleId);
    final vendorId = vehicle['vendor_id'] as String;
    setState(() => _loadingPrice = true);
    try {
      final price = await _repo.computeTripPrice(
        vehicleTypeId: _selectedVehicleTypeId!,
        vendorId: vendorId,
        startDate: _startDate,
        endDate: _endDate,
        withDriver: _withDriver,
      );
      setState(() {
        _priceBreakdown = price;
        _loadingPrice = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not compute price: $e';
        _loadingPrice = false;
      });
    }
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (range != null) {
      setState(() {
        _startDate = range.start;
        _endDate = range.end;
      });
      if (_selectedVehicleId != null) await _recomputePrice();
    }
  }

  Future<void> _book() async {
    if (_pickup.text.trim().isEmpty || _destination.text.trim().isEmpty || _selectedVehicleId == null) {
      setState(() => _error = 'Fill pickup, destination and select a vehicle.');
      return;
    }
    setState(() {
      _booking = true;
      _error = null;
    });
    try {
      final bookingId = await _repo.createTripBooking(
        vehicleId: _selectedVehicleId!,
        pickup: _pickup.text.trim(),
        destination: _destination.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        passengers: _passengers,
        withDriver: _withDriver,
        purpose: _purpose.text.trim().isEmpty ? null : _purpose.text.trim(),
      );
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Trip booked!'),
          content: Text('Booking ID: $bookingId\nOur vendor will assign a driver shortly.'),
          actions: [FilledButton(onPressed: () => Navigator.pop(dialogContext), style: FilledButton.styleFrom(backgroundColor: TravelColors.primary), child: const Text('OK'))],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const TripBookingsScreen()));
    } catch (e) {
      setState(() => _error = 'Booking failed: $e');
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TravelColors.background,
      appBar: AppBar(title: const Text('Book a trip'), backgroundColor: TravelColors.primary, foregroundColor: Colors.white),
      body: _loadingTypes
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(controller: _pickup, decoration: const InputDecoration(labelText: 'Pickup location', border: OutlineInputBorder(), prefixIcon: Icon(Icons.trip_origin))),
                const SizedBox(height: 12),
                TextField(controller: _destination, decoration: const InputDecoration(labelText: 'Destination', border: OutlineInputBorder(), prefixIcon: Icon(Icons.place))),
                const SizedBox(height: 12),
                ListTile(
                  tileColor: TravelColors.cardGrey,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  title: Text('${_fmt(_startDate)} → ${_fmt(_endDate)}  (${_endDate.difference(_startDate).inDays + 1} day(s))'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickDateRange,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Passengers:'),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: _passengers > 1 ? () => setState(() => _passengers--) : null),
                    Text('$_passengers', style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => setState(() => _passengers++)),
                  ],
                ),
                const Divider(height: 24),
                Text('Vehicle type', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _vehicleTypes.map((t) {
                    final selected = t['id'] == _selectedVehicleTypeId;
                    return ChoiceChip(
                      label: Text('${t['name']} (${t['capacity']} seats)'),
                      selected: selected,
                      selectedColor: TravelColors.primaryLight,
                      onSelected: (_) => _onVehicleTypeSelected(t['id'] as String),
                    );
                  }).toList(),
                ),
                if (_selectedVehicleTypeId != null) ...[
                  const SizedBox(height: 16),
                  Text('Vehicle', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (_loadingVehicles)
                    const Center(child: CircularProgressIndicator())
                  else if (_vehicles.isEmpty)
                    const Text('No vehicles available for this type right now.')
                  else
                    ..._vehicles.map((v) {
                      final selected = v['id'] == _selectedVehicleId;
                      final vendorName = (v['travel_vendors'] as Map?)?['business_name'] ?? '';
                      return Card(
                        color: selected ? TravelColors.primaryLight : null,
                        child: ListTile(
                          leading: const Icon(Icons.directions_car),
                          title: Text('${v['registration_number']} · $vendorName'),
                          subtitle: Text(v['model_name'] ?? ''),
                          trailing: selected ? const Icon(Icons.check_circle, color: TravelColors.primary) : null,
                          onTap: () => _onVehicleSelected(v['id'] as String),
                        ),
                      );
                    }),
                ],
                const SizedBox(height: 16),
                SwitchListTile(
                  tileColor: TravelColors.cardGrey,
                  title: const Text('Include driver'),
                  value: _withDriver,
                  activeThumbColor: TravelColors.primary,
                  onChanged: (v) {
                    setState(() => _withDriver = v);
                    if (_selectedVehicleId != null) _recomputePrice();
                  },
                ),
                const SizedBox(height: 12),
                TextField(controller: _purpose, decoration: const InputDecoration(labelText: 'Trip purpose (optional — e.g. family trip, college trip)', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                if (_loadingPrice) const Center(child: CircularProgressIndicator()),
                if (_priceBreakdown != null && !_loadingPrice)
                  Card(
                    color: TravelColors.primaryLight,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Price summary', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text('${_priceBreakdown!['days']} day(s) × ₹${_priceBreakdown!['per_day_rate']}/day'),
                          if ((_priceBreakdown!['driver_allowance'] as num? ?? 0) > 0) Text('Driver allowance: ₹${_priceBreakdown!['driver_allowance']}'),
                          const Divider(),
                          Text('Total: ₹${_priceBreakdown!['base_amount']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: const TextStyle(color: Colors.red))],
                const SizedBox(height: 20),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: TravelColors.primary, padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: (_selectedVehicleId == null || _booking) ? null : _book,
                  child: _booking ? const CircularProgressIndicator(color: Colors.white) : const Text('Confirm booking'),
                ),
              ],
            ),
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
