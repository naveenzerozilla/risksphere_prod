import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:RiskSphare/models/companymodel.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:RiskSphare/constants/enums.dart';
import 'package:RiskSphare/design_system/components/custom_button.dart';
import 'package:RiskSphare/main.dart';
import 'package:RiskSphare/screens/onboarding/login_screen.dart';
import 'package:RiskSphare/service/api_service.dart';
import 'package:RiskSphare/service/language_service.dart';

import '../design_system/primitives/custom_typography.dart';
import '../design_system/primitives/utilities/custom_spacing.dart';
import '../models/initial_data_model.dart';
import '../screens/onboarding/create_account_screen.dart';
import '../screens/onboarding/splash_screen.dart';
import '../service/shared_preference_service.dart';
import 'package:http/http.dart' as http;

import '../utils/api_constants.dart';

class AuthNotifier extends ChangeNotifier {
  ValueNotifier<List<Companies>> companyOptionsNotifier = ValueNotifier([]);
  List<Companies> companyOptions = [];
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool isNewUser = false;

  User? _user;

  User? get user => _user;

  bool _isSigningIn = false;

  bool get isSigningIn => _isSigningIn;

  bool _isSigningOut = false;

  bool get isSigningOut => _isSigningOut;

  bool _isSigningUp = false;

  bool get isSigningUp => _isSigningUp;

  bool _isResettingPassword = false;

  bool get isResettingPassword => _isResettingPassword;

  bool _isRemindLoading = false;

  bool get isRemindLoading => _isRemindLoading;

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

  /// Splash Screen
  ///

  /// fetch company
  ///
  // Future<List<Companies>> fetchCompanies(String name) async {
  //   final url =
  //       "https://us-central1-project-green-f4d78.cloudfunctions.net/send_default_data?name=$name";
  //
  //   try {
  //     final response = await http.get(Uri.parse(url));
  //     if (response.statusCode == 200) {
  //       final List<dynamic> jsonResponse = json.decode(response.body);
  //       return jsonResponse.map((data) => Companies.fromJson(data)).toList();
  //     } else {
  //       return [];
  //     }
  //   } catch (e) {
  //     print("Error fetching companies: $e");
  //     return [];
  //   }
  // }

  // Future<List<Companies>> fetchCompanies(String name) async {
  //   print(name);
  //   String encodedName = Uri.encodeComponent(name);
  //   final url =
  //       "https://us-central1-project-green-f4d78.cloudfunctions.net/send_default_data?name=$encodedName";
  //   print(url);
  //
  //   try {
  //     final response = await http.get(Uri.parse(url), headers: {
  //       'Content-Type': 'application/json',
  //       'Accept': 'application/json',
  //     });
  //
  //     print(response.statusCode);
  //     print("Raw API Response: ${response.body}");
  //
  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);
  //
  //       if (data is Map &&
  //           data.containsKey("result") &&
  //           data["result"] is List) {
  //         final List<dynamic> companyList = data["result"];
  //         return companyList.map((json) => Companies.fromJson(json)).toList();
  //       } else {
  //         print("⚠ Unexpected API response format: $data");
  //         return [];
  //       }
  //     } else {
  //       print(" Error: ${response.statusCode}");
  //       return [];
  //     }
  //   } catch (e) {
  //     print("Error fetching companies: $e");
  //     return [];
  //   }
  // }

  Future<void> fetchCompanies(String name) async {
    print("Fetching: $name");

    // if (name.isEmpty) {
    //   companyOptionsNotifier.value = [];
    //   return;
    // }

    try {
      final response = await http.get(
        Uri.parse("https://us-central1-project-green-f4d78.cloudfunctions.net/send_default_data?name=${Uri.encodeComponent(name)}"),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        print("object");
        final data = json.decode(response.body);

        if (data is Map && data.containsKey("result") && data["result"] is List) {
          print("data");
          final List<dynamic> companyList = data["result"];
          print(companyList);
          companyOptionsNotifier.value = companyList.map((json) => Companies.fromJson(json)).toList();
        } else {
          companyOptionsNotifier.value = [];
        }
      } else {
        companyOptionsNotifier.value = [];
      }
    } catch (e) {
      print("Error fetching companies: $e");
      companyOptionsNotifier.value = [];
    }
    companyOptionsNotifier.notifyListeners();
  }




