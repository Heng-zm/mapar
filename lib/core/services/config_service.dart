import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../constants/app_constants.dart';
import 'local_storage_service.dart';

class ConfigService {
  ConfigService(this._storage);

  final LocalStorageService _storage;
  String _tokenFromEnv = '';

  Future<void> init() async {
    const dartDefineToken = String.fromEnvironment(AppConstants.mapboxAccessTokenKey);
    _tokenFromEnv = dartDefineToken.isNotEmpty
        ? dartDefineToken
        : (dotenv.env[AppConstants.mapboxAccessTokenKey] ?? '');
  }

  String get mapboxAccessToken {
    final localOverride = _storage.getString(AppConstants.storageTokenOverrideKey);
    if (localOverride != null && localOverride.trim().isNotEmpty) return localOverride.trim();
    return _tokenFromEnv.trim();
  }

  Future<void> setTokenOverride(String token) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) {
      await _storage.remove(AppConstants.storageTokenOverrideKey);
      if (_tokenFromEnv.isNotEmpty) MapboxOptions.setAccessToken(_tokenFromEnv);
      return;
    }
    await _storage.setString(AppConstants.storageTokenOverrideKey, trimmed);
    MapboxOptions.setAccessToken(trimmed);
  }
}
