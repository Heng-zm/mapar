import '../../../core/models/geo_point.dart';

enum RouteProfile {
  driving('driving', 'Driving', 'mapbox/driving'),
  walking('walking', 'Walking', 'mapbox/walking'),
  cycling('cycling', 'Cycling', 'mapbox/cycling');

  const RouteProfile(this.id, this.label, this.mapboxProfile);
  final String id;
  final String label;
  final String mapboxProfile;
}

class RouteStep {
  const RouteStep({
    required this.instruction,
    required this.type,
    required this.location,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final String instruction;
  final String type;
  final GeoPoint location;
  final double distanceMeters;
  final double durationSeconds;

  factory RouteStep.fromJson(Map<String, dynamic> json) {
    final maneuver = json['maneuver'] as Map<String, dynamic>? ?? {};
    final location = (maneuver['location'] as List<dynamic>? ?? [0, 0]).cast<num>();
    return RouteStep(
      instruction: maneuver['instruction'] as String? ?? 'Continue',
      type: maneuver['type'] as String? ?? 'continue',
      location: GeoPoint(latitude: location[1].toDouble(), longitude: location[0].toDouble()),
      distanceMeters: (json['distance'] as num? ?? 0).toDouble(),
      durationSeconds: (json['duration'] as num? ?? 0).toDouble(),
    );
  }
}

class RoutePlan {
  const RoutePlan({
    required this.coordinates,
    required this.steps,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.profile,
  });

  final List<GeoPoint> coordinates;
  final List<RouteStep> steps;
  final double distanceMeters;
  final double durationSeconds;
  final RouteProfile profile;

  bool get hasRoute => coordinates.length >= 2;
}
