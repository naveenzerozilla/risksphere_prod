import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:RiskSphere/providers/theme_provider.dart';
import 'package:RiskSphere/providers/user_profile_provider.dart';
import 'package:RiskSphere/screens/home/dashboard_screen.dart';
import 'package:RiskSphere/screens/onboarding/login_screen.dart';
import 'package:RiskSphere/service/shared_preference_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
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

    themeProvider = context.read<ThemeProvider>();
    _initialScreenFuture = _determineInitialScreen();
  }

  /// 🔐 SINGLE SOURCE OF TRUTH FOR INITIAL ROUTING
  Future<Widget> _determineInitialScreen() async {
    final auth = FirebaseAuth.instance;

    /// 1️⃣ First-run logic (ONLY ONCE)
    final bool? firstRun = await SharedPreferenceService.getBool("first_run");

    if (firstRun != false) {
      await SharedPreferenceService.setBool("first_run", false);
      await auth.signOut();
      return const LoginScreen();
    }

    /// 2️⃣ Wait until Firebase finishes restoring auth state
    User? user;
    try {
      user = await auth
          .authStateChanges()
          .timeout(const Duration(seconds: 5))
          .first;
    } catch (_) {
      user = null;
    }

    /// 3️⃣ No session → Login
    if (user == null) {
      return const LoginScreen();
    }

    /// 4️⃣ Session exists → restore claims + profile
    try {
      final tokenResult = await user.getIdTokenResult(true);
      final claims = tokenResult.claims ?? {};

      await SharedPreferenceService.setClaims(claims);

      /// Load profile AFTER navigation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<UserProfileProvider>().getAllUserData(context, '', '');
      });

      return DashboardScreen();
    } catch (e) {

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

        if (!snapshot.hasData || snapshot.hasError) {
          return const LoginScreen();
        }

        return snapshot.data!;
      },
    );
  }
}

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:provider/provider.dart';
// import 'package:RiskSphere/providers/theme_provider.dart';
// import 'package:RiskSphere/providers/user_profile_provider.dart';
// import 'package:RiskSphere/screens/home/dashboard_screen.dart';
// import 'package:RiskSphere/screens/onboarding/login_screen.dart';
// import 'package:RiskSphere/service/shared_preference_service.dart';
// import 'package:tuple/tuple.dart';
//
// // Required for background compute call
// Future<void> storeClaimsInBackground(
//     Tuple2<Map<String, dynamic>, String> data) async {
//   final claims = data.item1;
//
//   try {
//     await SharedPreferenceService.setClaims(claims);
//     await SharedPreferenceService.getAllClaims();
//   } catch (e) {
//     debugPrint("Error storing claims in isolate: $e");
//   }
// }
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
//
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 300),
//     );
//
//     _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
//     _controller.forward();
//
//     themeProvider = Provider.of<ThemeProvider>(context, listen: false);
//     _initialScreenFuture = _determineInitialScreen();
//   }
//
//   Future<Widget> _determineInitialScreen() async {
//     final auth = FirebaseAuth.instance;
//
//     final bool? firstRun = await SharedPreferenceService.getBool("first_run");
//
//     if (firstRun == null || firstRun == true) {
//       await SharedPreferenceService.setBool("first_run", false);
//
//       // Force logout ONCE (important)
//       await FirebaseAuth.instance.signOut();
//     }
//
//     User? user = await auth.idTokenChanges().first;
//
//     if (user == null) {
//       return const LoginScreen();
//     }
//
//     // 3️⃣ User exists → restore session normally
//     try {
//       final tokenResult = await user.getIdTokenResult();
//       final claims = tokenResult.claims ?? {};
//
//       await SharedPreferenceService.setClaims(claims);
//
//       Future.microtask(() {
//         Provider.of<UserProfileProvider>(context, listen: false)
//             .getAllUserData(context, '', '');
//       });
//
//       return  DashboardScreen();
//     } catch (e) {
//       debugPrint("restore error → $e");
//       return const LoginScreen();
//     }
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
//                 child: SizedBox(
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
