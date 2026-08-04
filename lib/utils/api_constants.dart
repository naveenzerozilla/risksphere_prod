import '../constants/configuration.dart';

class AppConstant {
  static const String Stripe_prod =
      'pk_live_51RWO6tRwbwNkvtwyBk3hTthEuR3oWdTGMNeZ9J3gshZOOPgu7GvygcD0ckMwvgxm12JCu7EZX9Jlh7x70BLT3We400Lfw89f3z';

  static const String REGION = "us-central1";

  static String get baseURL =>
      'https://${REGION}-${Configuration.projectId}.cloudfunctions.net';

  static String get CORPORATE_MANAGEMENT_URL => '$baseURL/companies_v2';

  static String get PAYMNET_GATEWAY_URL =>
      '$baseURL/pricing_v2/payment_session';

  static String get PAYMNET_DETAILS_URL => '$baseURL/pricing_v2/session_status';
  static String get RECOMMENDATION_ENGINE_V3 =>
      '$baseURL/';
  static String get RECOMMENDATION_ENGINE_V2 =>
      '$baseURL/recommendation_engine_v2/confirm_sync';
  static String VENDOR_DATA_COMPARISON =
      '$baseURL/recommendation_engine_v2/vendor_data_comparison';
  static String UNLINK_PARAMETER =
      '$baseURL/vendor_management_v2/unlink_parameter';

  static String get CORPORATE_MANAGEMENT_URL_NEW =>
      '$baseURL/user_management_new_v2/companies_list';

  static String get DELETE_LOCATION_IMAGE =>
      '$baseURL/data_categories_v2/locationparameter/';

  static String get DELETE_SOV_IMAGE =>
      '$baseURL/data_categories_v2/sovparameter/';

  static String get DELETE_CAMPUS_IMAGE =>
      '$baseURL/data_categories_v2/campusparameter/';

  static String get DELETE_DATA_IMAGE =>
      '$baseURL/data_categories_v2/dataparameter/';

  static String get SWITCH_INDIVIDUAL_URL =>
      '$baseURL/user_management_new_v2/last_updated_role';

  static String get CREATE_CORPORATE_URL => '$baseURL/new_user_create_v2';
  static String get Fetch_purchase_chatbot => '$baseURL/chat_with_agent_v2/purchase';
  static String get Fetch_purchase => '$baseURL/chat_with_agent_v2';

  static String get UPDATE_CORPORATE_URL => '$baseURL/companies_v2';

  static String get UPDATE_CORPORATE_URL_NEW => '$baseURL/companies_v2';

  static String get UPLOAD_FILE => '$baseURL/upload_file_v2';

  static String get GET_CORPORATE_ROLES =>
      '$baseURL/support_v2?corporate_type=true';

  static String get GET_FEATURE_LIST => '$baseURL/feature_settings_v2';

  static String get ADD_FEATURE => '$baseURL/feature_settings_v2';

  static String get GET_ROLES => '$baseURL/support_v2?role=true';

  static String get GET_EMAILS => '$baseURL/support_v2?emails=true';

  static String get ADD_EMAILS => '$baseURL/support_v2';

  static String get CHANGE_STATUS => '$baseURL/support_v2';
  static String get GET_GOOGLE_TOKEN => '$baseURL/locations_v2/get_token';
  static  String GET_LOCATION_DETAILS =
      '$baseURL/locations_v2/getlocation';

  static String get GET_EMPLOYEES =>
      '$baseURL/user_management_v2?employees_list=true';

  static String get GET_CURRENT_ROLE =>
      '$baseURL/user_management_v2?current_role=true&current_user=true';

  static String get GET_EMPLOYEES_NEW =>
      '$baseURL/user_management_new_v2/employee_list';

  static String get HANDLE_CHATBOT => '$baseURL/handle_chatbot_v2';

  static String get Fetch_user_managements =>
      '$baseURL/user_management_v2?current_role=true&current_user=true';

  static String get CREATE_EMPLOYEES => '$baseURL/new_user_create_v2';

  static String get UPDATE_EMPLOYEES => '$baseURL/user_management_v2';

  static String get Fetch_USER_LIST =>
      '$baseURL/user_management_new_v2/comprehensive_users';

  static String get VIEW_EMPLOYEES => '$baseURL/user_management_v2';

  static String get GET_USER_DETAILS => '$baseURL/user_management_v2';

  static String get UPDATE_USER_DETAILS => '$baseURL/user_management_v2';

