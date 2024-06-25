import 'package:green/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceService {
  static const String CAMCL = 'CAMCL'; // Corporate-List
  static const String CAMUL = 'CAMUL'; // User-List
  static const String CAMCC = 'CAMCC'; // Create-Corporate
  static const String CAMEC = 'CAMEC'; // Edit-Corporate-Profile [reusing create screen]
  static const String CAMVC = 'CAMVC'; // View-Corporate-Profile
  static const String CAMDC = 'CAMDC'; // Delete-Corporate-Profile
  static const String CAMED = 'CAMED'; // enable-disable
  static const String CAMLL = 'CAMLL'; // Show corporate verification tab
  static const String CAMCUM = 'CAMCUM'; // Show Users drop down menu option in corporate management
  static const String CAMCUL = 'CAMCUL'; // Show Profile drop down menu option in corporate management
  static const String CAMVU = 'CAMVU'; // Show User verification tab
  static const String CUMED = 'CUMED'; // edit user
  static const String CUMDU = 'CUMDU'; // delete user
  static const String CUMAM = 'CUMAM'; // assign account manager
  static const String CUMDA = 'CUMDA'; // delegate account manager
  static const String CUMRD = 'CUMRD'; // revoke delegation
  static const String CUMRE = 'CUMRE'; // Add reportees
  static const String CUMAU = 'CUMAU'; // Assigned User
  static const String CUMBU = 'CUMBU'; // Bulk Upload
  static const String CUMEU = 'CUMEU'; // Edit User profile
  static const String CUMVP = 'CUMVP'; // View and Edit my user profile
  static const String CUMCL = 'CUMCL'; // Connections
  static const String CUMCU = 'CUMCU'; // create user
  static const String NCMED = 'NCMED'; // Total Corporates
  static const String NCMDU = 'NCMDU'; // All Users
  static const String NCMEU = 'NCMEU'; // My corporate users
  static const String NCMVP = 'NCMVP'; // Connections Request
  static const String NCMCL = 'NCMCL'; // Verification request
  static const String NCMUL = 'NCMUL'; // Non-Corporate User List
  static const String EMPED = 'EMPED'; // Company Onboarding Stats
  static const String EMPDU = 'EMPDU'; // User Onboarding Stats
  static const String EMPEU = 'EMPEU'; // Categories
  static const String EMPVP = 'EMPVP'; // Role
  static const String EMPCL = 'EMPCL'; // Features
  static const String EMPUL = 'EMPUL'; // Employee List
  static const String DASTC = 'DASTC'; // Email
  static const String DASTU = 'DASTU'; // Corporate Role
  static const String DASMU = 'DASMU'; // Placeholder for future use
  static const String DASCR = 'DASCR'; // Placeholder for future use
  static const String DASVR = 'DASVR'; // Placeholder for future use
  static const String DASCO = 'DASCO'; // Placeholder for future use
  static const String DASUO = 'DASUO'; // Placeholder for future use
  static const String SETCA = 'SETCA'; // Placeholder for future use
  static const String SETRO = 'SETRO'; // Placeholder for future use
  static const String SETFE = 'SETFE'; // Placeholder for future use
  static const String SETEM = 'SETEM'; // Placeholder for future use
  static const String SETROL = 'SETROL'; // Placeholder for future use
  static const String NCMMT = 'NCMMT'; // My Teams for NCM
  static const String EMPMT = 'EMPMT'; // My Teams for EMP

  static Future<void> setClaims(Map<String, dynamic> claims) async {
    await AuthNotifier().getAllClaims();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Set all keys to false
    prefs.setBool(CAMCL, false);
    prefs.setBool(CAMUL, false);
    prefs.setBool(CAMCC, false);
    prefs.setBool(CAMEC, false);
    prefs.setBool(CAMVC, false);
    prefs.setBool(CAMDC, false);
    prefs.setBool(CAMED, false);
    prefs.setBool(CAMLL, false);
    prefs.setBool(CAMCUM, false);
    prefs.setBool(CAMCUL, false);
    prefs.setBool(CAMVU, false);
    prefs.setBool(CUMED, false);
    prefs.setBool(CUMDU, false);
    prefs.setBool(CUMAM, false);
    prefs.setBool(CUMDA, false);
    prefs.setBool(CUMRD, false);
    prefs.setBool(CUMRE, false);
    prefs.setBool(CUMAU, false);
    prefs.setBool(CUMBU, false);
    prefs.setBool(CUMEU, false);
    prefs.setBool(CUMVP, false);
    prefs.setBool(CUMCL, false);
    prefs.setBool(CUMCU, false);
    prefs.setBool(NCMED, false);
    prefs.setBool(NCMDU, false);
    prefs.setBool(NCMEU, false);
    prefs.setBool(NCMVP, false);
    prefs.setBool(NCMCL, false);
    prefs.setBool(NCMUL, false);
    prefs.setBool(EMPED, false);
    prefs.setBool(EMPDU, false);
    prefs.setBool(EMPEU, false);
    prefs.setBool(EMPVP, false);
    prefs.setBool(EMPCL, false);
    prefs.setBool(EMPUL, false);
    prefs.setBool(DASTC, false);
    prefs.setBool(DASTU, false);
    prefs.setBool(DASMU, false);
    prefs.setBool(DASCR, false);
    prefs.setBool(DASVR, false);
    prefs.setBool(DASCO, false);
    prefs.setBool(DASUO, false);
    prefs.setBool(SETCA, false);
    prefs.setBool(SETRO, false);
    prefs.setBool(SETFE, false);
    prefs.setBool(SETEM, false);
    prefs.setBool(SETROL, false);
    prefs.setBool(NCMMT, false);
    prefs.setBool(EMPMT, false);

    claims.forEach((key, value) {
      switch (key) {
        case CAMCL:
        case CAMUL:
        case CAMCC:
        case CAMEC:
        case CAMVC:
        case CAMDC:
        case CAMED:
        case CAMLL:
        case CAMCUM:
        case CAMCUL:
        case CAMVU:
        case CUMED:
        case CUMDU:
        case CUMAM:
        case CUMDA:
        case CUMRD:
        case CUMRE:
        case CUMAU:
        case CUMBU:
        case CUMEU:
        case CUMVP:
        case CUMCL:
        case CUMCU:
        case NCMED:
        case NCMDU:
        case NCMEU:
        case NCMVP:
        case NCMCL:
        case NCMUL:
        case EMPED:
        case EMPDU:
        case EMPEU:
        case EMPVP:
        case EMPCL:
        case EMPUL:
        case DASTC:
        case DASTU:
        case DASMU:
        case DASCR:
        case DASVR:
        case DASCO:
        case DASUO:
        case SETCA:
        case SETRO:
        case SETFE:
        case SETEM:
        case SETROL:
        case NCMMT:
        case EMPMT:

          prefs.setBool(key, value);
          print('Claim $key set to $value');
          break;
        default:
          print('Ignoring unknown claim: $key');
          break;
      }
    });
  }

  static Future<Map<String, dynamic>> getAllClaims() async {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> claims = {};
    List<String> staticStrings = [
      CAMCL,
      CAMUL,
      CAMCC,
      CAMEC,
      CAMVC,
      CAMDC,
      CAMED,
      CAMLL,
      CAMCUM,
      CAMCUL,
      CAMVU,
      CUMED,
      CUMDU,
      CUMAM,
      CUMDA,
      CUMRD,
      CUMRE,
      CUMAU,
      CUMBU,
      CUMEU,
      CUMVP,
      CUMCL,
      CUMCU,
      NCMED,
      NCMDU,
      NCMEU,
      NCMVP,
      NCMCL,
      NCMUL,
      EMPED,
      EMPDU,
      EMPEU,
      EMPVP,
      EMPCL,
      EMPUL,
      DASTC,
      DASTU,
      DASMU,
      DASCR,
      DASVR,
      DASCO,
      DASUO,
      SETCA,
      SETRO,
      SETFE,
      SETEM,
      SETROL,
    ];
    for (String key in staticStrings) {
      bool value = prefs.getBool(key) ?? false;
      if (value != null) {
        claims[key] = value;
        print('Retrieved claim $key with value $value');
      }
    }
    return claims;
  }

  static Future<bool?> getClaimForSubfeature(String subfeature) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
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
