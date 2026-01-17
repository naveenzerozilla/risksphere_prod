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

  InitialDataModel.fromJson(Map<String, dynamic> json) {
    companyType = (json['company_type'] as List?)
            ?.map((e) => CompanyType.fromJson(e))
            .toList() ??
        [];
    role = (json['role'] as List?)?.map((e) => Role.fromJson(e)).toList() ?? [];
    companies = (json['companies'] as List?)
            ?.map((e) => Companies.fromJson(e))
            .toList() ??
        [];
    config =
        (json['config'] as List?)?.map((e) => Config.fromJson(e)).toList() ??
            [];

    companies.forEach((element) {
      log("company: ${element.name}");
      log("country: ${element.countryName}");
    });
  }

  // InitialDataModel.fromJson(Map<String, dynamic> json){
  //   companyType = List.from(json['company_type']).map((e)=>CompanyType.fromJson(e)).toList();
  //   role = List.from(json['role']).map((e)=>Role.fromJson(e)).toList();
  //   companies = List.from(json['companies']).map((e)=>Companies.fromJson(e)).toList();
  //   companies!.forEach((element) {
  //     log("company: ${element.name}");
  //     log("country: ${element.countryName}");
  //   });
  //   config = List.from(json['config']).map((e)=>Config.fromJson(e)).toList();
  // }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['company_type'] = companyType.map((e) => e.toJson()).toList();
    _data['role'] = role.map((e) => e.toJson()).toList();
    _data['companies'] = companies.map((e) => e.toJson()).toList();
    _data['config'] = config.map((e) => e.toJson()).toList();
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
    required this.companyName,
    required this.corporateUserVerificationByAdmin,
    required this.canBeListed,
    required this.trialPeriodDays,
    required this.id,
    required this.adminSelfRegistration,
    required this.type,
    // required this.usedBy,
  });

  late final bool isApplicableForTrial;
  late final bool enableCorporateVerification;
  late final List<Roles> roles;
  late final bool corporateUserSelfRegistration;
  late final String name;
  late final String companyName;
  late final bool corporateUserVerificationByAdmin;
  late final bool canBeListed;
  late final int trialPeriodDays;
  late final String id;
  late final bool adminSelfRegistration;
  late final String type;
  // late final String usedBy;

  CompanyType.fromJson(Map<String, dynamic> json) {
    // id = json['id'];
    if (json['is_applicable_for_trial'].runtimeType == bool) {
      isApplicableForTrial = json['is_applicable_for_trial'];
    } else {
      print("is_applicable_for_trial: ${json['is_applicable_for_trial']}");
      if (json['is_applicable_for_trial'] == null ||
          json['is_applicable_for_trial'] == "") {
        isApplicableForTrial = false;
      } else {
        isApplicableForTrial = bool.parse(json['is_applicable_for_trial']);
      }
      //isApplicableForTrial = bool.parse(json['is_applicable_for_trial']);
    }
    //isApplicableForTrial = json['is_applicable_for_trial'];
    if (json['enable_corporate_verification'].runtimeType == bool) {
      enableCorporateVerification = json['enable_corporate_verification'];
    } else {
      if (json['enable_corporate_verification'] == null ||
          json['enable_corporate_verification'] == "") {
        enableCorporateVerification = false;
      } else {
        enableCorporateVerification =
            bool.parse(json['enable_corporate_verification']);
      }
      // enableCorporateVerification = bool.parse(json['enable_corporate_verification']);
    }
    //enableCorporateVerification = json['enable_corporate_verification'];
    roles = List.from(json['roles']).map((e) => Roles.fromJson(e)).toList();
    if (json['corporate_user_self_registration'].runtimeType == bool) {
      corporateUserSelfRegistration = json['corporate_user_self_registration'];
    } else {
      if (json['corporate_user_self_registration'] == null ||
          json['corporate_user_self_registration'] == "") {
        corporateUserSelfRegistration = false;
      } else {
        corporateUserSelfRegistration =
            bool.parse(json['corporate_user_self_registration']);
      }
      //corporateUserSelfRegistration = bool.parse(json['corporate_user_self_registration']);
    }
    //corporateUserSelfRegistration = json['corporate_user_self_registration'];
    name = json['company_name'] ?? "";
    companyName = json['name'] ?? "";
    if (json['corporate_user_verification_by_admin'].runtimeType == bool) {
      corporateUserVerificationByAdmin =
          json['corporate_user_verification_by_admin'];
    } else {
      if (json['corporate_user_verification_by_admin'] == null ||
          json['corporate_user_verification_by_admin'] == "") {
        corporateUserVerificationByAdmin = false;
      } else {
        corporateUserVerificationByAdmin =
            bool.parse(json['corporate_user_verification_by_admin']);
      }
      //corporateUserVerificationByAdmin = bool.parse(json['corporate_user_verification_by_admin']);
    }
    //corporateUserVerificationByAdmin = json['corporate_user_verification_by_admin'];
    if (json['can_be_listed'].runtimeType == bool) {
      canBeListed = json['can_be_listed'];
    } else {
      if (json['can_be_listed'] == null || json['can_be_listed'] == "") {
        canBeListed = false;
      } else {
        canBeListed = bool.parse(json['can_be_listed']);
      }
      //canBeListed = bool.parse(json['can_be_listed']);
    }
    //canBeListed = json['can_be_listed'];
    trialPeriodDays = json['trial_period_days'] ?? 0;
    id = json['id'];
    if (json['admin_self_registration'].runtimeType == bool) {
      adminSelfRegistration = json['admin_self_registration'];
    } else {
      if (json['admin_self_registration'] == null ||
          json['admin_self_registration'] == "") {
        adminSelfRegistration = false;
      } else {
        adminSelfRegistration = bool.parse(json['admin_self_registration']);
      }
      //adminSelfRegistration = bool.parse(json['admin_self_registration']);
    }
    //adminSelfRegistration = json['admin_self_registration'];
    type = json['type'];
    // usedBy = json['used_by'];
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['is_applicable_for_trial'] = isApplicableForTrial;
    _data['enable_corporate_verification'] = enableCorporateVerification;
    _data['roles'] = roles.map((e) => e.toJson()).toList();
    _data['corporate_user_self_registration'] = corporateUserSelfRegistration;
    _data['company_name'] = name;
    _data['name'] = companyName;
    _data['corporate_user_verification_by_admin'] =
        corporateUserVerificationByAdmin;
    _data['can_be_listed'] = canBeListed;
    _data['trial_period_days'] = trialPeriodDays;
    _data['id'] = id;
    _data['admin_self_registration'] = adminSelfRegistration;
    _data['type'] = type;
    // _data['used_by'] = usedBy;
    return _data;
  }
}