  static String get GET_AVATARS => '$baseURL/get_avatar_v2';

  static String get GET_DASHBOARD => '$baseURL/dashboard_data_v2';

  static String get UPLOAD_SOV_LOCATIONS => '$baseURL/sov_v2/upload';

  static String get GET_CONNECTIONS =>
      '$baseURL/user_management_v2/current?connections=true';

  static String get DUPLICATE_ACCOUNT =>
      '$baseURL/accounts_v2'; //'$baseURL/accounts';

  static String get GET_REQUESTS => '$baseURL/user_management_v2?requests=true';

  static String get GET_NETWORK_LIST =>
      '$baseURL/user_management_new_v2/all_user_list?connections=true';

  static String get ACCEPT_REJECT_REQUEST => '$baseURL/user_management_v2';

  static String get SEND_NETWORKING_REQUEST => '$baseURL/user_management_v2';

  static String get GET_USER_TEAMS =>
      '$baseURL/user_management_v2?my_team=true';

  static String get DELETE_TEAM_MEMBER => '$baseURL/user_management_v2';

  static String get ADD_TEAM_MEMBERS => '$baseURL/user_management_v2';

  static String get GET_CORPORATE_USER => '$baseURL/companies_v2';

  static String get GET_CORPORATE_USER_NEW =>
      '$baseURL/user_management_new_v2/company_user_list';

  static String get UPDATE_USER_STATUS => '$baseURL/user_management_v2';

  static String get NON_CORPORATE_USER_STATUS => '$baseURL/user_management_v2';

  static String get NON_CORPORATE_USER_STATUS_NEW =>
      '$baseURL/user_management_new_v2/individual_user_list';

  static String get CREATE_CORPORATE_EMPLOYEES =>
      '$baseURL/new_company_user_create_v2';

  static String get DELETE_CORPORATE_EMPLOYEES => '$baseURL/delete_user/user/';

  static String get TRANSFER_USER_AUTOCOMPLETE =>
      '$baseURL/user_management_new_v2/company_user_list/current';

  static String get APP_SUPPORT_URL =>
      '$baseURL/sendEmail_to_client_v2?type=support';

  static String get MAIN_HAZARDS_TILE_PROVIDERS =>
      '$baseURL/vendor_hazards_v2/hazards_layer';

  /// ---------------- R2 APIs ----------------

  static String get GET_ACCOUNT_LIST => '$baseURL/locations_v2/accounts';

  static String get HANDLE_VENDOR_DATA =>
      '$baseURL/recommendation_engine_v2/handle_vendor_data';

  static String get GET_PRICING_LIST => '$baseURL/pricing_v2';

  static String get GET_Transaction_LIST =>
      '$baseURL/pricing_v2/transactions/details';

  static String get GET_INVOICE_LIST => '$baseURL/pricing_v2/payment/details';

  static String get GET_HAZARDHUB_LIST =>
      '$baseURL/vendor_management_v2/vendor_key/hazard_hub';

  static String get GET_RISKSPHERE_LIST =>
      '$baseURL/data_categories_v2?get_filtered=true';

  static String get PARAMETER_CONFIRM_API =>
      '$baseURL/vendor_management_v2/link_company_db_with_vendor_dp';

  static String get GET_RECOMMENDATION_LIST =>
      '$baseURL/recommendation_engine_v2/sov';

  static String get HANDLEVENDORSUBMIT =>
      '$baseURL/recommendation_engine_v2/handle_vendor_data';

  static String get SOV_PARAMETER_UPDATE =>
      '$baseURL/recommendation_engine_v2/sov_update';

  static String get ADD_ACCOUNT => '$baseURL/locations_v2/create_account';

  static String get UPLOAD_SOV_ACCOUNT => '$baseURL/sov_v2';

  static String get FETCH_LOCATIONS_DUPLICATION_CHECK =>
      '$baseURL/duplicate_check_v2';

  static String get FETCH_LOCATION_DUPLICATIONS =>
      '$baseURL/duplicate_check_v2/duplicate';

  static String get FETCH_LOCATION_CONFLICTS =>
      '$baseURL/duplicate_check_v2/similar';

  static String get RESOLVE_LOCATION_CONFLICTS =>
      '$baseURL/duplicate_check_v2/resolveconflict';

  static String get SKIP_LOCATION_CONFLICTS =>
      '$baseURL/duplicate_check_v2/skipconflict';

  static String get START_HAZARD_CONFLICTS =>
      '$baseURL/locations_v2/starthazard';

