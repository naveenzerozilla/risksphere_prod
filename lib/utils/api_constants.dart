import '../constants/configuration.dart';

class AppConstant {
  static const String REGION = "us-central1";

  static String get baseURL => 'https://${REGION}-${Configuration.projectId}.cloudfunctions.net';

  // R1 API URL
  static String get CORPORATE_MANAGEMENT_URL => '$baseURL/companies';
  static String get CORPORATE_MANAGEMENT_URL_NEW => '$baseURL/user_management_new/companies_list';
  static String get CREATE_CORPORATE_URL => '$baseURL/new_user_create';
  static String get UPDATE_CORPORATE_URL => '$baseURL/companies';
  static String get UPDATE_CORPORATE_URL_NEW => '$baseURL/companies';
  static String get UPLOAD_FILE => '$baseURL/upload_file';
  static String get GET_CORPORATE_ROLES => '$baseURL/support?corporate_type=true';
  static String get GET_FEATURE_LIST => '$baseURL/feature_settings';
  static String get ADD_FEATURE => '$baseURL/feature_settings';
  static String get GET_ROLES => '$baseURL/support?role=true';
  static String get GET_EMAILS => '$baseURL/support?emails=true';
  static String get ADD_EMAILS => '$baseURL/support';
  static String get CHANGE_STATUS => '$baseURL/support';
  static String get GET_EMPLOYEES => '$baseURL/user_management?employees_list=true';
  static String get GET_EMPLOYEES_NEW => '$baseURL/user_management_new/employee_list';
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
  static String get GET_CONNECTIONS => '$baseURL/user_management?connections=true';
  static String get GET_REQUESTS => '$baseURL/user_management?requests=true';
  static String get ACCEPT_REJECT_REQUEST => '$baseURL/user_management';
  static String get GET_NETWORKING_USER_SUGGESTIONS => '$baseURL/user_management_new/company_user_list/current';
  static String get SEND_NETWORKING_REQUEST => '$baseURL/user_management';
  static String get GET_USER_TEAMS => '$baseURL/user_management?my_team=true';
  static String get DELETE_TEAM_MEMBER => '$baseURL/user_management';
  static String get ADD_TEAM_MEMBERS => '$baseURL/user_management';
  static String get GET_CORPORATE_USER => '$baseURL/companies';
  static String get GET_CORPORATE_USER_NEW => '$baseURL/user_management_new/company_user_list';

  static String get UPDATE_USER_STATUS => '$baseURL/user_management';
  static String get NON_CORPORATE_USER_STATUS => '$baseURL/user_management';
  static String get NON_CORPORATE_USER_STATUS_NEW => '$baseURL/user_management_new/individual_user_list';
  static String get CREATE_CORPORATE_EMPLOYEES => '$baseURL/new_company_user_create';
  static String get DELETE_CORPORATE_EMPLOYEES => '$baseURL/user_management';
  static String get TRANSFER_USER_AUTOCOMPLETE => '$baseURL/user_management_new/company_user_list/current';
  static String get MAIN_HAZARDS_TILE_PROVIDERS => '$baseURL/vendor_hazards/hazards_layer';