//   Future<List<Companies>> fetchCompanies(String name) async {
//     print(name);
//     String encodedName = Uri.encodeComponent(name);
//     final url =
//         "https://us-central1-project-green-f4d78.cloudfunctions.net/send_default_data?name=$encodedName";
// print(url);
//     try {
//       final response = await http.get(Uri.parse(url),  headers: {
//         'Content-Type': 'application/json',
//         'Accept': 'application/json',
//       },);
// print(response.statusCode);
//       // Debugging: Print raw response
//       print("Raw API Response: ${response.body}");
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//
//         if (data is List) {
//           // ✅ Case 1: API returns a direct list of companies
//           return data.map((json) => Companies.fromJson(json)).toList();
//         } else if (data is Map) {
//           // ✅ Case 2: API returns an object, check where the list exists
//           if (data.containsKey("companies") && data["companies"] is List) {
//             final List<dynamic> companyList = data["companies"];
//             return companyList.map((json) => Companies.fromJson(json)).toList();
//           } else if (data.containsKey("data") && data["data"] is List) {
//             final List<dynamic> companyList = data["data"];
//             return companyList.map((json) => Companies.fromJson(json)).toList();
//           } else {
//             print("⚠ Unexpected API response format: $data");
//             return [];
//           }
//         } else {
//           print("⚠ Unexpected data type from API");
//           return [];
//         }
//       } else {
//         print("❌ Error: ${response.statusCode}");
//         return [];
//       }
//     } catch (e) {
//       print("❌ Error fetching companies: $e");
//       return [];
//     }
//   }

  /// Login

  Future<void> signInWithEmailAndPassword(
      String email, String password, BuildContext context1) async {
    try {
      _isSigningIn = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,





      );
      _user = userCredential.user;

      IdTokenResult token = await userCredential.user!.getIdTokenResult();
      Map<String, dynamic>? claims = token.claims ?? {};
      log("Claims231: $claims");

      String isAdminVerified = await getAllClaims();
      print("is admin verified" + isAdminVerified.length.toString());
      print(isAdminVerified.toLowerCase());

      if (!(_user?.emailVerified ?? false)) {
        _isSigningIn = false;
        var typography = CustomTypography(context1);
        ScaffoldMessenger.of(context1).showSnackBar(
          SnackBar(
            content: Text(
              LanguageService.getTranslated(
                  context1, "login_email_not_verified_error"),
              style: typography.Body1,
            ),
          ),
        );

        await _auth.signOut();
        final _googleSignIn = GoogleSignIn();
        var isSignedIn = await _googleSignIn.isSignedIn();
        if (isSignedIn) await _googleSignIn.disconnect();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return;
      } else if (isAdminVerified.toLowerCase() == "false" ||
          isAdminVerified.length.toString() == "0") {
        _isSigningIn = false;
        // Show dialog with reminder to verify email for admin
        // ignore: use_build_context_synchronously
        await showDialog(
          context: context1,
          barrierDismissible: false,
          builder: (BuildContext context) {
            var typography = CustomTypography(context);
            return StatefulBuilder(
              // Use StatefulBuilder to update UI inside AlertDialog
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
                                  // Start showing loader
                                  setState(() {
                                    isRemindLoading = true;
                                  });

                                  bool result = await remindUser();

                                  // Stop showing loader
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

                                  // Ensure UI updates before closing dialog
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
                                            color: Colors
                                                .white)) // Ensure visibility
                                    : Text(
                                        LanguageService.getTranslated(context,
                                            "login_admin_not_verified_remind_button"),
                                        style: typography.Body1,
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

        // await showDialog(
        //   context: context1,
        //   barrierDismissible: false,
        //   builder: (BuildContext context) {
        //     var typography = CustomTypography(context);
        //     return AlertDialog(
        //       title: Text(
        //         LanguageService.getTranslated(
        //             context, "login_admin_not_verified_dialog_title"),
        //         style: typography.H6.copyWith(color: Colors.white),
        //       ),
        //       content: Text(
        //         LanguageService.getTranslated(
        //             context, "login_admin_not_verified_dialog_description"),
        //         style: typography.Body1.copyWith(color: Colors.white),
        //       ),
        //       actions: [
        //         // Remind and cancel in column
        //         Column(
        //           children: [
        //             Row(
        //               children: [
        //                 Expanded(
        //                   child: CustomButton(
        //                     type: ButtonType.elevated,
        //                     onPressed: () async {
        //                       // Start loading
        //                       isRemindLoading = true;
        //                       notifyListeners(); // Notify UI to update
        //
        //                       bool result = await remindUser();
        //
        //                       // Stop loading
        //                       isRemindLoading = false;
        //                       notifyListeners(); // Notify UI to update
        //
        //                       if (result) {
        //
        //                         ScaffoldMessenger.of(context).showSnackBar(
        //                           SnackBar(
        //                             content: Text(
        //                               LanguageService.getTranslated(
        //                                   context, "login_admin_not_verified_remind_success"),
        //                               style: typography.H6.copyWith(color: Colors.black),
        //                             ),
        //                           ),
        //                         );
        //
        //                       }
        //
        //                       final _googleSignIn = GoogleSignIn();
        //                       var isSignedIn = await _googleSignIn.isSignedIn();
        //
        //                       if (isSignedIn) await _googleSignIn.disconnect();
        //                       await _auth.signOut();
        //                       Navigator.pop(context);
        //                     },
        //                     child: isRemindLoading
        //                         ? Center(child: CircularProgressIndicator())
        //                         : Text(
        //                       LanguageService.getTranslated(
        //                           context, "login_admin_not_verified_remind_button"),
        //                       style: typography.Body1,
        //                     ),
        //                   ),
        //                 ),
        //
        //                 //           Expanded(
        //                 //             child: CustomButton(
        //                 //                 type: ButtonType.elevated,
        //                 // // Add this to the state of your widget
        //                 //
        //                 //   onPressed: () async {
        //                 //     showDialog(
        //                 //       context: context,
        //                 //       barrierDismissible: false, // Prevent dismissing the dialog
        //                 //       builder: (BuildContext context) {
        //                 //         return Center(
        //                 //           child: CircularProgressIndicator(), // Show loading spinner
        //                 //         );
        //                 //       },
        //                 //     );
        //                 //
        //                 //                   // Wait for 2 seconds before proceeding
        //                 //                   await Future.delayed(Duration(seconds: 1));
        //                 //
        //                 //                   // Close the dialog after 2 seconds
        //                 //                   // Navigator.pushAndRemoveUntil(
        //                 //                   //     context,
        //                 //                   //     MaterialPageRoute(
        //                 //                   //         builder: (context) => LoginScreen()),
        //                 //                   //     (route) => false);
        //                 //                       WidgetsBinding.instance.addPostFrameCallback((_) {
        //                 //                         notifyListeners();
        //                 //                         isRemindLoading =true;
        //                 //                       });
        //                 //
        //                 //                   print("Remind user: ${_user?.email}");
        //                 //
        //                 //                   bool result = await remindUser();
        //                 //
        //                 //                       WidgetsBinding.instance.addPostFrameCallback((_) {
        //                 //                         notifyListeners();
        //                 //                         isRemindLoading =false;
        //                 //                       });
        //                 //
        //                 //
        //                 //                       if (result) {
        //                 //                   ScaffoldMessenger.of(context).showSnackBar(
        //                 //                     SnackBar(
        //                 //                       content: Text(
        //                 //                         LanguageService.getTranslated(context,
        //                 //                             "login_admin_not_verified_remind_success"),
        //                 //                         // style: typography.Body1,
        //                 //                         style: typography.H6
        //                 //                             .copyWith(color: Colors.black),
        //                 //                       ),
        //                 //                     ),
        //                 //                   );
        //                 //                   }
        //                 //
        //                 //                   final _googleSignIn = GoogleSignIn();
        //                 //                   var isSignedIn = await _googleSignIn.isSignedIn();
        //                 //
        //                 //                   if (isSignedIn) await _googleSignIn.disconnect();
        //                 //                   await _auth.signOut();
        //                 //
        //                 //                   WidgetsBinding.instance.addPostFrameCallback((_) {
        //                 //                     notifyListeners();
        //                 //                   });
        //                 //                 },
        //                 //                 child:
        //                 //                     !isRemindLoading
        //                 //                                           ? Center(child: CircularProgressIndicator())
        //                 //                                           :
        //                 //                     Text(
        //                 //                   LanguageService.getTranslated(context1,
        //                 //                       "login_admin_not_verified_remind_button"),
        //                 //                   style: typography.Body1,
        //                 //                 )),
        //                 //           ),
        //               ],
        //             ),
        //             SizedBox(height: CustomSpacing.four),
        //             Row(
        //               children: [
        //                 Expanded(
        //                   child: CustomButton(
        //                       type: ButtonType.text,
        //                       onPressed: () async {
        //
        //                         final _googleSignIn = GoogleSignIn();
        //                         var isSignedIn =
        //                         await _googleSignIn.isSignedIn();
        //                         if (isSignedIn)
        //                           await _googleSignIn.disconnect();
        //                         await _auth.signOut();
        //                         WidgetsBinding.instance
        //                             .addPostFrameCallback((_) {
        //                           notifyListeners();
        //                         });
        //                         Navigator.pushAndRemoveUntil(
        //                             context,
        //                             MaterialPageRoute(
        //                                 builder: (context) => SplashScreen()),
        //                                 (route) => false);
        //                       },
        //                       child: Text(
        //                         LanguageService.getTranslated(context,
        //                             "login_admin_not_verified_cancel_button"),
        //                         style:
        //                         typography.H6.copyWith(color: Colors.white),
        //                       )),
        //                 ),
        //               ],
        //             ),
        //           ],
        //         ),
        //       ],
        //     );
        //   },
        // );

        return;
      }

      await SharedPreferenceService.setClaims(claims);
      await SharedPreferenceService.getAllClaims();
      _isSigningIn = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      _isSigningIn = false;
      var typography = CustomTypography(context1);
      ScaffoldMessenger.of(context1).showSnackBar(
        SnackBar(
          content: Text(
            LanguageService.getTranslated(
                context1, "login_invaild_email_password_error"),
            style: typography.Body1,
          ),
        ),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      // Handle error
      print("Error signing in: $e");
    }
  }

  Future<void> signInWithGoogle({BuildContext? context}) async {
    try {
      _isSigningIn = true;
      notifyListeners(); // Immediately notify listeners about signing in state

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

        print('Is Individual? ${claims['isIndividual']}');
        _isSigningIn = false; // Stop loader before navigation
        notifyListeners();

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
            MaterialPageRoute(builder: (context) => MyApp()),
            (route) => false,
          );
        }
      } else {
        _isSigningIn = false;
        notifyListeners(); // Ensure the loader is hidden if sign-in is canceled
      }
    } on FirebaseAuthException catch (e) {
      _isSigningIn = false;
      notifyListeners(); // Stop loader
      print("Error signing in with Google: $e");

      ScaffoldMessenger.of(context!).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'An error occurred.'),
        ),
      );
    } catch (e) {
      _isSigningIn = false;
      notifyListeners(); // Stop loader
      print("Error signing in with Google: $e");
    }
  }

  // Future<void> signInWithGoogle({BuildContext? context}) async {
  //   try {
  //     _isSigningIn = true;
  //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //       notifyListeners();
  //     });
  //
  //     final GoogleSignInAccount? googleSignInAccount =
  //     await _googleSignIn.signIn();
  //     if (googleSignInAccount != null) {
  //       final GoogleSignInAuthentication googleSignInAuthentication =
  //       await googleSignInAccount.authentication;
  //       final AuthCredential credential = GoogleAuthProvider.credential(
  //         accessToken: googleSignInAuthentication.accessToken,
  //         idToken: googleSignInAuthentication.idToken,
  //       );
  //       final UserCredential userCredential =
  //       await _auth.signInWithCredential(credential);
  //       _user = userCredential.user;
  //       log('user: $userCredential');
  //       print('Is new user? ${userCredential.additionalUserInfo?.isNewUser}');
  //       IdTokenResult token = await userCredential.user!.getIdTokenResult();
  //       Map<String, dynamic>? claims = token.claims ?? {};
  //       log("Claims: $claims");
  //
  //       await SharedPreferenceService.setClaims(claims);
  //       await SharedPreferenceService.getAllClaims();
  //
  //       print('Is Individual? ${claims['isIndividual']}');
  //       if (claims['isIndividual'] == null) {
  //         isNewUser = true;
  //         // Navigate to create account screen and pass the user data
  //         Navigator.push(
  //           context!,
  //           MaterialPageRoute(
  //             builder: (context) =>
  //                 CreateAccountScreen(
  //                   userCredential: userCredential,
  //                 ),
  //           ),
  //         );
  //       } else {
  //         isNewUser = false;
  //         Navigator.pushAndRemoveUntil(
  //             context!,
  //             MaterialPageRoute(builder: (context) => MyApp()),
  //                 (route) => false);
  //       }
  //     }
  //     _isSigningIn = false;
  //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //       notifyListeners();
  //     });
  //   } on FirebaseAuthException catch (e) {
  //     _isSigningIn = false;
  //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //       notifyListeners();
  //     });
  //     // Handle error
  //     print("Error signing in with Google: $e");
  //     ScaffoldMessenger.of(context!).showSnackBar(
  //       SnackBar(
  //         content: Text(e.message!),
  //       ),
  //     );
  //   } catch (e) {
  //     print("Error signing in with Google: $e");
  //     _isSigningIn = false;
  //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //       notifyListeners();
  //     });
  //     // Handle error
  //     print("Error signing in with Google: $e");
  //   }
  // }

  Future<void> signInWithMicrosoft({BuildContext? context}) async {
    try {
      _isSigningIn = true;
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

      print('Is Individual? ${claims['isIndividual']}');

      print('Current User: ${userCredential.user!.email}');
      print('Current firebase user: ${_auth.currentUser!.email}');
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
        Navigator.pushAndRemoveUntil(
          context!,
          MaterialPageRoute(builder: (context) => MyApp()),
          (route) => false,
        );
      }

      _isSigningIn = false;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      _isSigningIn = false;
      notifyListeners();
      print("Error signing in with Microsoft: $e");
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'An error occurred'),
          ),
        );
      }
    }
  }

  Future<void> signOut() async {
    try {
      _isSigningOut = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      final _googleSignIn = GoogleSignIn();
      var isSignedIn = await _googleSignIn.isSignedIn();
      if (isSignedIn) await _googleSignIn.disconnect();
      await _auth.signOut();
      _user = null;
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
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
// and another things...
        //await _auth.sendPasswordResetEmail(email: email);
        // Reset password email sent successfully
        _isResettingPassword = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return true;
      } else {
// show error message etc.
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

      // Handle error
      print("Error sending password reset email: $e");
      ScaffoldMessenger.of(context!).showSnackBar(
        SnackBar(
          content: Text(e.message!),
        ),
      );
      return false;
    }
  }

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
      final HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('add_role_at_user_create');
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
      final HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('add_role_at_user_create');
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
      final HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('add_role_at_user_create');
      final result = await callable.call(body);

      print('Cloud Function result: ${result.data}');
      if (result.data == 'role_assigned') {
        //Send email to verify
        await userCredential.user?.sendEmailVerification();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            var typography = CustomTypography(context);
            return AlertDialog(
              title: Text(
                isApplicableForTrial
                    ? 'Enjoy your ${trialPeriodDays}-day free trial!'
                    : 'Check your inbox.',
                style: typography.H6.copyWith(color: Colors.white),
              ),
              content: Text(
                isApplicableForTrial
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
            style: CustomTypography(context).Body1,
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

  /// Registration for Corporate
  Future<void> signUpCorporateWithEmailAndPassword(
      String companyId,
      String companyLegalName,
      CompanyType companyType,
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
      String? _selectedCorporateCountryName) async {
    try {
      _isSigningUp = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      // Create a new user with email and password
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );
      print('cred: $userCredential');

      var body = {
        "company_id": companyId,
        "accountType": "corporate",
        "trial_period_days": trialPeriodDays,
        "is_applicable_for_trial": isApplicableForTrial,
        "company_name": companyLegalName.trim(),
        "company_type": companyType.type,
        "company_display_name": companyDisplayName,
        "displayName": adminName,
        'display_name': companyDisplayName,
        "email": adminEmail.trim(),
        "country_code": adminCountryCode,
        "phone": adminPhone,
        'authData': userCredential.toJson(),
        'is_email_password': true,
        'company_type_id': companyType.id,
        'company_type_name': companyType.name,
        'isIndividual': false,
        'roles': roles?.toJson(),
        'uId': userCredential.user?.uid,
        'company_detail': selectedCompany?.toJson(),
        'password': adminPassword,
        'confirm_password': adminPassword,
        'name': adminName,
        'country': _selectedCorporateCountryName,
      };
      log("body: ${jsonEncode(body)}");

      // Call the Firebase Cloud Function
      final HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('add_role_at_user_create');
      final result = await callable.call(body);

      print('Cloud Function result: ${result.data}');
      if (result.data == 'role_assigned') {
        //Send email to verify
        await userCredential.user?.sendEmailVerification();
        print(
            "company verified by admin and selected company is null: ${initialData!.config[0].companyVerificationByAdmin} ${selectedCompany == null}");
        print(
            "selected company is not null: ${selectedCompany != null} ${selectedCompany?.corporateUserVerificationByAdmin} ${roles?.name.toLowerCase() != 'admin'}");
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
                      // Navigator.pushAndRemoveUntil(
                      //     context,
                      //     MaterialPageRoute(builder: (context) => MyApp()),
                      //         (route) => false);
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
        } else if (selectedCompany != null &&
            selectedCompany!.corporateUserVerificationByAdmin! &&
            roles?.name.toLowerCase() != 'admin') {
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
                      // Navigator.pushAndRemoveUntil(
                      //     context,
                      //     MaterialPageRoute(builder: (context) => MyApp()),
                      //         (route) => false);
                    },
                    child: Row(
                      children: [
                        Icon(Icons.arrow_back),
                        SizedBox(width: CustomSpacing.four),
                        Text(
                          LanguageService.getTranslated(context,
                              "login_registration_request_dialog_back_button_text"),
                          style: typography.Body1,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        } else {
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
                      // Navigator.pushAndRemoveUntil(
                      //     context,
                      //     MaterialPageRoute(builder: (context) => MyApp()),
                      //         (route) => false);
                    },
                    child: Row(
                      children: [
                        Icon(Icons.arrow_back),
                        SizedBox(width: CustomSpacing.four),
                        Text(
                          LanguageService.getTranslated(context,
                              "login_check_your_inbox_dialog_back_button_text"),
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
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
    } on FirebaseFunctionsException catch (e) {
      _isSigningUp = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      // Handle error
      print('$e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? "Error signing up"),
        ),
      );
    } on BackendException catch (e) {
      _isSigningUp = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      // Handle error
      print('Error signing up: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
        ),
      );
    } catch (e) {
      _isSigningUp = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      // Handle error
      print('Error signing up: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  /// Initial Options

  Future<void> initialOptions() async {
    try {
      final HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('send_default_data');
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
        print("User is not authenticated.");
        return "";
      }

      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('assignClaims');

      // Use cached token if available
      String? token = await _auth.currentUser!.getIdToken(false);
      log("Token: $token");

      HttpsCallableResult response = await callable.call(<String, dynamic>{
        'Authorization': 'Bearer ${token ?? ""}',
      });

      if (response.data == null || response.data is! Map || !response.data.containsKey('is_user_exists')) {
        print("Invalid response from Firebase");
        return "";
      }

      final data = response.data as Map<String, dynamic>;

      // Batch shared preferences updates
      await Future.wait([
        SharedPreferenceService.setScheduleInProgress(data['schedule_inprogress'].toString()),
        SharedPreferenceService.setSovUploadTempId(data['last_process_temp_id'] ?? ""),
        SharedPreferenceService.setSovUploadProcessId(data['last_process_id'] ?? ""),
        SharedPreferenceService.setSovUploadState(data['last_process_state'] ?? ""),
        SharedPreferenceService.setSovAccountId(data['last_account'] ?? ""),
        SharedPreferenceService.setSovSubAccountId(data['last_sub_account'] ?? ""),
        SharedPreferenceService.setSovAccountName(data['last_account_name'] ?? ""),
        SharedPreferenceService.setSovSubAccountName(data['last_sub_account_name'] ?? ""),
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
      return "";
    } finally {
      isAssignClaimsLoading = false;
    }
  }
//before shared preference call
  // Future<String> getAllClaims() async {
  //   try {
  //     if (isAssignClaimsLoading) return "";
  //     isAssignClaimsLoading = true;
  //
  //     if (_auth.currentUser == null) {
  //       print("User is not authenticated.");
  //       return "";
  //     }
  //
  //     final HttpsCallable callable =
  //         FirebaseFunctions.instance.httpsCallable('assignClaims');
  //
  //     String? token = await _auth.currentUser!.getIdToken(true);
  //     log("Old Token: $token");
  //
  //     HttpsCallableResult response = await callable.call(<String, dynamic>{
  //       'Authorization': 'Bearer ${token ?? ""}',
  //     });
  //
  //     print("Raw Firebase Response: $response"); // Log full response
  //
  //     if (!response.data.containsKey('is_user_exists')) {
  //       print("Response missing expected field");
  //       return "";
  //       // throw Exception("Response missing expected field: is_user_exists");
  //     }
  //     if (response.data == null) {
  //       throw Exception("Response data is null");
  //     }
  //     if (response.data is! Map) {
  //       throw Exception("Response data is not a Map: ${response.data}");
  //     }
  //
  //     // print("is_user_exists: ${response.data["is_user_exists"]}");
  //     // print("is_user_exists: ${response.data['schedule_inprogress']}");
  //     // print("is_user_exists: ${response.data['last_account']}");
  //     // print("is_user_exists: ${response.data['last_sub_account']}");
  //     SharedPreferenceService.setScheduleInProgress(
  //         response.data['schedule_inprogress'].toString());
  //     // SharedPreferenceService.setScheduleInProgress(
  //     //     response.data['schedule_inprogress']);
  //     SharedPreferenceService.setSovUploadTempId(
  //         response.data['last_process_temp_id'] ?? "");
  //     SharedPreferenceService.setSovUploadProcessId(
  //         response.data['last_process_id'] ?? "");
  //     SharedPreferenceService.setSovUploadState(
  //         response.data['last_process_state'] ?? "");
  //     SharedPreferenceService.setSovAccountId(
  //         response.data['last_account'] ?? "");
  //     SharedPreferenceService.setSovSubAccountId(
  //         response.data['last_sub_account'] ?? "");
  //     SharedPreferenceService.setSovAccountName(
  //         response.data['last_account_name'] ?? "");
  //     SharedPreferenceService.setSovSubAccountName(
  //         response.data['last_sub_account_name'] ?? "");
  //     if (response.data.containsKey('remaining_trial_days')) {
  //       int? trialDays = response.data['remaining_trial_days'];
  //       bool isTrialApplicable =
  //           response.data['is_applicable_for_trial'] ?? false;
  //       int? trialSubdestinations = response.data['trial_subdestinations'] ?? 0;
  //       int? trialEditLocations = response.data['trial_max_updates'] ?? 0;
  //       int? trialMaxLocations = response.data['trial_max_locations'] ?? 0;
  //       int? trialLocations = response.data['trial_locations'] ?? 0;
  //       int? trailTotalUsers = response.data['total_trial_users'] ?? 0;
  //       int? trialTotalUsersVerified =
  //           response.data['total_users_verified'] ?? 0;
  //
  //       // Store trial info in shared preferences
  //       await SharedPreferenceService.saveTrialInfo(
  //           trialDays ?? 0,
  //           isTrialApplicable,
  //           trialSubdestinations ?? 0,
  //           trialEditLocations ?? 0,
  //           trialMaxLocations ?? 0,
  //           trialLocations ?? 0,
  //           trailTotalUsers ?? 0,
  //           trialTotalUsersVerified ?? 0);
  //
  //       print(
  //           "Trial info saved: $trialDays days, Applicable: $isTrialApplicable");
  //     } else {
  //       print("No trial info found in claims response.");
  //       //await SharedPreferenceService.saveTrialInfo(16, true, 1735977542);
  //     }
  //     return response.data["is_user_exists"].toString();
  //   } catch (e, stack) {
  //     print(stack);
  //     print('Error getting all claims: $e');
  //     return "";
  //   } finally {
  //     isAssignClaimsLoading = false;
  //   }
  // }

  // Future<String> getAllClaims() async {
  //   try {
  //     if (isAssignClaimsLoading) return "";
  //     isAssignClaimsLoading = true;
  //     final HttpsCallable callable =
  //         FirebaseFunctions.instance.httpsCallable('assignClaims');
  //     String? token = await _auth.currentUser!.getIdToken(true);
  //     log("Old: $token");
  //
  //     HttpsCallableResult response = await callable.call(<String, dynamic>{
  //       'Authorization': 'Bearer ${token ?? ""}',
  //     });
  //     print("is_user_exists: ${response.data["is_user_exists"]}");
  //     print("update claims response:");
  //    print(response.data['schedule_inprogress']);
  //
  //     print("update claims response: ${response.data}");
  //     SharedPreferenceService.setScheduleInProgress(
  //         response.data['schedule_inprogress']);
  //     SharedPreferenceService.setSovUploadTempId(
  //         response.data['last_process_temp_id'] ?? "");
  //     SharedPreferenceService.setSovUploadProcessId(
  //         response.data['last_process_id'] ?? "");
  //     SharedPreferenceService.setSovUploadState(
  //         response.data['last_process_state'] ?? "");
  //
  //     SharedPreferenceService.setSovAccountId(
  //         response.data['last_account'] ?? "");
  //     print(response.data['last_account']);
  //     SharedPreferenceService.setSovSubAccountId(
  //         response.data['last_sub_account'] ?? "");
  //     print(response.data['last_sub_account']);
  //
  //     SharedPreferenceService.setSovAccountName(
  //         response.data['last_account_name'] ?? "");
  //     SharedPreferenceService.setSovSubAccountName(
  //         response.data['last_sub_account_name'] ?? "");
  //
  //     // Save trial information from the response
  //     if (response.data.containsKey('remaining_trial_days')) {
  //       int? trialDays = response.data['remaining_trial_days'];
  //       bool isTrialApplicable =
  //           response.data['is_applicable_for_trial'] ?? false;
  //       int? trialSubdestinations = response.data['trial_subdestinations'] ?? 0;
  //       int? trialEditLocations = response.data['trial_max_updates'] ?? 0;
  //       int? trialMaxLocations = response.data['trial_max_locations'] ?? 0;
  //       int? trialLocations = response.data['trial_locations'] ?? 0;
  //       int? trailTotalUsers = response.data['total_trial_users'] ?? 0;
  //       int? trialTotalUsersVerified =
  //           response.data['total_users_verified'] ?? 0;
  //
  //       // Store trial info in shared preferences
  //       await SharedPreferenceService.saveTrialInfo(
  //           trialDays ?? 0,
  //           isTrialApplicable,
  //           trialSubdestinations ?? 0,
  //           trialEditLocations ?? 0,
  //           trialMaxLocations ?? 0,
  //           trialLocations ?? 0,
  //           trailTotalUsers ?? 0,
  //           trialTotalUsersVerified ?? 0);
  //
  //       print(
  //           "Trial info saved: $trialDays days, Applicable: $isTrialApplicable");
  //     } else {
  //       print("No trial info found in claims response.");
  //       //await SharedPreferenceService.saveTrialInfo(16, true, 1735977542);
  //     }
  //
  //     String? newToken = await _auth.currentUser!
  //         .getIdTokenResult(true)
  //         .then((value) => value.token);
  //     log("New: $newToken");
  //     print('response: ${response.data}');
  //     print("is_user_exists: ${response.data["is_user_exists"]}");
  //     return response.data["is_user_exists"].toString();
  //   } catch (e, stack) {
  //     print(stack);
  //     print('Error getting all claims: $e');
  //     return "";
  //   } finally {
  //     isAssignClaimsLoading = false;
  //   }
  // }

  int _parseFirestoreTimestamp(Map<String, dynamic> timestamp) {
    try {
      int seconds = timestamp['_seconds'] ?? 0;
      return seconds; // Return as UNIX timestamp (seconds)
    } catch (e) {
      print("Error parsing Firestore timestamp: $e");
      return 0; // Default to 0 if parsing fails
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

      // Define the Cloud Function URL
      final url = '${AppConstant.baseURL}/sendEmail_to_client?type=remind';

      // Set the headers including the Authorization header with the token
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      };

      // Define the request body
      final body = json.encode({
        'type': 'remind',
      });

      print('Sending reminder to user: ${user.email}');
      print('Headers: $headers');
      print('Body: $body');
      print('URL: $url');
      // Make the POST request
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
        'creationTime': user?.metadata.creationTime?.toIso8601String(),
        'lastSignInTime': user?.metadata.lastSignInTime?.toIso8601String(),
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
      'uid': user?.uid,
      'additionalUserInfo': {
        'isNewUser': additionalUserInfo?.isNewUser,
        'profile': additionalUserInfo?.profile,
        'providerId': additionalUserInfo?.providerId,
        'username': additionalUserInfo?.username,
        'authorizationCode': additionalUserInfo?.authorizationCode,
      },
      'credential': credential is EmailAuthCredential
          ? {
              'email': (credential as EmailAuthCredential).email,
              'password': (credential as EmailAuthCredential).password,
            }
          : credential is GoogleAuthCredential
              ? {
                  'accessToken':
                      (credential as GoogleAuthCredential).accessToken,
                  'idToken': (credential as GoogleAuthCredential).idToken,
                }
              : null,
    };
  }
}
