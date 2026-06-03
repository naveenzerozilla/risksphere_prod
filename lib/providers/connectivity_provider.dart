import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityProvider with ChangeNotifier {
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  late final StreamSubscription _subscription;

  final StreamController<bool> _statusStreamController =
  StreamController<bool>.broadcast();
  Stream<bool> get statusStream => _statusStreamController.stream;

  ConnectivityProvider() {
    _checkInitialConnection();
    // _subscription = Connectivity().onConnectivityChanged.listen(_updateStatus);
  }

  void _checkInitialConnection() async {
    final result = await Connectivity().checkConnectivity();
    // _updateStatus(result);
  }
  void _updateStatus(ConnectivityResult result) async {
    final currentResult = await Connectivity().checkConnectivity();

    bool previousStatus = _isOnline;
    _isOnline = currentResult != ConnectivityResult.none;

    _statusStreamController.add(_isOnline); //  Always emit for SnackBar

    if (_isOnline != previousStatus) {
      notifyListeners(); //  Only notify UI if status changed
    }
  }


  @override
  void dispose() {
    _subscription.cancel();
    _statusStreamController.close();
    super.dispose();
  }
}


