import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static final _storage = FlutterSecureStorage();

  // Save email & password
  static Future<void> saveLogin(String email, String password) async {
    await _storage.write(key: "email", value: email);
    await _storage.write(key: "password", value: password);
  }

  // Get login data
  static Future<Map<String, String?>> getLogin() async {
    String? email = await _storage.read(key: "email");
    String? password = await _storage.read(key: "password");
    return {
      "email": email,
      "password": password,
    };
  }

  // Clear login
  static Future<void> clearLogin() async {
    await _storage.delete(key: "email");
    await _storage.delete(key: "password");
  }
}
