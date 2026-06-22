import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../constants/app_constants.dart';
import 'local_storage_service.dart';

class ConfigService {
  ConfigService(this._storage);

  final LocalStorageService _storage;
  String _tokenFromRuntimeConfig = '';

  Future<void> init() async {
    // Build/run-time token injection. This is safer and more reliable than
    // bundling a `.env` file as a Flutter asset, especially for Flutter Web.
    const dartDefineToken = String.fromEnvironment(AppConstants.mapboxAccessTokenKey);
    _tokenFromRuntimeConfig = dartDefineToken.trim();
  }

  String get mapboxAccessToken {
    final localOverride = _storage.getString(AppConstants.storageTokenOverrideKey);
    if (localOverride != null && localOverride.trim().isNotEmpty) return localOverride.trim();
    return _tokenFromRuntimeConfig.trim();
  }

  Future<void> setTokenOverride(String token) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) {
      await _storage.remove(AppConstants.storageTokenOverrideKey);
      if (_tokenFromRuntimeConfig.isNotEmpty) MapboxOptions.setAccessToken(_tokenFromRuntimeConfig);
      return;
    }
    await _storage.setString(AppConstants.storageTokenOverrideKey, trimmed);
    MapboxOptions.setAccessToken(trimmed);
  }
}
