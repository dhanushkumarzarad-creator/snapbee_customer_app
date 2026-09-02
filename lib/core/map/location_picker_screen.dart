// ============================================================================
// location_picker_screen.dart — full-screen OSM map location picker.
// ----------------------------------------------------------------------------
// Reqs it satisfies: address/location selection with map (1), current-
// location detection (2), search + draggable pin (3), returns lat/lng +
// address (4). Reuses the existing [LocationService] (GPS) and the
// [GeocodingService] abstraction (Nominatim) — no duplicate location stack.
//
// Pin model: the pin is fixed at screen centre and the map pans under it
// (the standard, jank-free "drag to set" pattern) — the confirmed point is
// always `mapController.camera.center`. A reverse geocode runs, debounced,
// whenever the map comes to rest, filling the address field unless the user
// has already edited it.
//
// States handled explicitly: acquiring GPS (spinner), permission denied,
// GPS disabled, geocoding network error, empty search results, and the
// ordinary "move the map" idle state.
// ============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../location/location_service.dart';
import 'geocoding_service.dart';
import 'map_config.dart';
import 'osm_map.dart';
import 'picked_location.dart';

class LocationPickerScreen extends StatefulWidget {
  /// Where to open the map. When null the picker tries the device location
  /// once, then falls back to a neutral wide view.
  final PickedLocation? initial;

  /// Injectable for tests; defaults to the real implementations.
  final GeocodingService? geocoding;
  final LocationService? locationService;
  final TileProvider? tileProvider;

  const LocationPickerScreen({
    super.key,
    this.initial,
    this.geocoding,
    this.locationService,
    this.tileProvider,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late final GeocodingService _geocoding =
      widget.geocoding ?? NominatimGeocodingService();
  late final LocationService _location = widget.locationService ?? LocationService();

  final MapController _map = MapController();
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();

  LatLng _center = const LatLng(MapConfig.fallbackLat, MapConfig.fallbackLng);
  double _zoom = MapConfig.fallbackZoom;

  String? _resolvedAddress;
  bool _reverseInFlight = false;
  bool _addressEditedByUser = false;

  bool _locating = false;
  String? _locateError;

  bool _searching = false;
  String? _searchError;
  List<GeoPlace> _results = const [];

  Timer? _reverseDebounce;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _addressCtrl.addListener(() {
      if (_addressCtrl.text != (_resolvedAddress ?? '')) {
        _addressEditedByUser = _addressCtrl.text.trim().isNotEmpty;
      }
    });

    final initial = widget.initial;
    if (initial != null) {
      _center = LatLng(initial.latitude, initial.longitude);
      _zoom = MapConfig.focusZoom;
      _resolvedAddress = initial.address.isEmpty ? null : initial.address;
      _addressCtrl.text = initial.address;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _useCurrentLocation(silent: true));
    }
  }

