// ============================================================================
// osm_map.dart — shared flutter_map building blocks (OSM tiles + attribution)
// and a small read-only map used for previews and live tracking.
// ----------------------------------------------------------------------------
// Everything map-related in the app goes through here so the tile source and
// attribution are defined exactly once (see map_config.dart).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'map_config.dart';

/// The configured OpenStreetMap raster tile layer. Use this in every
/// [FlutterMap]. `tileProvider` is injectable so widget tests can supply an
/// offline stub instead of hitting the network.
TileLayer osmTileLayer({TileProvider? tileProvider}) => TileLayer(
      urlTemplate: MapConfig.tileUrlTemplate,
      userAgentPackageName: MapConfig.tilePackageName,
      maxNativeZoom: MapConfig.tileMaxZoom.round(),
      maxZoom: MapConfig.tileMaxZoom,
      tileProvider: tileProvider,
      // Keep the last tiles visible while new ones load — no white flashes.
      keepBuffer: 4,
    );

/// Required OSM attribution. Bottom-right, unobtrusive, tappable.
Widget osmAttribution() => RichAttributionWidget(
      alignment: AttributionAlignment.bottomRight,
      attributions: [
        TextSourceAttribution(
          MapConfig.tileAttribution,
          onTap: () {}, // opening a URL needs url_launcher; label alone satisfies the policy
        ),
      ],
    );

/// A non-interactive map centred on [point] with a single pin — used for the
/// checkout preview and (with [extraMarkers]) live delivery tracking.
class StaticLocationMap extends StatelessWidget {
  final LatLng point;
  final double zoom;
  final double height;
  final List<Marker> extraMarkers;
  final Color pinColor;
  final TileProvider? tileProvider;
  final MapController? controller;

  const StaticLocationMap({
    super.key,
    required this.point,
    this.zoom = 15.5,
    this.height = 150,
    this.extraMarkers = const [],
    this.pinColor = const Color(0xFFEF6C00),
    this.tileProvider,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: height,
        child: FlutterMap(
          mapController: controller,
          options: MapOptions(
            initialCenter: point,
            initialZoom: zoom,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
          ),
          children: [
            osmTileLayer(tileProvider: tileProvider),
            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  width: 40,
                  height: 40,
                  alignment: Alignment.topCenter,
                  child: Icon(Icons.location_on, color: pinColor, size: 40),
                ),
                ...extraMarkers,
              ],
            ),
            osmAttribution(),
          ],
        ),
      ),
    );
  }
}
