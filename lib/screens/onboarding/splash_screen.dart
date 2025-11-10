import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:RiskSphere/providers/auth_provider.dart';
import 'package:RiskSphere/providers/theme_provider.dart';
import 'package:RiskSphere/providers/user_profile_provider.dart';
import 'package:RiskSphere/screens/home/dashboard_screen.dart';
import 'package:RiskSphere/screens/onboarding/login_screen.dart';
import 'package:RiskSphere/service/shared_preference_service.dart';
import 'package:tuple/tuple.dart';

// ✅ Moved outside class — compute() requires top-level/static function
Future<void> storeClaimsInBackground(Tuple2<Map<String, dynamic>, String> data) async {
  final claims = data.item1;
  final token = data.item2;

  try {
    await SharedPreferenceService.setClaims(claims);
    // optionally store token if needed
    // await SharedPreferenceService.setToken(token);
    await SharedPreferenceService.getAllClaims();
  } catch (e) {
    debugPrint("Error storing claims in isolate: $e");
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late ThemeProvider themeProvider;
  late Future<Widget> _initialScreenFuture;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.forward();

    themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    _initialScreenFuture = _determineInitialScreen();
  }

  Future<Widget> _determineInitialScreen() async {
    final authNotifier = Provider.of<AuthNotifier>(context, listen: false);
    authNotifier.initialOptions();

    try {
      // Give Firebase time to restore session
      await Future.delayed(const Duration(milliseconds: 300));

      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        log("No currentUser found.");
        return const LoginScreen();
      }

      // Run Firebase calls in parallel
      final results = await Future.wait([
        user.reload(),
        user.getIdTokenResult(),
        user.getIdToken(),
      ]);

      final tokenResult = results[1] as IdTokenResult;
      final tokenString = results[2] as String;
      final claims = tokenResult.claims ?? {};

      // ✅ Run heavy preference writes off main thread
      await compute(storeClaimsInBackground, Tuple2(claims, tokenString));

      // ✅ Fetch profile after UI builds
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.microtask(() {
          final profileProvider =
          Provider.of<UserProfileProvider>(context, listen: false);
          profileProvider.getAllUserData(context, '', '');
        });
      });

      // ✅ Instantly go to Dashboard
      return const DashboardScreen();
    } catch (e, stackTrace) {
      log("Error in _determineInitialScreen: $e\n$stackTrace");
      return const LoginScreen();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _initialScreenFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: themeProvider.getTheme.scaffoldBackgroundColor,
            body: Center(
              child: FadeTransition(
                opacity: _animation,
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: SvgPicture.asset(
                    'assets/images/logo.svg',
                    semanticsLabel: 'Logo',
                  ),
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const LoginScreen();
        }

        return snapshot.data!;
      },
    );
  }
}

