// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:provider/provider.dart';
// import 'connectivity_provider.dart';
//
// class ConnectivityToastListener extends StatefulWidget {
//   final Widget child;
//
//   const ConnectivityToastListener({super.key, required this.child});
//
//   @override
//   State<ConnectivityToastListener> createState() => _ConnectivityToastListenerState();
// }
//
// class _ConnectivityToastListenerState extends State<ConnectivityToastListener> {
//   late ConnectivityProvider _provider;
//   bool? _lastStatus;
//
//   @override
//   void initState() {
//     super.initState();
//
//     // Delay the listener until after first build
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _provider = Provider.of<ConnectivityProvider>(context, listen: false);
//       _lastStatus = _provider.isOnline;
//
//       _provider.addListener(_handleConnectivityChange);
//     });
//   }
//
//   void _handleConnectivityChange() {
//     final isOnline = _provider.isOnline;
//
//     if (_lastStatus != isOnline) {
//       showConnectivityToast(isOnline);
//       _lastStatus = isOnline;
//     }
//   }
//
//   @override
//   void dispose() {
//     _provider.removeListener(_handleConnectivityChange);
//     super.dispose();
//   }
//
//   void showConnectivityToast(bool isOnline) {
//     final msg = isOnline ? "Back Online" : "No Internet Connection";
//     final bgColor = isOnline ? Colors.green : Colors.red;
//
//     Fluttertoast.cancel(); // Cancel any existing toasts to avoid overlap
//
//     Fluttertoast.showToast(
//       msg: msg,
//       backgroundColor: bgColor,
//       textColor: Colors.white,
//       gravity: ToastGravity.TOP,
//       toastLength: Toast.LENGTH_SHORT,
//       fontSize: 16.0,
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return widget.child;
//   }
// }
