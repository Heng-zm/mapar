import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/geo_point.dart';
import '../../../core/utils/geo_utils.dart';
import '../../search/models/place_result.dart';
import '../../trips/models/trip_record.dart';
import '../../trips/services/trip_history_service.dart';
import '../models/route_models.dart';

class NavigationSessionController extends ChangeNotifier {
  RouteProfile _profile = RouteProfile.driving;
  PlaceResult? _destination;
  RoutePlan? _route;
  bool _isNavigating = false;
  DateTime? _startedAt;
  final List<GeoPoint> _travelPath = [];
  final List<double> _speedSamples = [];
  double _maxSpeed = 0;

  RouteProfile get profile => _profile;
  PlaceResult? get destination => _destination;
  RoutePlan? get route => _route;
  bool get isNavigating => _isNavigating;
  bool get hasDestination => _destination != null && _route != null;
  List<GeoPoint> get travelPath => List.unmodifiable(_travelPath);

  void setProfile(RouteProfile profile) {
    _profile = profile;
    notifyListeners();
  }

  void setRoute(PlaceResult destination, RoutePlan route) {
    _destination = destination;
    _route = route;
    _profile = route.profile;
    notifyListeners();
  }

  void clearRoute() {
    _destination = null;
    _route = null;
    _isNavigating = false;
    _startedAt = null;
    _travelPath.clear();
    _speedSamples.clear();
    _maxSpeed = 0;
    notifyListeners();
  }

  void start(Position currentPosition) {
    if (_route == null || _destination == null) return;
    _isNavigating = true;
    _startedAt = DateTime.now();
    _travelPath
      ..clear()
      ..add(GeoPoint(latitude: currentPosition.latitude, longitude: currentPosition.longitude));
    _speedSamples.clear();
    _maxSpeed = currentPosition.speed > 0 ? currentPosition.speed : 0;
    notifyListeners();
  }

  void onLocationUpdate(Position position) {
    if (!_isNavigating) return;
    final point = GeoPoint(latitude: position.latitude, longitude: position.longitude);
    final shouldAdd = _travelPath.isEmpty || GeoUtils.distanceMeters(_travelPath.last, point) >= 3;
    if (shouldAdd) _travelPath.add(point);
    if (position.speed >= 0) {
      _speedSamples.add(position.speed);
      if (position.speed > _maxSpeed) _maxSpeed = position.speed;
    }
    notifyListeners();
  }

  Future<TripRecord?> stopAndSave(TripHistoryService history) async {
    if (!_isNavigating || _startedAt == null) {
      clearRoute();
      return null;
    }

    final endedAt = DateTime.now();
    final duration = endedAt.difference(_startedAt!).inSeconds.toDouble();
    final distance = GeoUtils.totalDistanceMeters(_travelPath);
    final double averageSpeed = _speedSamples.isEmpty
        ? (duration > 0 ? distance / duration : 0.0)
        : _speedSamples.reduce((a, b) => a + b) / _speedSamples.length;

    final trip = TripRecord(
      id: const Uuid().v4(),
      startedAt: _startedAt!,
      endedAt: endedAt,
      path: List.unmodifiable(_travelPath),
      distanceMeters: distance,
      durationSeconds: duration,
      maxSpeedMps: _maxSpeed,
      averageSpeedMps: averageSpeed,
    );

    if (trip.path.length >= 2) {
      await history.addTrip(trip);
    }

    clearRoute();
    return trip.path.length >= 2 ? trip : null;
  }

  double distanceRemaining(GeoPoint? current) {
    if (current == null || _route == null || _route!.coordinates.isEmpty) return _route?.distanceMeters ?? 0;
    final index = GeoUtils.closestPointIndex(current, _route!.coordinates);
    final rest = [current, ..._route!.coordinates.skip(index)];
    return GeoUtils.totalDistanceMeters(rest);
  }

  double progress(GeoPoint? current) {
    if (_route == null || _route!.distanceMeters <= 0) return 0;
    final remaining = distanceRemaining(current).clamp(0.0, _route!.distanceMeters).toDouble();
    return (1.0 - remaining / _route!.distanceMeters).clamp(0.0, 1.0).toDouble();
  }

  String currentInstruction(GeoPoint? current) {
    if (_route == null || _route!.steps.isEmpty) return 'Go straight';
    if (current == null) return _route!.steps.first.instruction;

    RouteStep best = _route!.steps.first;
    var bestDistance = double.infinity;
    for (final step in _route!.steps) {
      final d = GeoUtils.distanceMeters(current, step.location);
      if (d < bestDistance) {
        bestDistance = d;
        best = step;
      }
    }
    return best.instruction;
  }
}