  static String get HANDLE_CONFLICT => '$baseURL/locations_v2';

  static String get TRANSFER_SOV => '$baseURL/locations_v2/transfer_sov';

  static String get TRANSFER_SUBACCOUNT =>
      '$baseURL/locations_v2/transfer_sub_account';

  static String get TRANSFER_ACCOUNT =>
      '$baseURL/locations_v2/transfer_account';

  /// ---------------- Locations ----------------

  static String get MY_LOCATION => '$baseURL/locations_v2';

  static String get IMAGE_LIST => '$baseURL/locations_v2/getmedia';

  static String get DOCUMENT_LIST => '$baseURL/data_categories_v2/documents';

  static String get ADD_COMMENT =>
      '$baseURL/locations_v2/update_location_comment';

  static String get ADD_TO_SOV => '$baseURL/locations_v2/add_to_sov';

  static String get LOCATION_SUMMARY =>
      '$baseURL/locations_v2/location_summary';

  static String get GET_SEARCH_LIST_BY_SOV => '$baseURL/user_management_new_v2';

  static String get EXPORT => '$baseURL/locations_v2/export';

  static String get EXPORT_SOV => '$baseURL/locations_v2/export_sov';

  static String get GLOBAL_SEARCH => '$baseURL/locations_v2/global_search';

  static String get GET_CURRENT_COMPANY_ID =>
      '$baseURL/locations_v2/current_company_id';

  /// ---------------- Monitoring ----------------

  static String get GET_JOB_MONITORING => '$baseURL/job_monitoring_v2';

  static String get GET_JOB_MONITORING_SUMMARY =>
      '$baseURL/vendor_management_v2/process_summary';

  /// ---------------- Vendor ----------------

  static String get VENDOR_MANAGEMENT_URL =>
      '$baseURL/vendor_management_v2/vendor_list/%20%20';

  static String get GET_VENDOR_HAZARD =>
      '$baseURL/vendor_hazards_v2/vendor_usage_dashboard';

  static String get GET_CORPORATE_DASHBOARD =>
      '$baseURL/vendor_hazards_v2/corporate_usage_dashboard';

  static String get GET_COMPANY_ID =>
      '$baseURL/user_management_new_v2/company_credits/';

  static String get RENAME_ACCOUNT => '$baseURL/accounts_v2';

  /// ---------------- Notifications ----------------

  static String get SUBSCRIBE_NOTIFICATION =>
      '$baseURL/user_management_new_v2/subscribe_notification';

  static String get GET_NEWS_FEED =>
      '$baseURL/user_management_new_v2/getActivityFeed';

  static String get GET_MAP_URL => '$baseURL/vendor_management_v2/get_map_url';

  static String get GET_EVENT_INFO =>
      '$baseURL/user_management_new_v2/eventinfo';

  static String get RENAME_SOV =>
      '$baseURL/accounts_v2/undefined/subaccount/undefined/sov';

  static String get GET_EVENT_FEED =>
      '$baseURL/user_management_new_v2/getEventFeed';

  static String get GET_EVENT_DATE =>
      '$baseURL/user_management_new_v2/getevent';

  static String get GET_CORPORATE_VERIFICATION_REQUESTS =>
      '$baseURL/companies_v2?leads=company';

  static String get NOTIFICATION_READ =>
      '$baseURL/user_management_new_v2/update_activity_feed_read_by';

  /// ---------------- Delete ----------------

  static String get DELETE_ACCOUNT => '$baseURL/locations_v2/delete_account/?';

  static String get DELETE_SUB_ACCOUNT =>
      '$baseURL/locations_v2/delete_subaccount?';

  static String get DELETE_SOV_ACCOUNT => '$baseURL/locations_v2/delete_sov?';

  /// ---------------- Hazard ----------------

  static String get GET_HAZARD_LIST =>
      '$baseURL/vendor_management_v2/hazard_list';

  static String get REQUEST_ACCESS => '$baseURL/accounts_v2';

  static String get CONFIGURATIONS =>
      '$baseURL/locations_v2/account_sub_global_configuration/global';

  static String get CONFIGURATIONS_ACCOUNTS =>
      '$baseURL/locations_v2/account_sub_global_configuration/account';

  static String get CONFIGURATIONS_SUB_ACCOUNTS =>
      '$baseURL/locations_v2/account_sub_global_configuration/sub_account';
  static String UPDATE_CONFIGURATION =
      '$baseURL/locations_v2/update_account_sub_global_configuration';
  static String UPDATE_ACCOUNT_NAME =
      '$baseURL/locations_v2/update_company_config';