  @override
  void dispose() {
    _reverseDebounce?.cancel();
    _searchCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  // --- current location ------------------------------------------------------

  Future<void> _useCurrentLocation({bool silent = false}) async {
    setState(() {
      _locating = true;
      if (!silent) _locateError = null;
    });
    try {
      final r = await _location.getCurrentLocation();
      if (!mounted) return;
      final p = LatLng(r.latitude, r.longitude);
      setState(() {
        _center = p;
        _zoom = MapConfig.focusZoom;
        _locating = false;
        _locateError = null;
      });
      if (_mapReady) _map.move(p, MapConfig.focusZoom);
      _scheduleReverse();
    } on LocationException catch (e) {
      if (!mounted) return;
      setState(() {
        _locating = false;
        // In silent (auto) mode, only surface a hard denial — not a "you
        // haven't granted it yet" first-run state.
        _locateError = silent ? null : e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locating = false;
        _locateError = silent ? null : 'Could not detect your location. Try again.';
      });
    }
  }

  // --- reverse geocode on map idle -----------------------------------------

  void _onMapEvent(MapEvent event) {
    final settled = event is MapEventMoveEnd ||
        event is MapEventFlingAnimationEnd ||
        event is MapEventDoubleTapZoomEnd ||
        event is MapEventScrollWheelZoom;
    if (!settled) return;
    _center = event.camera.center;
    _zoom = event.camera.zoom;
    _scheduleReverse();
  }

  void _scheduleReverse() {
    _reverseDebounce?.cancel();
    _reverseDebounce = Timer(const Duration(milliseconds: 700), _runReverse);
  }

  Future<void> _runReverse() async {
    final at = _center;
    setState(() => _reverseInFlight = true);
    try {
      final address = await _geocoding.reverse(at.latitude, at.longitude);
      if (!mounted) return;
      setState(() {
        _reverseInFlight = false;
        _resolvedAddress = address;
        if (!_addressEditedByUser && address != null) {
          _addressCtrl.text = address;
        }
      });
    } on GeocodingException catch (e) {
      if (!mounted) return;
      setState(() => _reverseInFlight = false);
      _snack(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _reverseInFlight = false);
    }
  }

  // --- search --------------------------------------------------------------

  Future<void> _runSearch() async {
    final q = _searchCtrl.text.trim();
    FocusScope.of(context).unfocus();
    if (q.isEmpty) {
      setState(() {
        _results = const [];
        _searchError = null;
      });
      return;
    }
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      final results = await _geocoding.search(q);
      if (!mounted) return;
      setState(() {
        _searching = false;
        _results = results;
        _searchError = results.isEmpty ? 'No matching places found.' : null;
      });
    } on GeocodingException catch (e) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _results = const [];
        _searchError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _results = const [];
        _searchError = 'Location search is unavailable right now.';
      });
    }
  }

  void _selectResult(GeoPlace place) {
    final p = LatLng(place.lat, place.lng);
    setState(() {
      _center = p;
      _zoom = MapConfig.focusZoom;
      _results = const [];
      _searchError = null;
      _searchCtrl.text = place.label;
      _addressEditedByUser = false;
      _resolvedAddress = place.label;
      _addressCtrl.text = place.label;
    });
    if (_mapReady) _map.move(p, MapConfig.focusZoom);
  }

  // --- confirm ------------------------------------------------------------

  void _confirm() {
    final typed = _addressCtrl.text.trim();
    Navigator.of(context).pop(
      PickedLocation(
        latitude: _center.latitude,
        longitude: _center.longitude,
        address: typed.isNotEmpty ? typed : (_resolvedAddress ?? ''),
      ),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set location', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          _SearchBar(
            controller: _searchCtrl,
            searching: _searching,
            onSubmit: _runSearch,
          ),
          if (_searchError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(_searchError!,
                  style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
            ),
          if (_results.isNotEmpty)
            _ResultsList(results: _results, onTap: _selectResult),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _map,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: _zoom,
                    minZoom: 2,
                    maxZoom: MapConfig.tileMaxZoom,
                    onMapReady: () => _mapReady = true,
                    onMapEvent: _onMapEvent,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    osmTileLayer(tileProvider: widget.tileProvider),
                    osmAttribution(),
                  ],
                ),
                // Fixed centre pin — the map pans under it.
                const IgnorePointer(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 40),
                      child: Icon(Icons.location_on, size: 44, color: Color(0xFFEF6C00)),
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: FloatingActionButton.small(
                    heroTag: 'picker-locate',
                    onPressed: _locating ? null : () => _useCurrentLocation(),
                    child: _locating
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
          ),
          _ConfirmPanel(
            addressController: _addressCtrl,
            resolvedAddress: _resolvedAddress,
            reverseInFlight: _reverseInFlight,
            locateError: _locateError,
            onConfirm: _locating ? null : _confirm,
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool searching;
  final VoidCallback onSubmit;

  const _SearchBar({
    required this.controller,
    required this.searching,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => onSubmit(),
        decoration: InputDecoration(
          hintText: 'Search area, street or landmark',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: searching
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : IconButton(icon: const Icon(Icons.arrow_forward), onPressed: onSubmit),
          isDense: true,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _ResultsList extends StatelessWidget {
  final List<GeoPlace> results;
  final ValueChanged<GeoPlace> onTap;

  const _ResultsList({required this.results, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 220),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: results.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final r = results[i];
            return ListTile(
              dense: true,
              leading: const Icon(Icons.place_outlined),
              title: Text(r.label, maxLines: 2, overflow: TextOverflow.ellipsis),
              onTap: () => onTap(r),
            );
          },
        ),
      ),
    );
  }
}

class _ConfirmPanel extends StatelessWidget {
  final TextEditingController addressController;
  final String? resolvedAddress;
  final bool reverseInFlight;
  final String? locateError;
  final VoidCallback? onConfirm;

  const _ConfirmPanel({
    required this.addressController,
    required this.resolvedAddress,
    required this.reverseInFlight,
    required this.locateError,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, size: 18, color: Color(0xFFEF6C00)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: reverseInFlight
                        ? Row(
                            children: const [
                              SizedBox(
                                  width: 14, height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2)),
                              SizedBox(width: 8),
                              Text('Finding address…'),
                            ],
                          )
                        : Text(
                            resolvedAddress ?? 'Move the map to place the pin',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                  ),
                ],
              ),
              if (locateError != null) ...[
                const SizedBox(height: 6),
                Text(locateError!,
                    style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
              ],
              const SizedBox(height: 10),
              TextField(
                controller: addressController,
                maxLines: 2,
                minLines: 1,
                decoration: const InputDecoration(
                  labelText: 'Address / landmark',
                  hintText: 'Flat / house no., building, street',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onConfirm,
                  icon: const Icon(Icons.check),
                  label: const Text('Confirm location'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
