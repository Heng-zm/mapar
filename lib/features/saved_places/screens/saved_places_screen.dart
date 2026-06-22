import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/connectivity_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/app_exception.dart';
import '../../navigation/controllers/navigation_session_controller.dart';
import '../../navigation/services/mapbox_directions_service.dart';
import '../models/saved_place.dart';
import '../services/saved_places_service.dart';

class SavedPlacesScreen extends StatelessWidget {
  const SavedPlacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SavedPlacesService>();
    final places = service.places;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Places'),
        actions: [
          if (places.isNotEmpty)
            IconButton(
              onPressed: () => _confirmClear(context),
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear saved places',
            ),
        ],
      ),
      body: places.isEmpty
          ? const _EmptySavedPlaces()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: places.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final place = places[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    leading: CircleAvatar(child: Icon(place.category.icon)),
                    title: Text(place.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${place.category.label} • ${place.address}', maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'navigate') {
                          _navigate(context, place);
                        } else if (value == 'edit') {
                          _edit(context, place);
                        } else if (value == 'delete') {
                          context.read<SavedPlacesService>().deletePlace(place.id);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'navigate', child: Text('Navigate on map')),
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _navigate(BuildContext context, SavedPlace place) async {
    final current = context.read<LocationService>().currentGeoPoint;
    if (current == null) {
      _snack(context, 'Current location is not ready.');
      return;
    }
    if (!context.read<ConnectivityService>().isOnline) {
      _snack(context, 'Route planning needs internet.');
      return;
    }
    try {
      final nav = context.read<NavigationSessionController>();
      final route = await context.read<MapboxDirectionsService>().getRoute(
            start: current,
            destination: place.point,
            profile: nav.profile,
          );
      nav.setRoute(place.toPlaceResult(), route);
      _snack(context, 'Route ready. Open the Map tab to view it.');
    } on MappException catch (error) {
      _snack(context, error.message);
    } catch (error) {
      _snack(context, 'Route failed: $error');
    }
  }

  Future<void> _edit(BuildContext context, SavedPlace place) async {
    final nameController = TextEditingController(text: place.name);
    var category = place.category;
    final updated = await showDialog<SavedPlace>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit saved place'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 12),
              DropdownButtonFormField<SavedPlaceCategory>(
                value: category,
                items: SavedPlaceCategory.values
                    .map((item) => DropdownMenuItem(value: item, child: Text(item.label)))
                    .toList(),
                onChanged: (value) => setState(() => category = value ?? category),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(context, place.copyWith(name: nameController.text.trim(), category: category)),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    if (updated != null) await context.read<SavedPlacesService>().updatePlace(updated);
  }

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear saved places?'),
        content: const Text('This removes all saved places from local storage.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')),
        ],
      ),
    );
    if (ok == true && context.mounted) await context.read<SavedPlacesService>().clear();
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _EmptySavedPlaces extends StatelessWidget {
  const _EmptySavedPlaces();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bookmark_border, size: 72),
            const SizedBox(height: 16),
            Text('No saved places yet', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Search a destination on the Map tab, then tap the save button in the navigation panel.'),
          ],
        ),
      ),
    );
  }
}
