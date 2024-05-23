import 'package:flutter/material.dart';

import '../../../design_system/primitives/custom_typography.dart';
import '../../../design_system/primitives/utilities/custom_spacing.dart';
import '../../../service/language_service.dart';

class UserManagementCorporateDropdownMenuService {
  final List<DropdownMenuItem<String>> _corporateDropdownItems = [
    DropdownMenuItem(
      child: Row(
        children: [
          Icon(Icons.apartment),
          SizedBox(width: CustomSpacing.two),
          Text(
            'Corporate Management', // Placeholder text
            style: CustomTypography.BottomNavigationActiveLabel,
          ),
        ],
      ),
      value: 'Corporate',
    ),
    DropdownMenuItem(
      child: Text(
        'Companies', // Placeholder text
        style: CustomTypography.BottomNavigationActiveLabel,
      ),
      value: 'Companies',
    ),
    DropdownMenuItem(
      child: Text(
        'Users', // Placeholder text
        style: CustomTypography.BottomNavigationActiveLabel,
      ),
      value: 'Users',
    ),
    DropdownMenuItem(
      child: Text(
        'Company Profiles', // Placeholder text
        style: CustomTypography.BottomNavigationActiveLabel,
      ),
      value: 'Company Profiles',
    ),
    DropdownMenuItem(
      child: Text(
        'Verification Requests', // Placeholder text
        style: CustomTypography.BottomNavigationActiveLabel,
      ),
      value: 'Verification Requests',
    ),
  ];

  List<DropdownMenuItem<String>> corporateDropdownItems(BuildContext context) {
    return _corporateDropdownItems.map((item) {
      String translatedText;
      switch (item.value) {
        case 'Corporate':
          translatedText = LanguageService.getTranslated(context, 'usermanagement_corp_dropdown_title_corporate_mang');
          break;
        case 'Companies':
          translatedText = LanguageService.getTranslated(context, 'usermanagement_corp_dropdown_option_companies');
          break;
        case 'Users':
          translatedText = LanguageService.getTranslated(context, 'usermanagement_corp_dropdown_option_users');
          break;
        case 'Company Profiles':
          translatedText = LanguageService.getTranslated(context, 'usermanagement_corp_dropdown_option_companies_profiles');
          break;
        case 'Verification Requests':
          translatedText = LanguageService.getTranslated(context, 'usermanagement_corp_dropdown_option_verification_requests');
          break;
        default:
          translatedText = item.child is Text ? (item.child as Text).data! : '';
      }

      return DropdownMenuItem<String>(
        child: item.child is Row
            ? Row(
          children: [
            (item.child as Row).children[0], // Icon
            (item.child as Row).children[1], // SizedBox
            Text(
              translatedText,
              style: CustomTypography.BottomNavigationActiveLabel,
            ),
          ],
        )
            : Text(
          translatedText,
          style: CustomTypography.BottomNavigationActiveLabel,
        ),
        value: item.value,
      );
    }).toList();
  }

  void setCorporateDropdownItems(BuildContext context, List<DropdownMenuItem<String>> newItems) {
    _corporateDropdownItems.clear();
    _corporateDropdownItems.addAll(newItems);
  }
}
