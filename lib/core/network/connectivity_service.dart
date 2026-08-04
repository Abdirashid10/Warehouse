import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Observes device connectivity for offline-aware UI.
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  final _onlineController = StreamController<bool>.broadcast();
  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool get isOnline => _isOnline;

  Stream<bool> get onlineStream => _onlineController.stream;

  Future<void> start() async {
    final results = await _connectivity.checkConnectivity();
    _updateOnline(results);
    _subscription = _connectivity.onConnectivityChanged.listen(_updateOnline);
  }

  void _updateOnline(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (_isOnline == online) return;
    _isOnline = online;
    _onlineController.add(online);
    if (kDebugMode) {
      debugPrint('Connectivity: ${online ? 'online' : 'offline'}');
    }
  }

  void dispose() {
    _subscription?.cancel();
    _onlineController.close();
  }
}
