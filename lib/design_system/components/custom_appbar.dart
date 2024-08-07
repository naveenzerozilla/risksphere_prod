import 'package:country_pickers/country.dart';
import 'package:country_pickers/country_picker_dropdown.dart';
import 'package:country_pickers/utils/utils.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:green/design_system/components/profile_image_widget.dart';
import 'package:green/providers/auth_provider.dart';
import 'package:green/screens/onboarding/splash_screen.dart';
import 'package:green/screens/userManagement/user_profile.dart';
import 'package:provider/provider.dart';

import '../primitives/custom_typography.dart';
import '../primitives/utilities/custom_spacing.dart';
import 'profile_dropdown.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isExpanded;
  final bool showNotificationDot;
  final Function(bool) onExpandPressed;
  final Function() onSearchPressed;
  final bool showDropdown;

  const CustomAppBar({
    Key? key,
    required this.isExpanded,
    required this.showNotificationDot,
    required this.onExpandPressed,
    required this.onSearchPressed,
    this.showDropdown = false,
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      titleSpacing: 0,
      title: isExpanded
          ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: CustomTypography.Subtitle1,
                border: InputBorder.none,
              ),
            ),
          )
          : GestureDetector(
              onTap: () {
                onExpandPressed(!isExpanded);
              },
              child: Container(
                padding: EdgeInsets.all(8),
                child: SvgPicture.asset(
                  'assets/images/logoHalf.svg',
                ),
              ),
            ),
      actions: <Widget>[
        GestureDetector(
          child: Icon(Icons.search, size: 28, color: Colors.grey),
          onTap: onSearchPressed,
        ),
        SizedBox(
          width: CustomSpacing.two,
        ),
        Consumer<AuthNotifier>(builder: (context, authNotifier, child) {
          return InkWell(
            onTap: () {
              SnackBar snackBar = SnackBar(
                content: Text('Coming Soon!'),
                duration: Duration(seconds: 2),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Coming Soon!',
                    style: CustomTypography.Body1,
                  ),
                ),
              );
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                SvgPicture.asset(
                  'assets/images/notificationIcon.svg',
                  height: 26,
                ),
                if (showNotificationDot)
                  Positioned(
                    top: -5,
                    right: -3,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
        SizedBox(
          width: CustomSpacing.four,
        ),
        CountryPickerDropdown(
          initialValue: _getInitialCountry(context),
          itemBuilder: (Country country) {
            return CircleAvatar(
              radius: 16.0,
              backgroundImage: AssetImage(
                CountryPickerUtils.getFlagImageAssetPath(country.isoCode),
                package: 'country_pickers',
              ),
            );
          },
          itemFilter: (Country country) {
            // Only include countries with these ISO codes
            return ['US', 'ES', 'FR', 'JP', 'CN'].contains(country.isoCode);
          },
          icon: SizedBox(),
          onValuePicked: (Country country) {
            switch (country.isoCode) {
              case 'US':
                context.setLocale(Locale('en'));
                break;
              case 'ES':
                context.setLocale(Locale('es'));
                break;
              case 'FR':
                context.setLocale(Locale('fr'));
                break;
              case 'JP':
                context.setLocale(Locale('ja'));
                break;
              case 'CN':
                context.setLocale(Locale('zh'));
                break;
            }
          },
        ),
        VerticalDivider(
          thickness: 1,
          width: 20,
          indent: 12,
          endIndent: 10,
        ),
        showDropdown
            ? Center(
                child: ProfileMenu(),
              )
            : Center(
              child: InkWell(onTap:() {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProfileScreen()),
                );
              },child: ProfileImageWidget()),
            ),
        SizedBox(width: 8),
      ],
    );
  }

  String _getInitialCountry(BuildContext context) {
    // ['US', 'ES', 'FR', 'JP', 'CN']
    if (context.locale == Locale('es')) return 'ES';
    if (context.locale == Locale('fr')) return 'FR';
    if (context.locale == Locale('ja')) return 'JP';
    if (context.locale == Locale('zh')) return 'CN';
    return 'US';
  }
}
