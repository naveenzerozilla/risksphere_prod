import 'package:RiskSphere/main.dart';
import 'package:country_pickers/country.dart';
import 'package:country_pickers/country_picker_dropdown.dart';
import 'package:country_pickers/utils/utils.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_recaptcha_v2_compat/flutter_recaptcha_v2_compat.dart';
import 'package:RiskSphere/screens/home/dashboard_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../appleauth.dart';
import '../../design_system/components/social_media_button.dart';
import '../../service/storage_service.dart';
import '../../utils/global_imports.dart';
import '../../utils/utils.dart';
import 'create_account_screen.dart';

import '../../utils/env.dart';

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
  
  String get clientId => Env.get('MS_CLIENT_ID');
  String get tenantId => Env.get('MS_TENANT_ID');
  String get redirectUrl => Env.get('MS_REDIRECT_URL');
  String get discoveryUrl =>
      "https://login.microsoftonline.com/$tenantId/v2.0/.well-known/openid-configuration";
  List<String> scopes = ['openid', 'profile', 'email', 'User.Read'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthNotifier>(context, listen: false).resetSigningInStates();
    });
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

      if (result != null) {
        print('Success! Token: ${result.accessToken}');
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => DashboardScreen()));
      } else {
        print('Authentication cancelled');
      }

      if (result != null && result.accessToken != null) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      print('Error during Microsoft sign-in: $e');
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

            AppleSignInButton(),
            SizedBox(height: CustomSpacing.two),

            Consumer<AuthNotifier>(
              builder: (context, authNotifier, _) {
                return SocialMediaButton(
                  onPressed: authNotifier.isSigningIn
                      ? null
                      : () => authNotifier.signInWithGoogle(context: context),
                  isLoading: authNotifier.isSigningInGoogle,
                  buttonText: LanguageService.getTranslated(
                      context, "login_googlebutton"),
                  iconPath: 'assets/images/googleLogo.svg',
                );
              },
            ),

            SizedBox(height: CustomSpacing.three),

            Consumer<AuthNotifier>(
              builder: (context, authNotifier, child) {
                return SocialMediaButton(
                  onPressed: authNotifier.isSigningIn
                      ? null
                      : () async {
                          await authNotifier.signInWithMicrosoft(context: context);
                          print(authNotifier.user.toString());
                          print(authNotifier.userProfile.toString());
                          print(authNotifier.isNewUser.toString());
                        },
                  isLoading: authNotifier.isSigningInMicrosoft,
                  buttonText: LanguageService.getTranslated(
                      context, "login_microsoft_button"),
                  iconPath: 'assets/images/microsoftLogo.svg',
                );
              },
            ),

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
                if (value == null || value.trim().isEmpty) {
                  return LanguageService.getTranslated(
                      context, 'Password is required');
                }

                if (value.length < 8) {
                  return LanguageService.getTranslated(
                      context, 'login_password_length_error');
                }

                return null;
              },
              // validator: (value) {
              //   if (value == null || value.isEmpty || value.length < 8) {
              //     return LanguageService.getTranslated(
              //         context, 'login_password_length_error');
              //   }
              //   // You can add more specific password validation here if needed
              //   return null;
              // },
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

                                  await authNotifier.signInWithEmailAndPassword(
                                      email, password, context);

                                  final user = authNotifier.user;
                                  if (user != null) {
                                    await user.reload();
                                    final isVerified = user.emailVerified;

                                    if (isVerified) {
                                      initFCM(user.uid).catchError((e) {
                                        debugPrint('FCM init error: $e');
                                      });

                                      TextInput.finishAutofillContext();
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                DashboardScreen()),
                                      );
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Login failed. Please check your email and password.')),
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

            SizedBox(height: CustomSpacing.eight),
          ],
        ),
      ),
    );
  }

  bool validateEmail(String text) {
    return regextest(text);
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
