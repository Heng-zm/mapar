import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;

import '../../../core/models/geo_point.dart';
import '../../navigation/models/route_models.dart';
import '../../search/models/place_result.dart';

class MappMapController extends ChangeNotifier {
  mbx.MapboxMap? _mapboxMap;
  mbx.CircleAnnotationManager? _circleManager;
  mbx.PolylineAnnotationManager? _polylineManager;
  mbx.CircleAnnotation? _userCircle;
  mbx.CircleAnnotation? _selectedCircle;
  mbx.PolylineAnnotation? _routeLine;

  GeoPoint? _lastUserPoint;
  bool _followUser = true;
  double _zoom = 15;

  bool get followUser => _followUser;
  bool get isReady => _mapboxMap != null;

  Future<void> onMapCreated(mbx.MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    _circleManager = await mapboxMap.annotations.createCircleAnnotationManager();
    _polylineManager = await mapboxMap.annotations.createPolylineAnnotationManager();
    if (_lastUserPoint != null) await updateUserLocation(_lastUserPoint!, animated: false);
    notifyListeners();
  }

  Future<void> updateUserLocation(GeoPoint point, {bool animated = true, double? heading}) async {
    _lastUserPoint = point;
    final manager = _circleManager;
    if (manager == null) return;

    final geometry = mbx.Point(coordinates: mbx.Position(point.longitude, point.latitude));
    if (_userCircle == null) {
      _userCircle = await manager.create(
        mbx.CircleAnnotationOptions(
          geometry: geometry,
          circleColor: const Color(0xFF2563EB).value,
          circleRadius: 11,
          circleStrokeColor: Colors.white.value,
          circleStrokeWidth: 3,
        ),
      );
    } else {
      _userCircle!.geometry = geometry;
      await manager.update(_userCircle!);
    }

    if (_followUser) {
      await moveCamera(point, zoom: _zoom, bearing: heading, pitch: 45, animated: animated);
    }
  }

  Future<void> showSelectedPlace(PlaceResult place) async {
    final manager = _circleManager;
    if (manager == null) return;
    if (_selectedCircle != null) await manager.delete(_selectedCircle!);
    _selectedCircle = await manager.create(
      mbx.CircleAnnotationOptions(
        geometry: mbx.Point(coordinates: mbx.Position(place.longitude, place.latitude)),
        circleColor: const Color(0xFFEF4444).value,
        circleRadius: 10,
        circleStrokeColor: Colors.white.value,
        circleStrokeWidth: 2,
      ),
    );
    await moveCamera(place.point, zoom: 15, pitch: 45);
  }

  Future<void> drawRoute(RoutePlan route) async {
    final manager = _polylineManager;
    if (manager == null || route.coordinates.length < 2) return;
    if (_routeLine != null) await manager.delete(_routeLine!);
    _routeLine = await manager.create(
      mbx.PolylineAnnotationOptions(
        geometry: mbx.LineString(
          coordinates: route.coordinates
              .map((point) => mbx.Position(point.longitude, point.latitude))
              .toList(),
        ),
        lineColor: const Color(0xFF3B82F6).value,
        lineWidth: 7,
        lineBorderColor: Colors.white.value,
        lineBorderWidth: 1.5,
      ),
    );
    await _fitRoute(route.coordinates);
  }

  Future<void> clearRoute() async {
    if (_routeLine != null && _polylineManager != null) {
      await _polylineManager!.delete(_routeLine!);
    }
    _routeLine = null;
    if (_selectedCircle != null && _circleManager != null) {
      await _circleManager!.delete(_selectedCircle!);
    }
    _selectedCircle = null;
  }

  Future<void> recenter() async {
    _followUser = true;
    if (_lastUserPoint != null) await moveCamera(_lastUserPoint!, zoom: _zoom, pitch: 45);
    notifyListeners();
  }

  void setFollowUser(bool value) {
    _followUser = value;
    notifyListeners();
  }

  Future<void> zoomIn() async {
    _zoom = (_zoom + 1).clamp(3, 20).toDouble();
    if (_lastUserPoint != null) await moveCamera(_lastUserPoint!, zoom: _zoom, pitch: 45);
  }

  Future<void> zoomOut() async {
    _zoom = (_zoom - 1).clamp(3, 20).toDouble();
    if (_lastUserPoint != null) await moveCamera(_lastUserPoint!, zoom: _zoom, pitch: 45);
  }

  Future<void> resetCompass() async {
    if (_lastUserPoint != null) await moveCamera(_lastUserPoint!, zoom: _zoom, bearing: 0, pitch: 30);
  }

  Future<void> moveCamera(
    GeoPoint point, {
    double zoom = 15,
    double? bearing,
    double? pitch,
    bool animated = true,
  }) async {
    final map = _mapboxMap;
    if (map == null) return;
    final options = mbx.CameraOptions(
      center: mbx.Point(coordinates: mbx.Position(point.longitude, point.latitude)),
      zoom: zoom,
      bearing: bearing,
      pitch: pitch,
    );
    if (!animated) {
      await map.setCamera(options);
      return;
    }
    try {
      await map.flyTo(options, mbx.MapAnimationOptions(duration: 650, startDelay: 0));
    } catch (_) {
      await map.setCamera(options);
    }
  }

  Future<void> _fitRoute(List<GeoPoint> points) async {
    if (points.isEmpty) return;
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;
    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }
    final center = GeoPoint(latitude: (minLat + maxLat) / 2, longitude: (minLng + maxLng) / 2);
    final spread = (maxLat - minLat).abs() + (maxLng - minLng).abs();
    final zoom = spread < 0.01 ? 14.5 : spread < 0.05 ? 12.5 : 10.5;
    await moveCamera(center, zoom: zoom, pitch: 35);
  }
}
