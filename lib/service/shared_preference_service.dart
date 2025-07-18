import 'package:RiskSphere/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceService {
  static Future<void> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  static const String CAMCL = 'CAMCL'; // Corporate-List
  static const String CAMUL = 'CAMUL'; // User-List
  static const String CAMCC = 'CAMCC'; // Create-Corporate
  static const String CAMEC =
      'CAMEC'; // Edit-Corporate-Profile [reusing create screen]
  static const String CAMVC = 'CAMVC'; // View-Corporate-Profile
  static const String CAMDC = 'CAMDC'; // Delete-Corporate-Profile
  static const String CAMED = 'CAMED'; // enable-disable
  static const String CAMLL = 'CAMLL'; // Show corporate verification tab
  static const String CAMCUM =
      'CAMCUM'; // Show Users drop down menu option in corporate management
  static const String CAMCUL =
      'CAMCUL'; // Show Profile drop down menu option in corporate management
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
  static const String FCMTK = 'FCMTK'; // FCM Token
  static const String SCHEDULE_INPROGRESS = 'SCHEDULE_INPROGRESS';
  static const String TRAIL_USER = 'TRAIL_USER';
  static const String TRAIL_LOCATION_COUNT = 'TRAIL_LOCATION_COUNT';
  static const String USER_LICENSE = 'USER_LICENSE';

  // Schedule In Progress
  static const String SOV_UPLOAD_TEMP_ID = 'SOV_UPLOAD_TEMP_ID';
  static const String SOV_UPLOAD_PROCESS_ID = 'SOV_UPLOAD_PROCESS_ID';
  static const String SOV_UPLOAD_STATE = 'SOV_UPLOAD_STATE';
  static const String SOV_ACCOUNT_ID = 'SOV_ACCOUNT_ID';
  static const String SOV_ACCOUNT_NAME = 'SOV_ACCOUNT_NAME';
  static const String SOV_SUB_ACCOUNT_ID = 'SOV_SUB_ACCOUNT_ID';
  static const String SOV_SUB_ACCOUNT_NAME = 'SOV_SUB_ACCOUNT_NAME';
  static const String IS_SUPER_ADMIN = 'is_cs';
  static const String IS_ADMIN = 'is_a';
  static const String IS_PG_ADMIN = 'is_sa';
  static const String Is_Indivudual = 'indivudual';
  static const String TRIAL_PERIOD_DAYS = 'trial_period_days';
  static const String TRIAL_CREATED_AT = 'trial_created_at';
  static const String IS_TRIAL_APPLICABLE = 'is_trial_period_applicable';
  static const String TRIAL_SUBDESTINATIONS = 'trial_subdestinations';
  static const String TRIAL_EDITLOCATIONS = 'trial_max_updates';
  static const String TRIAL_MAX_LOCATIONS = 'trial_max_locations';
  static const String TRIAL_LOCATIONS = 'trial_locations';
  static const String TOTAL_TRIAL_USERS = 'total_trial_users';
  static const String TOTAL_USERS_VERIFIED = 'total_users_verified';

  // Save and get FCM Token
  static Future<void> saveFcmToken(String fcmToken) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(FCMTK, fcmToken);
  }

  static Future<String?> getFcmToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(FCMTK);
  }

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
    prefs.setBool(IS_PG_ADMIN, false);
    prefs.setBool(IS_ADMIN, false);
    prefs.setBool(IS_SUPER_ADMIN, false);
    prefs.setBool(Is_Indivudual, false);

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
        case IS_PG_ADMIN:
        case IS_ADMIN:
        case IS_SUPER_ADMIN:
        case Is_Indivudual:
          if (value.runtimeType == int) {
            if (value == 1) {
              prefs.setBool(key, true);
              print('Claim $key set to true');
            } else {
              prefs.setBool(key, false);
              print('Claim $key set to false');
            }
            break;
          }
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
      NCMMT,
      EMPMT,
      IS_PG_ADMIN,
      IS_ADMIN,
      IS_SUPER_ADMIN,
      Is_Indivudual
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

  // static Future<void> setScheduleInProgress(bool value) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setString('schedule_in_progress', value.toString()); // Convert bool to String
  // }
  //
  // static Future<String?> getScheduleInProgress() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   return prefs.getString('schedule_in_progress'); // Now returns a String
  // }
  static Future<void> setScheduleInProgress(String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(SCHEDULE_INPROGRESS, value);
    print('Schedule in progress $value');
  }

  static Future<String?> getScheduleInProgress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? value = prefs.getString(SCHEDULE_INPROGRESS);
    print('Schedule in progress $value');
    return value;
  }
  static Future<void> setTrialUser(String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(TRAIL_USER, value);
    print('Schedule in progress $value');
  }

  static Future<String?> getTrialUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? value = prefs.getString(TRAIL_USER);
    print('Schedule in progress $value');
    return value;
  }
  static Future<void> setTrailLocation(String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(TRAIL_LOCATION_COUNT, value);
    print('Schedule in progress $value');
  }

  static Future<String?> getTrailLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? value = prefs.getString(TRAIL_LOCATION_COUNT);
    print('Schedule in progress $value');
    return value;
  }

  static Future<void> setUserLicense(String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(USER_LICENSE, value);
    print('Set user license to $value');
  }

  static Future<String?> getUserLicense() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? value = prefs.getString(USER_LICENSE);
    print('Retrieved user license with value $value');
    return value;
  }
  // Save Notification Subscription Status
  static Future<void> saveHasAnyPlan(bool hasanyplan) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasanyplan', hasanyplan);
    print('Notification Subscription saved: $hasanyplan');
  }

