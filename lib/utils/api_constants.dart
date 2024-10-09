import '../constants/configuration.dart';

class AppConstant {
  static const String REGION = "us-central1";

  static String get baseURL => 'https://${REGION}-${Configuration.projectId}.cloudfunctions.net';

  // R1 API URL
  static String get CORPORATE_MANAGEMENT_URL => '$baseURL/companies';
  static String get CREATE_CORPORATE_URL => '$baseURL/new_user_create';
  static String get UPDATE_CORPORATE_URL => '$baseURL/companies';
  static String get UPLOAD_FILE => '$baseURL/upload_file';
  static String get GET_CORPORATE_ROLES => '$baseURL/support?corporate_type=true';
  static String get GET_FEATURE_LIST => '$baseURL/feature_settings';
  static String get ADD_FEATURE => '$baseURL/feature_settings';
  static String get GET_ROLES => '$baseURL/support?role=true';
  static String get GET_EMAILS => '$baseURL/support?emails=true';
  static String get ADD_EMAILS => '$baseURL/support';
  static String get CHANGE_STATUS => '$baseURL/support';
  static String get GET_EMPLOYEES => '$baseURL/user_management?employees_list=true';
  static String get GET_ROLES_FOR_EMPLOYEES => '$baseURL/companies?role=internal';
  static String get GET_ROLES_FOR_CORPORATE_EMPLOYEES => '$baseURL/companies?role=external';
  static String get CREATE_EMPLOYEES => '$baseURL/new_user_create';
  static String get UPDATE_EMPLOYEES => '$baseURL/user_management';
  static String get VIEW_EMPLOYEES => '$baseURL/user_management';
  static String get GET_CORPORATE_VERIFICATION_REQUESTS => '$baseURL/companies?leads=company';
  static String get GET_USER_VERIFICATION_REQUESTS => '$baseURL/companies?leads=users';
  static String get CHANGE_CORPORATE_STATUS => '$baseURL/companies';
  static String get CHANGE_USER_STATUS => '$baseURL/companies';
  static String get CHANGE_USER_ROLE => '$baseURL/companies';
  static String get GET_USER_DETAILS => '$baseURL/user_management';
  static String get UPDATE_USER_DETAILS => '$baseURL/user_management';
  static String get GET_AVATARS => '$baseURL/get_avatar';
  static String get GET_DASHBOARD => '$baseURL/dashboard_data';
  static String get GET_CONNECTIONS => '$baseURL/user-management?connections=true';
  static String get GET_REQUESTS => '$baseURL/user-management?requests=true';
  static String get ACCEPT_REJECT_REQUEST => '$baseURL/companies';
  static String get GET_NETWORKING_USER_SUGGESTIONS => '$baseURL/user_management';
  static String get SEND_NETWORKING_REQUEST => '$baseURL/user_management';
  static String get GET_USER_TEAMS => '$baseURL/user_management?my_team=true';
  static String get DELETE_TEAM_MEMBER => '$baseURL/user_management';
  static String get ADD_TEAM_MEMBERS => '$baseURL/user_management';
  static String get GET_CORPORATE_USER => '$baseURL/companies';

  static String get UPDATE_USER_STATUS => '$baseURL/user_management';
  static String get NON_CORPORATE_USER_STATUS => '$baseURL/user_management';
  static String get CREATE_CORPORATE_EMPLOYEES => '$baseURL/new_company_user_create';
  static String get DELETE_CORPORATE_EMPLOYEES => '$baseURL/user_management';

  // R2 APIS
  static String get GET_ACCOUNT_LIST => '$baseURL/accounts/mobile';
  static String get RENAME_ACCOUNT => '$baseURL/accounts';
  static String get DUPLICATE_ACCOUNT => 'https://eb2e-49-207-208-98.ngrok-free.app/project-green-f4d78/us-central1/accounts';//'$baseURL/accounts';
  static String get CHANGE_COLUMN_VISIBILITY => '$baseURL/accounts';
  static String get AUTO_COMPLETE_ACCOUNT_LIST => '$baseURL/accounts';
  static String get ADD_ACCOUNT => '$baseURL/accounts';
  static String get REQUEST_ACCESS => '$baseURL/accounts';
  static String get UPLOAD_SOV_ACCOUNT => '$baseURL/sov';

  // Sub Accounts
  static String get GET_SUB_ACCOUNT_LIST => '$baseURL/accounts';
  static String get RENAME_SUB_ACCOUNT => '$baseURL/accounts';
  static String get DUPLICATE_SUB_ACCOUNT => '$baseURL/accounts';
  static String get CHANGE_COLUMN_VISIBILITY_SUB_ACCOUNT => '$baseURL/accounts';
  static String get AUTO_COMPLETE_SUB_ACCOUNT_LIST => '$baseURL/accounts';
  static String get ADD_SUB_ACCOUNT => '$baseURL/accounts';
  static String get REQUEST_ACCESS_SUB_ACCOUNT => '$baseURL/accounts';
  static String get UPLOAD_SOV_SUB_ACCOUNT => '$baseURL/sov';

  // Sov
  static String get GET_SOV_LIST => '$baseURL/accounts';
  static String get RENAME_SOV => '$baseURL/accounts';
  static String get DUPLICATE_SOV => '$baseURL/accounts';
  static String get CHANGE_COLUMN_VISIBILITY_SOV => '$baseURL/accounts';
  static String get AUTO_COMPLETE_SOV_LIST => '$baseURL/accounts';
  static String get ADD_SOV => '$baseURL/accounts';
  static String get REQUEST_ACCESS_SOV => '$baseURL/accounts';

  // Location
  static String get GET_LOCATION_LIST => '$baseURL/accounts';
  static String get ADD_LOCATION => '$baseURL/accounts';

  // Location Profile
  static String get GET_LOCATION_PROFILE => '$baseURL/accounts';

  /// R3 APIS
  static String get GET_JOB_MONITORING => '$baseURL/job_monitoring';

}