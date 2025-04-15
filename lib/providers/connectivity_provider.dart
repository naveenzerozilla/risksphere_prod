// import 'dart:async'; // Add this import for StreamSubscription
// import 'package:flutter/material.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
//
// class ConnectivityProvider with ChangeNotifier {
//   bool _isOnline = true;
//   bool get isOnline => _isOnline;
//
//   final Connectivity _connectivity = Connectivity();
//   StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
//
//   ConnectivityProvider() {
//     _initializeConnectivity();
//   }
//
//   Future<void> _initializeConnectivity() async {
//     try {
//       // Check initial connectivity
//       final result = await _connectivity.checkConnectivity();
//       await _updateStatus(result);
//
//       // Listen to connectivity changes
//       _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
//         _updateStatus(results);
//       });
//     } catch (e) {
//       debugPrint('Error initializing connectivity: $e');
//       _isOnline = false;
//       notifyListeners();
//     }
//   }
//
//   Future<void> _updateStatus(List<ConnectivityResult> results) async {
//     try {
//       final previousStatus = _isOnline;
//       // Consider connected if any of the results is not none
//       _isOnline = results.isNotEmpty && results.any((result) => result != ConnectivityResult.none);
//
//       if (previousStatus != _isOnline) {
//         notifyListeners();
//       }
//     } catch (e) {
//       debugPrint('Error updating connectivity status: $e');
//     }
//   }
//
//   @override
//   void dispose() {
//     _connectivitySubscription?.cancel();
//     super.dispose();
//   }
// }