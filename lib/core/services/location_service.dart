import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/geo_point.dart';

class LocationService extends ChangeNotifier {
  StreamSubscription<Position>? _positionSubscription;

  Position? _position;
  String? _error;
  bool _serviceEnabled = true;
  bool _permissionGranted = false;

  Position? get position => _position;
  GeoPoint? get currentGeoPoint => _position == null
      ? null
      : GeoPoint(latitude: _position!.latitude, longitude: _position!.longitude);
  String? get error => _error;
  bool get serviceEnabled => _serviceEnabled;
  bool get permissionGranted => _permissionGranted;
  bool get poorGpsSignal => _position != null && _position!.accuracy > 50;

  Future<void> start() async {
    try {
      _serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!_serviceEnabled) {
        _error = 'Location service is disabled. Please turn on GPS.';
        notifyListeners();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        _permissionGranted = false;
        _error = permission == LocationPermission.deniedForever
            ? 'Location permission is permanently denied. Enable it in system settings.'
            : 'Location permission is required for live map tracking.';
        notifyListeners();
        return;
      }

      _permissionGranted = true;
      _error = null;
      _position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
      );
      notifyListeners();

      _positionSubscription?.cancel();
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 2,
        ),
      ).listen(
        (position) {
          _position = position;
          _error = null;
          notifyListeners();
        },
        onError: (Object error) {
          _error = 'Location update failed: $error';
          notifyListeners();
        },
      );
    } catch (error) {
      _error = 'Location failed: $error';
      notifyListeners();
    }
  }

  Future<void> openSettings() async {
    await Geolocator.openAppSettings();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}