  static String get UPLOAD_IMAGES_NEW =>
      '$baseURL/locations_v2/location_profile_images';

  static String get GET_USER_VERIFICATION_REQUESTS =>
      '$baseURL/companies_v2?leads=users';

  static String get GET_NETWORKING_USER_SUGGESTIONS =>
      '$baseURL/user_management_new_v2/all_user_list?connections=true';

  static String get GET_ROLES_FOR_EMPLOYEES =>
      '$baseURL/companies_v2?role=internal';

  static String get GET_ROLES_FOR_CORPORATE_EMPLOYEES =>
      '$baseURL/companies_v2?role=external';

  static String get GET_LOCATION_PARAMETERS =>
      '$baseURL/data_categories_v2/locationparameter/';

  static String get CHANGE_USER_ROLE => '$baseURL/companies_v2';

  static String get GET_CAMPUS_PARAMETERS =>
      '$baseURL/data_categories_v2/campusparameter/';

  static String get GET_SOV_PARAMETERS =>
      '$baseURL/data_categories_v2/sovparameter/';

  static String get GET_DATA_PARAMETERS =>
      '$baseURL/data_categories_v2/subaccountparameter/';

  static String get GET_SOV_LIST => '$baseURL/accounts_v2';

  static String get GET_LOCATION_PROFILE_NEW => '$baseURL/locations_v2';

  static String get EDIT_CAMPUS => '$baseURL/locations_v2/editcampus';

  static String get UPLOAD_SOV_SUB_ACCOUNT => '$baseURL/sov_v2';

  static String get GET_LOCATION_PROFILE => '$baseURL/accounts_v2';

  static String get GET_LOCATION_PROFILE_INDIVIDUAL_NEW =>
      '$baseURL/locations_v2/getlocation';

  static String get ADD_SUBDESTINATION =>
      '$baseURL/locations_v2/addsubdestination';

  static String get SOV_COMPLETE_STATUS1 =>
      '$baseURL/locations_v2/getsubdestination?';

  static String get SOV_COMPLETE_STATUS =>
      '$baseURL/locations_v2/location_status';

  static String get UPLOAD_DOCUMENT_NEW =>
      '$baseURL/locations_v2/location_media/';

  static String get ADD_TO_MONITORING =>
      '$baseURL/locations_v2/add_to_sov_monitoring';

  static String get DELETE_DOCUMENT_NEW =>
      '$baseURL/locations_v2/location_media/';

  static String get CHANGE_OCCUPANCY => '$baseURL/locations_V2/rented';

  static String get UPDATE_HAZARD => '$baseURL/locations_v2/updatehazard';

  static String get GIFT_CREDITS => '$baseURL/locations_v2/gift_credits';

  static String get ACCEPT_CREDITS => '$baseURL/locations_v2/accept_credits';

  static String get SENT_GIFTS => '$baseURL/locations_v2/sent_gifts';

  static String get RENAME_SUB_ACCOUNT => '$baseURL/accounts_v2';

  static String get REVOKE_GIFTS => '$baseURL/locations_v2/revoke_gift';

  static String get DUPLICATE_SUB_ACCOUNT => '$baseURL/accounts_v2';

  static String get CHANGE_COLUMN_VISIBILITY_SUB_ACCOUNT =>
      '$baseURL/accounts_v2';

  static String get ADD_SUB_ACCOUNT =>
      '$baseURL/locations_v2/create_sub_account';

  static String get GET_AUTOCOMPLETE_SOV_LIST => '$baseURL/locations_v2/sov';

  static String get SHARE_SOV_LIST => '$baseURL/locations_v2/share_sov';
  static String get sendConnectionRequest => '$baseURL/user_management_v2';

  static String get GET_SUB_ACCOUNT_LIST => '$baseURL/locations_v2';

  static String get CANCEL_SOV_UPLOAD_PROCESS =>
      '$baseURL/user_management_new_v2/my_last_process/cancel';

  static String get GET_SOV_LIST_BY_SOV =>
      '$baseURL/locations_v2/accessible_sov';

  static String get GET_EVENET_SOV_LIST_BY_SOV =>
      '$baseURL/vendor_management_v2/event_based_on_monitoring_sov';

  static String get CHANGE_CORPORATE_STATUS => '$baseURL/companies_v2';

  static String get CHANGE_COLUMN_VISIBILITY => '$baseURL/accounts_v2';
}
