import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/local_storage_service.dart';
import '../models/saved_place.dart';

class SavedPlacesService extends ChangeNotifier {
  SavedPlacesService(this._storage);

  final LocalStorageService _storage;
  final List<SavedPlace> _places = [];

  List<SavedPlace> get places => List.unmodifiable(_places);

  Future<void> load() async {
    _places
      ..clear()
      ..addAll(_storage.getJsonList(AppConstants.storageSavedPlacesKey).map(SavedPlace.fromJson));
    _places.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  Future<void> savePlace(SavedPlace place) async {
    _places.removeWhere((item) => item.latitude == place.latitude && item.longitude == place.longitude && item.name == place.name);
    _places.insert(0, place);
    await _save();
    notifyListeners();
  }

  Future<void> updatePlace(SavedPlace place) async {
    final index = _places.indexWhere((item) => item.id == place.id);
    if (index == -1) return;
    _places[index] = place;
    await _save();
    notifyListeners();
  }

  Future<void> deletePlace(String id) async {
    _places.removeWhere((item) => item.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> clear() async {
    _places.clear();
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    await _storage.setJsonList(AppConstants.storageSavedPlacesKey, _places.map((place) => place.toJson()).toList());
  }
}
