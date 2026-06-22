import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/local_storage_service.dart';
import '../models/trip_record.dart';

class TripHistoryService extends ChangeNotifier {
  TripHistoryService(this._storage);

  final LocalStorageService _storage;
  final List<TripRecord> _trips = [];

  List<TripRecord> get trips => List.unmodifiable(_trips);

  Future<void> load() async {
    _trips
      ..clear()
      ..addAll(_storage.getJsonList(AppConstants.storageTripsKey).map(TripRecord.fromJson));
    _trips.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    notifyListeners();
  }

  Future<void> addTrip(TripRecord trip) async {
    _trips.insert(0, trip);
    await _save();
    notifyListeners();
  }

  Future<void> deleteTrip(String id) async {
    _trips.removeWhere((trip) => trip.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> clear() async {
    _trips.clear();
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    await _storage.setJsonList(AppConstants.storageTripsKey, _trips.map((trip) => trip.toJson()).toList());
  }
}
