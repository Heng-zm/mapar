import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/utils/formatters.dart';
import '../../map/widgets/glass_panel.dart';
import '../../search/models/place_result.dart';
import '../../settings/controllers/settings_controller.dart';
import '../models/route_models.dart';

class NavigationBottomSheet extends StatelessWidget {
  const NavigationBottomSheet({
    super.key,
    required this.destination,
    required this.route,
    required this.position,
    required this.settings,
    required this.distanceRemainingMeters,
    required this.progress,
    required this.isNavigating,
    required this.selectedProfile,
    required this.onProfileChanged,
    required this.onStartStop,
    required this.onSavePlace,
    required this.onClear,
  });

  final PlaceResult destination;
  final RoutePlan route;
  final Position? position;
  final SettingsController settings;
  final double distanceRemainingMeters;
  final double progress;
  final bool isNavigating;
  final RouteProfile selectedProfile;
  final ValueChanged<RouteProfile> onProfileChanged;
  final VoidCallback onStartStop;
  final VoidCallback onSavePlace;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final speed = position?.speed ?? 0;
    final etaSeconds = speed > 1 ? distanceRemainingMeters / speed : route.durationSeconds * (1 - progress);
    return GlassPanel(
      borderRadius: 28,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(destination.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    Text(destination.address, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              IconButton(onPressed: onClear, icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 14),
          Row(
            children: [
              _Metric(label: 'Remaining', value: Formatters.distance(distanceRemainingMeters, settings.distanceUnit)),
              _Metric(label: 'ETA', value: Formatters.duration(etaSeconds)),
              _Metric(label: 'Speed', value: Formatters.speed(speed, settings.speedUnit)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<RouteProfile>(
                  value: selectedProfile,
                  decoration: const InputDecoration(labelText: 'Route mode', contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                  items: RouteProfile.values
                      .map((profile) => DropdownMenuItem(value: profile, child: Text(profile.label)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) onProfileChanged(value);
                  },
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(onPressed: onSavePlace, icon: const Icon(Icons.bookmark_add_outlined), tooltip: 'Save place'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onStartStop,
              icon: Icon(isNavigating ? Icons.stop_circle_outlined : Icons.navigation_outlined),
              label: Text(isNavigating ? 'Stop navigation' : 'Start navigation'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
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
