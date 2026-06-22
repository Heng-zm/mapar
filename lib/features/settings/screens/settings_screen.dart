import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/map_styles.dart';
import '../../../core/services/local_storage_service.dart';
import '../../saved_places/services/saved_places_service.dart';
import '../../trips/services/trip_history_service.dart';
import '../controllers/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Dark mode'),
                  subtitle: const Text('Use a modern dark navigation UI.'),
                  value: settings.isDarkMode,
                  onChanged: settings.setDarkMode,
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Map style'),
                  subtitle: Text(settings.mapStyle.label),
                  trailing: DropdownButton<MapStyleOption>(
                    value: settings.mapStyle,
                    items: MapStyles.values
                        .map((style) => DropdownMenuItem(value: style, child: Text(style.label)))
                        .toList(),
                    onChanged: (style) {
                      if (style != null) settings.setMapStyle(style);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Distance unit'),
                  trailing: DropdownButton<DistanceUnit>(
                    value: settings.distanceUnit,
                    items: DistanceUnit.values
                        .map((unit) => DropdownMenuItem(
                              value: unit,
                              child: Text(unit == DistanceUnit.kilometer ? 'Kilometer' : 'Mile'),
                            ))
                        .toList(),
                    onChanged: (unit) {
                      if (unit != null) settings.setDistanceUnit(unit);
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Speed unit'),
                  trailing: DropdownButton<SpeedUnit>(
                    value: settings.speedUnit,
                    items: SpeedUnit.values
                        .map((unit) => DropdownMenuItem(
                              value: unit,
                              child: Text(unit == SpeedUnit.kmh ? 'km/h' : 'mph'),
                            ))
                        .toList(),
                    onChanged: (unit) {
                      if (unit != null) settings.setSpeedUnit(unit);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.key_outlined),
                  title: const Text('Manage Mapbox token'),
                  subtitle: Text(_tokenPreview(settings.currentToken)),
                  onTap: () => _editToken(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cleaning_services_outlined),
                  title: const Text('Clear cache'),
                  subtitle: const Text('Clears recent place searches only. Saved places and trips are kept.'),
                  onTap: () async {
                    await context.read<LocalStorageService>().clearCacheOnly();
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache cleared.')));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Clear saved places'),
                  onTap: () => context.read<SavedPlacesService>().clear(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_sweep_outlined),
                  title: const Text('Clear trip history'),
                  onTap: () => context.read<TripHistoryService>().clear(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About Mapp AR'),
              subtitle: const Text('Smart Mapbox map, GPS tracker, route planner, and simulated AR guidance. Version 1.0.0'),
              isThreeLine: true,
            ),
          ),
        ],
      ),
    );
  }

  String _tokenPreview(String token) {
    if (token.isEmpty) return 'No token configured';
    final end = token.length < 12 ? token.length : 12;
    return '${token.substring(0, end)}...';
  }

  Future<void> _editToken(BuildContext context) async {
    final settings = context.read<SettingsController>();
    final controller = TextEditingController(text: settings.currentToken);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mapbox public token'),
        content: TextField(
          controller: controller,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Token',
            hintText: 'pk....',
            helperText: 'For production, prefer --dart-define instead of entering a token in the app.',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, ''), child: const Text('Use runtime token')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();
    if (result != null) {
      await settings.setMapboxToken(result);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Token updated. Restart if the native map was already loaded.')));
    }
  }
}