// Get Notification Subscription Status
  static Future<bool> getHasAnyPlan() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('hasanyplan') ?? false;
  }



  static Future<void> setGeocodingLicense(String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('geocoding_license', value);
    print('Set geocoding license to $value');
  }

  static Future<String?> getGeocodingLicense() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? value = prefs.getString('geocoding_license');
    print('Retrieved geocoding license with value $value');
    return value;
  }

  static Future<void> setHazardLicense(String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('hazard_license', value);
    print('Set hazard license to $value');
  }

  static Future<String?> getHazardLicense() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? value = prefs.getString('hazard_license');
    print('Retrieved hazard license with value $value');
    return value;
  }

  // static Future<void> setScheduleInProgress(bool value) async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   await prefs.setBool(SCHEDULE_INPROGRESS, value);
  //   print('Set Schedule In Progress to $value');
  // }
  //
  // static Future<bool?> getScheduleInProgress() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   bool? value = prefs.getBool(SCHEDULE_INPROGRESS);
  //   print('Retrieved Schedule In Progress with value $value');
  //   return value;
  // }

  static Future<void> setSovUploadTempId(String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(SOV_UPLOAD_TEMP_ID, value);
    print('Set SOV upload id to $value');
  }

  static Future<String?> getSovUploadTempId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? value = prefs.getString(SOV_UPLOAD_TEMP_ID);
    print('Retrieved Schedule In Progress with value $value');
    return value;
  }

  static Future<void> setSovUploadProcessId(String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(SOV_UPLOAD_PROCESS_ID, value);
    print('Set SOV upload id to $value');
  }

  static Future<String?> getSovUploadProcessId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? value = prefs.getString(SOV_UPLOAD_PROCESS_ID);
    print('Retrieved Schedule In Progress with value $value');
    return value;
  }

  static Future<void> setSovUploadState(String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(SOV_UPLOAD_STATE, value);
    print('Set SOV upload state to $value');
  }

  static Future<String?> getSovUploadState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? value = prefs.getString(SOV_UPLOAD_STATE);
    print('Retrieved SOV upload state with value $value');
    return value;
  }

  static Future<void> setSovAccountId(String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(SOV_ACCOUNT_ID, value);
    print('Set SOV account id to $value');
  }

  static Future<String?> getSovAccountId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? value = prefs.getString(SOV_ACCOUNT_ID);
    print('Retrieved SOV account id with value $value');
    return value;
  }

  static Future<void> setSovSubAccountId(String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(SOV_SUB_ACCOUNT_ID, value);
    print('Set SOV sub account id to $value');
  }

  static Future<String?> getSovSubAccountId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? value = prefs.getString(SOV_SUB_ACCOUNT_ID);
    print('Retrieved SOV sub account id with value $value');
    return value;
  }

  static Future<void> setSovAccountName(String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(SOV_ACCOUNT_NAME, value);
    print('Set SOV account name to $value');
  }

  static Future<String?> getSovAccountName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? value = prefs.getString(SOV_ACCOUNT_NAME);
    print('Retrieved SOV account name with value $value');
    return value;
  }

  static Future<void> setSovSubAccountName(String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(SOV_SUB_ACCOUNT_NAME, value);
    print('Set SOV sub account name to $value');
  }

  static Future<String?> getSovSubAccountName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? value = prefs.getString(SOV_SUB_ACCOUNT_NAME);
    print('Retrieved SOV sub account name with value $value');
    return value;
  }

  // Clear all Sov related shared preferences
  static Future<void> clearSovPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(SOV_UPLOAD_TEMP_ID);
    await prefs.remove(SOV_UPLOAD_PROCESS_ID);
    await prefs.remove(SOV_UPLOAD_STATE);
    await prefs.remove(SOV_ACCOUNT_ID);
    await prefs.remove(SOV_ACCOUNT_NAME);
    await prefs.remove(SOV_SUB_ACCOUNT_ID);
    await prefs.remove(SOV_SUB_ACCOUNT_NAME);
    print('Cleared all SOV related shared preferences');
  }

  // Save Notification Subscription Status
  static Future<void> saveNotificationSubscription(bool isSubscribed) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationSubscribed', isSubscribed);
    print('Notification Subscription saved: $isSubscribed');
  }

