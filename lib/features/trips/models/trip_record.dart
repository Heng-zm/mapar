import '../../../core/models/geo_point.dart';

class TripRecord {
  const TripRecord({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.path,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.maxSpeedMps,
    required this.averageSpeedMps,
  });

  final String id;
  final DateTime startedAt;
  final DateTime endedAt;
  final List<GeoPoint> path;
  final double distanceMeters;
  final double durationSeconds;
  final double maxSpeedMps;
  final double averageSpeedMps;

  factory TripRecord.fromJson(Map<String, dynamic> json) {
    return TripRecord(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: DateTime.parse(json['endedAt'] as String),
      path: (json['path'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map(GeoPoint.fromJson)
          .toList(),
      distanceMeters: (json['distanceMeters'] as num? ?? 0).toDouble(),
      durationSeconds: (json['durationSeconds'] as num? ?? 0).toDouble(),
      maxSpeedMps: (json['maxSpeedMps'] as num? ?? 0).toDouble(),
      averageSpeedMps: (json['averageSpeedMps'] as num? ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt.toIso8601String(),
        'path': path.map((item) => item.toJson()).toList(),
        'distanceMeters': distanceMeters,
        'durationSeconds': durationSeconds,
        'maxSpeedMps': maxSpeedMps,
        'averageSpeedMps': averageSpeedMps,
      };
}
