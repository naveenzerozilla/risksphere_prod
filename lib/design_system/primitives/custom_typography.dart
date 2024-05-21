import 'package:flutter/material.dart';

class CustomTypography {
  static const double buttonLargeFontSize = 16.0;

  static const TextStyle ButtonLarge = TextStyle(
    fontFamily: 'General Sans',
    fontWeight: FontWeight.w500,
    fontSize: buttonLargeFontSize,
    height: 26.0 / buttonLargeFontSize, // Calculate the height based on line-height and font size
    letterSpacing: 0.46000000834465027,
  );

  static const TextStyle Caption = TextStyle(
    color: Color.fromRGBO(255, 255, 255, 0.70), // Using rgba(255, 255, 255, 0.70)
    fontFamily: 'General Sans',
    fontSize: 12.0,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w400,
    height: 1.66, // Corresponds to line-height: 166%
    letterSpacing: 0.4,
  );

  static const TextStyle H6 = TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontFamily: 'General Sans',
    fontWeight: FontWeight.w500,
    height: 0.08,
    letterSpacing: 0.15,);

  static const TextStyle H7 = TextStyle(
    fontSize: 18,
    fontFamily: 'General Sans',
    fontWeight: FontWeight.w500,
    height: 0.08,
    letterSpacing: 0.15,);

  static const TextStyle Body1 = TextStyle(
    fontFamily: 'General Sans',
    fontWeight: FontWeight.w400,
    fontSize: 16.0,
    height: 1.0, // Since line-height is a variable, set height to 1.0
    letterSpacing: 0.15000000596046448,
  );

  static const TextStyle Body1_5 = TextStyle(
    fontFamily: 'General Sans',
    fontWeight: FontWeight.w400,
    fontSize: 15.0,
    height: 1.0, // Since line-height is a variable, set height to 1.0
    letterSpacing: 0.15000000596046448,
  );

  static const TextStyle Body2 = TextStyle(
    fontFamily: 'General Sans',
    fontWeight: FontWeight.w400,
    fontSize: 14.0,
    height: 1.0, // Since line-height is a variable, set height to 1.0
    letterSpacing: 0.15000000596046448,
  );

  static const TextStyle InputValue = TextStyle(
    fontFamily: 'General Sans',
    fontWeight: FontWeight.w400,
    fontSize: 16.0,
    height: 1.0, // Since line-height is a variable, set height to 1.0
    letterSpacing: 0.15000000596046448,
  );

  static const TextStyle InputLabel = TextStyle(
    fontFamily: 'General Sans',
    fontWeight: FontWeight.w400,
    fontSize: 12.0,
    height: 1.0, // Since line-height is given as 12px, set height to 1.0
    letterSpacing: 0.15000000596046448,
  );

  static const TextStyle H4 = TextStyle(
    fontFamily: 'General Sans',
    fontWeight: FontWeight.w400,
    fontSize: 34.0,
    height: 1.23558823529, // Calculate this value based on the provided line-height
    letterSpacing: 0.25,
  );

  static const TextStyle Subtitle1 = TextStyle(
    fontFamily: 'General Sans',
    fontWeight: FontWeight.w400,
    fontSize: 16.0,
    height: 1.75,
    letterSpacing: 0.15000000596046448,
  );
  static const TextStyle Subtitle2 = TextStyle(
    fontFamily: 'General Sans',
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    height: 1.57, // Calculated based on the provided line-height of 157%
    letterSpacing: 0.1,
  );


  static const TextStyle BottomNavigationActiveLabel = TextStyle(
    fontFamily: 'General Sans',
    fontWeight: FontWeight.w400,
    fontSize: 14.0,
    height: 1.59142857143,
    letterSpacing: 0.4000000059604645,
  );


  static const TextStyle H5_Regular = TextStyle(
    fontFamily: 'General Sans',
    fontWeight: FontWeight.w400,
    fontSize: 24.0,
    height: 1.1265625, // Calculate this value based on the provided line-height.. height = fontSize * (lineHeight / fontSize);...height = 24.0 * (32.02 / 24.0) ≈ 1.1265625
  );


  // XS sizes
  static const TextStyle XS_Light = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w300,
    fontSize: 12.0,
  );

  static const TextStyle XS_Regular = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    fontSize: 12.0,
  );

  static const TextStyle XS_Medium = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    fontSize: 12.0,
  );

  static const TextStyle XS_SemiBold = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 12.0,
  );

  static const TextStyle XS_Bold = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w700,
    fontSize: 12.0,
  );

  // SM sizes
  static const TextStyle SM_Light = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w300,
    fontSize: 14.0,
  );

  static const TextStyle SM_Regular = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    fontSize: 14.0,
  );

  static const TextStyle SM_Medium = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    fontSize: 14.0,
  );

  static const TextStyle SM_SemiBold = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 14.0,
  );

  static const TextStyle SM_Bold = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w700,
    fontSize: 14.0,
  );

  // Base sizes
  static const TextStyle Base_Light = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w300,
    fontSize: 16.0,
  );

  static const TextStyle Base_Regular = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    fontSize: 16.0,
  );

  static const TextStyle Base_Medium = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    fontSize: 16.0,
  );

  static const TextStyle Base_SemiBold = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 16.0,
  );

  static const TextStyle Base_Bold = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w700,
    fontSize: 16.0,
  );

