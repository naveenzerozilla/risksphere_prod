import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get(String key) => dotenv.env[key] ?? '';
}
