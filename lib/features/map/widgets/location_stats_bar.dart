import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/utils/formatters.dart';
import '../../settings/controllers/settings_controller.dart';
import 'glass_panel.dart';

class LocationStatsBar extends StatelessWidget {
  const LocationStatsBar({
    super.key,
    required this.position,
    required this.settings,
    required this.poorSignal,
  });

  final Position? position;
  final SettingsController settings;
  final bool poorSignal;

  @override
  Widget build(BuildContext context) {
    final p = position;
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borderRadius: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _Tile(label: 'Speed', value: p == null ? '--' : Formatters.speed(p.speed, settings.speedUnit)),
              _Tile(label: 'GPS', value: p == null ? '--' : '±${p.accuracy.toStringAsFixed(0)}m'),
              _Tile(label: 'Alt', value: p == null ? '--' : '${p.altitude.toStringAsFixed(0)}m'),
              _Tile(label: 'Head', value: p == null ? '--' : '${p.heading.toStringAsFixed(0)}°'),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(poorSignal ? Icons.signal_cellular_connected_no_internet_4_bar : Icons.gps_fixed,
                  size: 16, color: poorSignal ? Colors.orange : Colors.green),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  p == null
                      ? 'Waiting for location...'
                      : '${p.latitude.toStringAsFixed(6)}, ${p.longitude.toStringAsFixed(6)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.outline)),
          Text(value, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
