import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:green/design_system/primitives/app_colors.dart';
import 'package:green/design_system/primitives/custom_typography.dart';
import 'package:provider/provider.dart';

import '../../design_system/components/custom_checkbox.dart';
import '../../design_system/components/custom_text_field.dart';
import '../../design_system/components/social_media_button.dart';
import '../../design_system/primitives/utilities/custom_spacing.dart';
import '../../design_system/repo/constants.dart';
import '../../design_system/repo/home.dart';
import '../../providers/auth_provider.dart';
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
                  await authNotifier.signInWithGoogle();
                  // Check if the user is authenticated after login attempt
                  if (authNotifier.user != null) {
                    // Navigate to the home screen or any other screen after login
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Home(
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
                        ),
                      ),
                    );
                  }
                },
                buttonText: 'Continue with Google',
                iconPath: 'assets/images/googleLogo.svg',
              );
            }
          ),

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
        Consumer<AuthNotifier>(builder: (context, authNotifier, child)
            {
              return authNotifier.isResettingPassword?Center(child: CircularProgressIndicator(color: AppColors.primaryMain,),):GestureDetector(
                  onTap: () async {
                    if(validateEmail(emailController.text)) {
                      await authNotifier.resetPassword(emailController.text);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Email sent to reset password. Please check your email.'),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Email is not valid. Please enter a valid email address.'),
                        ),
                      );
                    }
                  },
                  child: Text('Forgot Password?',
                      style: CustomTypography.Subtitle1.copyWith(
                          color: AppColors.primaryMain)));
            }
          ),
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
                                await authNotifier.signInWithEmailAndPassword(
                                    email, password);

                                // Check if the user is authenticated after login attempt
                                if (authNotifier.user != null) {
                                  // Navigate to the home screen or any other screen after login
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Home(
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
                                      ),
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
                MaterialPageRoute(
                  builder: (context) => CreateAccountScreen()
                ),
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
        ],
      ),
    );
  }

  regextest(String value) {
    String pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    RegExp regExp = new RegExp(pattern);
    return regExp.hasMatch(value);
  }

  void handleBrightnessChange(bool useLightMode) {}

  void handleMaterialVersionChange() {}

  void handleColorSelect(int value) {}

  void handleImageSelect(int value) {}

  bool validateEmail(String text) {
    return regextest(text);
  }
}
