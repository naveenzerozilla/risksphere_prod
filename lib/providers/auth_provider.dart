import 'dart:developer';

import 'package:RiskSphere/screens/home/dashboard_screen.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../main.dart';
import '../models/initial_data_model.dart' hide Config;
import '../screens/onboarding/create_account_screen.dart';
import 'package:http/http.dart' as http;
import '../utils/global_imports.dart' hide CompanyType;
import 'package:RiskSphere/utils/appcheckService.dart';

class AuthNotifier extends ChangeNotifier {
  ValueNotifier<List<Companies>> companyOptionsNotifier = ValueNotifier([]);
  List<Companies> companyOptions = [];
  List<Companies> filteredCompanyOptions = [];
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FlutterAppAuth _appAuth = FlutterAppAuth();
  String? accessToken;
  Map<String, dynamic>? userProfile;
  bool _isSubmittingSupport = false;

  bool get isSubmittingSupport => _isSubmittingSupport;

  static const String _redirectUrl = 'com.risksphere.green://oauth2redirect';

  // final String _discoveryUrl =
  //     // 'https://login.microsoftonline.com/common/v2.0/.well-known/openid-configuration';
  //
  //     'https://login.microsoftonline.com/$_tenantId/v2.0/.well-known/openid-configuration';

  final List<String> _scopes = const [
    'openid',
    'profile',
    'email',
    'User.Read'
  ];

  bool isNewUser = false;
  bool isLoading = false;

  User? _user;

