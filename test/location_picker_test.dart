import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapbee_customer_app/core/location/location_service.dart';
import 'package:snapbee_customer_app/core/map/geocoding_service.dart';
import 'package:snapbee_customer_app/core/map/location_picker_screen.dart';
import 'package:snapbee_customer_app/core/map/picked_location.dart';

/// Offline stub — every tile is a 1x1 transparent pixel, so the widget test
/// never touches the network.
class _StubTileProvider extends TileProvider {
  static final _pixel = Uint8List.fromList(base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+P+/HgAFhAJ/wlseKgAAAABJRU5ErkJggg=='));

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(_pixel);
}

class _FakeGeocoding implements GeocodingService {
  List<GeoPlace> searchResults;
  Object? searchThrows;
  String? reverseResult;

  _FakeGeocoding({
    this.searchResults = const [],
    this.searchThrows,
    this.reverseResult,
  });

  @override
  Future<List<GeoPlace>> search(String query, {int limit = 6}) async {
    if (searchThrows != null) throw searchThrows!;
    return searchResults;
  }

  @override
  Future<String?> reverse(double lat, double lng) async => reverseResult;
}

class _FakeLocationService implements LocationService {
  LocationResult? result;
  LocationException? error;
  _FakeLocationService({this.result, this.error});

  @override
  Future<LocationResult> getCurrentLocation() async {
    if (error != null) throw error!;
    return result ?? const LocationResult(latitude: 0, longitude: 0);
  }
}

/// Pumps the picker on a generous surface with a real route beneath it (so
/// `Navigator.pop` returns a value), writing the popped result into [onResult].
Future<void> _open(
  WidgetTester tester, {
  required GeocodingService geocoding,
  LocationService? location,
  PickedLocation? initial,
  required void Function(PickedLocation?) onResult,
}) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (ctx) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final r = await Navigator.of(ctx).push<PickedLocation>(
            MaterialPageRoute(
              builder: (_) => LocationPickerScreen(
                geocoding: geocoding,
                locationService: location,
                initial: initial ??
                    const PickedLocation(
                        latitude: 12.9716, longitude: 77.5946, address: ''),
                tileProvider: _StubTileProvider(),
              ),
            ),
          );
          onResult(r);
        });
        return const Scaffold(body: SizedBox.shrink());
      },
    ),
  ));
  await tester.pump(); // run post-frame -> push
  await tester.pump(const Duration(milliseconds: 400)); // route transition
}

void main() {
  testWidgets('renders the OSM map, search field and confirm button', (tester) async {
    await _open(tester, geocoding: _FakeGeocoding(), onResult: (_) {});
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.text('Confirm location'), findsOneWidget);
    expect(find.widgetWithText(TextField, ''), findsWidgets);
  });

  testWidgets('search shows results; tapping one recenters and fills the address',
      (tester) async {
    final geo = _FakeGeocoding(searchResults: const [
      GeoPlace(label: 'MG Road, Bengaluru', lat: 12.9747, lng: 77.6094),
      GeoPlace(label: 'MG Road, Mumbai', lat: 18.9256, lng: 72.8311),
    ]);
    await _open(tester, geocoding: geo, onResult: (_) {});

    await tester.enterText(find.byType(TextField).first, 'MG Road');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('MG Road, Bengaluru'), findsOneWidget);
    expect(find.text('MG Road, Mumbai'), findsOneWidget);

    await tester.tap(find.text('MG Road, Bengaluru'));
    await tester.pump();

    expect(find.text('MG Road, Mumbai'), findsNothing); // list cleared
    // label now lives in both the search field and the editable address field
    expect(find.widgetWithText(TextField, 'MG Road, Bengaluru'), findsNWidgets(2));
  });

  testWidgets('empty search result surfaces a no-matches message', (tester) async {
    await _open(tester, geocoding: _FakeGeocoding(searchResults: const []), onResult: (_) {});
    await tester.enterText(find.byType(TextField).first, 'nowhere');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('No matching places found.'), findsOneWidget);
  });

  testWidgets('geocoding failure shows the typed error; map stays usable',
      (tester) async {
    await _open(tester,
        geocoding: _FakeGeocoding(
            searchThrows:
                const GeocodingException('Location search is unavailable right now.')),
        onResult: (_) {});
    await tester.enterText(find.byType(TextField).first, 'anything');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Location search is unavailable right now.'), findsOneWidget);
    expect(find.byType(FlutterMap), findsOneWidget);
  });

  testWidgets('current-location button surfaces a permission error', (tester) async {
    final loc = _FakeLocationService(
        error: const LocationException('Location permission is required.'));
    await _open(tester, geocoding: _FakeGeocoding(), location: loc, onResult: (_) {});

    await tester.tap(find.byIcon(Icons.my_location));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Location permission is required.'), findsOneWidget);
  });

  testWidgets('confirm returns a PickedLocation with the centre coordinate + address',
      (tester) async {
    PickedLocation? result;
    await _open(
      tester,
      geocoding: _FakeGeocoding(reverseResult: '12 MG Road'),
      initial: const PickedLocation(
          latitude: 12.9716, longitude: 77.5946, address: 'Home, MG Road'),
      onResult: (r) => result = r,
    );

    expect(find.widgetWithText(TextField, 'Home, MG Road'), findsOneWidget);

    await tester.tap(find.text('Confirm location'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(result, isNotNull);
    expect(result!.latitude, closeTo(12.9716, 1e-4));
    expect(result!.longitude, closeTo(77.5946, 1e-4));
    expect(result!.address, 'Home, MG Road');
  });
}