// Get Notification Subscription Status
  static Future<bool> getNotificationSubscription() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notificationSubscribed') ?? false;
  }

  // Save Trial Info with Firebase Timestamp
  static Future<void> saveTrialInfo(
      int trialDays,
      bool isApplicable,
      int trialSubDestinations,
      int trialEditLocations,
      int trialMaxLocations,
      int trialLocations,
      int totalTrialUsers,
      int totalUsersVerified) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(TRIAL_PERIOD_DAYS, trialDays);
    await prefs.setBool(IS_TRIAL_APPLICABLE, isApplicable);
    await prefs.setInt(TRIAL_SUBDESTINATIONS, trialSubDestinations);
    await prefs.setInt(TRIAL_EDITLOCATIONS, trialEditLocations);
    await prefs.setInt(TRIAL_MAX_LOCATIONS, trialMaxLocations);
    await prefs.setInt(TRIAL_LOCATIONS, trialLocations);
    await prefs.setInt(TOTAL_TRIAL_USERS, totalTrialUsers);
    await prefs.setInt(TOTAL_USERS_VERIFIED, totalUsersVerified);
  }

// Get Trial Period Days
  static Future<int?> getTrialPeriodDays() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(TRIAL_PERIOD_DAYS);
  }

//

// Check If Trial Is Applicable
  static Future<bool?> isTrialApplicable() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(IS_TRIAL_APPLICABLE);
  }

  static Future<int?> getTrialSubDestinations() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(TRIAL_SUBDESTINATIONS);
  }

  static Future<int?> getTrialEditLocations() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(TRIAL_EDITLOCATIONS);
  }

  static Future<int?> getTrialMaxLocations() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(TRIAL_MAX_LOCATIONS);
  }

  static Future<int?> getTrialLocations() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(TRIAL_LOCATIONS);
  }

  static Future<int?> getTotalTrialUsers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(TOTAL_TRIAL_USERS);
  }

  static Future<int?> getTotalUsersVerified() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(TOTAL_USERS_VERIFIED);
  }

  Future<void> saveUserTrialData(Map<String, dynamic> user) async {
    if (user.containsKey('trial_period_days')) {
      int trialDays = user['trial_period_days'];
      bool isTrialApplicable = user['is_trial_period_applicable'];
      int trialSubDestinations = user['trial_subdestinations'];
      int trialEditLocations = user['trial_max_updates'];
      int trialMaxLocations = user['trial_max_locations'];
      int trialLocations = user['trial_locations'];
      int totalTrialUsers = user['total_trial_users'];
      int totalUsersVerified = user['total_users_verified'];

      await SharedPreferenceService.saveTrialInfo(
          trialDays,
          isTrialApplicable,
          trialSubDestinations,
          trialEditLocations,
          trialMaxLocations,
          trialLocations,
          totalTrialUsers,
          totalUsersVerified);
    }
  }
}