  // R2 APIS
  static String get GET_ACCOUNT_LIST => '$baseURL/locations/accounts';
  static String get RENAME_ACCOUNT => '$baseURL/accounts';
  static String get DUPLICATE_ACCOUNT => '$baseURL/accounts';//'$baseURL/accounts';
  static String get CHANGE_COLUMN_VISIBILITY => '$baseURL/accounts';
  static String get AUTO_COMPLETE_ACCOUNT_LIST => '$baseURL/accounts';
  static String get ADD_ACCOUNT => '$baseURL/locations/create_account';
  static String get REQUEST_ACCESS => '$baseURL/accounts';
  static String get UPLOAD_SOV_ACCOUNT => '$baseURL/sov';
  static String get FETCH_LOCATIONS_DUPLICATION_CHECK=> '$baseURL/duplicate_check';
  static String get FETCH_LOCATION_DUPLICATIONS=> '$baseURL/duplicate_check/duplicate';
  static String get FETCH_LOCATION_CONFLICTS=> '$baseURL/duplicate_check/similar';
  static String get RESOLVE_LOCATION_CONFLICTS=> '$baseURL/duplicate_check/conflicts';
  static String get CANCEL_SOV_UPLOAD_PROCESS => '$baseURL/user_management_new/my_last_process/cancel';
  static String get TRANSFER_SOV => '$baseURL/locations/transfer_sov';
  static String get TRANSFER_SUBACCOUNT=> '$baseURL/locations/transfer_sub_account';
  static String get TRANSFER_ACCOUNT=> '$baseURL/locations/transfer_account';
  static String get FETCH_SOV_UPLOAD_DATA => '$baseURL/user_management_new/my_last_process';

  // Sub Accounts
  static String get GET_SUB_ACCOUNT_LIST => '$baseURL/locations';
  static String get RENAME_SUB_ACCOUNT => '$baseURL/accounts';
  static String get DUPLICATE_SUB_ACCOUNT => '$baseURL/accounts';
  static String get CHANGE_COLUMN_VISIBILITY_SUB_ACCOUNT => '$baseURL/accounts';
  static String get AUTO_COMPLETE_SUB_ACCOUNT_LIST => '$baseURL/accounts';
  static String get ADD_SUB_ACCOUNT => '$baseURL/locations/create_sub_account';
  static String get REQUEST_ACCESS_SUB_ACCOUNT => '$baseURL/accounts';
  static String get UPLOAD_SOV_SUB_ACCOUNT => '$baseURL/sov';

  // Sov
  static String get GET_SOV_LIST => '$baseURL/accounts';
  static String get GET_SOV_LIST_BY_SOV => '$baseURL/locations/sov';
  static String get GET_AUTOCOMPLETE_SOV_LIST => '$baseURL/locations/sov';
  static String get RENAME_SOV => '$baseURL/accounts';
  static String get DUPLICATE_SOV => '$baseURL/accounts';
  static String get CHANGE_COLUMN_VISIBILITY_SOV => '$baseURL/accounts';
  static String get AUTO_COMPLETE_SOV_LIST => '$baseURL/accounts';
  static String get ADD_SOV => '$baseURL/accounts';
  static String get REQUEST_ACCESS_SOV => '$baseURL/accounts';

  // Location
  static String get GET_LOCATION_LIST => '$baseURL/accounts';
  static String get ADD_LOCATION => '$baseURL/accounts';
  static String get MY_LOCATION => '$baseURL/locations';
  static String get ADD_TO_SOV=> '$baseURL/locations/add_to_sov';

  // Location Profile
  static String get GET_LOCATION_PROFILE => '$baseURL/accounts';
  static String get GET_LOCATION_PROFILE_INDIVIDUAL_NEW => '$baseURL/locations/getlocation';
  static String get ADD_SUBDESTINATION => '$baseURL/locations/addsubdestination';

  // Location Profile New
  static String get GET_LOCATION_PROFILE_NEW => '$baseURL/locations';
  static String get EDIT_CAMPUS => '$baseURL/locations/editcampus';
  static String get CHANGE_OCCUPANCY => '$baseURL/locations/rented';

  // Upload Images New
  static String get UPLOAD_IMAGES_NEW => '$baseURL/locations/location_profile_images';

  /// R3 APIS
  static String get GET_JOB_MONITORING => '$baseURL/job_monitoring';
  static String get GET_JOB_MONITORING_SUMMARY => '$baseURL/vendor_management/process_summary';
  static String get UPLOAD_SOV_LOCATIONS => '$baseURL/sov/upload';
  static String get EXPORT => '$baseURL/locations/export';
  static String get GLOBAL_SEARCH => '$baseURL/locations/global_search';

  static String get GET_CURRENT_COMPANY_ID => '$baseURL/locations/current_company_id';

}