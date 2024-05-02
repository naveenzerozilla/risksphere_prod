
// Copyright 2021 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

// NavigationRail shows if the screen width is greater or equal to
// narrowScreenWidthThreshold; otherwise, NavigationBar is used for navigation.
const double narrowScreenWidthThreshold = 450;

const double mediumWidthBreakpoint = 1000;
const double largeWidthBreakpoint = 1500;

const double transitionLength = 500;

// Whether the user has chosen a theme color via a direct [ColorSeed] selection,
// or an image [ColorImageProvider].
enum ColorSelectionMethod {
  colorSeed,
  image,
}

enum ColorSeed {
  baseColor('M3 Baseline', Color(0xff6750a4)),
  indigo('Indigo', Colors.indigo),
  blue('Blue', Colors.blue),
  teal('Teal', Colors.teal),
  green('Green', Colors.green),
  yellow('Yellow', Colors.yellow),
  orange('Orange', Colors.orange),
  deepOrange('Deep Orange', Colors.deepOrange),
  pink('Pink', Colors.pink);

  const ColorSeed(this.label, this.color);
  final String label;
  final Color color;
}

enum ColorImageProvider {
  leaves('Leaves',
      'https://flutter.github.io/assets-for-api-docs/assets/material/content_based_color_scheme_1.png'),
  peonies('Peonies',
      'https://flutter.github.io/assets-for-api-docs/assets/material/content_based_color_scheme_2.png'),
  bubbles('Bubbles',
      'https://flutter.github.io/assets-for-api-docs/assets/material/content_based_color_scheme_3.png'),
  seaweed('Seaweed',
      'https://flutter.github.io/assets-for-api-docs/assets/material/content_based_color_scheme_4.png'),
  seagrapes('Sea Grapes',
      'https://flutter.github.io/assets-for-api-docs/assets/material/content_based_color_scheme_5.png'),
  petals('Petals',
      'https://flutter.github.io/assets-for-api-docs/assets/material/content_based_color_scheme_6.png');

  const ColorImageProvider(this.label, this.url);
  final String label;
  final String url;
}

enum ScreenSelected {
  component(0),
  color(1),
  typography(2),
  elevation(3);

  const ScreenSelected(this.value);
  final int value;
}

enum ColorItem {
  red('red', Colors.red),
  orange('orange', Colors.orange),
  yellow('yellow', Colors.yellow),
  green('green', Colors.green),
  blue('blue', Colors.blue),
  indigo('indigo', Colors.indigo),
  violet('violet', Color(0xFF8F00FF)),
  purple('purple', Colors.purple),
  pink('pink', Colors.pink),
  silver('silver', Color(0xFF808080)),
  gold('gold', Color(0xFFFFD700)),
  beige('beige', Color(0xFFF5F5DC)),
  brown('brown', Colors.brown),
  grey('grey', Colors.grey),
  black('black', Colors.black),
  white('white', Colors.white);

  const ColorItem(this.label, this.color);
  final String label;
  final Color color;
}

enum Value { first, second }

enum Options { option1, option2, option3 }

enum Calendar { day, week, month, year }

enum ColorLabel {
  blue('Blue', Colors.blue),
  pink('Pink', Colors.pink),
  green('Green', Colors.green),
  yellow('Yellow', Colors.yellow),
  grey('Grey', Colors.grey);

  const ColorLabel(this.label, this.color);
  final String label;
  final Color color;
}

enum IconLabel {
  smile('Smile', Icons.sentiment_satisfied_outlined),
  cloud(
    'Cloud',
    Icons.cloud_outlined,
  ),
  brush('Brush', Icons.brush_outlined),
  heart('Heart', Icons.favorite);

  const IconLabel(this.label, this.icon);
  final String label;
  final IconData icon;
}

List<String> countryCodes = [
  "+93", "+355", "+213", "+1-684", "+376", "+244", "+1-264", "+672", "+1-268", "+54", "+374", "+297", "+61", "+43", "+994", "+1-242", "+973", "+880", "+1-246",
  "+375", "+32", "+501", "+229", "+1-441", "+975", "+591", "+387", "+267", "+55", "+246", "+1-284", "+673", "+359", "+226", "+257", "+855", "+237", "+1",
  "+238", "+1-345", "+236", "+235", "+56", "+86", "+61", "+61", "+57", "+269", "+242", "+243", "+682", "+506", "+385", "+53", "+357", "+420", "+45",
  "+253", "+1-767", "+1-809", "+1-829", "+1-849", "+670", "+593", "+20", "+503", "+240", "+291", "+372", "+251", "+500", "+298", "+679", "+358",
  "+33", "+689", "+241", "+220", "+995", "+49", "+233", "+350", "+30", "+299", "+1-473", "+590", "+1-671", "+502", "+224", "+245", "+592", "+509",
  "+504", "+852", "+36", "+354", "+91", "+62", "+98", "+964", "+353", "+972", "+39", "+1-876", "+81", "+962", "+7", "+254", "+686", "+850", "+82",
  "+965", "+996", "+856", "+371", "+961", "+266", "+231", "+218", "+423", "+370", "+352", "+853", "+389", "+261", "+265", "+60", "+960", "+223",
  "+356", "+692", "+596", "+222", "+230", "+269", "+52", "+691", "+373", "+377", "+976", "+382", "+1-664", "+212", "+258", "+95", "+264", "+674",
  "+977", "+31", "+599", "+687", "+64", "+505", "+227", "+234", "+683", "+672", "+1-670", "+47", "+968", "+92", "+680", "+970", "+507", "+675",
  "+595", "+51", "+63", "+64", "+48", "+351", "+1-787", "+1-939", "+974", "+262", "+40", "+7", "+250", "+290", "+1-869", "+1-758", "+1-784",
  "+685", "+378", "+239", "+966", "+221", "+381", "+248", "+232", "+65", "+1-721", "+421", "+386", "+677", "+252", "+27", "+500", "+34", "+94",
  "+249", "+597", "+47", "+268", "+46", "+41", "+963", "+886", "+992", "+255", "+66", "+228", "+690", "+676", "+1-868", "+216", "+90", "+993",
  "+1-649", "+688", "+1-340", "+256", "+380", "+971", "+44", "+1", "+598", "+998", "+678", "+379", "+58", "+84", "+681", "+967", "+260", "+263",
];

List<String> roles = ["Cat Modeller", "Location Manager", "Insurance Buyer", "Corporate Admin", "Under Writer", "Under Writer Analyst", "Broker", "Broker Analyst", "Risk Engineer", "Support"];

enum SignUpOptions { individual, corporate, }
