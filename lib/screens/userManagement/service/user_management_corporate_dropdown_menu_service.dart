import 'package:flutter/material.dart';

import '../../../design_system/primitives/custom_typography.dart';
import '../../../design_system/primitives/utilities/custom_spacing.dart';
import '../../../service/language_service.dart';

class UserManagementCorporateDropdownMenuService {
  // Private list to hold dropdown items
  final List<DropdownMenuItem<String>> _corporateDropdownItems = [];

  // This method returns a list of DropdownMenuItem<String> with translated and styled text.
  List<DropdownMenuItem<String>> corporateDropdownItems(BuildContext context) {
    var typography = CustomTypography(context);

    return _corporateDropdownItems.isEmpty
        ? [
      DropdownMenuItem(
        child: Row(
          children: [
            Icon(Icons.apartment),
            SizedBox(width: CustomSpacing.two),
            Text(
              LanguageService.getTranslated(context, 'usermanagement_corp_dropdown_title_corporate_mang'),
              style: typography.BottomNavigationActiveLabel,
            ),
          ],
        ),
        value: 'Corporate',
      ),
      DropdownMenuItem(
        child: Text(
          LanguageService.getTranslated(context, 'usermanagement_corp_dropdown_option_companies'),
          style: typography.BottomNavigationActiveLabel,
        ),
        value: 'Companies',
      ),
      DropdownMenuItem(
        child: Text(
          LanguageService.getTranslated(context, 'usermanagement_corp_dropdown_option_users'),
          style: typography.BottomNavigationActiveLabel,
        ),
        value: 'Users',
      ),
      DropdownMenuItem(
        child: Text(
          LanguageService.getTranslated(context, 'usermanagement_corp_dropdown_option_companies_profiles'),
          style: typography.BottomNavigationActiveLabel,
        ),
        value: 'Company Profiles',
      ),
      DropdownMenuItem(
        child: Text(
          LanguageService.getTranslated(context, 'usermanagement_corp_dropdown_option_verification_requests'),
          style: typography.BottomNavigationActiveLabel,
        ),
        value: 'Verification Requests',
      ),
    ]
        : _corporateDropdownItems;
  }

  // This method allows you to update the dropdown items dynamically.
  void setCorporateDropdownItems(BuildContext context, List<DropdownMenuItem<String>> newItems) {
    var typography = CustomTypography(context);

    final List<DropdownMenuItem<String>> translatedItems = newItems.map((item) {
      String translatedText;
      if (item.child is Row) {
        final rowChildren = (item.child as Row).children;
        final textWidget = rowChildren.lastWhere((element) => element is Text) as Text;
        translatedText = textWidget.data!;
      } else if (item.child is Text) {
        translatedText = (item.child as Text).data!;
      } else {
        translatedText = '';
      }

      return DropdownMenuItem<String>(
        child: item.child is Row
            ? Row(
          children: [
            (item.child as Row).children[0], // Icon
            SizedBox(width: CustomSpacing.two),
            Text(
              translatedText,
              style: typography.BottomNavigationActiveLabel,
            ),
          ],
        )
            : Text(
          translatedText,
          style: typography.BottomNavigationActiveLabel,
        ),
        value: item.value,
      );
    }).toList();

    _corporateDropdownItems.clear();
    _corporateDropdownItems.addAll(translatedItems);
  }
}
