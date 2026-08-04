import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get(String key) {
    if (key == 'GOOGLE_MAPS_API_KEY') {
      if (Platform.isAndroid) {
        final androidKey = dotenv.env['GOOGLE_MAPS_API_KEY_ANDROID'];
        if (androidKey != null && androidKey.isNotEmpty) {
          return androidKey;
        }
      } else if (Platform.isIOS) {
        final iosKey = dotenv.env['GOOGLE_MAPS_API_KEY_IOS'];
        if (iosKey != null && iosKey.isNotEmpty) {
          return iosKey;
        }
      }
    }
    return dotenv.env[key] ?? '';
  }
}
