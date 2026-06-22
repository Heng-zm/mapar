import 'package:dio/dio.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/geo_point.dart';
import '../../../core/services/config_service.dart';
import '../../../core/utils/app_exception.dart';
import '../models/route_models.dart';

class MapboxDirectionsService {
  MapboxDirectionsService(this._config) : _dio = Dio();

  final ConfigService _config;
  final Dio _dio;

  Future<RoutePlan> getRoute({
    required GeoPoint start,
    required GeoPoint destination,
    required RouteProfile profile,
  }) async {
    final token = _config.mapboxAccessToken;
    if (token.isEmpty) throw const MappException('Mapbox token is missing. Add it with --dart-define or Settings.');

    final coordinates = '${start.longitude},${start.latitude};${destination.longitude},${destination.latitude}';
    final profilePath = profile.mapboxProfile.split('/').last;

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${AppConstants.mapboxDirectionsBase}/$profilePath/$coordinates',
        queryParameters: {
          'access_token': token,
          'geometries': 'geojson',
          'overview': 'full',
          'steps': true,
          'language': 'en',
        },
      );

      final routes = response.data?['routes'] as List<dynamic>? ?? [];
      if (routes.isEmpty) throw const MappException('No route found for this destination.');

      final route = routes.first as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>? ?? {};
      final rawCoordinates = (geometry['coordinates'] as List<dynamic>? ?? []).cast<List<dynamic>>();
      final routeCoordinates = rawCoordinates
          .map((item) => GeoPoint(latitude: (item[1] as num).toDouble(), longitude: (item[0] as num).toDouble()))
          .toList();

      final legs = (route['legs'] as List<dynamic>? ?? []);
      final steps = legs
          .expand((leg) => ((leg as Map<String, dynamic>)['steps'] as List<dynamic>? ?? []))
          .cast<Map<String, dynamic>>()
          .map(RouteStep.fromJson)
          .toList();

      return RoutePlan(
        coordinates: routeCoordinates,
        steps: steps,
        distanceMeters: (route['distance'] as num? ?? 0).toDouble(),
        durationSeconds: (route['duration'] as num? ?? 0).toDouble(),
        profile: profile,
      );
    } on DioException catch (error) {
      final message = error.response?.data is Map<String, dynamic>
          ? (error.response!.data as Map<String, dynamic>)['message']?.toString()
          : error.message;
      throw MappException('Route planning failed: ${message ?? 'network error'}');
    }
  }
}
