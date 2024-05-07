import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceService {
  static const String CL = 'CL'; // Corporate-List
  static const String UL = 'UL'; // User-List
  static const String CC = 'CC'; // Create-Corporate
  static const String EC =
      'EC'; // Edit-Corporate-Profile [reusing create screen]
  static const String VC = 'VC'; // View-Corporate-Profile
  static const String DC = 'DC'; // Delete-Corporate-Profile
  static const String ED = 'ED'; // enable-disable
  static const String LL = 'LL'; // Show corporate verification tab
  static const String CUM =
      'CUM'; // Show Users drop down menu option in corporate management
  static const String CUL =
      'CUL'; // Show Profile drop down menu option in corporate management
  static const String VU = 'VU'; // Show User verification tab
  static const String DU = 'DU'; // delete user
  static const String AM = 'AM'; // assign account manager
  static const String DA = 'DA'; // delegate account manager
  static const String RD = 'RD'; // revoke delegation
  static const String RE = 'RE'; // Add reportees
  static const String AU = 'AU'; // Assigned User
  static const String BU = 'BU'; // Bulk Upload
  static const String EU = 'EU'; // Edit User profile
  static const String VP = 'VP'; // View and Edit my user profile
  static const String COL = 'COL'; // Connections
  static const String CU = 'CU'; // create user
  static const String TC = 'TC'; // Total Corporates
  static const String TU = 'TU'; // All Users
  static const String MU = 'MU'; // My corporate users
  static const String CR = 'CR'; // Connections Request
  static const String VR = 'VR'; // Verification request
  static const String CO = 'CO'; // Company Onboarding Stats
  static const String UO = 'UO'; // User Onboarding Stats
  static const String CA = 'CA'; // Categories
  static const String RO = 'RO'; // Role
  static const String FE = 'FE'; // Features
  static const String EM = 'EM'; // Email
  static const String ROL = 'ROL'; // Corporate Role

  /// Method to set claims in SharedPreferences
  static Future<void> setClaims(Map<String, dynamic> claims) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    claims.forEach((key, value) {
      // Check if the claim key matches any of the static strings
      switch (key) {
        case CL:
        case UL:
        case CC:
        case EC:
        case VC:
        case DC:
        case ED:
        case LL:
        case CUM:
        case CUL:
        case VU:
        case DU:
        case AM:
        case DA:
        case RD:
        case RE:
        case AU:
        case BU:
        case EU:
        case VP:
        case CR:
        case VR:
        case CO:
        case UO:
        case CA:
        case RO:
        case FE:
        case EM:
        case ROL:
          // If the claim key matches, set the corresponding static string as the key in SharedPreferences
          prefs.setBool(key, value);
          print('Claim $key set to $value');
          break;
        default:
          // If the claim key doesn't match any static string, ignore it
          print('Ignoring unknown claim: $key');
          break;
      }
    });
  }

  /// Method to get claims from SharedPreferences
  static Future<Map<String, dynamic>> getAllClaims() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> claims = {};
    // Loop through each static string and retrieve its corresponding value from SharedPreferences
    //CL, UL, CC, EC, VC, DC, ED, LL, CUM, CUL, VU, DU, AM, DA, RD, RE, AU, BU, EU, VP, CR, VR, CO, UO, CA, RO, FE, EM, ROL
    List<String> staticStrings = [
      CL,
      UL,
      CC,
      EC,
      VC,
      DC,
      ED,
      LL,
      CUM,
      CUL,
      VU,
      DU,
      AM,
      DA,
      RD,
      RE,
      AU,
      BU,
      EU,
      VP,
      CR,
      VR,
      CO,
      UO,
      CA,
      RO,
      FE,
      EM,
      ROL
    ];
    for (String key in staticStrings) {
      bool? value = prefs.getBool(key);
      if (value != null) {
        claims[key] = value;
        print('Retrieved claim $key with value $value');
      }
    }
    return claims;
  }

  // Method to get a single claim for a subfeature from SharedPreferences
  static Future<bool?> getClaimForSubfeature(String subfeature) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      // Retrieve the claim for the given subfeature
      bool? value = prefs.getBool(subfeature);
      if (value != null) {
        print('Retrieved claim for $subfeature with value $value');
        return value;
      } else {
        print('Claim for $subfeature not found');
        return null;
      }
    } catch (e) {
      print('Error retrieving claim for $subfeature: $e');
      return null;
    }
  }

}
