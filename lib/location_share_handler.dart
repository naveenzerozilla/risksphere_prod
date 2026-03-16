// import 'dart:async';
// import 'package:receive_sharing_intent/receive_sharing_intent.dart';
//
// class LocationShareHandler {
//   StreamSubscription? _intentSub;
//
//   void init(Function(String lat, String lng) onLocationReceived) {
//     // When app is opened from background
//     _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen((value) {
//       if (value.isNotEmpty) {
//         _extractLatLng(value.first.path, onLocationReceived);
//       }
//     });
//
//     // When app is opened from terminated state
//     ReceiveSharingIntent.instance.getInitialMedia().then((value) {
//       if (value.isNotEmpty) {
//         _extractLatLng(value.first.path, onLocationReceived);
//       }
//     });
//   }
//
//   void _extractLatLng(String text, Function(String, String) callback) {
//     final regex = RegExp(r'query=([-0-9.]+),([-0-9.]+)');
//     final match = regex.firstMatch(text);
//
//     if (match != null) {
//       final lat = match.group(1)!;
//       final lng = match.group(2)!;
//       callback(lat, lng);
//     }
//   }
//
//   void dispose() {
//     _intentSub?.cancel();
//   }
// }