  Future<void> handleAppleLogin(BuildContext context) async {
    try {
      isLoading = true;
      notifyListeners();

      // 🔥 Call backend / store user / navigate
      debugPrint("Apple login success → continue flow");

      // Example:
      // Navigator.pushReplacementNamed(context, Routes.home);
    } catch (e) {
      debugPrint("AuthNotifier Error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  User? get user => _user;

  bool _isSigningIn = false;
  bool _isSigningInGoogle = false;
  bool _isSigningInMicrosoft = false;
  bool _isSigningInApple = false;

  bool get isSigningIn => _isSigningIn || _isSigningInGoogle || _isSigningInMicrosoft || _isSigningInApple;
  bool get isSigningInGoogle => _isSigningInGoogle;
  bool get isSigningInMicrosoft => _isSigningInMicrosoft;
  bool get isSigningInApple => _isSigningInApple;

  set isSigningIn(bool value) {
    _isSigningIn = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  set isSigningInGoogle(bool value) {
    _isSigningInGoogle = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  set isSigningInMicrosoft(bool value) {
    _isSigningInMicrosoft = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  set isSigningInApple(bool value) {
    _isSigningInApple = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void resetSigningInStates() {
    _isSigningIn = false;
    _isSigningInGoogle = false;
    _isSigningInMicrosoft = false;
    _isSigningInApple = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isSigningOut = false;

  bool get isSigningOut => _isSigningOut;

  bool _isSigningUp = false;

  bool get isSigningUp => _isSigningUp;

  bool _isResettingPassword = false;

  bool get isResettingPassword => _isResettingPassword;

  bool _isRemindLoading = false;

  bool get isRemindLoading => _isRemindLoading;
  List<Roles> roles = [];
  List<CompanyType> companyType = [];

  set isRemindLoading(bool value) {
    _isRemindLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isAssignClaimsLoading = false;

  bool get isAssignClaimsLoading => _isAssignClaimsLoading;

  set isAssignClaimsLoading(bool value) {
    _isAssignClaimsLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

// Private variables to hold role list, company list, and company type list
  List<Role>? _roleList;
  List<Companies>? _companyList;
  List<CompanyType>? _companyTypeList;
  bool isRemindLoadings = false;
  List<Companies> companyLists = [];

// Getters for role list, company list, and company type list
  List<Role>? get roleList => _roleList;

  List<Companies>? get companyList => _companyList;

  List<CompanyType>? get companyTypeList => _companyTypeList;

  // Setters for role list, company list, and company type list
  set roleList(List<Role>? roleList) {
    _roleList = roleList;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  set companyList(List<Companies>? companyList) {
    _companyList = companyList;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  set companyTypeList(List<CompanyType>? companyTypeList) {
    _companyTypeList = companyTypeList;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  InitialDataModel? _initialData;

  InitialDataModel? get initialData => _initialData;

  set initialData(InitialDataModel? initialData) {
    _initialData = initialData;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  AuthNotifier() {
    _initAuthState();
  }

  Future<void> _initAuthState() async {
    _user = _auth.currentUser;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<void> fetchIndividualRoles() async {
    try {
      final response = await http.get(
        Uri.parse("${AppConstant.baseURL}/send_default_data_v2"),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) return _clearRoles();

      final decoded = jsonDecode(response.body);
      final data = decoded["data"];
      if (data == null) return _clearRoles();

      final List roleList = data["role"] as List;
      if (roleList.isEmpty) return _clearRoles();

      Map<String, dynamic>? individual;
      for (final item in roleList) {
        if (item["accountType"] == "individual") {
          individual = Map<String, dynamic>.from(item);
          break;
        }
      }

      if (individual == null) return _clearRoles();

      final List categories = individual["categories"] as List;
      if (categories.isEmpty) return _clearRoles();

      roles = categories
          .whereType<Map>()
          .map((e) => Roles.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      final List corpCompany = data["company_type"] as List;

      companyType = corpCompany
          .whereType<Map>()
          .map((e) => CompanyType.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      print("Total roles fetched for individual: ${roles.length}");
      print("Role names: ${roles.map((e) => e.name).toList()}");
    } catch (e, st) {
      print("Error parsing: $e");
      print(st);
      return _clearRoles();
    }

    notifyListeners();
  }

  Future<void> submitSupportRequest(
    BuildContext context,
    String subject,
    String message,
  ) async {
    var typography = CustomTypography(context);

    try {
      _isSubmittingSupport = true;
      notifyListeners();

      ApiService apiService = ApiService(AppConstant.APP_SUPPORT_URL);

      await apiService.post({
        'subject': subject,
        'body': message,
      });

      // ✅ STOP LOADER
      _isSubmittingSupport = false;
      notifyListeners();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Support request sent successfully!',
            style: typography.ButtonLargeBlack,
          ),
        ),
      );
    } on BackendException catch (e) {
      _isSubmittingSupport = false;
      notifyListeners();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message, style: typography.ButtonLargeBlack),
        ),
      );
    } catch (e) {
      _isSubmittingSupport = false;
      notifyListeners();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString(), style: typography.ButtonLargeBlack),
        ),
      );
    }
  }

  void _clearRoles() {
    roles = [];
    notifyListeners();
  }

  Future<void> fetchCompanies(String name) async {
    print("Fetching: $name");

    try {
      final response = await http.get(
        Uri.parse(
          "${AppConstant.baseURL}/send_default_data_v2?name=${Uri.encodeComponent(name)}",
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        print("RAW DATA => $data");

        if (data is Map && data["result"] is List) {
          final List result = data["result"];

          companyOptions = result.map<Companies>((item) {
            if (item is String) {
              final decoded = jsonDecode(item);
              return Companies.fromJson(Map<String, dynamic>.from(decoded));
            }

            if (item is Map) {
              return Companies.fromJson(Map<String, dynamic>.from(item));
            }

            throw Exception("Invalid company item type: ${item.runtimeType}");
          }).toList();
        } else {
          companyOptions = [];
        }
      } else {
        companyOptions = [];
      }
    } catch (e, st) {
      print("Error fetching companies: $e");
      print(st);
      companyOptions = [];
    }

    notifyListeners();
  }

  void filterCompanies(String query) {
    final input = query.trim().toLowerCase();
    if (input.isEmpty) {
      filteredCompanyOptions = [];
    } else {
      filteredCompanyOptions = companyOptions
          .where((company) => company.name.toLowerCase().contains(input))
          .toList();
    }
    notifyListeners();
  }

  Future<void> signInWithEmailAndPassword(
      String email, String password, BuildContext context1) async {
    try {
      _isSigningIn = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      print("================ LOGIN DETAILS ================");
      print("Authenticating with Firebase Auth...");
      print("Email: $email");
      print("Password: [REDACTED]");
      print("===============================================");

      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = userCredential.user;

      if (!(_user?.emailVerified ?? false)) {
        _isSigningIn = false;
        await _auth.signOut();

        var typography = CustomTypography(context1);
        ScaffoldMessenger.of(context1).showSnackBar(
          SnackBar(
            content: Text(
              LanguageService.getTranslated(
                  context1, "login_email_not_verified_error"),
            ),
            duration: Duration(seconds: 3),
          ),
        );

        final _googleSignIn = GoogleSignIn();
        var isSignedIn = await _googleSignIn.isSignedIn();
        if (isSignedIn) await _googleSignIn.disconnect();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return;
      }
      IdTokenResult token = await userCredential.user!.getIdTokenResult();
      Map<String, dynamic>? claims = token.claims ?? {};

      String isAdminVerified = await getAllClaims();
      // print("is admin verified" + isAdminVerified.length.toString());
      // print(isAdminVerified.toLowerCase());
      if (isAdminVerified == "server_error") {
        _isSigningIn = false;

        if (context1.mounted) {
          ScaffoldMessenger.of(context1).showSnackBar(
            const SnackBar(
              content: Text(
                "We're experiencing a server issue. Please try again later.",
              ),
            ),
          );
        }

        await _auth.signOut();

        final googleSignIn = GoogleSignIn();
        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.disconnect();
        }

        notifyListeners();
        return;
      }
      if (isAdminVerified.toLowerCase() == "false" || isAdminVerified.isEmpty) {
        _isSigningIn = false;
        // Show dialog with reminder to verify email for admin
        // ignore: use_build_context_synchronously
        await showDialog(
          context: context1,
          barrierDismissible: false,
          builder: (BuildContext context) {
            var typography = CustomTypography(context);
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: Text(
                    LanguageService.getTranslated(
                        context, "login_admin_not_verified_dialog_title"),
                    style: typography.H6.copyWith(color: Colors.white),
                  ),
                  content: Text(
                    LanguageService.getTranslated(
                        context, "login_admin_not_verified_dialog_description"),
                    style: typography.Body1.copyWith(color: Colors.white),
                  ),
                  actions: [
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                type: ButtonType.elevated,
                                onPressed: () async {
                                  setState(() {
                                    isRemindLoading = true;
                                  });

                                  bool result = await remindUser();

                                  setState(() {
                                    isRemindLoading = false;
                                  });

                                  if (result) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          LanguageService.getTranslated(context,
                                              "login_admin_not_verified_remind_success"),
                                          style: typography.H6
                                              .copyWith(color: Colors.black),
                                        ),
                                      ),
                                    );
                                  }

                                  final _googleSignIn = GoogleSignIn();
                                  var isSignedIn =
                                      await _googleSignIn.isSignedIn();

                                  if (isSignedIn)
                                    await _googleSignIn.disconnect();
                                  await _auth.signOut();

                                  Future.delayed(Duration(milliseconds: 500),
                                      () {
                                    if (Navigator.canPop(context)) {
                                      Navigator.pop(context);
                                    }
                                  });
                                },
                                child: isRemindLoading
                                    ? Center(
                                        child: CircularProgressIndicator(
                                            color: Colors.white))
                                    : Text(
                                        LanguageService.getTranslated(context,
                                            "login_admin_not_verified_remind_button"),
                                      ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: CustomSpacing.four),
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                  type: ButtonType.text,
                                  onPressed: () async {
                                    final _googleSignIn = GoogleSignIn();
                                    var isSignedIn =
                                        await _googleSignIn.isSignedIn();
                                    if (isSignedIn)
                                      await _googleSignIn.disconnect();
                                    await _auth.signOut();

                                    if (Navigator.canPop(context)) {
                                      Navigator.pop(context);
                                    }
                                    Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                SplashScreen()),
                                        (route) => false);
                                  },
                                  child: Text(
                                    LanguageService.getTranslated(context,
                                        "login_admin_not_verified_cancel_button"),
                                    style: typography.H6
                                        .copyWith(color: Colors.white),
                                  )),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        );

        return;
      }

      await SharedPreferenceService.setClaims(claims);
      await SharedPreferenceService.getAllClaims();
      unawaited(initFCM(_user!.uid));
      _isSigningIn = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      _isSigningIn = false;
      var typography = CustomTypography(context1);
      if (context1.mounted) {
        ScaffoldMessenger.of(context1).showSnackBar(
          SnackBar(
            content: Text(
              LanguageService.getTranslated(
                  context1, "login_invaild_email_password_error"),
            ),
          ),
        );
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      print("Error signing in: $e");
    }
  }

  Future<void> signInWithGoogle({BuildContext? context}) async {
    try {
      _isSigningInGoogle = true;
      notifyListeners(); // Immediately notify listeners about signing in state
      await _googleSignIn.signOut(); // optional but safe

      final GoogleSignInAccount? googleSignInAccount =
          await _googleSignIn.signIn();
      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );

        final UserCredential userCredential =
            await _auth.signInWithCredential(credential);

        _user = userCredential.user;
        log('user: $userCredential');
        print('Is new user? ${userCredential.additionalUserInfo?.isNewUser}');

        IdTokenResult token = await userCredential.user!.getIdTokenResult();
        Map<String, dynamic>? claims = token.claims ?? {};
        log("Claims: $claims");

        await SharedPreferenceService.setClaims(claims);
        await SharedPreferenceService.getAllClaims();
        unawaited(initFCM(_user!.uid));

        print('Is Individual? ${claims['isIndividual']}');

        if (claims['isIndividual'] == null) {
          isNewUser = true;
          // Navigate to create account screen and pass the user data
          await Navigator.push(
            context!,
            MaterialPageRoute(
              builder: (context) => CreateAccountScreen(
                userCredential: userCredential,
              ),
            ),
          );
        } else {
          isNewUser = false;
          await Navigator.pushAndRemoveUntil(
            context!,
            MaterialPageRoute(builder: (context) => DashboardScreen()),
            (route) => false,
          );
        }
      } else {
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Google Sign-In returned null (canceled or config mismatch).'),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      print("Error signing in with Google: $e");
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'An error occurred.'),
          ),
        );
      }
    } catch (e) {
      print(e);
      print("Error signing in with Google: $e");
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In Error: $e'),
          ),
        );
      }
    } finally {
      _isSigningInGoogle = false;
      notifyListeners();
    }
  }

  Future<void> signInWithMicrosoft({BuildContext? context}) async {
    try {
      _isSigningInMicrosoft = true;
      notifyListeners();

      final microsoftProvider = MicrosoftAuthProvider();

      microsoftProvider.addScope('email');
      microsoftProvider.addScope('openid');
      microsoftProvider.addScope('profile');
      microsoftProvider.addScope('User.Read');

      UserCredential userCredential;
      if (kIsWeb) {
        userCredential =
            await FirebaseAuth.instance.signInWithPopup(microsoftProvider);
      } else {
        userCredential =
            await FirebaseAuth.instance.signInWithProvider(microsoftProvider);
      }

      // Handle user data or token claims if necessary
      // Example:
      IdTokenResult token = await userCredential.user!.getIdTokenResult();
      Map<String, dynamic>? claims = token.claims ?? {};
      log("Claims: $claims");

      await SharedPreferenceService.setClaims(claims);
      await SharedPreferenceService.getAllClaims();

      _user = userCredential.user;
      if (claims['isIndividual'] == null) {
        isNewUser = true;
        Navigator.push(
          context!,
          MaterialPageRoute(
            builder: (context) => CreateAccountScreen(
              userCredential: userCredential,
            ),
          ),
        );
      } else {
        isNewUser = false;
        await Navigator.pushAndRemoveUntil(
          context!,
          MaterialPageRoute(builder: (context) => DashboardScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      print("Error signing in with Microsoft: Code: ${e.code} | Message: ${e.message} | Email: ${e.email} | Details: ${e.toString()}");
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'An error occurred'),
          ),
        );
      }
    } finally {
      _isSigningInMicrosoft = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      _isSigningOut = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      await _secureStorage.deleteAll();
      // final _googleSignIn = GoogleSignIn();
      // var isSignedIn = await _googleSignIn.isSignedIn();
      // if (isSignedIn) await _googleSignIn.disconnect();
      await _auth.signOut();
      _user = null;
      userProfile = null;
      _isSigningOut = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      _isSigningOut = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      // Handle error
      print("Error signing out: $e");
    }
  }

  Future<bool> resetPassword(String email, BuildContext context) async {
    try {
      _isResettingPassword = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      bool isUserRegistered = await userExists(email.trim());

      if (isUserRegistered) {
        String? appCheckToken;
        try {
          appCheckToken = await AppCheckService.getToken();
        } catch (e) {
          debugPrint("Failed to get App Check token: $e");
        }

        final response = await http.post(
          Uri.parse('${AppConstant.baseURL}/auth_handler_v2/user-check'),
          headers: {
            "Content-Type": "application/json",
            if (appCheckToken != null) "X-Firebase-AppCheck": appCheckToken,
          },
          body: jsonEncode({"email": email.trim()}),
        );

        debugPrint(
            "Forgot password API: ${response.statusCode} ${response.body}");

        // ✅ Step 2 — Then send Firebase reset email
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());

        _isResettingPassword = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return true;
      } else {
        _isResettingPassword = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return false;
      }
    } on FirebaseAuthException catch (e) {
      _isResettingPassword = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      debugPrint("Error sending password reset email: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Something went wrong")),
      );
      return false;
    } catch (e) {
      _isResettingPassword = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      debugPrint("Reset password error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to send password reset email"),
        ),
      );
      return false;
    }
  }