class CorporateRoles {
  bool? isForIndividual;
  bool? isSelectable;
  bool? isApplicableForTrial;
  String? role;
  String? name;
  String? description;
  bool? isApplicableForInternal;
  int? trialPeriodDays;
  bool? isMultipleRoleEnabled;
  bool? status;
  SovOperations? sovOperations;

  CorporateRoles(
      {this.isForIndividual,
      this.isSelectable,
      this.isApplicableForTrial,
      this.role,
      this.name,
      this.description,
      this.isApplicableForInternal,
      this.trialPeriodDays,
      this.isMultipleRoleEnabled,
      this.status,
      this.sovOperations});

  CorporateRoles.fromJson(Map<String, dynamic> json) {
    isForIndividual = json['is_for_individual'];
    isSelectable = json['is_selectable'];
    isApplicableForTrial = json['is_applicable_for_trial'];
    role = json['role'];
    name = json['name'];
    description = json['description'];
    isApplicableForInternal = json['is_applicable_for_internal'];
    trialPeriodDays = json['trial_period_days'];
    isMultipleRoleEnabled = json['is_multiple_role_enabled'];
    status = json['status'];
    sovOperations = json['sov_operations'] != null
        ? new SovOperations.fromJson(json['sov_operations'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['is_for_individual'] = this.isForIndividual;
    data['is_selectable'] = this.isSelectable;
    data['is_applicable_for_trial'] = this.isApplicableForTrial;
    data['role'] = this.role;
    data['name'] = this.name;
    data['description'] = this.description;
    data['is_applicable_for_internal'] = this.isApplicableForInternal;
    data['trial_period_days'] = this.trialPeriodDays;
    data['is_multiple_role_enabled'] = this.isMultipleRoleEnabled;
    data['status'] = this.status;
    if (this.sovOperations != null) {
      data['sov_operations'] = this.sovOperations!.toJson();
    }
    return data;
  }
}

class Roles {
  Roles(
      {this.isForIndividual,
      this.isApplicableForTrial,
      this.role,
      this.name,
      this.isMultipleRoleEnabled,
      this.id,
      this.isSelectable,
      this.description,
      this.isApplicableForInternal,
      this.trialPeriodDays,
      this.status,
      this.sovOperations});

  late final bool? isForIndividual;
  late final bool? isApplicableForTrial;
  late final String? role;
  late final String? name;
  late final bool? isMultipleRoleEnabled;

  late final String? id;

  bool? isSelectable;
  String? description;
  bool? isApplicableForInternal;
  int? trialPeriodDays;
  bool? status;
  SovOperations? sovOperations;

  Roles.fromJson(Map<String, dynamic> json) {
    isForIndividual = json['is_for_individual'] ?? false;
    isApplicableForTrial = json['is_applicable_for_trial'] ?? false;
    role = json['role'] ?? '';
    name = json['name'] ?? '';
    isMultipleRoleEnabled = json['is_multiple_role_enabled'] ?? false;
    if (json['id'] != null) {
      id = json['id'] ?? '';
    } else {
      id = "";
    }
    isSelectable = json['is_selectable'];

    description = json['description'];
    isApplicableForInternal = json['is_applicable_for_internal'];
    trialPeriodDays = json['trial_period_days'];
    status = json['status'];
    sovOperations = json['sov_operations'] != null
        ? new SovOperations.fromJson(json['sov_operations'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['is_selectable'] = this.isSelectable;
    _data['description'] = this.description;
    _data['is_applicable_for_internal'] = this.isApplicableForInternal;
    _data['trial_period_days'] = this.trialPeriodDays;
    _data['is_for_individual'] = isForIndividual;
    _data['is_applicable_for_trial'] = isApplicableForTrial;
    _data['role'] = role;
    _data['name'] = name;
    _data['is_multiple_role_enabled'] = isMultipleRoleEnabled;
    _data['id'] = id;
    _data['status'] = this.status;
    if (this.sovOperations != null) {
      _data['sov_operations'] = this.sovOperations!.toJson();
    }
    return _data;
  }
}

class SovOperations {
  bool? view;
  bool? edit;
  bool? comment;

  SovOperations({this.view, this.edit, this.comment});

  SovOperations.fromJson(Map<String, dynamic> json) {
    view = json['view'];
    edit = json['edit'];
    comment = json['comment'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['view'] = this.view;
    data['edit'] = this.edit;
    data['comment'] = this.comment;
    return data;
  }
}

class Role {
  Role({
    required this.accountType,
    required this.categories,
  });

  late final String accountType;
  late final List<Categories> categories;

  Role.fromJson(Map<String, dynamic> json) {
    accountType = json['accountType'] ?? "";
    if (json['categories'] != null) {
      categories = List.from(json['categories'])
          .map((e) => Categories.fromJson(e))
          .toList();
    }
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['accountType'] = accountType;
    _data['categories'] = categories.map((e) => e.toJson()).toList();
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

  late final bool? isForIndividual;
  late final bool? isApplicableForTrial;
  late final String? role;
  late final String? name;
  late final bool? isMultipleRoleEnabled;
  late final String? id;

  Categories.fromJson(Map<String, dynamic> json) {
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
    required this.companyName,
    required this.companyTypeName,
    required this.corporateUserSelfRegistration,
    required this.corporateUserVerificationByAdmin,
    required this.noOfUsers,
    required this.admins,
    required this.roles,
    required this.countryName,
    required this.countryCode,
    required this.id,
    required this.companyDisplayName,
    required this.source,
    required this.status,
    // required this.createdAt,
    // required this.updatedAt,
    required this.verficationStatus,
  });

  late final bool isActive;
  late final bool isAuthorized;
  late final List<UserIds> userIds;

  late final String displayName;
  late final bool adminSelfRegistration;
  late final String companyTypeId;
  late final String name;
  late final String companyName;
  late final String companyTypeName;
  late final bool corporateUserSelfRegistration;
  late final bool corporateUserVerificationByAdmin;
  late final int noOfUsers;
  late final List<Admins> admins;
  late final List<Roles> roles;
  late final String id;
  late final String countryName;
  late final String countryCode;
  late final String companyDisplayName;
  late final String source;
  late bool isEnabled;
  late bool status;
  // late final CreatedAt createdAt;
  // late final UpdatedAt updatedAt;
  late final String verficationStatus;

  Companies.fromJson(Map<String, dynamic> json) {
    id = json['id'] ?? "";
    isActive = json['status'] ?? false;
    isAuthorized = json['is_authorized'] ?? false;
    /*if(json['user_ids']!=null) {
      userIds =
          List.from(json['user_ids']).map((e) => UserIds.fromJson(e)).toList();
    }*/
    userIds = [];

    if (json['company_display_name'] != null) {
      displayName = json['company_display_name'];
    } else {
      displayName = "";
    }
    adminSelfRegistration = json['admin_self_registration'] ?? false;

    companyTypeId = json['company_type_id'] ?? "";
    if (json['company_name'] != null) {
      name = json['company_name'];
    } else {
      name = "";
    }
    if (json['name'] != null) {
      companyName = json['name'];
    } else {
      companyName = "";
    }

    if (json['company_type'] != null) {
      companyTypeName = json['company_type'];
    } else {
      companyTypeName = "";
    }
    corporateUserSelfRegistration =
        json['corporate_user_self_registration'] ?? false;
    corporateUserVerificationByAdmin =
        json['corporate_user_verification_by_admin'] ?? false;
    noOfUsers = json['no_of_users'] ?? 0;
    admins = [];
    // print("display name: $displayName");
    print("company id: $id");
    print("admins: $admins");
    roles = (json['roles'] != null)
        ? List.from(json['roles']).map((e) => Roles.fromJson(e)).toList()
        : [];
    if (json["country"].runtimeType == String) {
      countryName = json['country'] ?? "";
    } else {
      countryName = json['country']?['name'] ?? "";
    }
    countryCode = json['country_code'] ?? "";
    companyDisplayName = json['company_display_name'] ?? "";
    source = json['source'] ?? "";
    isEnabled = json['is_enabled'] ?? true;
    status = json['status'] ?? true;
    // createdAt = CreatedAt.fromJson(json['created_at']);
    // updatedAt = UpdatedAt.fromJson(json['updated_at']);
    verficationStatus = json['verfication_status'] ?? "";
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['is_active'] = isActive;
    _data['is_authorized'] = isAuthorized;
    _data['user_ids'] = userIds.map((e) => e.toJson()).toList();
    _data['display_name'] = displayName;
    _data['admin_self_registration'] = adminSelfRegistration;
    _data['company_type_id'] = companyTypeId;
    _data['company_name'] = name;
    _data['name'] = companyName;
    _data['company_type'] = companyTypeName;
    _data['corporate_user_self_registration'] = corporateUserSelfRegistration;
    _data['corporate_user_verification_by_admin'] =
        corporateUserVerificationByAdmin;
    _data['no_of_users'] = noOfUsers;
    _data['admins'] = admins.map((e) => e.toJson()).toList();
    _data['roles'] = roles.map((e) => e.toJson()).toList();
    _data["id"] = id;
    _data['country'] = countryName;
    _data['country_code'] = countryCode;
    _data['company_display_name'] = companyDisplayName;
    _data['source'] = source;
    _data['is_enabled'] = true;
    _data['status'] = status;
    // _data['created_at'] = createdAt.toJson();
    // _data['updated_at'] = updatedAt.toJson();
    _data['verfication_status'] = verficationStatus;
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

  UserIds.fromJson(Map<String, dynamic> json) {
    phoneNo = null;
    role = null;
    isIndividual = json['is_individual'] ?? false;
    if (json['manage_user_ids'] != null) {
      manageUserIds = List.castFrom<dynamic, dynamic>(json['manage_user_ids']);
    }
    isAccountManager = json['is_account_manager'] ?? false;
    if (json['created_at'] != null) {
      createdAt = CreatedAt.fromJson(json['created_at']);
    }
    displayName = json['display_name'] ?? "";
    expertise = null;
    isVerified = json['is_verified'] ?? false;
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

  CreatedAt.fromJson(Map<String, dynamic> json) {
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

  UpdatedAt.fromJson(Map<String, dynamic> json) {
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

  ActiveDate.fromJson(Map<String, dynamic> json) {
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

  Admins.fromJson(Map<String, dynamic> json) {
    phoneNo = null;
    role = null;
    isIndividual = json['is_individual'] ?? false;
    if (json['manage_user_ids'] != null) {
      manageUserIds = List.castFrom<dynamic, dynamic>(json['manage_user_ids']);
    }
    isAccountManager = json['is_account_manager'] ?? false;
    if (json['created_at'] != null) {
      createdAt = CreatedAt.fromJson(json['created_at']);
    }
    displayName = json['display_name'] ?? "";
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

  Config.fromJson(Map<String, dynamic> json) {
    companyVerificationByAdmin = json['company_verification_by_admin'];
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['company_verification_by_admin'] = companyVerificationByAdmin;
    return _data;
  }
}
