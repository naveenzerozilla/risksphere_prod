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

class AppleSignInButton extends StatelessWidget {
  final VoidCallback? onSuccess;
  final void Function(Exception error)? onError;

  const AppleSignInButton({super.key, this.onSuccess, this.onError});

  static const String serviceId = 'com.sonofthunder.risksphere.service';
  static const String firebaseProjectId = 'project-green-prod';

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
          (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _signInWithApple(BuildContext context) async {
    try {
      final rawNonce = _generateNonce();
      final hashedNonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
        webAuthenticationOptions: Platform.isIOS
            ? null
            : WebAuthenticationOptions(
          clientId: serviceId,
          redirectUri: Uri.parse(
            'https://project-green-prod.firebaseapp.com/__/auth/handler',
            // 'com.sonofthunder.risksphere://apple-callback',
          ),
        ),
      );

      if (appleCredential.identityToken == null) {
        throw Exception('Apple identity token is missing');
      }

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        oauthCredential,
      );

      final user = userCredential.user;

      if (user == null) {
        throw Exception('Firebase user is null after Apple sign-in');
      }

      IdTokenResult token = await userCredential.user!.getIdTokenResult();
      Map<String, dynamic>? claims = token.claims ?? {};

      await SharedPreferenceService.setClaims(claims);
      await SharedPreferenceService.getAllClaims();

      if (claims['isIndividual'] == null) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateAccountScreen(
              userCredential: userCredential,
              email: userCredential.additionalUserInfo!.profile!['email'],
              user: "apple",
            ),
          ),
        );
      } else {
        await Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen()),
              (route) => false,
        );
      }

      onSuccess?.call();
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException - Code: ${e.code}');
      debugPrint('Message: ${e.message}');
      onError?.call(e);
    } on SignInWithAppleAuthorizationException catch (e) {
      debugPrint('AppleAuthException - Code: ${e.code}');
      debugPrint('Message: ${e.message}');
      onError?.call(Exception(e.message));
    } catch (e) {
      debugPrint('Unknown Error: $e');
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
        onPressed: () => _signInWithApple(context),
        icon: const Icon(Icons.apple, color: Colors.white),
        label: const Text(
          "Continue with Apple",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}
