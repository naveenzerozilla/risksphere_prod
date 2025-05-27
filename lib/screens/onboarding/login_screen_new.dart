// import 'package:flutter/material.dart';
// import '../home/dashboard_screen.dart';
//
//
// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});
//
//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }
//
// class _LoginScreenState extends State<LoginScreen> {
//   void _goToDashboard() async {
//     await Future.delayed(Duration(milliseconds: 100));
//     if (mounted) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => DashboardScreen()),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: ListView(
//         children: [
//           InkWell(
//             onTap: _goToDashboard,
//             child: Text("Login"),
//           ),
//         ],
//       ),
//     );
//   }
// }
