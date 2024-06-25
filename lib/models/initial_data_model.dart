import 'dart:developer';

class InitialDataModel {
  InitialDataModel({
    required this.companyType,
    required this.role,
    required this.companies,
    required this.config,
  });
  late final List<CompanyType> companyType;
  late final List<Role> role;
  late final List<Companies> companies;
  late final List<Config> config;

  InitialDataModel.fromJson(Map<String, dynamic> json){
    companyType = List.from(json['company_type']).map((e)=>CompanyType.fromJson(e)).toList();
    role = List.from(json['role']).map((e)=>Role.fromJson(e)).toList();
    companies = List.from(json['companies']).map((e)=>Companies.fromJson(e)).toList();
    companies!.forEach((element) {
      log("company: ${element.name}");
      log("country: ${element.countryName}");
    });
    config = List.from(json['config']).map((e)=>Config.fromJson(e)).toList();
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['company_type'] = companyType.map((e)=>e.toJson()).toList();
    _data['role'] = role.map((e)=>e.toJson()).toList();
    _data['companies'] = companies.map((e)=>e.toJson()).toList();
    _data['config'] = config.map((e)=>e.toJson()).toList();
    return _data;
  }
}

class CompanyType {
  CompanyType({
    required this.isApplicableForTrial,
    required this.enableCorporateVerification,
    required this.roles,
    required this.corporateUserSelfRegistration,
    required this.name,
    required this.corporateUserVerificationByAdmin,
    required this.canBeListed,
    required this.trialPeriodDays,
    required this.id,
    required this.adminSelfRegistration,
    required this.type,
    required this.usedBy,
  });
  late final bool isApplicableForTrial;
  late final bool enableCorporateVerification;
  late final List<Roles> roles;
  late final bool corporateUserSelfRegistration;
  late final String name;
  late final bool corporateUserVerificationByAdmin;
  late final bool canBeListed;
  late final int trialPeriodDays;
  late final String id;
  late final bool adminSelfRegistration;
  late final String type;
  late final String usedBy;

  CompanyType.fromJson(Map<String, dynamic> json){
    isApplicableForTrial = json['is_applicable_for_trial'];
    enableCorporateVerification = json['enable_corporate_verification'];
    roles = List.from(json['roles']).map((e)=>Roles.fromJson(e)).toList();
    corporateUserSelfRegistration = json['corporate_user_self_registration'];
    name = json['name']??"";
    corporateUserVerificationByAdmin = json['corporate_user_verification_by_admin'];
    canBeListed = json['can_be_listed'];
    trialPeriodDays = json['trial_period_days']??0;
    id = json['id'];
    adminSelfRegistration = json['admin_self_registration'];
    type = json['type'];
    usedBy = json['used_by'];
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['is_applicable_for_trial'] = isApplicableForTrial;
    _data['enable_corporate_verification'] = enableCorporateVerification;
    _data['roles'] = roles.map((e)=>e.toJson()).toList();
    _data['corporate_user_self_registration'] = corporateUserSelfRegistration;
    _data['name'] = name;
    _data['corporate_user_verification_by_admin'] = corporateUserVerificationByAdmin;
    _data['can_be_listed'] = canBeListed;
    _data['trial_period_days'] = trialPeriodDays;
    _data['id'] = id;
    _data['admin_self_registration'] = adminSelfRegistration;
    _data['type'] = type;
    _data['used_by'] = usedBy;
    return _data;
  }
}

class Roles {
  Roles({
    required this.isForIndividual,
    required this.isApplicableForTrial,
    required this.role,
    required this.name,
    required this.isMultipleRoleEnabled,
    required this.id,
  });
  late final bool isForIndividual;
  late final bool isApplicableForTrial;
  late final String role;
  late final String name;
  late final bool isMultipleRoleEnabled;
  late final String id;

  Roles.fromJson(Map<String, dynamic> json){
    isForIndividual = json['is_for_individual']??false;
    isApplicableForTrial = json['is_applicable_for_trial']??false;
    role = json['role']??'';
    name = json['name']?? '';
    isMultipleRoleEnabled = json['is_multiple_role_enabled']??false;
    if(json['id']!=null) {
      id = json['id']??'';
    } else {
      id = "";
    }
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['is_for_individual'] = isForIndividual;
    _data['is_applicable_for_trial'] = isApplicableForTrial;
    _data['role'] = role;
    _data['name'] = name;
    _data['is_multiple_role_enabled'] = isMultipleRoleEnabled;
    _data['id'] = id;
    return _data;
  }
}

class Role {
  Role({
    required this.accountType,
    required this.categories,
  });
  late final String accountType;
  late final List<Categories> categories;

  Role.fromJson(Map<String, dynamic> json){
    accountType = json['accountType']??"";
    if(json['categories']!=null) {
      categories = List.from(json['categories']).map((e)=>Categories.fromJson(e)).toList();
    }
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['accountType'] = accountType;
    _data['categories'] = categories.map((e)=>e.toJson()).toList();
    return _data;
  }
}