//   Future<bool> resetPassword(String email, BuildContext context) async {
//     try {
//       _isResettingPassword = true;
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         notifyListeners();
//       });
//       bool isUserRegistered = await userExists(email.trim());
//
//       if (isUserRegistered) {
//         await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
// // and another things...
//         //await _auth.sendPasswordResetEmail(email: email);
//         // Reset password email sent successfully
//         _isResettingPassword = false;
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           notifyListeners();
//         });
//         return true;
//       } else {
// // show error message etc.
//         _isResettingPassword = false;
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           notifyListeners();
//         });
//         return false;
//       }
//     } on FirebaseAuthException catch (e) {
//       _isResettingPassword = false;
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         notifyListeners();
//       });
//
//       // Handle error
//       print("Error sending password reset email: $e");
//       ScaffoldMessenger.of(context!).showSnackBar(
//         SnackBar(
//           content: Text(e.message!),
//         ),
//       );
//       return false;
//     }
//   }

  Future<bool> userExists(String email) async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: 'TemporaryPassword123!', // Use a temporary password
      );

      // If the account creation is successful, delete the account and return false
      await userCredential.user!.delete();
      return false;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // If account creation fails because the email is already in use,
        // return true
        return true;
      } else {
        // If account creation fails for any other reason, return false
        return false;
      }
    }
  }

  /// Registration for Individual on Google Signup
  Future<String> signUpIndividualWithGoogle(
      UserCredential userCredential,
      String phone,
      String selectedCountryCode,
      List<Categories> selectedRoles,
      BuildContext context) async {
    try {
      _isSigningUp = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      print('cred: $userCredential');

      var body = {
        'email': userCredential.user?.email,
        'name': userCredential.user?.displayName,
        'displayName': userCredential.user?.displayName,
        'roles': selectedRoles.map((role) => role.toJson()).toList(),
        'authData': userCredential.toJson(),
        "country_code": selectedCountryCode,
        'phone': phone,
        'is_email_password': false,
        'isIndividual': true,
        'uId': userCredential.user?.uid,
      };
      log("body: ${jsonEncode(body)}");

      // Call the Firebase Cloud Function
      final HttpsCallable callable = FirebaseFunctions.instance
          .httpsCallable('add_role_at_user_create_v2');
      final result = await callable.call(body);

      print('Cloud Function result: ${result.data}');

      _user = userCredential.user;
      _isSigningUp = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return result.data;
    } on FirebaseAuthException catch (e) {
      _isSigningUp = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      // Handle error
      print('Error signing up: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message!),
        ),
      );

      return '';
    }
  }

  Future<String> signUpIndividualWithApple(
      String? email,
      String? password,
      String? name,
      String? displayname,
      String? mobile,
      String? countryCode,
      List<Categories> selectedRoles,
      UserCredential? userCredential,
      BuildContext context) async {
    try {
      _isSigningUp = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      var body = {
        'email': email,
        'name': email,
        'displayName': email,
        'roles': selectedRoles.map((role) => role.toJson()).toList(),
        'authData': userCredential!.toJson(),
        "country_code": countryCode,
        'phone': mobile,
        'is_email_password': false,
        'isIndividual': true,
        'uId': userCredential.user?.uid,
      };
      log("body: ${jsonEncode(body)}");

      // Call the Firebase Cloud Function
      final HttpsCallable callable = FirebaseFunctions.instance
          .httpsCallable('add_role_at_user_create_v2');
      final result = await callable.call(body);

      print('Cloud Function result: ${result.data}');

      _user = userCredential.user;
      _isSigningUp = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return result.data;
    } on FirebaseAuthException catch (e) {
      _isSigningUp = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      // Handle error
      print('Error signing up: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message!),
        ),
      );

      return '';
    }
  }

  /// Registration for Individual on Microsoft Signup
  Future<String> signUpIndividualWithMicrosoft(
      UserCredential userCredential,
      String phone,
      String selectedCountryCode,
      List<Categories> selectedRoles,
      BuildContext context) async {
    try {
      _isSigningUp = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      print('cred: $userCredential');

      var body = {
        'email': userCredential.user?.email,
        'name': userCredential.user?.displayName,
        'displayName': userCredential.user?.displayName,
        'roles': selectedRoles.map((role) => role.toJson()).toList(),
        'authData': userCredential.toJson(),
        "country_code": selectedCountryCode,
        'phone': phone,
        'is_email_password': false,
        'isIndividual': true,
        'uId': userCredential.user?.uid,
      };
      log("body: ${jsonEncode(body)}");

      // Call the Firebase Cloud Function
      final HttpsCallable callable = FirebaseFunctions.instance
          .httpsCallable('add_role_at_user_create_v2');
      final result = await callable.call(body);

      print('Cloud Function result: ${result.data}');

      _user = userCredential.user;
      _isSigningUp = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return result.data;
    } on FirebaseAuthException catch (e) {
      _isSigningUp = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      // Handle error
      print('Error signing up: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message!),
        ),
      );

      return '';
    }
  }

  /// Registration for Individual
  Future<void> signUpIndividualWithEmailAndPassword(
      String mail,
      String password,
      String name,
      String displayName,
      String phone,
      String selectedCountryCode,
      List<Categories> selectedRoles,
      bool isApplicableForTrial,
      int trialPeriodDays,
      BuildContext context) async {
    try {
      _isSigningUp = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      // Create a new user with email and password
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: mail,
        password: password,
      );
      print('cred: $userCredential');

      var body = {
        'email': mail,
        'name': name,
        'displayName': displayName,
        'roles': selectedRoles.map((role) => role.toJson()).toList(),
        'authData': userCredential.toJson(),
        "country_code": selectedCountryCode,
        'phone': phone,
        'is_email_password': true,
        'isIndividual': true,
        'uId': userCredential.user?.uid,
      };
      log("body: ${jsonEncode(body)}");

      // Call the Firebase Cloud Function
      final HttpsCallable callable = FirebaseFunctions.instance
          .httpsCallable('add_role_at_user_create_v2');
      final result = await callable.call(body);

      print('Cloud Function result: ${result.data}');
      if (result.data == 'role_assigned') {
        //Send email to verify
        // await userCredential.user?.sendEmailVerification();
        final url =
            '${AppConstant.baseURL}/sendEmail_to_client_v2?type=email_verification&email=$mail';
        final response = await http.get(Uri.parse(url));
        print("Email verification response: ${response.body}");
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            var typography = CustomTypography(context);
            return AlertDialog(
              title: Text(
                Platform.isIOS
                    ? "Account Created"
                    : isApplicableForTrial
                        ? 'Enjoy your ${trialPeriodDays}-day free trial!'
                        : 'Check your inbox.',
                style: typography.H6.copyWith(color: Colors.white),
              ),
              content: Text(
                Platform.isIOS
                    ? "Activate email by clicking link sent."
                    : isApplicableForTrial
                        ? 'Trial account created with full features. Upgrade for continued access or remain free after ${trialPeriodDays} days. Activate email by clicking link sent.'
                        : 'We just sent you an email to confirm your account. Check your registered email address "${obscureEmail(mail)}" to complete the process.',
                style: typography.Body1.copyWith(color: Colors.white),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    // Navigator.pushAndRemoveUntil(
                    //     context,
                    //     MaterialPageRoute(builder: (context) => MyApp()),
                    //         (route) => false);
                  },
                  child: Row(
                    children: [
                      Icon(Icons.arrow_back),
                      SizedBox(width: CustomSpacing.four),
                      Text('Back to Login'),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      }

      _user = userCredential.user;
      _isSigningUp = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } on FirebaseAuthException catch (e) {
      print('Failed with error code: ${e.code}');
      print(e.message);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      _isSigningUp = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ?? "Something went wrong",
            style: CustomTypography(context).ButtonLargeBlack,
          ),
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      print('Failed with error code: ${e.code}');
      print(e.message);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      _isSigningUp = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ?? "Something went wrong",
            style: CustomTypography(context).Body1,
          ),
        ),
      );
    } on BackendException catch (e) {
      print('Failed with error code: ${e.message}');
      print(e.message);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      _isSigningUp = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Something went wrong. Please try again later.',
            style: CustomTypography(context).Body1,
          ),
        ),
      );
    } catch (e) {
      print('Failed with error code: $e');
      print(e);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      _isSigningUp = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Something went wrong. Please try again later.',
            style: CustomTypography(context).Body1,
          ),
        ),
      );
    }
  }

  Map<String, dynamic> normalizeCompanyType(dynamic companyType) {
    if (companyType == null)
      return {
        "type": null,
        "id": null,
        "name": null,
      };

    // CASE 1: companyType is a String
    if (companyType is String) {
      return {
        "type": companyType,
        "id": null,
        "name": companyType,
      };
    }

    // CASE 2: companyType is an object (your model)
    return {
      "type": companyType.type,
      "id": companyType.id,
      "name": companyType.name,
    };
  }

  /// Registration for Corporate
  Future<void> signUpCorporateWithEmailAndPassword(
    dynamic companyId,
    String companyLegalName,
    String companyTypeName,
    String companyDisplayName,
    String adminName,
    String adminEmail,
    String adminCountryCode,
    String adminPhone,
    String adminPassword,
    Roles? roles,
    BuildContext context,
    Companies? selectedCompany,
    bool isApplicableForTrial,
    int trialPeriodDays,
    String? selectedCorporateCountryName,
    String? companyTypeId,
  ) async {
    try {
      _isSigningUp = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());

      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );

      final user = userCredential.user!;
      final rolePayload = roles?.toJson() ??
          {
            "role": "admin",
            "name": "Admin",
          };

      final Map<String, dynamic> payload = {
        "accountType": "corporate",
        "isIndividual": false,

        "company_name": companyLegalName.trim().isEmpty
            ? companyDisplayName.trim()
            : companyLegalName.trim(),
        "company_display_name": companyDisplayName.trim(),
        "company_type": companyTypeName,
        "company_type_id": companyTypeId,
        "company_type_name": companyTypeName,

        /// admin
        "name": adminName.trim(),
        "email": adminEmail.trim(),
        "phone": adminPhone,
        "country_code": adminCountryCode,
        "country": "India",

        "roles": rolePayload,
        "corporateRoles": rolePayload,

        "disableCompanyTypeField": false,
        "disableCountryField": false,
        "is_email_password": true,

        /// auth
        "password": adminPassword,
        "confirmPassword": adminPassword,

        /// trial
        "trial_period_days": trialPeriodDays,
        "is_applicable_for_trial": isApplicableForTrial,

        /// firebase
        "uId": user.uid,

        /// authData
        "authData": {
          "displayName": user.displayName,
          "email": user.email,
          "isEmailVerified": user.emailVerified,
          "isAnonymous": user.isAnonymous,
          "metadata": {
            "createdAt":
                user.metadata.creationTime?.millisecondsSinceEpoch.toString(),
            "lastLoginAt":
                user.metadata.lastSignInTime?.millisecondsSinceEpoch.toString(),
          },
          "phoneNumber": user.phoneNumber,
          "photoURL": user.photoURL,
          "refreshToken": user.refreshToken,
          "tenantId": user.tenantId,
          "providerData": user.providerData
              .map((e) => {
                    "providerId": e.providerId,
                    "uid": e.uid,
                    "email": e.email,
                    "displayName": e.displayName,
                    "phoneNumber": e.phoneNumber,
                    "photoURL": e.photoURL,
                  })
              .toList(),
          "uId": user.uid,
        },
      };

      /// ✅ ADD company_id ONLY IF NOT MANUAL
      if (companyId != null && companyId != "manual") {
        payload["company_id"] = companyId;
      }

      /// DEBUG
      print(const JsonEncoder.withIndent('  ').convert({"data": payload}));

      /// 3️⃣ CALL CLOUD FUNCTION
      final response = await http.post(
        Uri.parse(
          '${AppConstant.baseURL}/add_role_at_user_create_v2',
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"data": payload}),
      );

      print("API RESPONSE >>> ${response.body}");

      /// 4️⃣ DECODE RESPONSE FIRST (🔥 FIX)
      final Map<String, dynamic> decodedResponse = jsonDecode(response.body);

      /// 5️⃣ HANDLE BACKEND ERRORS PROPERLY
      if (response.statusCode != 200) {
        final backendMessage = decodedResponse['error'] ??
            decodedResponse['message'] ??
            "Something went wrong";

        throw BackendException(backendMessage.toString(), response.statusCode);
      }

      /// 6️⃣ SUCCESS FLOW
      if (decodedResponse['data'] == 'role_assigned') {
        final url =
            '${AppConstant.baseURL}/sendEmail_to_client_v2?type=email_verification&email=$adminEmail';
        await http.get(Uri.parse(url));

        if (initialData != null &&
            initialData!.config[0].companyVerificationByAdmin &&
            selectedCompany == null) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              var typography = CustomTypography(context);
              return AlertDialog(
                title: Text(
                  isApplicableForTrial
                      ? 'Enjoy your ${trialPeriodDays}-day free trial!'
                      : LanguageService.getTranslated(
                          context, "login_check_your_inbox_dialog_title"),
                  style: typography.H6.copyWith(color: Colors.white),
                ),
                content: Text(
                  isApplicableForTrial
                      ? 'Trial account created with full features. Upgrade for continued access or remain free after ${trialPeriodDays} days. Activate email by clicking link sent.'
                      : LanguageService.getTranslated(
                          context, "login_check_your_inbox_dialog_description"),
                  style: typography.Body1.copyWith(color: Colors.white),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: Row(
                      children: [
                        Icon(Icons.arrow_back),
                        SizedBox(width: CustomSpacing.four),
                        Text(
                          LanguageService.getTranslated(
                            context,
                            "login_check_your_inbox_dialog_back_button_text",
                          ),
                          style: typography.Body1,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        }

        /// ------------------------------------------------------

        else if (selectedCompany != null &&
            selectedCompany.corporateUserVerificationByAdmin &&
            roles?.name!.toLowerCase() != 'admin') {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              var typography = CustomTypography(context);
              return AlertDialog(
                title: Text(
                  isApplicableForTrial
                      ? 'Enjoy your ${trialPeriodDays}-day free trial!'
                      : LanguageService.getTranslated(
                          context, "login_check_your_inbox_dialog_title"),
                  style: typography.H6.copyWith(color: Colors.white),
                ),
                content: Text(
                  isApplicableForTrial
                      ? 'Trial account created with full features. Upgrade for continued access or remain free after ${trialPeriodDays} days. Activate email by clicking link sent.'
                      : LanguageService.getTranslated(context,
                          "login_registration_request_dialog_description"),
                  style: typography.Body1.copyWith(color: Colors.white),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: Row(
                      children: [
                        Icon(Icons.arrow_back),
                        SizedBox(width: CustomSpacing.four),
                        Text(
                          LanguageService.getTranslated(
                            context,
                            "login_registration_request_dialog_back_button_text",
                          ),
                          style: typography.Body1,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        }

        /// ------------------------------------------------------

        else {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              var typography = CustomTypography(context);
              return AlertDialog(
                title: Text(
                  LanguageService.getTranslated(
                      context, "login_check_your_inbox_dialog_title"),
                  style: typography.H6.copyWith(color: Colors.white),
                ),
                content: Text(
                  LanguageService.getTranslated(context,
                          "login_registration_request_dialog_description_part_1") +
                      "${obscureEmail(adminEmail)}" +
                      LanguageService.getTranslated(context,
                          "login_registration_request_dialog_description_part_2"),
                  style: typography.Body1.copyWith(color: Colors.white),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: Row(
                      children: [
                        Icon(Icons.arrow_back),
                        SizedBox(width: CustomSpacing.four),
                        Text(
                          LanguageService.getTranslated(
                            context,
                            "login_check_your_inbox_dialog_back_button_text",
                          ),
                          style: typography.Body1,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        }
      }

      _user = userCredential.user;
      _isSigningUp = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
    } on FirebaseAuthException catch (e) {
      _isSigningUp = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Authentication failed")),
      );
    } on FirebaseFunctionsException catch (e) {
      _isSigningUp = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Cloud Function error")),
      );
    } on BackendException catch (e) {
      _isSigningUp = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());

      /// ✅ THIS WILL SHOW:
      /// "No trial users left for this company"
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      _isSigningUp = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  // Future<void> signUpCorporateWithEmailAndPassword(
  //   dynamic companyId,
  //   String companyLegalName,
  //   String companyTypeName,
  //   String companyDisplayName,
  //   String adminName,
  //   String adminEmail,
  //   String adminCountryCode,
  //   String adminPhone,
  //   String adminPassword,
  //   Roles? roles,
  //   BuildContext context,
  //   Companies? selectedCompany,
  //   bool isApplicableForTrial,
  //   int trialPeriodDays,
  //   String? selectedCorporateCountryName,
  //   String? companyTypeId,
  // ) async {
  //   try {
  //     _isSigningUp = true;
  //     WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
  //
  //     final UserCredential userCredential =
  //         await _auth.createUserWithEmailAndPassword(
  //       email: adminEmail,
  //       password: adminPassword,
  //     );
  //     final rolePayload = roles?.toJson() ??
  //         {
  //           "role": "admin",
  //           "name": "Admin",
  //         };
  //
  //     final user = userCredential.user!;
  //
  //     /// 3️⃣ BUILD FINAL PAYLOAD (WEB + MOBILE ALIGNED)
  //     final payload = {
  //       "accountType": "corporate",
  //       "isIndividual": false,
  //       // "disableCompanyNameField": false,
  //
  //       "company_name": companyLegalName.trim().isEmpty
  //           ? companyDisplayName.trim()
  //           : companyLegalName.trim(),
  //       "company_display_name": companyDisplayName.trim(),
  //       "company_type": companyTypeName,
  //       "company_type_id": companyTypeId,
  //       "company_type_name": companyTypeName,
  //
  //       /// admin
  //       "name": adminName.trim(),
  //       "email": adminEmail.trim(),
  //       "phone": adminPhone,
  //
  //       "country_code": adminCountryCode,
  //
  //       /// roles (🔥 BOTH REQUIRED)
  //       "roles": rolePayload,
  //       "corporateRoles": rolePayload,
  //
  //       /// flags
  //       "disableCompanyTypeField": false,
  //       "disableCountryField": false,
  //       "is_email_password": true,
  //
  //       /// auth
  //       "password": adminPassword,
  //       "confirmPassword": adminPassword,
  //
  //       /// trials
  //       "trial_period_days": 7,
  //       "is_applicable_for_trial": isApplicableForTrial,
  //
  //       /// firebase
  //       "uId": user.uid,
  //       "country": "India",
  //
  //       /// 🔥 AUTH DATA (FULL – SAME AS WEB)
  //       "authData": {
  //         "displayName": user.displayName,
  //         "email": user.email,
  //         "isEmailVerified": user.emailVerified,
  //         "isAnonymous": user.isAnonymous,
  //
  //         /// ✅ WEB-ALIGNED METADATA
  //         "metadata": {
  //           "createdAt":
  //               user.metadata.creationTime?.millisecondsSinceEpoch.toString(),
  //           "lastLoginAt":
  //               user.metadata.lastSignInTime?.millisecondsSinceEpoch.toString(),
  //         },
  //
  //         /// optional but backend-safe
  //         "phoneNumber": user.phoneNumber,
  //         "photoURL": user.photoURL,
  //         "refreshToken": user.refreshToken,
  //         "tenantId": user.tenantId,
  //
  //         /// providers
  //         "providerData": user.providerData
  //             .map((e) => {
  //                   "providerId": e.providerId,
  //                   "uid": e.uid,
  //                   "email": e.email,
  //                   "displayName": e.displayName,
  //                   "phoneNumber": e.phoneNumber,
  //                   "photoURL": e.photoURL,
  //                 })
  //             .toList(),
  //
  //         "uId": user.uid,
  //       },
  //     };
  //     if (companyId != null && companyId != "manual") {
  //       payload["company_id"] = companyId;
  //     }
  //     /// ✅ DEBUG — THIS MUST LOOK LIKE VALID JSON
  //     print(
  //       const JsonEncoder.withIndent('  ').convert({"data": payload}),
  //     );
  //
  //     /// 4️⃣ CALL CLOUD FUNCTION (HTTP – SAME AS WEB)
  //     final response = await http.post(
  //       Uri.parse(
  //         "https://us-central1-project-green-prod.cloudfunctions.net/add_role_at_user_create_v2",
  //       ),
  //       headers: {
  //         "Content-Type": "application/json",
  //       },
  //       body: jsonEncode({"data": payload}),
  //     );
  //
  //     print("API RESPONSE >>> ${response.body}");
  //
  //     if (response.statusCode != 200) {
  //       final backendMessage =
  //           decodedResponse['error'] ??
  //               decodedResponse['message'] ??
  //               'Something went wrong';
  //
  //       throw BackendException(backendMessage.toString());
  //     }
  //
  //     final decodedResponse = jsonDecode(response.body);
  //
  //     if (decodedResponse['data'] == 'role_assigned') {
  //       final url =
  //           '${AppConstant.baseURL}/sendEmail_to_client_v2?type=email_verification&email=$adminEmail';
  //       await http.get(Uri.parse(url));
  //
  //       if (initialData != null &&
  //           initialData!.config[0].companyVerificationByAdmin &&
  //           selectedCompany == null) {
  //         showDialog(
  //           context: context,
  //           barrierDismissible: false,
  //           builder: (BuildContext context) {
  //             var typography = CustomTypography(context);
  //             return AlertDialog(
  //               title: Text(
  //                 isApplicableForTrial
  //                     ? 'Enjoy your ${trialPeriodDays}-day free trial!'
  //                     : LanguageService.getTranslated(
  //                         context, "login_check_your_inbox_dialog_title"),
  //                 style: typography.H6.copyWith(color: Colors.white),
  //               ),
  //               content: Text(
  //                 isApplicableForTrial
  //                     ? 'Trial account created with full features. Upgrade for continued access or remain free after ${trialPeriodDays} days. Activate email by clicking link sent.'
  //                     : LanguageService.getTranslated(
  //                         context, "login_check_your_inbox_dialog_description"),
  //                 style: typography.Body1.copyWith(color: Colors.white),
  //               ),
  //               actions: [
  //                 TextButton(
  //                   onPressed: () {
  //                     Navigator.pop(context);
  //                     Navigator.pop(context);
  //                     // Navigator.pushAndRemoveUntil(
  //                     //     context,
  //                     //     MaterialPageRoute(builder: (context) => MyApp()),
  //                     //         (route) => false);
  //                   },
  //                   child: Row(
  //                     children: [
  //                       Icon(Icons.arrow_back),
  //                       SizedBox(width: CustomSpacing.four),
  //                       Text(
  //                         LanguageService.getTranslated(
  //                           context,
  //                           "login_check_your_inbox_dialog_back_button_text",
  //                         ),
  //                         style: typography.Body1,
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ],
  //             );
  //           },
  //         );
  //       } else if (selectedCompany != null &&
  //           selectedCompany!.corporateUserVerificationByAdmin! &&
  //           roles?.name!.toLowerCase() != 'admin') {
  //         showDialog(
  //           context: context,
  //           barrierDismissible: false,
  //           builder: (BuildContext context) {
  //             var typography = CustomTypography(context);
  //             return AlertDialog(
  //               title: Text(
  //                 isApplicableForTrial
  //                     ? 'Enjoy your ${trialPeriodDays}-day free trial!'
  //                     : LanguageService.getTranslated(
  //                         context, "login_check_your_inbox_dialog_title"),
  //                 style: typography.H6.copyWith(color: Colors.white),
  //               ),
  //               content: Text(
  //                 isApplicableForTrial
  //                     ? 'Trial account created with full features. Upgrade for continued access or remain free after ${trialPeriodDays} days. Activate email by clicking link sent.'
  //                     : LanguageService.getTranslated(context,
  //                         "login_registration_request_dialog_description"),
  //                 style: typography.Body1.copyWith(color: Colors.white),
  //               ),
  //               actions: [
  //                 TextButton(
  //                   onPressed: () {
  //                     Navigator.pop(context);
  //                     Navigator.pop(context);
  //                     // Navigator.pushAndRemoveUntil(
  //                     //     context,
  //                     //     MaterialPageRoute(builder: (context) => MyApp()),
  //                     //         (route) => false);
  //                   },
  //                   child: Row(
  //                     children: [
  //                       Icon(Icons.arrow_back),
  //                       SizedBox(width: CustomSpacing.four),
  //                       Text(
  //                         LanguageService.getTranslated(context,
  //                             "login_registration_request_dialog_back_button_text"),
  //                         style: typography.Body1,
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ],
  //             );
  //           },
  //         );
  //       } else {
  //         showDialog(
  //           context: context,
  //           barrierDismissible: false,
  //           builder: (BuildContext context) {
  //             var typography = CustomTypography(context);
  //             return AlertDialog(
  //               title: Text(
  //                 LanguageService.getTranslated(
  //                     context, "login_check_your_inbox_dialog_title"),
  //                 style: typography.H6.copyWith(color: Colors.white),
  //               ),
  //               content: Text(
  //                 LanguageService.getTranslated(context,
  //                         "login_registration_request_dialog_description_part_1") +
  //                     "${obscureEmail(adminEmail)}" +
  //                     LanguageService.getTranslated(context,
  //                         "login_registration_request_dialog_description_part_2"),
  //                 style: typography.Body1.copyWith(color: Colors.white),
  //               ),
  //               actions: [
  //                 TextButton(
  //                   onPressed: () {
  //                     Navigator.pop(context);
  //                     Navigator.pop(context);
  //                     // Navigator.pushAndRemoveUntil(
  //                     //     context,
  //                     //     MaterialPageRoute(builder: (context) => MyApp()),
  //                     //         (route) => false);
  //                   },
  //                   child: Row(
  //                     children: [
  //                       Icon(Icons.arrow_back),
  //                       SizedBox(width: CustomSpacing.four),
  //                       Text(
  //                         LanguageService.getTranslated(context,
  //                             "login_check_your_inbox_dialog_back_button_text"),
  //                         style: typography.Body1,
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ],
  //             );
  //           },
  //         );
  //       }
  //     }
  //
  //     _user = userCredential.user;
  //     _isSigningUp = false;
  //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //       notifyListeners();
  //     });
  //   } on FirebaseAuthException catch (e) {
  //     _isSigningUp = false;
  //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //       notifyListeners();
  //     });
  //
  //     // Handle error
  //     print('Error signing up: $e');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(e.message!),
  //       ),
  //     );
  //   } on FirebaseFunctionsException catch (e) {
  //     _isSigningUp = false;
  //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //       notifyListeners();
  //     });
  //
  //     // Handle error
  //     print('$e');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(e.message ?? "Error signing up"),
  //       ),
  //     );
  //   } on BackendException catch (e) {
  //     _isSigningUp = false;
  //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //       notifyListeners();
  //     });
  //
  //     // Handle error
  //     print('Error signing up: $e');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(e.message),
  //       ),
  //     );
  //   } catch (e) {
  //     _isSigningUp = false;
  //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //       notifyListeners();
  //     });
  //
  //     // Handle error
  //     print('Error signing up: $e');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(e.toString()),
  //       ),
  //     );
  //   }
  // }

  /// Initial Options

  Future<void> initialOptions() async {
    try {
      final HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('send_default_data_v2');
      final result = await callable.call();
      log('Cloud Function result: ${json.encode(result.data)}');
      print('Cloud Function result: ${json.encode(result.data)}');

      // Parse the data as JSON
      final jsonData = json.decode(json.encode(result.data));

      // Convert the JSON data to the expected type
      final data = Map<String, dynamic>.from(jsonData);

      // Parse the result
      InitialDataModel initialDataModel = InitialDataModel.fromJson(data);
      initialData = initialDataModel;
      roleList = initialDataModel.role;
      companyList = initialDataModel.companies;
      companyTypeList = initialDataModel.companyType;

/*
      // Print all three lists
      print('Role List:');
      roleList?.forEach((role) {
        print(role.toJson());
      });

      print('Company Type List:');
      companyTypeList?.forEach((companyType) {
        print(companyType.toJson());
      });

      print('Company List:');
      companyList?.forEach((company) {
        print(company.toJson());
      });*/
    } catch (e, stack) {
      // Handle error
      print('Error getting initial options: $e');
      print(stack);
    }
  }

  String obscureEmail(String email) {
    List<String> parts = email.split('@');

    String obscure(String part, int visibleStart, int visibleEnd) {
      return part.replaceRange(
          visibleStart, visibleEnd, '*' * (visibleEnd - visibleStart));
    }

    String localPart = obscure(parts[0], 1, parts[0].length - 1);
    String domainPart = obscure(parts[1], 1, parts[1].length - 2);

    return '$localPart@$domainPart';
  }

  Future<String> getAllClaims() async {
    try {
      if (isAssignClaimsLoading) return "";
      isAssignClaimsLoading = true;
      if (_auth.currentUser == null) {
        return "server_error";
      }
      // if (_auth.currentUser == null) {
      //   print("User is not authenticated.");
      //   return "";
      // }

      final HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('assignClaims_v2');

      String? token = await _auth.currentUser!.getIdToken(false);

      print("================ CALLABLE: assignClaims_v2 ================");
      print("URL: HTTPS Callable Function (assignClaims_v2)");
      print("Payload data: {'Authorization': 'Bearer ${token != null ? (token.substring(0, 15) + "...") : "null"}'}");
      print("==========================================================");

      HttpsCallableResult response = await callable.call(<String, dynamic>{
        'Authorization': 'Bearer ${token ?? ""}',
      });

      if (response.data == null ||
          response.data is! Map ||
          !response.data.containsKey('is_user_exists')) {
        print("Invalid response from Firebase");
        return "";
      }

      final data = response.data as Map<String, dynamic>;

      await Future.wait([
        SharedPreferenceService.setUserLicense(
            (data['has_user_license_count'] != null &&
                        data['has_user_license_count'] is Map
                    ? data['has_user_license_count']['left_credits']
                    : 0)
                .toString()),
        SharedPreferenceService.setGeocodingLicense(
            (data['has_geocoding_license_count'] != null &&
                        data['has_geocoding_license_count'] is Map
                    ? data['has_geocoding_license_count']['left_credits']
                    : 0)
                .toString()),
        SharedPreferenceService.setHazardLicense(
            (data['has_hazard_license_count'] != null &&
                        data['has_hazard_license_count'] is Map
                    ? data['has_hazard_license_count']['left_credits']
                    : 0)
                .toString()),
        SharedPreferenceService.setHurricane(
            (data['hurricane_kineticast'] != null &&
                        data['hurricane_kineticast'] is Map
                    ? data['hurricane_kineticast']['left_credits']
                    : 0)
                .toString()),
        SharedPreferenceService.setEarthquake(
            (data['earthquake_usgs'] != null && data['earthquake_usgs'] is Map
                    ? data['earthquake_usgs']['left_credits']
                    : 0)
                .toString()),
        SharedPreferenceService.setHasImpromentLicenseCount(
            (data['has_improvement_license_count'] != null &&
                        data['has_improvement_license_count'] is Map
                    ? data['has_improvement_license_count']['left_credits']
                    : 0)
                .toString()),
        SharedPreferenceService.setHazardHubLicense(
            (data['has_hazard_hub_license'] != null &&
                        data['has_hazard_hub_license'] is Map
                    ? data['has_hazard_hub_license']['left_credits']
                    : 0)
                .toString()),

        // "total_trial_days": 7,
        // "hurricane_kineticast": {
        //   "left_credits": 30
        // },
        // "earthquake_usgs": {
        //   "left_credits": 20
        // },

        SharedPreferenceService.setTrialUser(
            data['total_trial_users'].toString()),
        SharedPreferenceService.setTrailLocation(
            data['trial_locations'].toString()),
        SharedPreferenceService.setScheduleInProgress(
            data['schedule_inprogress'].toString()),
        SharedPreferenceService.setUpcomingScheduleStartTime(
            data['upcoming_schedule_starttime'] ?? ""),
        SharedPreferenceService.setUpcomingScheduleEndTime(
            data['upcoming_schedule_endtime'] ?? ""),
        SharedPreferenceService.saveHasAnyPlan(data['has_any_plan']),
        SharedPreferenceService.saveHasNewUser(data['is_new_account']),
        SharedPreferenceService.setDefaultAccountID(
            data['default_account_id'] ?? ""),

        SharedPreferenceService.setDefaultSUBAccountID(
            data['default_sub_account_id'] ?? ""),
        SharedPreferenceService.setDefaultMonitoringSov(
            data['default_monitoring_sov'] ?? ""),
        SharedPreferenceService.setDefaultAccountName(
            data['default_account_name'] ?? ""),
        SharedPreferenceService.setDefaultSUBAccountName(
            data['default_sub_account_name'] ?? ""),
        SharedPreferenceService.setSovUploadTempId(
            data['last_process_temp_id'] ?? ""),
        SharedPreferenceService.setDefaultDatasetID(data['dataset_id'] ?? ""),
        SharedPreferenceService.setSovUploadProcessId(
            data['last_process_id'] ?? ""),
        SharedPreferenceService.setSovUploadState(
            data['last_process_state'] ?? ""),
        SharedPreferenceService.setSovAccountId(data['last_account'] ?? ""),
        SharedPreferenceService.setSovSubAccountId(
            data['last_sub_account'] ?? ""),
        SharedPreferenceService.setSovAccountName(
            data['last_account_name'] ?? ""),
        SharedPreferenceService.setSovSubAccountName(
            data['last_sub_account_name'] ?? ""),
        SharedPreferenceService.setTrialPeriodStartDate(
          data['trial_period_start_date'] != null
              ? Timestamp(
                  data['trial_period_start_date']['_seconds'],
                  data['trial_period_start_date']['_nanoseconds'],
                )
              : null,
        )
      ]);

      // Parallel trial info saving
      if (data.containsKey('remaining_trial_days')) {
        await SharedPreferenceService.saveTrialInfo(
          data['remaining_trial_days'] ?? 0,
          data['is_applicable_for_trial'] ?? false,
          data['trial_subdestinations'] ?? 0,
          data['trial_max_updates'] ?? 0,
          data['trial_max_locations'] ?? 0,
          data['trial_locations'] ?? 0,
          data['total_trial_users'] ?? 0,
          data['total_users_verified'] ?? 0,
        );
      }

      return data["is_user_exists"].toString();
    } catch (e, stack) {
      print('Error getting all claims: $e');
      print('Stack trace: $stack');
      return "server_error";
    } finally {
      isAssignClaimsLoading = false;
    }
  }

  /// Remind API
  Future<bool> remindUser() async {
    try {
      // Get the current user
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("No user is signed in");
      }

      // Get the ID token of the current user
      String? idToken = await user.getIdToken();

      final url = '${AppConstant.baseURL}/sendEmail_to_client_v2?type=remind';

      // Set the headers including the Authorization header with the token
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      };

      // Define the request body
      final body = json.encode({
        'type': 'remind',
      });

      final response =
          await http.post(Uri.parse(url), headers: headers, body: body);

      // Handle the response
      if (response.statusCode == 200) {
        print('Cloud Function result: ${response.body}');
        return true;
      } else {
        print('Error: ${response.statusCode} - ${response.reasonPhrase}');
        return false;
      }
    } catch (e) {
      // Handle error
      print('Error reminding user: $e');
      return false;
    }
  }
}

extension UserCredentialExtension on UserCredential {
  Map<String, dynamic> toJson() {
    final user = this.user;
    final additionalUserInfo = this.additionalUserInfo;
    final credential = this.credential;
    return {
      'displayName': user?.displayName,
      'email': user?.email,
      'isEmailVerified': user?.emailVerified,
      'isAnonymous': user?.isAnonymous,
      'metadata': {
        'createdAt': user?.metadata.creationTime?.toIso8601String(),
        'lastLoginAt': user?.metadata.lastSignInTime?.toIso8601String(),
      },
      'phoneNumber': user?.phoneNumber,
      'photoURL': user?.photoURL,
      'providerData': user?.providerData
          .map((userInfo) => {
                'displayName': userInfo.displayName,
                'email': userInfo.email,
                'phoneNumber': userInfo.phoneNumber,
                'photoURL': userInfo.photoURL,
                'providerId': userInfo.providerId,
                'uid': userInfo.uid,
              })
          .toList(),
      'refreshToken': user?.refreshToken,
      'tenantId': user?.tenantId,
      'uId': user?.uid,
      'authData': {
        'isNewUser': additionalUserInfo?.isNewUser,
        'profile': additionalUserInfo?.profile,
        'providerId': additionalUserInfo?.providerId,
        'username': additionalUserInfo?.username,
        'authorizationCode': additionalUserInfo?.authorizationCode,
      },
      'credential': credential is EmailAuthCredential
          ? {
              'email': (credential).email,
              'password': (credential).password,
            }
          : credential is GoogleAuthCredential
              ? {
                  'accessToken':
                      (credential).accessToken,
                  'idToken': (credential).idToken,
                }
              : null,
    };
  }
}
