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

import 'login_screen_new.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late ThemeProvider themeProvider;

  @override
  void initState() {
    super.initState();
    _initialize();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.forward();
    themeProvider = Provider.of<ThemeProvider>(context, listen: false);
  }

  Future<void> _initialize() async {
    final authNotifier = Provider.of<AuthNotifier>(context, listen: false);
    Provider.of<AuthNotifier>(context, listen: false).initialOptions();

    // Optional: remove if _test listener is not required before navigation
    _test();

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      });
      return;
    }

    await _handleNavigation(currentUser);
  }

  Future<void> _handleNavigation(User user) async {
    try {
      await user.reload();

      final tokenFuture = user.getIdTokenResult();
      final tokenStringFuture = user.getIdToken();

      final token = await tokenFuture;
      final tokenString = await tokenStringFuture;

      final claims = token.claims ?? {};
      log("Claims: $claims");
      log("Token: $tokenString");

      await SharedPreferenceService.setClaims(claims);
      await SharedPreferenceService.getAllClaims();

      final isUserRegistered = claims['isIndividual'] != null;

      if (isUserRegistered) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => DashboardScreen()),
          );
        });

        // Load user profile in background
        Future.microtask(() {
          Provider.of<UserProfileProvider>(context, listen: false)
              .getAllUserData(context, '', '');
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        });
      }
    } catch (e) {
      log("Navigation error: $e");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      // _goToLogin();
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
}
