import 'package:flutter/material.dart';

import '../../../design_system/primitives/custom_typography.dart';
import '../../../service/language_service.dart';

class VerificationTabsService {
  final List<Tab> _verificationTabs = [
    Tab(
      child: Text(
        'Corporate Verification', // Placeholder text
        style: CustomTypography.BottomNavigationActiveLabel,
      ),
    ),
    Tab(
      child: Text(
        'User Verification', // Placeholder text
        style: CustomTypography.BottomNavigationActiveLabel,
      ),
    ),
  ];

  List<Tab> verificationTabs(BuildContext context) {
    return _verificationTabs.map((tab) {
      String translatedText;
      switch (tab.child is Text ? (tab.child as Text).data : '') {
        case 'Corporate Verification':
          translatedText = LanguageService.getTranslated(context, 'usermanagement_corporate_verification_tab');
          break;
        case 'User Verification':
          translatedText = LanguageService.getTranslated(context, 'usermanagemet_user _verification_tab');
          break;
        default:
          translatedText = tab.child is Text ? (tab.child as Text).data! : '';
      }

      return Tab(
        child: Text(
          translatedText,
          style: CustomTypography.BottomNavigationActiveLabel,
        ),
      );
    }).toList();
  }

  void setVerificationTabs(BuildContext context, List<Tab> newTabs) {
    _verificationTabs.clear();
    _verificationTabs.addAll(newTabs);
  }
}
