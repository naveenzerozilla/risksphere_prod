// region-projectid.cloudfunction.net/{function name}
class AppConstant {
  /// R1 API URL
  // Url for corporate management
  static const String CORPORATE_MANAGEMENT_URL = "https://companies-nzc3rkheha-uc.a.run.app";
  static const String CREATE_CORPORATE_URL = "https://new-user-create-nzc3rkheha-uc.a.run.app";
  static const String UPDATE_CORPORATE_URL = "https://companies-nzc3rkheha-uc.a.run.app";
  static const String UPLOAD_FILE = "https://upload-file-nzc3rkheha-uc.a.run.app";
  static const String GET_CORPORATE_ROLES = "https://support-nzc3rkheha-uc.a.run.app?corporate_type=true";
  static const String GET_FEATURE_LIST = "https://feature-settings-nzc3rkheha-uc.a.run.app";
  static const String ADD_FEATURE = "https://feature-settings-nzc3rkheha-uc.a.run.app";
  static const String GET_ROLES = "https://support-nzc3rkheha-uc.a.run.app?role=true";
  static const String GET_EMAILS = "https://support-nzc3rkheha-uc.a.run.app?emails=true";
  static const String ADD_EMAILS = "https://support-nzc3rkheha-uc.a.run.app";
  static const String CHANGE_STATUS = "https://support-nzc3rkheha-uc.a.run.app";
  static const String GET_EMPLOYEES = "https://user-management-nzc3rkheha-uc.a.run.app?employees_list=true";
  static const String GET_ROLES_FOR_EMPLOYEES = "https://companies-nzc3rkheha-uc.a.run.app?role=internal";
  static const String GET__ROLES_FOR_CORPORATE_EMPLOYEES = "https://companies-nzc3rkheha-uc.a.run.app?role=external";
  static const String CREATE_EMPLOYEES = "https://new-user-create-nzc3rkheha-uc.a.run.app";
  static const String UPDATE_EMPLOYEES = "https://user-management-nzc3rkheha-uc.a.run.app";
  static const String VIEW_EMPLOYEES = "https://user-management-nzc3rkheha-uc.a.run.app";
  static const String GET_CORPORATE_VERIFICATION_REQUESTS = "https://companies-nzc3rkheha-uc.a.run.app?leads=company";
  static const String GET_USER_VERIFICATION_REQUESTS = "https://companies-nzc3rkheha-uc.a.run.app?leads=users";
  static const String CHANGE_CORPORATE_STATUS = "https://companies-nzc3rkheha-uc.a.run.app";
  static const String CHANGE_USER_STATUS = "https://companies-nzc3rkheha-uc.a.run.app";
  static const String CHANGE_USER_ROLE = "https://companies-nzc3rkheha-uc.a.run.app";
  static  const String GET_USER_DETAILS = "https://user-management-nzc3rkheha-uc.a.run.app";
  static const String UPDATE_USER_DETAILS = "https://user-management-nzc3rkheha-uc.a.run.app";
  static const String GET_AVATARS = "https://us-central1-project-green-f4d78.cloudfunctions.net/get_avatar";
  static const String GET_DASHBOARD = "https://dashboard-data-nzc3rkheha-uc.a.run.app";
  static const String GET_CONNECTIONS = "https://user-management-nzc3rkheha-uc.a.run.app?connections=true";
  static const String GET_REQUESTS = "https://user-management-nzc3rkheha-uc.a.run.app?requests=true";
  static const String ACCEPT_REJECT_REQUEST = "https://companies-nzc3rkheha-uc.a.run.app";
  static const String GET_NETWORKING_USER_SUGGESTIONS = "https://user-management-nzc3rkheha-uc.a.run.app";
  static const String SEND_NETWORKING_REQUEST = "https://user-management-nzc3rkheha-uc.a.run.app";
  static const String GET_USER_TEAMS = "https://user-management-nzc3rkheha-uc.a.run.app?my_team=true";
  static const String DELETE_TEAM_MEMBER = "https://user-management-nzc3rkheha-uc.a.run.app";
  static const String ADD_TEAM_MEMBERS = "https://user-management-nzc3rkheha-uc.a.run.app";
  static  const String GET_CORPORATE_USER = "https://companies-nzc3rkheha-uc.a.run.app";

