import 'package:flutter/material.dart';

import '../../../design_system/primitives/custom_typography.dart';
import '../../../service/language_service.dart';

class VerificationTabsService {
  // Private list to hold Tab items
  final List<Tab> _verificationTabs = [];

  // This method returns a list of Tab with translated and styled text.
  List<Tab> verificationTabs(BuildContext context) {
    var typography = CustomTypography(context);

    // Check if _verificationTabs is empty, return the default tabs with translations
    return _verificationTabs.isEmpty
        ? [
      Tab(
        child: Text(
          LanguageService.getTranslated(context, 'usermanagement_corporate_verification_tab'),
          style: typography.BottomNavigationActiveLabel,
        ),
      ),
      Tab(
        child: Text(
          LanguageService.getTranslated(context, 'usermanagement_user_verification_tab'),
          style: typography.BottomNavigationActiveLabel,
        ),
      ),
    ]
        : _verificationTabs.map((tab) {
      String translatedText = '';
      if (tab.child is Text) {
        switch ((tab.child as Text).data) {
          case 'Corporate Verification':
            translatedText = LanguageService.getTranslated(context, 'usermanagement_corporate_verification_tab');
            break;
          case 'User Verification':
            translatedText = LanguageService.getTranslated(context, 'usermanagement_user_verification_tab');
            break;
          default:
            translatedText = (tab.child as Text).data ?? '';
        }
      }

      return Tab(
        child: Text(
          translatedText,
          style: typography.BottomNavigationActiveLabel,
        ),
      );
    }).toList();
  }

  // This method allows you to update the Tab items dynamically.
  void setVerificationTabs(BuildContext context, List<Tab> newTabs) {
    _verificationTabs.clear();
    _verificationTabs.addAll(newTabs);
  }
}
