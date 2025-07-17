import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:RiskSphere/providers/auth_provider.dart';
import 'package:RiskSphere/providers/theme_provider.dart';
import 'package:RiskSphere/providers/user_profile_provider.dart';
import 'package:RiskSphere/screens/home/dashboard_screen.dart';
import 'package:RiskSphere/screens/onboarding/login_screen.dart';
import 'package:RiskSphere/service/shared_preference_service.dart';

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
      duration: Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.forward();
    themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    _initialScreenFuture = _determineInitialScreen();
  }

  Future<Widget> _determineInitialScreen() async {
    final authNotifier = Provider.of<AuthNotifier>(context, listen: false);
    authNotifier.initialOptions();

    _test(); // Optional

    try {
      // Wait a little for Firebase to restore the session
      await Future.delayed(const Duration(milliseconds: 500));

      // 👇 Use direct currentUser check
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        log("No currentUser found.");
        return const LoginScreen();
      }

      // Reload to ensure token/claims are updated
      await currentUser.reload();
      final tokenResult = await currentUser.getIdTokenResult();
      final tokenString = await currentUser.getIdToken();
      final claims = tokenResult.claims ?? {};

      log("Claims: $claims");
      log("Token: $tokenString");

      await SharedPreferenceService.setClaims(claims);
      await SharedPreferenceService.getAllClaims();

      Future.microtask(() {
        Provider.of<UserProfileProvider>(context, listen: false)
            .getAllUserData(context, '', '');
      });

      return DashboardScreen(); // ✅ Go to dashboard
    } catch (e, stackTrace) {
      log("Error in _determineInitialScreen: $e\n$stackTrace");
      return const LoginScreen();
    }
  }


  void _test() {
    final db = FirebaseFirestore.instance;
    final docRef = db.collection("test_process").doc("6gIC6Ljq3A3TQxUIH2oz");

    docRef.snapshots().listen(
      (event) {
        log("current data: ${event.data()}");
        log("loading percent: ${event.data()?['progress']}");
      },
      onError: (error) => log("Listen failed: $error"),
    );
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
                child: Container(
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
//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:provider/provider.dart';
// import 'package:RiskSphere/providers/auth_provider.dart';
// import 'package:RiskSphere/providers/theme_provider.dart';
// import 'package:RiskSphere/providers/user_profile_provider.dart';
// import 'package:RiskSphere/screens/home/dashboard_screen.dart';
// import 'package:RiskSphere/screens/onboarding/login_screen.dart';
// import 'package:RiskSphere/service/shared_preference_service.dart';
//
// import 'login_screen_new.dart';
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
//
//   @override
//   void initState() {
//     super.initState();
//     _initialize();
//     _controller = AnimationController(
//       vsync: this,
//       duration: Duration(milliseconds: 300),
//     );
//     _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
//     _controller.forward();
//     themeProvider = Provider.of<ThemeProvider>(context, listen: false);
//   }
//
//
//   Future<void> _initialize() async {
//     final authNotifier = Provider.of<AuthNotifier>(context, listen: false);
//     authNotifier.initialOptions();
//
//     _test();
//
//     try {
//       // 👇 Wait for Firebase to restore auth state properly
//       final currentUser = await FirebaseAuth.instance.authStateChanges().first;
//
//       if (currentUser == null) {
//         log("No current user found. Redirecting to LoginScreen.");
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (_) => const LoginScreen()),
//           );
//         });
//         return;
//       }
//
//       await currentUser.reload();
//
//       final tokenResult = await currentUser.getIdTokenResult();
//       final tokenString = await currentUser.getIdToken();
//       final claims = tokenResult.claims ?? {};
//
//       log("Claims: $claims");
//       log("Token: $tokenString");
//
//       await SharedPreferenceService.setClaims(claims);
//       await SharedPreferenceService.getAllClaims();
//
//       final isUserRegistered = claims['isIndividual'] != null;
//       log("isUserRegistered: $isUserRegistered");
//
//       if (tokenString != null && tokenString.isNotEmpty) {
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (_) => DashboardScreen()),
//           );
//         });
//
//         // Load user profile in background
//         Future.microtask(() {
//           Provider.of<UserProfileProvider>(context, listen: false)
//               .getAllUserData(context, '', '');
//         });
//       } else {
//         log("Empty tokenString. Redirecting to LoginScreen.");
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (_) => const LoginScreen()),
//           );
//         });
//       }
//     } catch (e, stackTrace) {
//       log("Navigation error: $e\n$stackTrace");
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (_) => const LoginScreen()),
//         );
//       });
//     }
//   }
//
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
//     return Scaffold(
//       backgroundColor: themeProvider.getTheme.scaffoldBackgroundColor,
//       body: Center(
//         child: FadeTransition(
//           opacity: _animation,
//           child: Container(
//             width: 200,
//             height: 200,
//             child: SvgPicture.asset(
//               'assets/images/logo.svg',
//               semanticsLabel: 'Logo',
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