  static  const String UPDATE_USER_STATUS = "https://user-management-nzc3rkheha-uc.a.run.app";
  static  const String NON_CORPORATE_USER_STATUS = "https://user-management-nzc3rkheha-uc.a.run.app";
  static const String CREATE_CORPORATE_EMPLOYEES = "https://new-company-user-create-nzc3rkheha-uc.a.run.app";
  static const String DELETE_CORPORATE_EMPLOYEES = "https://user-management-nzc3rkheha-uc.a.run.app";

  /// R2 APIS
  // Accounts
  static const String GET_ACCOUNT_LIST = "https://us-central1-project-green-f4d78.cloudfunctions.net/accounts/mobile";
  static const String RENAME_ACCOUNT = "https://us-central1-project-green-f4d78.cloudfunctions.net/accounts";
  static const String DUPLICATE_ACCOUNT = "https://us-central1-project-green-f4d78.cloudfunctions.net/accounts";
  static const String CHANGE_COLUMN_VISIBILITY = "https://us-central1-project-green-f4d78.cloudfunctions.net/accounts";
  static const String AUTO_COMPLETE_ACCOUNT_LIST = "https://us-central1-project-green-f4d78.cloudfunctions.net/accounts";
  static const String ADD_ACCOUNT = "https://us-central1-project-green-f4d78.cloudfunctions.net/accounts";
  static const String REQUEST_ACCESS = "https://us-central1-project-green-f4d78.cloudfunctions.net/accounts";
  // Sub Accounts
  static const String GET_SUB_ACCOUNT_LIST = "https://us-central1-project-green-f4d78.cloudfunctions.net/accounts";
  static const String RENAME_SUB_ACCOUNT = "https://us-central1-project-green-f4d78.cloudfunctions.net/accounts";
  static const String DUPLICATE_SUB_ACCOUNT = "https://us-central1-project-green-f4d78.cloudfunctions.net/accounts";
  static const String CHANGE_COLUMN_VISIBILITY_SUB_ACCOUNT = "https://us-central1-project-green-f4d78.cloudfunctions.net/accounts";
  static const String AUTO_COMPLETE_SUB_ACCOUNT_LIST = "https://us-central1-project-green-f4d78.cloudfunctions.net/accounts";
  static const String ADD_SUB_ACCOUNT = "https://us-central1-project-green-f4d78.cloudfunctions.net/accounts";
  static const String REQUEST_ACCESS_SUB_ACCOUNT = "https://us-central1-project-green-f4d78.cloudfunctions.net/accounts";
  static const String SOV = "https://us-central1-project-green-f4d78.cloudfunctions.net/sov";
  // Sov
  static const String GET_SOV_LIST = "https://us-central1-project-green-f4d78.cloudfunctions.net/accounts";
  static const String RENAME_SOV = "https://us-central1-project-green-f4d78.cloudfunctions.net/accounts";
  static const String DUPLICATE_SOV = "https://us-central1-project-green-f4d78.cloudfunctions.net/accounts";
  static const String CHANGE_COLUMN_VISIBILITY_SOV = "https://us-central1-project-green-f4d78.cloudfunctions.net/accounts";
  static const String AUTO_COMPLETE_SOV_LIST = "https://us-central1-project-green-f4d78.cloudfunctions.net/accounts";
  static const String ADD_SOV = "https://us-central1-project-green-f4d78.cloudfunctions.net/accounts";
  static const String REQUEST_ACCESS_SOV = "https://us-central1-project-green-f4d78.cloudfunctions.net/accounts";
}