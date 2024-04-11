import 'dart:convert';
import 'dart:developer';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/initial_data_model.dart';
import '../screens/onboarding/create_account_screen.dart';

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
  List<Comapnies>? _companyList;
  List<CompanyType>? _companyTypeList;

// Getters for role list, company list, and company type list
  List<Role>? get roleList => _roleList;
  List<Comapnies>? get companyList => _companyList;
  List<CompanyType>? get companyTypeList => _companyTypeList;

  // Setters for role list, company list, and company type list
  set roleList(List<Role>? roleList) {
    _roleList = roleList;
    notifyListeners();
  }
  set companyList(List<Comapnies>? companyList) {
    _companyList = companyList;
    notifyListeners();
  }
  set companyTypeList(List<CompanyType>? companyTypeList) {
    _companyTypeList = companyTypeList;
    notifyListeners();
  }

  InitialDataModel? _initialData;
  InitialDataModel? get initialData => _initialData;
  set initialData(InitialDataModel? initialData) {
    _initialData = initialData;
    notifyListeners();
  }



  AuthNotifier() {
    _initAuthState();
  }

  Future<void> _initAuthState() async {
    _user = _auth.currentUser;
    notifyListeners();
  }
  /// Splash Screen



  /// Login

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      _isSigningIn = true;
      notifyListeners();
      // Create the reCAPTCHA verifier
      RecaptchaVerifier recaptchaVerifier = RecaptchaVerifier(
        size: RecaptchaVerifierSize.normal,
        onSuccess: () {
          // Handle reCAPTCHA success
          print('reCAPTCHA verified successfully');
        },
        onError: (FirebaseAuthException exception) {
          // Handle reCAPTCHA errors
          print('reCAPTCHA verification failed: $exception');
        },
        onExpired: () {
          // Handle reCAPTCHA expiration
          print('reCAPTCHA verification expired');
        }, auth: FirebaseAuthPlatform.instance,
      );

      // Verify the reCAPTCHA token
      await recaptchaVerifier.verify();

      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = userCredential.user;
      _isSigningIn = false;
      notifyListeners();
    } catch (e) {
      _isSigningIn = false;
      notifyListeners();
      // Handle error
      print("Error signing in: $e");
    }
  }

  Future<void> signInWithGoogle({BuildContext? context}) async {
    try {
      _isSigningIn = true;
      notifyListeners();

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
      notifyListeners();
    } catch (e) {
      _isSigningIn = false;
      notifyListeners();
      // Handle error
      print("Error signing in with Google: $e");
    }
  }

  Future<void> signOut() async {
    try {
      _isSigningOut = true;
      notifyListeners();

      await _auth.signOut();
      _user = null;
      _isSigningOut = false;
      notifyListeners();
    } catch (e) {
      _isSigningOut = false;
      notifyListeners();
      // Handle error
      print("Error signing out: $e");
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      _isResettingPassword = true;
      notifyListeners();

      await _auth.sendPasswordResetEmail(email: email);
      // Reset password email sent successfully
      _isResettingPassword = false;
      notifyListeners();
    } catch (e) {
      _isResettingPassword = false;
      notifyListeners();
      // Handle error
      print("Error sending password reset email: $e");
    }
  }

  /// Registration for Individual on Google Signup
  Future<String> signUpIndividualWithGoogle(UserCredential userCredential, String phone, String selectedCountryCode, List<Categories> selectedRoles) async {
    try {
      _isSigningUp = true;
      notifyListeners();

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
      notifyListeners();
      return result.data;
    } catch (e) {
      _isSigningUp = false;
      notifyListeners();

      // Handle error
      print('Error signing up: $e');

      return '';
    }
  }

  /// Registration for Individual
  Future<void> signUpIndividualWithEmailAndPassword(String mail, String password, String name, String displayName, String phone, String selectedCountryCode, List<Categories> selectedRoles) async {
    try {
      _isSigningUp = true;
      notifyListeners();

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
      }

      _user = userCredential.user;
      _isSigningUp = false;
      notifyListeners();
    } catch (e) {
      _isSigningUp = false;
      notifyListeners();

      // Handle error
      print('Error signing up: $e');
    }
  }

  /// Registration for Corporate
  Future<void> signUpCorporateWithEmailAndPassword(String companyLegalName, CompanyType companyType, String companyDisplayName, String adminEmail, String adminCountryCode, String adminPhone, String adminPassword, Roles? roles, [Comapnies? selectedCompany]) async {
    try {
      _isSigningUp = true;
      notifyListeners();

      // Create a new user with email and password
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );
      print('cred: $userCredential');


      var body = {
        "company_name": companyLegalName,
        "company_type": companyType.toJson(),
        "displayName": companyDisplayName,
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
        "accountType": "corporate",
        'company_detail': selectedCompany?.toJson(),
        'password': adminPassword,
        'confirm_password': adminPassword,
        'name': null,
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
      }

      _user = userCredential.user;
      _isSigningUp = false;
      notifyListeners();
    } catch (e) {
      _isSigningUp = false;
      notifyListeners();

      // Handle error
      print('Error signing up: $e');
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
      companyList = initialDataModel.comapnies;
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
