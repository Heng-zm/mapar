import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/map_styles.dart';
import '../../../core/services/config_service.dart';
import '../../../core/services/local_storage_service.dart';

enum DistanceUnit { kilometer, mile }
enum SpeedUnit { kmh, mph }

class SettingsController extends ChangeNotifier {
  SettingsController(this._storage, this._config);

  final LocalStorageService _storage;
  final ConfigService _config;

  bool _isDarkMode = true;
  MapStyleOption _mapStyle = MapStyles.streets;
  DistanceUnit _distanceUnit = DistanceUnit.kilometer;
  SpeedUnit _speedUnit = SpeedUnit.kmh;

  bool get isDarkMode => _isDarkMode;
  MapStyleOption get mapStyle => _mapStyle;
  DistanceUnit get distanceUnit => _distanceUnit;
  SpeedUnit get speedUnit => _speedUnit;
  String get currentToken => _config.mapboxAccessToken;

  Future<void> load() async {
    final raw = _storage.getString(AppConstants.storageSettingsKey);
    if (raw == null) return;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _isDarkMode = json['isDarkMode'] as bool? ?? true;
    _mapStyle = MapStyles.byKey(json['mapStyle'] as String? ?? MapStyles.streets.key.name);
    _distanceUnit = DistanceUnit.values.firstWhere(
      (unit) => unit.name == json['distanceUnit'],
      orElse: () => DistanceUnit.kilometer,
    );
    _speedUnit = SpeedUnit.values.firstWhere(
      (unit) => unit.name == json['speedUnit'],
      orElse: () => SpeedUnit.kmh,
    );
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    notifyListeners();
    await _save();
  }

  Future<void> setMapStyle(MapStyleOption style) async {
    _mapStyle = style;
    notifyListeners();
    await _save();
  }

  Future<void> setDistanceUnit(DistanceUnit unit) async {
    _distanceUnit = unit;
    notifyListeners();
    await _save();
  }

  Future<void> setSpeedUnit(SpeedUnit unit) async {
    _speedUnit = unit;
    notifyListeners();
    await _save();
  }

  Future<void> setMapboxToken(String token) async {
    await _config.setTokenOverride(token);
    notifyListeners();
  }

  Future<void> _save() async {
    await _storage.setString(
      AppConstants.storageSettingsKey,
      jsonEncode({
        'isDarkMode': _isDarkMode,
        'mapStyle': _mapStyle.key.name,
        'distanceUnit': _distanceUnit.name,
        'speedUnit': _speedUnit.name,
      }),
    );
  }
}
