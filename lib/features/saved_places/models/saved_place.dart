import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/geo_point.dart';
import '../../search/models/place_result.dart';

enum SavedPlaceCategory {
  home('Home', Icons.home_outlined),
  work('Work', Icons.work_outline),
  favorite('Favorite', Icons.star_border),
  custom('Custom', Icons.bookmark_border);

  const SavedPlaceCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}

class SavedPlace {
  const SavedPlace({
    required this.id,
    required this.name,
    required this.address,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String address;
  final SavedPlaceCategory category;
  final double latitude;
  final double longitude;
  final DateTime createdAt;

  GeoPoint get point => GeoPoint(latitude: latitude, longitude: longitude);

  PlaceResult toPlaceResult() => PlaceResult(
        id: id,
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
      );

  factory SavedPlace.fromPlaceResult(PlaceResult place, {required SavedPlaceCategory category}) {
    return SavedPlace(
      id: const Uuid().v4(),
      name: place.name,
      address: place.address,
      category: category,
      latitude: place.latitude,
      longitude: place.longitude,
      createdAt: DateTime.now(),
    );
  }

  SavedPlace copyWith({String? name, String? address, SavedPlaceCategory? category}) {
    return SavedPlace(
      id: id,
      name: name ?? this.name,
      address: address ?? this.address,
      category: category ?? this.category,
      latitude: latitude,
      longitude: longitude,
      createdAt: createdAt,
    );
  }

  factory SavedPlace.fromJson(Map<String, dynamic> json) {
    return SavedPlace(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String? ?? '',
      category: SavedPlaceCategory.values.firstWhere(
        (category) => category.name == json['category'],
        orElse: () => SavedPlaceCategory.favorite,
      ),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'category': category.name,
        'latitude': latitude,
        'longitude': longitude,
        'createdAt': createdAt.toIso8601String(),
      };
}
