import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:green/design_system/repo/constants.dart';
import 'package:green/providers/auth_provider.dart';
import 'package:green/screens/home/dashboard_screen.dart';
import 'package:green/screens/onboarding/create_account_screen.dart';
import 'package:green/screens/onboarding/login_screen.dart';
import 'package:provider/provider.dart';

import '../../design_system/repo/home.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../service/shared_preference_service.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late ThemeProvider themeProvider;

  int progress = 0;

  @override
  void initState() {
    super.initState();
    _test();
    _getInitData();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.forward();
    themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    var authNotifier = Provider.of<AuthNotifier>(context, listen: false);
    // Call function to move to the next screen after 2 seconds of animation completion
    Future.delayed(Duration(seconds: 2) + Duration(seconds: 4), () {
      bool isUserLoggedIn = authNotifier.user!=null;
      print("User: ${authNotifier.user}");
      if(FirebaseAuth.instance.currentUser==null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen(),),
        );
      } else

      if(isUserLoggedIn) {
        navigationMethod(isUserLoggedIn, authNotifier.user!);

      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen(),),
        );
      }
    });
  }

  Future<void> _test() async {
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

  Future<void> navigationMethod(bool isUserLoggedIn, User user) async {

    try {
      await user.reload();

      IdTokenResult token = await user.getIdTokenResult();
      Map<String, dynamic>? claims = token.claims?? {};
      log("Claims: $claims");
      await SharedPreferenceService.setClaims(claims);
      await SharedPreferenceService.getAllClaims();
      String? tokenString = await user.getIdToken();
      log("Token: ${token.token}");


      if(claims['isIndividual']==null) {
        print("User is not registered");
        isUserLoggedIn = false;
      }
      log("Is User Logged In: $isUserLoggedIn");
      if(isUserLoggedIn) {
        // redirect to dashboard
        Provider.of<UserProfileProvider>(context, listen: false)
            .getAllUserData(context, '', '');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen(),),);

      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen( )),
        );
      }
    } catch (e) {
      print("Error: $e");
      if(isUserLoggedIn) {
        // redirect to dashboard
        Provider.of<UserProfileProvider>(context, listen: false)
            .getAllUserData(context, '', '');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen(),),);

      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen( )),
        );
      }
    }

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
      body: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Logo
          Center(
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
        ],
      ),
    );
  }

  void handleBrightnessChange(bool useLightMode) {
  }

  void handleMaterialVersionChange() {
  }

  void handleColorSelect(int value) {
  }

  void handleImageSelect(int value) {
  }

  void _getInitData() {
    Provider.of<AuthNotifier>(context, listen: false).initialOptions();
  }
}
