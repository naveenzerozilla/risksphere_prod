import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:green/design_system/repo/constants.dart';
import 'package:green/providers/auth_provider.dart';
import 'package:green/screens/onboarding/create_account_screen.dart';
import 'package:green/screens/onboarding/login_screen.dart';
import 'package:provider/provider.dart';

import '../../design_system/repo/home.dart';
import '../../providers/theme_provider.dart';

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
    _getInitData();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 4),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.forward();
    themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    var authNotifier = Provider.of<AuthNotifier>(context, listen: false);
    // Call function to move to the next screen after 2 seconds of animation completion
    Future.delayed(Duration(seconds: 2) + Duration(seconds: 4), () {
      bool isUserLoggedIn = authNotifier.user!=null;
      if(isUserLoggedIn) {
        // redirect to dashboard
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Home(
          useLightMode: false,
          useMaterial3: true,
          colorSelected: ColorSeed.baseColor,
          imageSelected: ColorImageProvider.leaves,
          handleBrightnessChange: handleBrightnessChange,
          handleMaterialVersionChange: handleMaterialVersionChange,
          handleColorSelect: handleColorSelect,
          handleImageSelect: handleImageSelect,
          colorSelectionMethod: ColorSelectionMethod.colorSeed,
        ),),);

      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen( )),
        );
      }
    });
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
