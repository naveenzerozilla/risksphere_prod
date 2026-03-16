import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:RiskSphere/screens/home/dashboard_screen.dart';
import 'package:RiskSphere/screens/onboarding/create_account_screen.dart';
import 'package:RiskSphere/service/shared_preference_service.dart';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'design_system/components/custom_button.dart';

class AppleSignInButton extends StatelessWidget {
  final VoidCallback? onSuccess;
  final void Function(Exception error)? onError;

  const AppleSignInButton({super.key, this.onSuccess, this.onError});

  static const String serviceId = 'com.risksphere.qa'; // Your Service ID
  static const String firebaseProjectId = 'project-green-r5-1-qa';

  /// Generates a cryptographically secure random nonce
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// Returns the SHA-256 hash of the input
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Apple Sign-In flow with Firebase authentication
  Future<void> _signInWithApple(BuildContext context) async {
    try {
      // 1️⃣ Generate nonce
      final rawNonce = _generateNonce();
      final hashedNonce = _sha256ofString(rawNonce);

      // 2️⃣ Request Apple credential
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
        webAuthenticationOptions: Platform.isIOS
            ? null
            : WebAuthenticationOptions(
                clientId: serviceId, // ← project-green-prod
                redirectUri: Uri.parse(
                  'https://$firebaseProjectId.firebaseapp.com/__/auth/handler', // ← project-green-prod
                ),
              ),
      );

      if (appleCredential.identityToken == null) {
        throw Exception('Apple identity token is missing');
      }
      debugPrint('Apple ID Token: ${appleCredential.identityToken}');

      // 3️⃣ Create OAuth credential for Firebase
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      // 4️⃣ Sign in to Firebase
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        oauthCredential,
      );

      final user = userCredential.user;

      if (user == null) {
        throw Exception('Firebase user is null after Apple sign-in');
      }

      debugPrint('✅ Apple Sign-In Successful');
      debugPrint('UID: ${user.uid}');
      // log('user: $userCredential');
      print('Is new user? ${userCredential}');
      print(
          'Is new user? ${userCredential.additionalUserInfo!.profile!['email']}');

      debugPrint(userCredential.toString());
      debugPrint('Email: ${user.phoneNumber}');
      debugPrint('Apple Email: ${appleCredential.email}');
      debugPrint('Apple Given Name: ${appleCredential.givenName}');
      debugPrint('Display Name: ${user.displayName}');

      IdTokenResult token = await userCredential.user!.getIdTokenResult();
      Map<String, dynamic>? claims = token.claims ?? {};
      print(claims.toString());

      await SharedPreferenceService.setClaims(claims);
      await SharedPreferenceService.getAllClaims();

      print('Is Individual? ${claims['isIndividual']}');

      print('Is Individual? ${claims['isIndividual']}');

      if (claims['isIndividual'] == null) {
        // Navigate to create account screen and pass the user data
        await Navigator.push(
          context!,
          MaterialPageRoute(
            builder: (context) => CreateAccountScreen(
                userCredential: userCredential,
                email: userCredential.additionalUserInfo!.profile!['email'],
                user: "apple"),
          ),
        );
      } else {
        await Navigator.pushAndRemoveUntil(
          context!,
          MaterialPageRoute(builder: (context) => DashboardScreen()),
          (route) => false,
        );
      }
      onSuccess?.call();
    } on FirebaseAuthException catch (e) {
      debugPrint('Code: ${e.code}');
      debugPrint('Message: ${e.message}');
      onError?.call(e);
    } on SignInWithAppleAuthorizationException catch (e) {
      debugPrint('Code: ${e.code}');
      debugPrint('Message: ${e.message}');
      onError?.call(Exception(e.message));
    } catch (e) {
      debugPrint('❌ Unknown Error: $e');
      onError?.call(Exception(e.toString()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.grey),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            _signInWithApple(context);
          },
          icon: const Icon(Icons.apple, color: Colors.white),
          label: const Text(
            "Continue with Apple",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ));

  }
}
