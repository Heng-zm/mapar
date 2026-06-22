import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  final _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Future<void> init() async {
    _update(await _connectivity.checkConnectivity());
    _subscription = _connectivity.onConnectivityChanged.listen(_update);
  }

  void _update(List<ConnectivityResult> results) {
    final online = results.isNotEmpty && !results.contains(ConnectivityResult.none);
    if (online != _isOnline) {
      _isOnline = online;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
