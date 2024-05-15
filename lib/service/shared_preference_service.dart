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
  static const String EMPED = 'EMPED'; // Company Onboarding Stats
  static const String EMPDU = 'EMPDU'; // User Onboarding Stats
  static const String EMPEU = 'EMPEU'; // Categories
  static const String EMPVP = 'EMPVP'; // Role
  static const String EMPCL = 'EMPCL'; // Features
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

  static Future<void> setClaims(Map<String, dynamic> claims) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
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
        case EMPED:
        case EMPDU:
        case EMPEU:
        case EMPVP:
        case EMPCL:
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
      EMPED,
      EMPDU,
      EMPEU,
      EMPVP,
      EMPCL,
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
      bool? value = prefs.getBool(key);
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
