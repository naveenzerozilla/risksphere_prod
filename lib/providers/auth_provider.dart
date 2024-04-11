import 'dart:convert';
import 'dart:developer';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:green/main.dart';

import '../design_system/primitives/custom_typography.dart';
import '../design_system/primitives/utilities/custom_spacing.dart';
import '../models/initial_data_model.dart';
import '../screens/onboarding/create_account_screen.dart';
import '../screens/onboarding/splash_screen.dart';

class AuthNotifier extends ChangeNotifier {
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

// Private variables to hold role list, company list, and company type list
  List<Role>? _roleList;
  List<Companies>? _companyList;
  List<CompanyType>? _companyTypeList;

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



  /// Login

  Future<void> signInWithEmailAndPassword(String email, String password, BuildContext context) async {
    try {
      _isSigningIn = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = userCredential.user;
      _isSigningIn = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      _isSigningIn = false;
      ScaffoldMessenger.of(context!).showSnackBar(
        SnackBar(
          content: Text('Invalid email or password'),
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      final GoogleSignInAccount? googleSignInAccount = await _googleSignIn.signIn();
      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication = await googleSignInAccount.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );
        final UserCredential userCredential = await _auth.signInWithCredential(credential);
        _user = userCredential.user;
        log('user: $userCredential');
        print('Is new user? ${userCredential.additionalUserInfo?.isNewUser}');
        IdTokenResult token = await userCredential.user!.getIdTokenResult();
        Map<String, dynamic>? claims = token.claims?? {};
        print("Claims: $claims");

        if(claims['isIndividual']==null&&claims['admin']==null) {
          isNewUser = true;
          // Navigate to create account screen and pass the user data
          Navigator.push(
            context!,
            MaterialPageRoute(
              builder: (context) => CreateAccountScreen(
                userCredential: userCredential,
              ),
            ),
          );
        }
      }
      _isSigningIn = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } on FirebaseAuthException catch (e) {
      _isSigningIn = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      // Handle error
      print("Error signing in with Google: $e");
      ScaffoldMessenger.of(context!).showSnackBar(
        SnackBar(
          content: Text(e.message!),
        ),
      );
    }
  }

  Future<void> signOut() async {
    try {
      _isSigningOut = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

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

  Future<void> resetPassword(String email, BuildContext context) async {
    try {
      _isResettingPassword = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      await _auth.sendPasswordResetEmail(email: email);
      // Reset password email sent successfully
      _isResettingPassword = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
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
    }
  }

  /// Registration for Individual on Google Signup
  Future<String> signUpIndividualWithGoogle(UserCredential userCredential, String phone, String selectedCountryCode, List<Categories> selectedRoles, BuildContext context) async {
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
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('add_role_at_user_create');
      final result = await callable.call(
          body
      );

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
  Future<void> signUpIndividualWithEmailAndPassword(String mail, String password, String name, String displayName, String phone, String selectedCountryCode, List<Categories> selectedRoles, BuildContext context) async {
    try {
      _isSigningUp = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });


      // Create a new user with email and password
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
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
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('add_role_at_user_create');
      final result = await callable.call(
          body
      );

      print('Cloud Function result: ${result.data}');
      if(result.data == 'role_assigned') {
        //Send email to verify
        await userCredential.user?.sendEmailVerification();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(selectedRoles.any(
                      (role) => role.isApplicableForTrial)?'Enjoy your 7-day free trial!':'Check your inbox.', style: CustomTypography.H6.copyWith(color: Colors.white),),
              content: Text(selectedRoles.any(
                      (role) => role.isApplicableForTrial)?'Trial account created with full features. Upgrade for continued access or remain free after 7 days. Activate email by clicking link sent.':'We just sent you an email to confirm your account. Check your registered email address "${obscureEmail(mail)}" to complete the process.', style: CustomTypography.Body1.copyWith(color: Colors.white),),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => MyApp()), (route) => false);
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
    } on FirebaseAuthException catch  (e) {
      print('Failed with error code: ${e.code}');
      print(e.message);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      _isSigningUp = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message!),
        ),
      );
    }
  }

  /// Registration for Corporate
  Future<void> signUpCorporateWithEmailAndPassword(String companyLegalName, CompanyType companyType, String companyDisplayName, String adminName, String adminEmail, String adminCountryCode, String adminPhone, String adminPassword, Roles? roles, BuildContext context, [Companies? selectedCompany]) async {
    try {
      _isSigningUp = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      // Create a new user with email and password
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );
      print('cred: $userCredential');


      var body = {
        "company_name": companyLegalName,
        "company_type": companyType.type,
        "company_display_name": companyDisplayName,
        "displayName": adminName,
        'display_name': companyDisplayName,
        "email": adminEmail,
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
      };
      log("body: ${jsonEncode(body)}");

      // Call the Firebase Cloud Function
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('add_role_at_user_create');
      final result = await callable.call(
          body
      );

      print('Cloud Function result: ${result.data}');
      if(result.data == 'role_assigned') {
        //Send email to verify
        await userCredential.user?.sendEmailVerification();
        print("company verified by admin and selected company is null: ${initialData!.config[0].companyVerificationByAdmin} ${selectedCompany == null}");
        print("selected company is not null: ${selectedCompany != null} ${selectedCompany?.corporateUserVerificationByAdmin} ${roles?.name.toLowerCase() != 'admin'}");
        if(initialData!=null&&initialData!.config[0].companyVerificationByAdmin && selectedCompany == null) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Check your inbox', style: CustomTypography.H6.copyWith(color: Colors.white),),
                content: Text('We just sent you an email to confirm your account. Check your registered email address "${obscureEmail(adminEmail)}" to complete the process.', style: CustomTypography.Body1.copyWith(color: Colors.white),),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => MyApp()), (route) => false);
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
        } else if(selectedCompany!=null&& selectedCompany.corporateUserVerificationByAdmin && roles?.name.toLowerCase() != 'admin') {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Registration request submitted', style: CustomTypography.H6.copyWith(color: Colors.white),),
                content: Text('Great news! Your registration request has been successfully submitted to your Corporate Admin, Amit at ${obscureEmail(adminEmail)}. Just a friendly reminder that your registration is currently pending approval. You should have received an email to verify your email address. Thank you for your cooperation!', style: CustomTypography.Body1.copyWith(color: Colors.white),),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => MyApp()), (route) => false);
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
    }
  }

  /// Initial Options

  Future<void> initialOptions() async {
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('send_default_data');
      final result = await callable.call();
      log('Cloud Function result: ${json.encode(result.data)}');



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
      });

    } catch (e, stack) {
      // Handle error
      print('Error getting initial options: $e');
      print(stack);
    }
  }
  String obscureEmail(String email) {
    List<String> parts = email.split('@');

    String obscure(String part, int visibleStart, int visibleEnd) {
      return part.replaceRange(visibleStart, visibleEnd, '*' * (visibleEnd - visibleStart));
    }

    String localPart = obscure(parts[0], 1, parts[0].length - 1);
    String domainPart = obscure(parts[1], 1, parts[1].length - 2);

    return '$localPart@$domainPart';
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
        'accessToken': (credential as GoogleAuthCredential).accessToken,
        'idToken': (credential as GoogleAuthCredential).idToken,
      }
          : null,
    };
  }


}
