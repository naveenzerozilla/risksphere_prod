import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';

class LanguageService {
  static String getTranslated(BuildContext context, String text) {
    return context.tr(text);
  }
}