// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:provider/provider.dart';
//
// import '../providers/connectivity_provider.dart';
//
// class BaseScaffold extends StatefulWidget {
//   final Widget body;
//
//    BaseScaffold({
//     Key? key,
//     required this.body,
//
//   }) : super(key: key);
//
//   @override
//   State<BaseScaffold> createState() => _BaseScaffoldState();
// }
//
// class _BaseScaffoldState extends State<BaseScaffold> {
//   bool? _wasOnline;
//
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//
//     final isOnline = Provider.of<ConnectivityProvider>(context).isOnline;
//     if (_wasOnline != null && _wasOnline != isOnline) {
//       _showToast(isOnline);
//     }
//     _wasOnline = isOnline;
//   }
//
//   void _showToast(bool isOnline) {
//     Fluttertoast.showToast(
//       msg: isOnline ? "Back Online" : "No Internet Connection",
//       backgroundColor: isOnline ? Colors.green : Colors.red,
//       textColor: Colors.white,
//       toastLength: Toast.LENGTH_SHORT,
//       gravity: ToastGravity.TOP,
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: widget.body,
//     );
//   }
// }