// import 'dart:developer';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:provider/provider.dart';
// import 'package:RiskSphere/providers/auth_provider.dart';
// import 'package:RiskSphere/providers/theme_provider.dart';
// import 'package:RiskSphere/providers/user_profile_provider.dart';
// import 'package:RiskSphere/screens/home/dashboard_screen.dart';
// import 'package:RiskSphere/screens/onboarding/login_screen.dart';
// import 'package:RiskSphere/service/shared_preference_service.dart';
// import 'package:tuple/tuple.dart';
//
// class SplashScreen extends StatefulWidget {
//   @override
//   _SplashScreenState createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _animation;
//   late ThemeProvider themeProvider;
//   late Future<Widget> _initialScreenFuture;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: Duration(milliseconds: 300),
//     );
//     _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
//     _controller.forward();
//     themeProvider = Provider.of<ThemeProvider>(context, listen: false);
//     _initialScreenFuture = _determineInitialScreen();
//   } // for compute
//
//   Future<Widget> _determineInitialScreen() async {
//     final authNotifier = Provider.of<AuthNotifier>(context, listen: false);
//     authNotifier.initialOptions();
//
//     try {
//       // Let Firebase restore session briefly
//       await Future.delayed(const Duration(milliseconds: 300));
//
//       final user = FirebaseAuth.instance.currentUser;
//
//       if (user == null) {
//         log("No currentUser found.");
//         return const LoginScreen();
//       }
//
//       // Parallel: reload user + fetch token + claims
//       final results = await Future.wait([
//         user.reload(),
//         user.getIdTokenResult(),
//         user.getIdToken(),
//       ]);
//
//       final tokenResult = results[1] as IdTokenResult;
//       final tokenString = results[2] as String;
//       final claims = tokenResult.claims ?? {};
//
//       // ✅ Move SharedPreferences + claim storage off the main thread
//       await compute(_storeClaimsInBackground, Tuple2(claims, tokenString));
//
//       // ✅ Schedule user profile fetch after UI builds
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         Future.microtask(() {
//           final profileProvider =
//               Provider.of<UserProfileProvider>(context, listen: false);
//           profileProvider.getAllUserData(context, '', '');
//         });
//       });
//
//       // ✅ Instantly return dashboard while background tasks continue
//       return const DashboardScreen();
//     } catch (e, stackTrace) {
//       log("Error in _determineInitialScreen: $e\n$stackTrace");
//       return const LoginScreen();
//     }
//   }
//
// // Runs in a background isolate
//   void _storeClaimsInBackground(
//       Tuple2<Map<String, dynamic>, String> data) async {
//     final claims = data.item1;
//     final token = data.item2;
//
//     try {
//       await SharedPreferenceService.setClaims(claims);
//       // await SharedPreferenceService.setToken(token);
//       await SharedPreferenceService.getAllClaims();
//     } catch (e) {
//       debugPrint("Error storing claims in isolate: $e");
//     }
//   }
//
//   // Future<Widget> _determineInitialScreen() async {
//   //   final authNotifier = Provider.of<AuthNotifier>(context, listen: false);
//   //   authNotifier.initialOptions();
//   //
//   //   _test(); // Optional
//   //
//   //   try {
//   //     // Wait a little for Firebase to restore the session
//   //     await Future.delayed(const Duration(milliseconds: 500));
//   //
//   //     // 👇 Use direct currentUser check
//   //     User? currentUser = FirebaseAuth.instance.currentUser;
//   //
//   //     if (currentUser == null) {
//   //       log("No currentUser found.");
//   //       return const LoginScreen();
//   //     }
//   //
//   //     // Reload to ensure token/claims are updated
//   //     await currentUser.reload();
//   //     final tokenResult = await currentUser.getIdTokenResult();
//   //     final tokenString = await currentUser.getIdToken();
//   //     final claims = tokenResult.claims ?? {};
//   //
//   //     log("Claims: $claims");
//   //     log("Token: $tokenString");
//   //
//   //     await SharedPreferenceService.setClaims(claims);
//   //     await SharedPreferenceService.getAllClaims();
//   //
//   //     Future.microtask(() {
//   //       Provider.of<UserProfileProvider>(context, listen: false)
//   //           .getAllUserData(context, '', '');
//   //     });
//   //
//   //     return DashboardScreen(); // ✅ Go to dashboard
//   //   } catch (e, stackTrace) {
//   //     log("Error in _determineInitialScreen: $e\n$stackTrace");
//   //     return const LoginScreen();
//   //   }
//   // }
//
//   void _test() {
//     final db = FirebaseFirestore.instance;
//     final docRef = db.collection("test_process").doc("6gIC6Ljq3A3TQxUIH2oz");
//
//     docRef.snapshots().listen(
//       (event) {
//         log("current data: ${event.data()}");
//         log("loading percent: ${event.data()?['progress']}");
//       },
//       onError: (error) => log("Listen failed: $error"),
//     );
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<Widget>(
//       future: _initialScreenFuture,
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Scaffold(
//             backgroundColor: themeProvider.getTheme.scaffoldBackgroundColor,
//             body: Center(
//               child: FadeTransition(
//                 opacity: _animation,
//                 child: Container(
//                   width: 200,
//                   height: 200,
//                   child: SvgPicture.asset(
//                     'assets/images/logo.svg',
//                     semanticsLabel: 'Logo',
//                   ),
//                 ),
//               ),
//             ),
//           );
//         }
//
//         if (snapshot.hasError || !snapshot.hasData) {
//           return const LoginScreen();
//         }
//
//         return snapshot.data!;
//       },
//     );
//   }
// }
