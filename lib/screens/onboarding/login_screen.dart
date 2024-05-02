import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_recaptcha_v2_compat/flutter_recaptcha_v2_compat.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:green/design_system/primitives/app_colors.dart';
import 'package:green/design_system/primitives/custom_typography.dart';
import 'package:green/screens/home/dashboard_screen.dart';
import 'package:provider/provider.dart';

import '../../design_system/components/custom_checkbox.dart';
import '../../design_system/components/custom_text_field.dart';
import '../../design_system/components/social_media_button.dart';
import '../../design_system/primitives/utilities/custom_spacing.dart';
import '../../design_system/repo/constants.dart';
import '../../design_system/repo/home.dart';
import '../../providers/auth_provider.dart';
import '../../utils/utils.dart';
import 'create_account_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool rememberMe = false;
  String verifyResult = "";
  bool isCaptchaVerified = false;
  RecaptchaV2Controller recaptchaV2Controller = RecaptchaV2Controller();

  @override
  void initState() {
    AuthNotifier authNotifier =
        Provider.of<AuthNotifier>(context, listen: false);
    authNotifier.signOut();

    super.initState();
  }


  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    recaptchaV2Controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Stack(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Image.asset(
                            'assets/images/loginImage.png',
                            fit: BoxFit.fitWidth,
                          ),
                        ),
                      ],
                    ),
                    Positioned.fill(
                      child: Center(
                          child: Text(
                        "Manage your Risk Profile",
                        style: CustomTypography.H5_Regular,
                      )),
                    ),
                  ],
                ),
                _loginForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _loginForm() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Let’s get started!',
            style: CustomTypography.H4,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: CustomSpacing.eight),
          // Social Media Buttons
          Consumer<AuthNotifier>(builder: (context, authNotifier, child) {
            return SocialMediaButton(
              onPressed: () async {
                // Add your onPressed function here
                await authNotifier.signInWithGoogle(context: context);
                // Check if the user is authenticated after login attempt
                if (authNotifier.user != null && !authNotifier.isNewUser) {
                  // Navigate to the home screen or any other screen after login
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => /*Home(
                        useLightMode: false,
                        useMaterial3: true,
                        colorSelected: ColorSeed.baseColor,
                        imageSelected: ColorImageProvider.leaves,
                        handleBrightnessChange: handleBrightnessChange,
                        handleMaterialVersionChange:
                            handleMaterialVersionChange,
                        handleColorSelect: handleColorSelect,
                        handleImageSelect: handleImageSelect,
                        colorSelectionMethod: ColorSelectionMethod.colorSeed,
                      ),*/
                              DashboardScreen(),
                    ),
                  );
                }
              },
              buttonText: 'Continue with Google',
              iconPath: 'assets/images/googleLogo.svg',
            );
          }),

          SizedBox(
            height: CustomSpacing.one,
          ),
          SocialMediaButton(
            onPressed: () {
              // Add your onPressed function here
            },
            buttonText: 'Continue with Microsoft',
            iconPath: 'assets/images/microsoftLogo.svg',
          ),
          SizedBox(height: CustomSpacing.eight),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Divider(
                  thickness: 1,
                  color: Colors.white.withOpacity(0.11999999731779099),
                ),
              ),
              SizedBox(width: CustomSpacing.three),
              Text(
                'Or register manually',
                style: CustomTypography.Subtitle1.copyWith(
                    color: Theme.of(context).colorScheme.onSurface),
              ),
              SizedBox(width: CustomSpacing.three),
              Expanded(
                child: Divider(
                  thickness: 1,
                  color: Colors.white.withOpacity(0.11999999731779099),
                ),
              ),
            ],
          ),
          SizedBox(height: CustomSpacing.eight),
          // Email
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email address',
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty || regextest(value) == false) {
                return 'Enter a valid email address';
              }
              // You can add more specific email validation here if needed
              return null;
            },
            controller: emailController,
          ),
          SizedBox(height: CustomSpacing.two),
          // Password
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              border: const OutlineInputBorder(),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty || value.length < 8) {
                return 'Password must be at least 8 characters';
              }
              // You can add more specific password validation here if needed
              return null;
            },
            controller: passwordController,
          ),
          SizedBox(height: CustomSpacing.two),
          Consumer<AuthNotifier>(builder: (context, authNotifier, child) {
            return authNotifier.isResettingPassword
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryMain,
                    ),
                  )
                : GestureDetector(
                    onTap: () async {
                      if (validateEmail(emailController.text)) {
                        await authNotifier.resetPassword(emailController.text, context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Email sent to reset password. Please check your email.'),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Email is not valid. Please enter a valid email address.'),
                          ),
                        );
                      }
                    },
                    child: Text('Forgot Password?',
                        style: CustomTypography.Subtitle1.copyWith(
                            color: AppColors.primaryMain)));
          }),
          /*SizedBox(height: CustomSpacing.four),

          Center(
            child: RecaptchaV2(
              apiKey: "6LfXp1UpAAAAAEku9BSeBt6JJxXrlvtYjh--X4D7",
              apiSecret: "6LfXp1UpAAAAAIFVynIPkooVWZi5qN8u16SYJTVt",
              controller: recaptchaV2Controller,
              onVerifiedError: (err) {
                print(err);
                isCaptchaVerified = false;
              },
              onVerifiedSuccessfully: (success) {
                setState(() {
                  if (success) {
                    verifyResult = "You've been verified successfully.";
                    isCaptchaVerified = true;
                    Future.delayed(Duration(minutes: 1), () {
                      isCaptchaVerified = false;
                    });
                  } else {
                    verifyResult = "Failed to verify.";
                    isCaptchaVerified = false;
                  }
                  print(verifyResult);
                });
              },
            ),
          ),*/
          SizedBox(height: CustomSpacing.four),

          Consumer<AuthNotifier>(builder: (context, authNotifier, child) {
            return Row(
              children: [
                Expanded(
                  child: Container(
                    height: 60,
                    child: authNotifier.isSigningIn
                        ? Center(
                            child: CircularProgressIndicator(
                            color: AppColors.primaryMain,
                          ))
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryMain,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onSurface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 22, vertical: 8),
                            ),
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {

                                final String email =
                                    emailController.text.trim();
                                final String password =
                                    passwordController.text.trim();

                               /* if(isCaptchaVerified == false) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Please verify that you are not a robot.'),
                                    ),
                                  );
                                  return;
                                }*/
                                await authNotifier.signInWithEmailAndPassword(
                                    email, password, context);

                                // Check if the user is authenticated after login attempt
                                final user = authNotifier.user;
                                if (user != null) {
                                  // Navigate to the home screen or any other screen after login
                                  var token = await user.getIdToken();
                                  print(
                                      "Claims: " + parseJwt(token!).toString());
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            DashboardScreen() /*Home(
                                        useLightMode: false,
                                        useMaterial3: true,
                                        colorSelected: ColorSeed.baseColor,
                                        imageSelected:
                                            ColorImageProvider.leaves,
                                        handleBrightnessChange:
                                            handleBrightnessChange,
                                        handleMaterialVersionChange:
                                            handleMaterialVersionChange,
                                        handleColorSelect: handleColorSelect,
                                        handleImageSelect: handleImageSelect,
                                        colorSelectionMethod:
                                            ColorSelectionMethod.colorSeed,
                                      ),*/
                                        ),
                                  );
                                }
                              }
                            },
                            child: Text(
                              'Submit',
                              style: CustomTypography.ButtonLarge.copyWith(
                                  color: Colors.black),
                            ),
                          ),
                  ),
                ),
              ],
            );
          }),
          SizedBox(height: CustomSpacing.four),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => CreateAccountScreen()),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: CustomSpacing.onePointFive,
                ),
                Text('Don’t have an account? ',
                    style: CustomTypography.Body1.copyWith(
                        color: Theme.of(context).colorScheme.onSurface)),
                Text('Register now!',
                    style: CustomTypography.Subtitle1.copyWith(
                        color: AppColors.primaryMain)),
              ],
            ),
          ),

          SizedBox(height: CustomSpacing.eight),
        ],
      ),
    );
  }

  void handleBrightnessChange(bool useLightMode) {}

  void handleMaterialVersionChange() {}

  void handleColorSelect(int value) {}

  void handleImageSelect(int value) {}

  bool validateEmail(String text) {
    return regextest(text);
  }

  Map<String, dynamic>? parseJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      return null;
    }

    final payload = parts[1];
    final String normalized = base64Url.normalize(payload);
    final String decoded = utf8.decode(base64Url.decode(normalized));
    return json.decode(decoded);
  }
}
