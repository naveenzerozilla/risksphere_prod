import 'dart:convert';
import 'dart:io';

import 'package:RiskSphere/main.dart';
import 'package:country_pickers/country.dart';
import 'package:country_pickers/country_picker_dropdown.dart';
import 'package:country_pickers/utils/utils.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_recaptcha_v2_compat/flutter_recaptcha_v2_compat.dart';

import 'package:RiskSphere/design_system/primitives/app_colors.dart';
import 'package:RiskSphere/design_system/primitives/custom_typography.dart';
import 'package:RiskSphere/screens/home/dashboard_screen.dart';
import 'package:RiskSphere/service/language_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../appleauth.dart';
import '../../design_system/components/social_media_button.dart';
import '../../design_system/primitives/utilities/custom_spacing.dart';

import '../../providers/auth_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../service/storage_service.dart';
import '../../utils/global_imports.dart';
import '../../utils/utils.dart';
import 'create_account_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final storage = FlutterSecureStorage();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool rememberMe = false;
  String verifyResult = "";
  bool isCaptchaVerified = false;
  RecaptchaV2Controller recaptchaV2Controller = RecaptchaV2Controller();
  bool _showPassword = false;
  final FlutterAppAuth appAuth = FlutterAppAuth();
  String clientId = 'eb81a783-765c-482d-8fcb-6440ab1d1201';
  String tenantId = 'abf269e2-9404-46f3-b577-2b0c86eac933';
  String redirectUrl = 'https://erp.projectzerozilla.com/';
  late String discoveryUrl =
      "https://login.microsoftonline.com/${tenantId!}/v2.0/.well-known/openid-configuration";
  List<String> scopes = ['openid', 'profile', 'email', 'User.Read'];

  @override
  void initState() {
    // AuthNotifier authNotifier =
    //     Provider.of<AuthNotifier>(context, listen: false);
    // authNotifier.signOut();

    super.initState();
    // _loadSavedLogin();
  }

  void _loadSavedLogin() async {
    final loginData = await StorageService.getLogin();
    if (loginData["email"] != null && loginData["password"] != null) {
      setState(() {
        emailController.text = loginData["email"] ?? "";
        passwordController.text = loginData["password"] ?? "";
        rememberMe = true;
      });
    }
  }

  Future<void> saveLoginData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', rememberMe);
    if (rememberMe) {
      await prefs.setString('email', emailController.text);
      await prefs.setString('password', passwordController.text);
    } else {
      await prefs.remove('email');
      await prefs.remove('password');
    }
  }

  Future<void> signInWithMicrosoft(BuildContext context) async {
    try {
      final result = await appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          clientId,
          "com.risksphere.green://oauth2redirect",
          discoveryUrl: discoveryUrl,
          scopes: scopes,
          promptValues: ['login'],
        ),
      );
      print(result);
      print("result");

      if (result != null) {
        print('Success! Token: ${result.accessToken}');
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    DashboardScreen())); // or your target route
      } else {
        // User cancelled - webview also closed
        print('Authentication cancelled');
      }

      // If authentication is successful, navigate to the desired screen
      if (result != null && result.accessToken != null) {
        Navigator.of(context)
            .pushReplacementNamed('/home'); // or your target route
      }
    } catch (e) {
      print('Error during Microsoft sign-in: $e');
      // Handle error, maybe show a snackbar or dialog
    }
  }

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);
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
                          "Set up your account",
                          // LanguageService.getTranslated(
                          //     context, "login_image_text"),
                          style: typography.H5_Regular,
                        ),
                      ),
                    ),
                  ],
                ),
                if (Platform.isIOS) SizedBox(height: CustomSpacing.eight),
                // SizedBox(height: CustomSpacing.two),
                CountryPickerDropdown(
                  initialValue: _getInitialCountry(),
                  itemBuilder: (Country country) {
                    return SizedBox(
                      width: MediaQuery.of(context).size.width * 0.4,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            backgroundImage: AssetImage(
                              CountryPickerUtils.getFlagImageAssetPath(
                                  country.isoCode),
                              package: 'country_pickers',
                            ),
                          ),
                          SizedBox(width: CustomSpacing.two),
                          Flexible(
                            child: Text(
                              country.name,
                              style: typography.Body1,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  itemFilter: (Country country) {
                    // Only include countries with these ISO codes
                    return ['US', 'ES', 'FR', 'JP', 'CN']
                        .contains(country.isoCode);
                  },
                  icon: SizedBox(),
                  onValuePicked: (Country country) {
                    switch (country.isoCode) {
                      case 'US':
                        context.setLocale(Locale('en'));
                        break;
                      case 'ES':
                        context.setLocale(Locale('es'));
                        break;
                      case 'FR':
                        context.setLocale(Locale('fr'));
                        break;
                      case 'JP':
                        context.setLocale(Locale('ja'));
                        break;
                      case 'CN':
                        context.setLocale(Locale('zh'));
                        break;
                    }
                  },
                ),
                _loginForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _loginForm() {
    var typography = CustomTypography(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: CustomSpacing.four),
            Center(
              child: Text(
                LanguageService.getTranslated(context, "login_title"),
                style: typography.H4,
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: CustomSpacing.eight),
            // AppleSignInButton(),
            // Social Media Buttons
            // if (Platform.isIOS) ...[
            AppleSignInButton(),
            // ],
            SizedBox(height: CustomSpacing.two),
            // Social Media Buttons
            // if (Platform.isAndroid) ...[
            Consumer<AuthNotifier>(
              builder: (context, authNotifier, _) {
                return SocialMediaButton(
                  onPressed: authNotifier.isSigningIn
                      ? null
                      : () => authNotifier.signInWithGoogle(context: context),
                  buttonText: LanguageService.getTranslated(
                      context, "login_googlebutton"),
                  iconPath: 'assets/images/googleLogo.svg',
                );
              },
            ),

            // Consumer<AuthNotifier>(builder: (context, authNotifier, child) {
            //   return SocialMediaButton(
            //     onPressed: () async {
            //       // Add your onPressed function here
            //       await authNotifier.signInWithGoogle(context: context);
            //
            //     },
            //     buttonText: LanguageService.getTranslated(
            //         context, "login_googlebutton"),
            //     iconPath: 'assets/images/googleLogo.svg',
            //   );
            // }),

            SizedBox(height: CustomSpacing.three),

            if (Platform.isAndroid)
              Consumer<AuthNotifier>(
                builder: (context, authNotifier, child) {
                  return SocialMediaButton(
                    onPressed: () async {
                      await authNotifier.signInWithMicrosoft(context: context);
                      print(authNotifier.user.toString());
                      print(authNotifier.userProfile.toString());
                      print(authNotifier.isNewUser.toString());
                    },
                    buttonText: LanguageService.getTranslated(
                        context, "login_microsoft_button"),
                    iconPath: 'assets/images/microsoftLogo.svg',
                  );
                },
              ),
            // Consumer<AuthNotifier>(
            //   builder: (context, authNotifier, _) {
            //     return AppleSignInButton(
            //       key: const ValueKey('apple_sign_in_button'),
            //       onSuccess: () async {
            //         // ✅ Apple + Firebase login success
            //         await authNotifier.handleAppleLogin(context);
            //       },
            //       onError: (error) {
            //         ScaffoldMessenger.of(context).showSnackBar(
            //           SnackBar(
            //             content: Text(error.toString()),
            //             backgroundColor: Colors.red,
            //           ),
            //         );
            //       },
            //     );
            //   },
            // ),

            SizedBox(height: CustomSpacing.four),
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
                  "Sign in",
                  // LanguageService.getTranslated(
                  //     context, "register_non_corporate_register_manually"),
                  style: typography.Subtitle1.copyWith(
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
            SizedBox(height: CustomSpacing.six),
            // ],
            // Email
            TextFormField(
              autovalidateMode: AutovalidateMode.onUserInteraction,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: LanguageService.getTranslated(
                    context, "register_non_corporate_emailfield_label"),
                hintText: LanguageService.getTranslated(
                    context, 'register_non_corporate_emailfield_placeholder'),
                border: const OutlineInputBorder(),
              ),
              autofillHints: [AutofillHints.email],
              validator: (value) {
                if (value == null ||
                    value.isEmpty ||
                    regextest(value) == false) {
                  return 'Enter a valid email address';
                }
                // You can add more specific email validation here if needed
                return null;
              },
              controller: emailController,
            ),
            SizedBox(height: CustomSpacing.three),
            // Password
            TextFormField(
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  icon: _showPassword
                      ? Icon(Icons.visibility)
                      : Icon(Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _showPassword = !_showPassword;
                    });
                  },
                ),
                labelText: LanguageService.getTranslated(
                    context, 'register_non_corporate_passwordfield_label'),
                hintText: LanguageService.getTranslated(
                    context, 'login_passwordfield_placeholder'),
                border: const OutlineInputBorder(),
              ),
              obscureText: !_showPassword,
              validator: (value) {
                if (value == null || value.isEmpty || value.length < 8) {
                  return LanguageService.getTranslated(
                      context, 'login_password_length_error');
                }
                // You can add more specific password validation here if needed
                return null;
              },
              controller: passwordController,
              autofillHints: [AutofillHints.password],
            ),
            SizedBox(height: CustomSpacing.two),

            // Remember Me
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                              try {
                                var result = await authNotifier.resetPassword(
                                    emailController.text, context);
                                if (result) {
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
                                          'Email not found. Please enter a valid email address.'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Email not found. Please enter a valid email address.'),
                                  ),
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Email is not valid. Please enter a valid email address.'),
                                ),
                              );
                            }
                          },
                          child: Text(
                              LanguageService.getTranslated(
                                  context, 'login_forgot_password'),
                              style: typography.Subtitle1.copyWith(
                                  color: AppColors.primaryMain)));
                }),
              ],
            ),
            // SizedBox(height: CustomSpacing.four),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: CustomSpacing.onePointFive),
                Text(
                  LanguageService.getTranslated(
                      context, 'login_dont_hv_account'),
                  style: typography.Body1.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  ' ',
                  style: typography.Body1.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CreateAccountScreen()),
                    );
                  },
                  child: Text(
                    LanguageService.getTranslated(
                        context, 'login_register_now'),
                    style: typography.Subtitle1.copyWith(
                      color: AppColors.primaryMain,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
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
            SizedBox(height: CustomSpacing.eight),

            Consumer<AuthNotifier>(builder: (context, authNotifier, child) {
              return Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
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
                                    horizontal: 12, vertical: 8),
                              ),
                              onPressed: () async {
                                saveLoginData();
                                if (rememberMe) {
                                  await StorageService.saveLogin(
                                      emailController.text,
                                      passwordController.text);
                                } else {
                                  await StorageService.clearLogin();
                                }
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
                                    print("fcmCall");
                                    initFCM(user.uid);
                                    print("fcmCall");
                                    TextInput.finishAutofillContext();
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              DashboardScreen()
                                          /*Home(
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
                                LanguageService.getTranslated(
                                    context, 'login_submit_button'),
                                style: typography.ButtonLarge.copyWith(
                                    color: Colors.black),
                              ),
                            ),
                    ),
                  ),
                ],
              );
            }),

            // Row(
            //   mainAxisAlignment: MainAxisAlignment.start,
            //   crossAxisAlignment: CrossAxisAlignment.center,
            //   children: [
            //     SizedBox(
            //       height: CustomSpacing.onePointFive,
            //     ),
            //     Text(
            //         LanguageService.getTranslated(
            //             context, 'login_dont_hv_account'),
            //         style: typography.Body1.copyWith(
            //             color: Theme.of(context).colorScheme.onSurface)),
            //     Text(
            //       ' ',
            //       style: typography.Body1.copyWith(
            //           color: Theme.of(context).colorScheme.onSurface),
            //     ),
            //     InkWell(
            //       onTap: () {
            //         print("object");
            //         Navigator.push(
            //             context,
            //             MaterialPageRoute(
            //                 builder: (context) => CreateAccountScreen()));
            //       },
            //       child: Flexible(
            //         child: Text(
            //             LanguageService.getTranslated(
            //                 context, 'login_register_now'),
            //             style: typography.Subtitle1.copyWith(
            //                 color: AppColors.primaryMain)),
            //       ),
            //     ),
            //   ],
            // ),

            SizedBox(height: CustomSpacing.eight),
          ],
        ),
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

  String _getInitialCountry() {
    final locale = context.locale.languageCode;

    switch (locale) {
      case 'es':
        return 'ES';
      case 'fr':
        return 'FR';
      case 'ja':
        return 'JP';
      case 'zh':
        return 'CN';
      default:
        return 'US';
    }
  }
}
