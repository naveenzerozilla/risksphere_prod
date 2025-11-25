import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppleSignInButton extends StatelessWidget {
  final VoidCallback? onSuccess;
  final Function(Exception)? onError;

  const AppleSignInButton({
    super.key,
    this.onSuccess,
    this.onError,
  });

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// 🔐 Hash a string with SHA256
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      /// Request Apple credentials
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      /// 🔧 Ensure we have a valid token
      if (appleCredential.identityToken == null) {
        throw Exception("Missing identityToken from Apple.");
      }

      /// Build Firebase credential
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      /// Sign in with Firebase
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      final user = userCredential.user;

      debugPrint("✅ Apple Sign-In Successful");
      debugPrint("UID: ${user?.uid}");
      debugPrint("Email: ${user?.email}");
      debugPrint("DisplayName: ${user?.displayName}");

      onSuccess?.call();
    } on SignInWithAppleAuthorizationException catch (e) {
      debugPrint(" Apple Auth Error: ${e.code} - ${e.message}");
      onError?.call(Exception(e.message ?? e.code));
    } on FirebaseAuthException catch (e) {
      debugPrint(" FirebaseAuth Error: ${e.code} - ${e.message}");
      onError?.call(e);
    } catch (e) {
      debugPrint(" Unknown Error: $e");
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
        onPressed: _signInWithApple,
        icon: const Icon(Icons.apple, color: Colors.white),
        label: const Text(
          "Continue with Apple",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}