// LG sizes
  static const TextStyle LG_Light = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w300,
    fontSize: 18.0,
  );

  static const TextStyle LG_Regular = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    fontSize: 18.0,
  );

  static const TextStyle LG_Medium = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    fontSize: 18.0,
  );

  static const TextStyle LG_SemiBold = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 18.0,
  );

  static const TextStyle LG_Bold = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w700,
    fontSize: 18.0,
  );

// XL sizes
  static const TextStyle XL_Light = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w300,
    fontSize: 20.0,
  );

  static const TextStyle XL_Regular = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    fontSize: 20.0,
  );

  static const TextStyle XL_Medium = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    fontSize: 20.0,
  );

  static const TextStyle XL_SemiBold = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 20.0,
  );

  static const TextStyle XL_Bold = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w700,
    fontSize: 20.0,
  );

// 2XL sizes
  static const TextStyle TwoXL_Light = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w300,
    fontSize: 24.0,
  );

  static const TextStyle TwoXL_Regular = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    fontSize: 24.0,
  );

  static const TextStyle TwoXL_Medium = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    fontSize: 24.0,
  );

  static const TextStyle TwoXL_SemiBold = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 24.0,
  );

  static const TextStyle TwoXL_Bold = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w700,
    fontSize: 24.0,
  );

// 3XL sizes
  static const TextStyle ThreeXL_Light = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w300,
    fontSize: 28.0,
  );

  static const TextStyle ThreeXL_Regular = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    fontSize: 28.0,
  );

  static const TextStyle ThreeXL_Medium = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    fontSize: 28.0,
  );

  static const TextStyle ThreeXL_SemiBold = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 28.0,
  );

  static const TextStyle ThreeXL_Bold = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w700,
    fontSize: 28.0,
  );

// 4XL sizes
  static const TextStyle FourXL_Light = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w300,
    fontSize: 32.0,
  );

  static const TextStyle FourXL_Regular = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    fontSize: 32.0,
  );

  static const TextStyle FourXL_Medium = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    fontSize: 32.0,
  );

  static const TextStyle FourXL_SemiBold = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 32.0,
  );

  static const TextStyle FourXL_Bold = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w700,
    fontSize: 32.0,
  );

// 5XL sizes
  static const TextStyle FiveXL_Light = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w300,
    fontSize: 36.0,
  );

  static const TextStyle FiveXL_Regular = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    fontSize: 36.0,
  );

  static const TextStyle FiveXL_Medium = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    fontSize: 36.0,
  );

  static const TextStyle FiveXL_SemiBold = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 36.0,
  );

  static const TextStyle FiveXL_Bold = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w700,
    fontSize: 36.0,
  );

// 6XL sizes
  static const TextStyle SixXL_Light = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w300,
    fontSize: 40.0,
  );

  static const TextStyle SixXL_Regular = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    fontSize: 40.0,
  );

  static const TextStyle SixXL_Medium = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    fontSize: 40.0,
  );

  static const TextStyle SixXL_SemiBold = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 40.0,
  );

  static const TextStyle SixXL_Bold = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w700,
    fontSize: 40.0,
  );

  // 7XL sizes
  static const TextStyle SevenXL_Light = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w300,
    fontSize: 12.0,
  );

  static const TextStyle SevenXL_Regular = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    fontSize: 12.0,
  );

  static const TextStyle SevenXL_Medium = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    fontSize: 12.0,
  );

  static const TextStyle SevenXL_SemiBold = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 12.0,
  );

  static const TextStyle SevenXL_Bold = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w700,
    fontSize: 12.0,
  );

// 8XL sizes
  static const TextStyle EightXL_Light = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w300,
    fontSize: 13.0,
  );

  static const TextStyle EightXL_Regular = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    fontSize: 13.0,
  );

  static const TextStyle EightXL_Medium = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    fontSize: 13.0,
  );

  static const TextStyle EightXL_SemiBold = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 13.0,
  );

  static const TextStyle EightXL_Bold = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w700,
    fontSize: 13.0,
  );

// 9XL sizes
  static const TextStyle NineXL_Light = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w300,
    fontSize: 14.0,
  );

  static const TextStyle NineXL_Regular = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    fontSize: 14.0,
  );

  static const TextStyle NineXL_Medium = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    fontSize: 14.0,
  );

  static const TextStyle NineXL_SemiBold = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 14.0,
  );

  static const TextStyle NineXL_Bold = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w700,
    fontSize: 14.0,
  );

// Badge size
  static const TextStyle Badge_ForSmallSize = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    fontSize: 12.0,
  );

// kbd sizes
  static const TextStyle kbd_Small = TextStyle(
    fontFamily: 'Fira Mono',
    fontWeight: FontWeight.w500,
    fontSize: 12.0,
  );

  static const TextStyle kbd_Default = TextStyle(
    fontFamily: 'Fira Mono',
    fontWeight: FontWeight.w500,
    fontSize: 16.0,
  );

  static const TextStyle kbd_Large = TextStyle(
    fontFamily: 'Fira Mono',
    fontWeight: FontWeight.w500,
    fontSize: 20.0,
  );

  // Text Case
  static const String textCaseNone = 'none';

// Text Decoration
  static const String textDecorationNone = 'none';

// Paragraph Indent
  static const String paragraphIndentZero = '0px';


}
