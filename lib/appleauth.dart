import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:RiskSphere/screens/home/dashboard_screen.dart';
import 'package:RiskSphere/screens/onboarding/create_account_screen.dart';
import 'package:RiskSphere/service/shared_preference_service.dart';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:RiskSphere/providers/auth_provider.dart';
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
    final authNotifier = Provider.of<AuthNotifier>(context, listen: false);
    try {
      authNotifier.isSigningInApple = true;
      UserCredential userCredential;

      if (Platform.isAndroid) {
        // Use Firebase native Apple provider to handle redirects and session states automatically
        final appleProvider = OAuthProvider('apple.com');
        appleProvider.addScope('email');
        appleProvider.addScope('name');
        
        userCredential = await FirebaseAuth.instance.signInWithProvider(appleProvider);
      } else {
        // Native Apple login sheet for iOS
        final rawNonce = _generateNonce();
        final hashedNonce = _sha256ofString(rawNonce);

        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: const [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: hashedNonce,
        );

        if (appleCredential.identityToken == null) {
          throw Exception('Apple identity token is missing');
        }

        final oauthCredential = OAuthProvider('apple.com').credential(
          idToken: appleCredential.identityToken,
          rawNonce: rawNonce,
          accessToken: appleCredential.authorizationCode,
        );

        userCredential = await FirebaseAuth.instance.signInWithCredential(
          oauthCredential,
        );
      }

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
    } finally {
      authNotifier.isSigningInApple = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthNotifier>(
      builder: (context, authNotifier, child) {
        final isLoading = authNotifier.isSigningInApple;
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
            onPressed: isLoading ? null : () => _signInWithApple(context),
            icon: isLoading
                ? Container(
                    width: 20,
                    height: 20,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.apple, color: Colors.white),
            label: Text(
              isLoading ? "Connecting..." : "Continue with Apple",
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        );
      },
    );
  }
}
