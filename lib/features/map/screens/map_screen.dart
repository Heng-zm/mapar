import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;
import 'package:provider/provider.dart';

import '../../../core/models/geo_point.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/app_exception.dart';
import '../../navigation/controllers/navigation_session_controller.dart';
import '../../navigation/models/route_models.dart';
import '../../navigation/services/mapbox_directions_service.dart';
import '../../navigation/widgets/navigation_bottom_sheet.dart';
import '../../saved_places/models/saved_place.dart';
import '../../saved_places/services/saved_places_service.dart';
import '../../search/models/place_result.dart';
import '../../search/widgets/place_search_sheet.dart';
import '../../settings/controllers/settings_controller.dart';
import '../../trips/services/trip_history_service.dart';
import '../controllers/mapp_map_controller.dart';
import '../widgets/glass_panel.dart';
import '../widgets/location_stats_bar.dart';
import '../widgets/map_controls.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _bound = false;
  String? _drawnRouteKey;

  late LocationService _location;
  late MappMapController _map;
  late NavigationSessionController _nav;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bound) return;
    _location = context.read<LocationService>();
    _map = context.read<MappMapController>();
    _nav = context.read<NavigationSessionController>();
    _location.addListener(_onLocationChanged);
    _nav.addListener(_onNavigationChanged);
    _bound = true;
  }

  void _onLocationChanged() {
    final point = _location.currentGeoPoint;
    if (point != null) {
      _map.updateUserLocation(point, heading: _location.position?.heading);
      final position = _location.position;
      if (position != null) _nav.onLocationUpdate(position);
    }
  }

  void _onNavigationChanged() {
    final route = _nav.route;
    final destination = _nav.destination;
    if (route == null || destination == null) {
      _drawnRouteKey = null;
      _map.clearRoute();
      return;
    }
    final key = '${destination.id}:${route.profile.id}:${route.coordinates.length}:${route.distanceMeters}';
    if (_drawnRouteKey == key) return;
    _drawnRouteKey = key;
    _map.showSelectedPlace(destination);
    _map.drawRoute(route);
  }

  @override
  void dispose() {
    if (_bound) {
      _location.removeListener(_onLocationChanged);
      _nav.removeListener(_onNavigationChanged);
    }
    super.dispose();
  }

  Future<void> _openSearch() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => PlaceSearchSheet(
        proximity: _location.currentGeoPoint,
        onSelected: (place) {
          Navigator.pop(context);
          _selectPlace(place);
        },
      ),
    );
  }

  Future<void> _selectPlace(PlaceResult place, {RouteProfile? profile}) async {
    final current = _location.currentGeoPoint;
    if (current == null) {
      _showMessage('Current location is not ready yet.');
      return;
    }
    await _map.showSelectedPlace(place);
    await _createRoute(current, place, profile ?? _nav.profile);
  }

  Future<void> _createRoute(GeoPoint current, PlaceResult place, RouteProfile profile) async {
    if (!context.read<ConnectivityService>().isOnline) {
      _showMessage('Internet is offline. Saved places and trips still work, but route planning needs internet.');
      return;
    }
    try {
      _showMessage('Planning ${profile.label.toLowerCase()} route...');
      final route = await context.read<MapboxDirectionsService>().getRoute(
            start: current,
            destination: place.point,
            profile: profile,
          );
      _nav.setRoute(place, route);
      await _map.drawRoute(route);
    } on MappException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Route failed: $error');
    }
  }

  Future<void> _changeProfile(RouteProfile profile) async {
    _nav.setProfile(profile);
    final destination = _nav.destination;
    final current = _location.currentGeoPoint;
    if (destination != null && current != null) {
      await _createRoute(current, destination, profile);
    }
  }

  Future<void> _startStopNavigation() async {
    if (_nav.isNavigating) {
      final trip = await _nav.stopAndSave(context.read<TripHistoryService>());
      await _map.clearRoute();
      _showMessage(trip == null ? 'Navigation stopped.' : 'Trip saved to history.');
      return;
    }
    final position = _location.position;
    if (position == null) {
      _showMessage('Current location is not ready yet.');
      return;
    }
    _nav.start(position);
    _showMessage('Navigation started. Open the AR tab for AR guidance.');
  }

  Future<void> _saveDestination() async {
    final destination = _nav.destination;
    if (destination == null) return;
    final category = await showModalBottomSheet<SavedPlaceCategory>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Save place as', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              for (final item in SavedPlaceCategory.values)
                ListTile(
                  leading: Icon(item.icon),
                  title: Text(item.label),
                  onTap: () => Navigator.pop(context, item),
                ),
            ],
          ),
        ),
      ),
    );
    if (category == null) return;
    await context.read<SavedPlacesService>().savePlace(
          SavedPlace.fromPlaceResult(destination, category: category),
        );
    _showMessage('Saved ${destination.name}.');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final location = context.watch<LocationService>();
    final connectivity = context.watch<ConnectivityService>();
    final nav = context.watch<NavigationSessionController>();
    final position = location.position;
    final destination = nav.destination;
    final route = nav.route;

    return Scaffold(
      body: Stack(
        children: [
          mbx.MapWidget(
            key: ValueKey('map-${settings.mapStyle.uri}'),
            styleUri: settings.mapStyle.uri,
            cameraOptions: mbx.CameraOptions(
              center: mbx.Point(coordinates: mbx.Position(104.9282, 11.5564)),
              zoom: 12,
              pitch: 20,
            ),
            onMapCreated: (mapboxMap) async {
              await context.read<MappMapController>().onMapCreated(mapboxMap);
              final point = context.read<LocationService>().currentGeoPoint;
              if (point != null) await context.read<MappMapController>().updateUserLocation(point, animated: false);
              _onNavigationChanged();
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _openSearch,
                    child: GlassPanel(
                      borderRadius: 22,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.search),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              destination?.name ?? 'Search destination',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text(settings.mapStyle.label, style: Theme.of(context).textTheme.labelMedium),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (!connectivity.isOnline)
                    _StatusBanner(icon: Icons.wifi_off, text: 'Offline mode: local saved places, recent searches, and trips are available.'),
                  if (location.error != null) _StatusBanner(icon: Icons.location_off, text: location.error!),
                  if (settings.currentToken.isEmpty)
                    const _StatusBanner(icon: Icons.key_off, text: 'Mapbox token missing. Add it in .env or Settings.'),
                  LocationStatsBar(position: position, settings: settings, poorSignal: location.poorGpsSignal),
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: 220,
            child: MapControls(
              settings: settings,
              onZoomIn: () => context.read<MappMapController>().zoomIn(),
              onZoomOut: () => context.read<MappMapController>().zoomOut(),
              onRecenter: () => context.read<MappMapController>().recenter(),
              onCompass: () => context.read<MappMapController>().resetCompass(),
            ),
          ),
          if (destination != null && route != null)
            DraggableScrollableSheet(
              initialChildSize: 0.32,
              minChildSize: 0.22,
              maxChildSize: 0.46,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 86),
                  child: NavigationBottomSheet(
                    destination: destination,
                    route: route,
                    position: position,
                    settings: settings,
                    distanceRemainingMeters: nav.distanceRemaining(location.currentGeoPoint),
                    progress: nav.progress(location.currentGeoPoint),
                    isNavigating: nav.isNavigating,
                    selectedProfile: nav.profile,
                    onProfileChanged: _changeProfile,
                    onStartStop: _startStopNavigation,
                    onSavePlace: _saveDestination,
                    onClear: () {
                      context.read<NavigationSessionController>().clearRoute();
                      context.read<MappMapController>().clearRoute();
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassPanel(
        borderRadius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: scheme.error),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
          ],
        ),
      ),
    );
  }
}
