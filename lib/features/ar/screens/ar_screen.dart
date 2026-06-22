import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:provider/provider.dart';

import '../../../core/services/location_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/geo_utils.dart';
import '../../navigation/controllers/navigation_session_controller.dart';
import '../../settings/controllers/settings_controller.dart';
import '../widgets/ar_overlay.dart';

class ARScreen extends StatefulWidget {
  const ARScreen({super.key});

  @override
  State<ARScreen> createState() => _ARScreenState();
}

class _ARScreenState extends State<ARScreen> {
  StreamSubscription<CompassEvent>? _compassSub;
  double? _compassHeading;

  @override
  void initState() {
    super.initState();
    _compassSub = FlutterCompass.events?.listen((event) {
      if (mounted) setState(() => _compassHeading = event.heading);
    });
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = context.watch<LocationService>();
    final nav = context.watch<NavigationSessionController>();
    final settings = context.watch<SettingsController>();
    final destination = nav.destination;
    final current = location.currentGeoPoint;

    if (destination == null || nav.route == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('AR Navigation')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.view_in_ar_outlined, size: 72),
                const SizedBox(height: 16),
                Text('Choose a destination on the Map tab first.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text('This first version uses a clean simulated AR overlay with compass, route progress, and direction arrows.'),
              ],
            ),
          ),
        ),
      );
    }

    final double heading = (_compassHeading ?? location.position?.heading ?? 0.0).toDouble();
    final double targetBearing = current == null ? 0.0 : GeoUtils.bearingDegrees(current, destination.point);
    final double delta = GeoUtils.bearingDeltaDegrees(targetBearing, heading);
    final remaining = nav.distanceRemaining(current);
    final instruction = nav.currentInstruction(current);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF111827), Color(0xFF0F172A), Color(0xFF020617)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              AROverlay(
                arrowDegrees: delta,
                instruction: _simpleGuidance(delta, instruction),
                distanceText: Formatters.distance(remaining, settings.distanceUnit),
                progress: nav.progress(current),
                headingText: '${heading.toStringAsFixed(0)}°',
                speedText: Formatters.speed(location.position?.speed ?? 0, settings.speedUnit),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: IconButton.filledTonal(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
              Positioned(
                right: 16,
                top: 20,
                child: Chip(
                  avatar: Icon(nav.isNavigating ? Icons.navigation : Icons.pause_circle_outline, size: 18),
                  label: Text(nav.isNavigating ? 'Live AR' : 'Preview'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _simpleGuidance(double delta, String routeInstruction) {
    if (delta.abs() < 18) return routeInstruction.isEmpty ? 'Go straight' : routeInstruction;
    if (delta > 0) return 'Turn right';
    return 'Turn left';
  }
}