class Categories {
  Categories({
    required this.isForIndividual,
    required this.isApplicableForTrial,
    required this.role,
    required this.name,
    required this.isMultipleRoleEnabled,
    required this.id,
  });
  late final bool isForIndividual;
  late final bool isApplicableForTrial;
  late final String role;
  late final String name;
  late final bool isMultipleRoleEnabled;
  late final String id;

  Categories.fromJson(Map<String, dynamic> json){
    isForIndividual = json['is_for_individual'];
    isApplicableForTrial = json['is_applicable_for_trial'];
    role = json['role'];
    name = json['name'];
    isMultipleRoleEnabled = json['is_multiple_role_enabled'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['is_for_individual'] = isForIndividual;
    _data['is_applicable_for_trial'] = isApplicableForTrial;
    _data['role'] = role;
    _data['name'] = name;
    _data['is_multiple_role_enabled'] = isMultipleRoleEnabled;
    _data['id'] = id;
    return _data;
  }
}

class Companies {
  Companies({
    required this.isActive,
    required this.isAuthorized,
    required this.userIds,
    required this.displayName,
    required this.adminSelfRegistration,
    required this.companyTypeId,
    required this.name,
    required this.corporateUserSelfRegistration,
    required this.corporateUserVerificationByAdmin,
    required this.noOfUsers,
    required this.admins,
    required this.roles,
    required this.countryName,
  });
  late final bool isActive;
  late final bool isAuthorized;
  late final List<UserIds> userIds;
  late final String displayName;
  late final bool adminSelfRegistration;
  late final String companyTypeId;
  late final String name;
  late final bool corporateUserSelfRegistration;
  late final bool corporateUserVerificationByAdmin;
  late final int noOfUsers;
  late final List<Admins> admins;
  late final List<Roles> roles;
  late final String id;
  late final String countryName;

  Companies.fromJson(Map<String, dynamic> json){
    id = json['id']??"";
    isActive = json['status']??false;
    isAuthorized = json['is_authorized'];
    /*if(json['user_ids']!=null) {
      userIds =
          List.from(json['user_ids']).map((e) => UserIds.fromJson(e)).toList();
    }*/
    userIds= [];

    if(json['company_display_name']!=null) {
      displayName = json['company_display_name'];
    } else {
      displayName = "";
    }
    adminSelfRegistration = json['admin_self_registration'];

    companyTypeId = json['company_type_id']??"";
    if(json['company_name']!=null) {
      name = json['company_name'];
    } else {
      name = "";
    }
    corporateUserSelfRegistration = json['corporate_user_self_registration'];
    corporateUserVerificationByAdmin = json['corporate_user_verification_by_admin'];
    noOfUsers = json['no_of_users'];
    admins = [];
    roles = List.from(json['roles']).map((e)=>Roles.fromJson(e)).toList();
    countryName = json['country']??"";

  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['is_active'] = isActive;
    _data['is_authorized'] = isAuthorized;
    _data['user_ids'] = userIds.map((e)=>e.toJson()).toList();
    _data['display_name'] = displayName;
    _data['admin_self_registration'] = adminSelfRegistration;
    _data['company_type_id'] = companyTypeId;
    _data['company_name'] = name;
    _data['corporate_user_self_registration'] = corporateUserSelfRegistration;
    _data['corporate_user_verification_by_admin'] = corporateUserVerificationByAdmin;
    _data['no_of_users'] = noOfUsers;
    _data['admins'] = admins.map((e)=>e.toJson()).toList();
    _data['roles'] = roles.map((e)=>e.toJson()).toList();
    _data["id"] = id;
    _data['country'] = countryName;
    return _data;
  }
}

class UserIds {
  UserIds({
    this.phoneNo,
    this.role,
    required this.isIndividual,
    required this.manageUserIds,
    required this.isAccountManager,
    required this.createdAt,
    required this.displayName,
    this.expertise,
    required this.isVerified,
    required this.isEnabled,
    required this.updatedAt,
    required this.userId,
    required this.name,
    required this.multipleRole,
    required this.email,
    required this.companyId,
  });
  late final Null phoneNo;
  late final Null role;
  late final bool isIndividual;
  late final List<dynamic> manageUserIds;
  late final bool isAccountManager;
  late final CreatedAt createdAt;
  late final String displayName;
  late final Null expertise;
  late final bool isVerified;
  late final bool isEnabled;
  late final UpdatedAt updatedAt;
  late final String userId;
  late final String name;
  late final bool multipleRole;
  late final String email;
  late final String companyId;

