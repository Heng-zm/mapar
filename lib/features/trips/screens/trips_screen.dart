import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../settings/controllers/settings_controller.dart';
import '../models/trip_record.dart';
import '../services/trip_history_service.dart';

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<TripHistoryService>();
    final trips = service.trips;
    final settings = context.watch<SettingsController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip History'),
        actions: [
          if (trips.isNotEmpty)
            IconButton(
              onPressed: () => _confirmClear(context),
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear trips',
            ),
        ],
      ),
      body: trips.isEmpty
          ? const _EmptyTrips()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: trips.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final trip = trips[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    leading: const CircleAvatar(child: Icon(Icons.route)),
                    title: Text(Formatters.date(trip.startedAt)),
                    subtitle: Text(
                      '${Formatters.distance(trip.distanceMeters, settings.distanceUnit)} • '
                      '${Formatters.duration(trip.durationSeconds)} • max ${Formatters.speed(trip.maxSpeedMps, settings.speedUnit)}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'view') {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => TripMapScreen(trip: trip)));
                        } else if (value == 'delete') {
                          context.read<TripHistoryService>().deleteTrip(trip.id);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'view', child: Text('View on map')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear trip history?'),
        content: const Text('This removes all locally saved trips.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')),
        ],
      ),
    );
    if (ok == true && context.mounted) await context.read<TripHistoryService>().clear();
  }
}

class TripMapScreen extends StatefulWidget {
  const TripMapScreen({super.key, required this.trip});
  final TripRecord trip;

  @override
  State<TripMapScreen> createState() => _TripMapScreenState();
}

class _TripMapScreenState extends State<TripMapScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final first = widget.trip.path.isNotEmpty ? widget.trip.path.first : null;
    return Scaffold(
      appBar: AppBar(title: const Text('Trip Map')),
      body: mbx.MapWidget(
        styleUri: settings.mapStyle.uri,
        viewport: mbx.CameraViewportState(
          center: first == null ? null : mbx.Point(coordinates: mbx.Position(first.longitude, first.latitude)),
          zoom: 13,
          pitch: 25,
        ),
        onMapCreated: (map) async {
          if (widget.trip.path.length < 2) return;
          final manager = await map.annotations.createPolylineAnnotationManager();
          await manager.create(
            mbx.PolylineAnnotationOptions(
              geometry: mbx.LineString(
                coordinates: widget.trip.path
                    .map((point) => mbx.Position(point.longitude, point.latitude))
                    .toList(),
              ),
              lineColor: Theme.of(context).colorScheme.primary.toARGB32(),
              lineWidth: 7,
              lineBorderColor: Colors.white.toARGB32(),
              lineBorderWidth: 1.4,
            ),
          );
        },
      ),
    );
  }
}

class _EmptyTrips extends StatelessWidget {
  const _EmptyTrips();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.route_outlined, size: 72),
            const SizedBox(height: 16),
            Text('No trips recorded yet', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Start navigation from the Map tab. When you stop, Mapp AR saves distance, duration, speed, and route path.'),
          ],
        ),
      ),
    );
  }
}
