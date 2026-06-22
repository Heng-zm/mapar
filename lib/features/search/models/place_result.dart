import '../../../core/models/geo_point.dart';

class PlaceResult {
  const PlaceResult({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.distanceMeters,
  });

  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double? distanceMeters;

  GeoPoint get point => GeoPoint(latitude: latitude, longitude: longitude);

  factory PlaceResult.fromMapboxFeature(Map<String, dynamic> feature, {GeoPoint? proximity}) {
    final center = (feature['center'] as List<dynamic>).cast<num>();
    final point = GeoPoint(latitude: center[1].toDouble(), longitude: center[0].toDouble());
    return PlaceResult(
      id: feature['id'] as String? ?? '${point.latitude},${point.longitude}',
      name: feature['text'] as String? ?? feature['place_name'] as String? ?? 'Unknown place',
      address: feature['place_name'] as String? ?? '',
      latitude: point.latitude,
      longitude: point.longitude,
      distanceMeters: null,
    );
  }

  PlaceResult copyWithDistance(double? meters) {
    return PlaceResult(
      id: id,
      name: name,
      address: address,
      latitude: latitude,
      longitude: longitude,
      distanceMeters: meters,
    );
  }

  factory PlaceResult.fromJson(Map<String, dynamic> json) {
    return PlaceResult(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'distanceMeters': distanceMeters,
      };
}
