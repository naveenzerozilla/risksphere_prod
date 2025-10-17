import 'package:flutter/material.dart';

class CustomTypography {
  final BuildContext context;

  CustomTypography(this.context);

  TextStyle get ButtonLargeBlack => TextStyle(
    fontFamily: 'General Sans',
    fontWeight: FontWeight.w500,
    fontSize: 16.0,
    height: 26.0 / 16.0,
    letterSpacing: 0.46,
    color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.grey,
  );
  TextStyle get ButtonLarge => TextStyle(
    fontFamily: 'General Sans',
    fontWeight: FontWeight.w500,
    fontSize: 16.0,
    height: 26.0 / 16.0,
    letterSpacing: 0.46,
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
  );

  TextStyle get Caption => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87,
    fontFamily: 'General Sans',
    fontSize: 12.0,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w400,
    height: 1.66,
    letterSpacing: 0.4,
  );
  TextStyle get Caption1 => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87,
    fontFamily: 'General Sans',
    fontSize: 11.0,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w400,
    height: 1.66,
    letterSpacing: 0.4,
  );

  TextStyle get H6 => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontSize: 20,
    fontFamily: 'General Sans',
    fontWeight: FontWeight.w500,
    height: 0.08,
    letterSpacing: 0.15,
  );

  TextStyle get H7 => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontSize: 18,
    fontFamily: 'General Sans',
    fontWeight: FontWeight.w500,
    height: 0.08,
    letterSpacing: 0.15,
  );

  TextStyle get Body1 => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'General Sans',
    fontWeight: FontWeight.w400,
    fontSize: 16.0,
    height: 1.0,
    letterSpacing: 0.15,
  );

  TextStyle get Body1_5 => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'General Sans',
    fontWeight: FontWeight.w400,
    fontSize: 15.0,
    height: 1.0,
    letterSpacing: 0.15,
  );

  TextStyle get Body2 => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'General Sans',
    fontWeight: FontWeight.w400,
    fontSize: 14.0,
    height: 1.0,
    letterSpacing: 0.15,
  );

  TextStyle get InputValue => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'General Sans',
    fontWeight: FontWeight.w400,
    fontSize: 16.0,
    height: 1.0,
    letterSpacing: 0.15,
  );

  TextStyle get InputLabel => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
    fontFamily: 'General Sans',
    fontWeight: FontWeight.w400,
    fontSize: 12.0,
    height: 1.0,
    letterSpacing: 0.15,
  );

  TextStyle get H4 => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'General Sans',
    fontWeight: FontWeight.w400,
    fontSize: 34.0,
    height: 1.24,
    letterSpacing: 0.25,
  );

  TextStyle get Subtitle1 => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'General Sans',
    fontWeight: FontWeight.w400,
    fontSize: 16.0,
    height: 1.75,
    letterSpacing: 0.15,
  );

  TextStyle get Subtitle2 => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'General Sans',
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    height: 1.57,
    letterSpacing: 0.1,
  );

  TextStyle get BottomNavigationActiveLabel => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'General Sans',
    fontWeight: FontWeight.w400,
    fontSize: 14.0,
    height: 1.59,
    letterSpacing: 0.4,
  );

  TextStyle get H5_Regular => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'General Sans',
    fontWeight: FontWeight.w400,
    fontSize: 24.0,
    height: 1.13,
  );

  // XS sizes
  TextStyle get XS_Light => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w300,
    fontSize: 12.0,
  );

  TextStyle get XS_Regular => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    fontSize: 12.0,
  );

  TextStyle get XS_Medium => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    fontSize: 12.0,
  );

  TextStyle get XS_SemiBold => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 12.0,
  );

  TextStyle get XS_Bold => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w700,
    fontSize: 12.0,
  );

  // SM sizes
  TextStyle get SM_Light => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w300,
    fontSize: 14.0,
  );

  TextStyle get SM_Regular => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    fontSize: 14.0,
  );

  TextStyle get SM_Medium => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    fontSize: 14.0,
  );

  TextStyle get SM_SemiBold => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 14.0,
  );

  TextStyle get SM_Bold => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w700,
    fontSize: 14.0,
  );

  // Base sizes
  TextStyle get Base_Light => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w300,
    fontSize: 16.0,
  );

  TextStyle get Base_Regular => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    fontSize: 16.0,
  );

  TextStyle get Base_Medium => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    fontSize: 16.0,
  );

  TextStyle get Base_SemiBold => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 16.0,
  );

  TextStyle get Base_Bold => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w700,
    fontSize: 16.0,
  );

  // LG sizes
  TextStyle get LG_Light => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w300,
    fontSize: 18.0,
  );

  TextStyle get LG_Regular => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    fontSize: 18.0,
  );

  TextStyle get LG_Medium => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    fontSize: 18.0,
  );

  TextStyle get LG_SemiBold => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 18.0,
  );

  TextStyle get LG_Bold => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w700,
    fontSize: 18.0,
  );

  // XL sizes
  TextStyle get XL_Light => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w300,
    fontSize: 20.0,
  );

  TextStyle get XL_Regular => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    fontSize: 20.0,
  );

  TextStyle get XL_Medium => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    fontSize: 20.0,
  );

  TextStyle get XL_SemiBold => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 20.0,
  );

  TextStyle get XL_Bold => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w700,
    fontSize: 20.0,
  );

  // 2XL sizes
  TextStyle get TwoXL_Light => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w300,
    fontSize: 24.0,
  );

  TextStyle get TwoXL_Regular => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    fontSize: 24.0,
  );

  TextStyle get TwoXL_Medium => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    fontSize: 24.0,
  );

  TextStyle get TwoXL_SemiBold => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 24.0,
  );

  TextStyle get TwoXL_Bold => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w700,
    fontSize: 24.0,
  );

  // 3XL sizes
  TextStyle get ThreeXL_Light => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w300,
    fontSize: 28.0,
  );

  TextStyle get ThreeXL_Regular => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    fontSize: 28.0,
  );

  TextStyle get ThreeXL_Medium => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    fontSize: 28.0,
  );

  TextStyle get ThreeXL_SemiBold => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 28.0,
  );

  TextStyle get ThreeXL_Bold => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w700,
    fontSize: 28.0,
  );

  // 4XL sizes
  TextStyle get FourXL_Light => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w300,
    fontSize: 32.0,
  );

  TextStyle get FourXL_Regular => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    fontSize: 32.0,
  );

  TextStyle get FourXL_Medium => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    fontSize: 32.0,
  );

  TextStyle get FourXL_SemiBold => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 32.0,
  );

  TextStyle get FourXL_Bold => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w700,
    fontSize: 32.0,
  );

  // 5XL sizes
  TextStyle get FiveXL_Light => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w300,
    fontSize: 36.0,
  );

  TextStyle get FiveXL_Regular => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    fontSize: 36.0,
  );

  TextStyle get FiveXL_Medium => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    fontSize: 36.0,
  );

  TextStyle get FiveXL_SemiBold => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 36.0,
  );

  TextStyle get FiveXL_Bold => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w700,
    fontSize: 36.0,
  );

  // 6XL sizes
  TextStyle get SixXL_Light => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w300,
    fontSize: 40.0,
  );

  TextStyle get SixXL_Regular => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    fontSize: 40.0,
  );

  TextStyle get SixXL_Medium => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    fontSize: 40.0,
  );

  TextStyle get SixXL_SemiBold => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 40.0,
  );

  TextStyle get SixXL_Bold => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w700,
    fontSize: 40.0,
  );
}
