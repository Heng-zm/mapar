import 'dart:math' as math;

import '../models/geo_point.dart';

class GeoUtils {
  const GeoUtils._();

  static const earthRadiusMeters = 6371008.8;

  static double distanceMeters(GeoPoint a, GeoPoint b) {
    final lat1 = _rad(a.latitude);
    final lat2 = _rad(b.latitude);
    final dLat = _rad(b.latitude - a.latitude);
    final dLon = _rad(b.longitude - a.longitude);

    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2);
    return 2 * earthRadiusMeters * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }

  static double totalDistanceMeters(List<GeoPoint> points) {
    if (points.length < 2) return 0;
    var total = 0.0;
    for (var i = 1; i < points.length; i++) {
      total += distanceMeters(points[i - 1], points[i]);
    }
    return total;
  }

  static double bearingDegrees(GeoPoint from, GeoPoint to) {
    final lat1 = _rad(from.latitude);
    final lat2 = _rad(to.latitude);
    final dLon = _rad(to.longitude - from.longitude);
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  static double bearingDeltaDegrees(double targetBearing, double heading) {
    var delta = (targetBearing - heading + 540) % 360 - 180;
    if (delta.isNaN) delta = 0;
    return delta;
  }

  static int closestPointIndex(GeoPoint current, List<GeoPoint> route) {
    if (route.isEmpty) return 0;
    var bestIndex = 0;
    var bestDistance = double.infinity;
    for (var i = 0; i < route.length; i++) {
      final d = distanceMeters(current, route[i]);
      if (d < bestDistance) {
        bestDistance = d;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  static double _rad(double value) => value * math.pi / 180;
}
