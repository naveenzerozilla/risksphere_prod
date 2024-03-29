import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthNotifier extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? _user;
  User? get user => _user;


  bool _isSigningIn = false;
  bool get isSigningIn => _isSigningIn;

  bool _isSigningOut = false;
  bool get isSigningOut => _isSigningOut;

  bool _isResettingPassword = false;
  bool get isResettingPassword => _isResettingPassword;

  AuthNotifier() {
    _initAuthState();
  }

  Future<void> _initAuthState() async {
    _user = _auth.currentUser;
    notifyListeners();
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      _isSigningIn = true;
      notifyListeners();

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

  Future<void> signInWithGoogle() async {
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
}