  UserIds.fromJson(Map<String, dynamic> json){
    phoneNo = null;
    role = null;
    isIndividual = json['is_individual']??false;
    if(json['manage_user_ids']!=null) {
      manageUserIds = List.castFrom<dynamic, dynamic>(json['manage_user_ids']);
    }
    isAccountManager = json['is_account_manager']??false;
    if(json['created_at']!=null) {
      createdAt = CreatedAt.fromJson(json['created_at']);
    }
    displayName = json['display_name']??"";
    expertise = null;
    isVerified = json['is_verified']??false;
    isEnabled = json['is_enabled'];
    updatedAt = UpdatedAt.fromJson(json['updated_at']);
    userId = json['user_id'];
    name = json['name'];
    multipleRole = json['multiple_role'];
    email = json['email'];
    companyId = json['company_id'];
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['phone_no'] = phoneNo;
    _data['role'] = role;
    _data['is_individual'] = isIndividual;
    _data['manage_user_ids'] = manageUserIds;
    _data['is_account_manager'] = isAccountManager;
    _data['created_at'] = createdAt.toJson();
    _data['display_name'] = displayName;
    _data['expertise'] = expertise;
    _data['is_verified'] = isVerified;
    _data['is_enabled'] = isEnabled;
    _data['updated_at'] = updatedAt.toJson();
    _data['user_id'] = userId;
    _data['name'] = name;
    _data['multiple_role'] = multipleRole;
    _data['email'] = email;
    _data['company_id'] = companyId;
    return _data;
  }
}

class CreatedAt {
  CreatedAt({
    required this.seconds,
    required this.nanoseconds,
  });
  late final int seconds;
  late final int nanoseconds;

  CreatedAt.fromJson(Map<String, dynamic> json){
    seconds = json['_seconds'];
    nanoseconds = json['_nanoseconds'];
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['_seconds'] = seconds;
    _data['_nanoseconds'] = nanoseconds;
    return _data;
  }
}

class UpdatedAt {
  UpdatedAt({
    required this.seconds,
    required this.nanoseconds,
  });
  late final int seconds;
  late final int nanoseconds;

  UpdatedAt.fromJson(Map<String, dynamic> json){
    seconds = json['_seconds'];
    nanoseconds = json['_nanoseconds'];
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['_seconds'] = seconds;
    _data['_nanoseconds'] = nanoseconds;
    return _data;
  }
}

class ActiveDate {
  ActiveDate({
    required this.seconds,
    required this.nanoseconds,
  });
  late final int seconds;
  late final int nanoseconds;

  ActiveDate.fromJson(Map<String, dynamic> json){
    seconds = json['_seconds'];
    nanoseconds = json['_nanoseconds'];
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['_seconds'] = seconds;
    _data['_nanoseconds'] = nanoseconds;
    return _data;
  }
}

class Admins {
  Admins({
    this.phoneNo,
    this.role,
    required this.isIndividual,
    required this.manageUserIds,
    required this.isAccountManager,
    required this.createdAt,
    required this.displayName,
    this.expertise,
    required this.isVerified,
    required this.isEnabled,
    required this.updatedAt,
    required this.userId,
    required this.name,
    required this.multipleRole,
    required this.email,
    required this.companyId,
  });
  late final Null phoneNo;
  late final Null role;
  late final bool isIndividual;
  late final List<dynamic> manageUserIds;
  late final bool isAccountManager;
  late final CreatedAt createdAt;
  late final String displayName;
  late final Null expertise;
  late final bool isVerified;
  late final bool isEnabled;
  late final UpdatedAt updatedAt;
  late final String userId;
  late final String name;
  late final bool multipleRole;
  late final String email;
  late final String companyId;

  Admins.fromJson(Map<String, dynamic> json){
    phoneNo = null;
    role = null;
    isIndividual = json['is_individual']??false;
    if(json['manage_user_ids']!=null) {
      manageUserIds = List.castFrom<dynamic, dynamic>(json['manage_user_ids']);
    }
    isAccountManager = json['is_account_manager']??false;
    if(json['created_at']!=null) {
      createdAt = CreatedAt.fromJson(json['created_at']);
    }
    displayName = json['display_name']??"";
    expertise = null;
    isVerified = json['is_verified'];
    isEnabled = json['is_enabled'];
    updatedAt = UpdatedAt.fromJson(json['updated_at']);
    userId = json['user_id'];
    name = json['name'];
    multipleRole = json['multiple_role'];
    email = json['email'];
    companyId = json['company_id'];
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['phone_no'] = phoneNo;
    _data['role'] = role;
    _data['is_individual'] = isIndividual;
    _data['manage_user_ids'] = manageUserIds;
    _data['is_account_manager'] = isAccountManager;
    _data['created_at'] = createdAt.toJson();
    _data['display_name'] = displayName;
    _data['expertise'] = expertise;
    _data['is_verified'] = isVerified;
    _data['is_enabled'] = isEnabled;
    _data['updated_at'] = updatedAt.toJson();
    _data['user_id'] = userId;
    _data['name'] = name;
    _data['multiple_role'] = multipleRole;
    _data['email'] = email;
    _data['company_id'] = companyId;
    return _data;
  }
}

class Config {
  Config({
    required this.companyVerificationByAdmin,
  });
  late final bool companyVerificationByAdmin;

  Config.fromJson(Map<String, dynamic> json){
    companyVerificationByAdmin = json['company_verification_by_admin'];
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['company_verification_by_admin'] = companyVerificationByAdmin;
    return _data;
  }
}