import 'package:dio/dio.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/geo_point.dart';
import '../../../core/services/config_service.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/utils/app_exception.dart';
import '../../../core/utils/geo_utils.dart';
import '../models/place_result.dart';

class MapboxGeocodingService {
  MapboxGeocodingService(this._config, this._storage) : _dio = Dio();

  final ConfigService _config;
  final LocalStorageService _storage;
  final Dio _dio;

  Future<List<PlaceResult>> search(String query, {GeoPoint? proximity}) async {
    final token = _config.mapboxAccessToken;
    if (token.isEmpty) throw const MappException('Mapbox token is missing. Add it with --dart-define or Settings.');

    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${AppConstants.mapboxGeocodingBase}/${Uri.encodeComponent(trimmed)}.json',
        queryParameters: {
          'access_token': token,
          'limit': 8,
          'autocomplete': true,
          'types': 'country,region,place,locality,neighborhood,address,poi',
          if (proximity != null) 'proximity': '${proximity.longitude},${proximity.latitude}',
        },
      );

      final features = (response.data?['features'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      return features.map((feature) {
        final place = PlaceResult.fromMapboxFeature(feature, proximity: proximity);
        if (proximity == null) return place;
        return place.copyWithDistance(GeoUtils.distanceMeters(proximity, place.point));
      }).toList();
    } on DioException catch (error) {
      final message = error.response?.data is Map<String, dynamic>
          ? (error.response!.data as Map<String, dynamic>)['message']?.toString()
          : error.message;
      throw MappException('Place search failed: ${message ?? 'network error'}');
    }
  }

  Future<List<PlaceResult>> recentSearches() async {
    return _storage
        .getJsonList(AppConstants.storageRecentSearchesKey)
        .map(PlaceResult.fromJson)
        .toList();
  }

  Future<void> saveRecentSearch(PlaceResult place) async {
    final current = await recentSearches();
    final deduped = [place, ...current.where((item) => item.id != place.id)].take(10).toList();
    await _storage.setJsonList(
      AppConstants.storageRecentSearchesKey,
      deduped.map((item) => item.toJson()).toList(),
    );
  }
}
