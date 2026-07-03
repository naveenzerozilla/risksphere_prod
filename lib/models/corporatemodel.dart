class corporatemodel {
  Data? data;

  corporatemodel({this.data});

  corporatemodel.fromJson(Map<String, dynamic> json) {
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  bool? disableCompanyTypeField;
  bool? disableCountryField;
  String? companyDisplayName;
  String? name;
  String? email;
  String? password;
  String? confirmPassword;
  String? companyName;
  String? country;
  String? companyType;
  CorporateRoles? corporateRoles;
  String? phone;
  String? countryCode;
  SelectedCompany? selectedCompany;
  String? accountType;
  bool? isIndividual;
  CorporateRoles? roles;
  String? companyId;
  String? companyTypeId;
  String? companyTypeName;
  String? uId;
  bool? isEmailPassword;
  int? trialPeriodDays;
  bool? isApplicableForTrial;
  AuthData? authData;

  Data(
      {this.disableCompanyTypeField,
      this.disableCountryField,
      this.companyDisplayName,
      this.name,
      this.email,
      this.password,
      this.confirmPassword,
      this.companyName,
      this.country,
      this.companyType,
      this.corporateRoles,
      this.phone,
      this.countryCode,
      this.selectedCompany,
      this.accountType,
      this.isIndividual,
      this.roles,
      this.companyId,
      this.companyTypeId,
      this.companyTypeName,
      this.uId,
      this.isEmailPassword,
      this.trialPeriodDays,
      this.isApplicableForTrial,
      this.authData});

  Data.fromJson(Map<String, dynamic> json) {
    disableCompanyTypeField = json['disableCompanyTypeField'];
    disableCountryField = json['disableCountryField'];
    companyDisplayName = json['company_display_name'];
    name = json['name'];
    email = json['email'];
    password = json['password'];
    confirmPassword = json['confirmPassword'];
    companyName = json['company_name'];
    country = json['country'];
    companyType = json['company_type'];
    corporateRoles = json['corporateRoles'] != null
        ? new CorporateRoles.fromJson(json['corporateRoles'])
        : null;
    phone = json['phone'];
    countryCode = json['country_code'];
    selectedCompany = json['selectedCompany'] != null
        ? new SelectedCompany.fromJson(json['selectedCompany'])
        : null;
    accountType = json['accountType'];
    isIndividual = json['isIndividual'];
    roles = json['roles'] != null
        ? new CorporateRoles.fromJson(json['roles'])
        : null;
    companyId = json['company_id'];
    companyTypeId = json['company_type_id'];
    companyTypeName = json['company_type_name'];
    uId = json['uId'];
    isEmailPassword = json['is_email_password'];
    trialPeriodDays = json['trial_period_days'];
    isApplicableForTrial = json['is_applicable_for_trial'];
    authData = json['authData'] != null
        ? new AuthData.fromJson(json['authData'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['disableCompanyTypeField'] = this.disableCompanyTypeField;
    data['disableCountryField'] = this.disableCountryField;
    data['company_display_name'] = this.companyDisplayName;
    data['name'] = this.name;
    data['email'] = this.email;
    data['password'] = this.password;
    data['confirmPassword'] = this.confirmPassword;
    data['company_name'] = this.companyName;
    data['country'] = this.country;
    data['company_type'] = this.companyType;
    if (this.corporateRoles != null) {
      data['corporateRoles'] = this.corporateRoles!.toJson();
    }
    data['phone'] = this.phone;
    data['country_code'] = this.countryCode;
    if (this.selectedCompany != null) {
      data['selectedCompany'] = this.selectedCompany!.toJson();
    }
    data['accountType'] = this.accountType;
    data['isIndividual'] = this.isIndividual;
    if (this.roles != null) {
      data['roles'] = this.roles!.toJson();
    }
    data['company_id'] = this.companyId;
    data['company_type_id'] = this.companyTypeId;
    data['company_type_name'] = this.companyTypeName;
    data['uId'] = this.uId;
    data['is_email_password'] = this.isEmailPassword;
    data['trial_period_days'] = this.trialPeriodDays;
    data['is_applicable_for_trial'] = this.isApplicableForTrial;
    if (this.authData != null) {
      data['authData'] = this.authData!.toJson();
    }
    return data;
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

class SelectedCompany {
  Null accountId;
  Null accountIdField;
  Null accountName;
  String? companyDisplayName;
  String? companyName;
  String? companyType;
  String? companyTypeId;
  String? country;
  String? countryCode;
  String? createdAt;
  String? id;
  bool? isEnabled;
  String? source;
  bool? status;
  String? updatedAt;
  Null verificationStatus;

  SelectedCompany(
      {this.accountId,
      this.accountIdField,
      this.accountName,
      this.companyDisplayName,
      this.companyName,
      this.companyType,
      this.companyTypeId,
      this.country,
      this.countryCode,
      this.createdAt,
      this.id,
      this.isEnabled,
      this.source,
      this.status,
      this.updatedAt,
      this.verificationStatus});

  SelectedCompany.fromJson(Map<String, dynamic> json) {
    accountId = json['account_id'];
    accountIdField = json['account_id_field'];
    accountName = json['account_name'];
    companyDisplayName = json['company_display_name'];
    companyName = json['company_name'];
    companyType = json['company_type'];
    companyTypeId = json['company_type_id'];
    country = json['country'];
    countryCode = json['country_code'];
    createdAt = json['created_at'];
    id = json['id'];
    isEnabled = json['is_enabled'];
    source = json['source'];
    status = json['status'];
    updatedAt = json['updated_at'];
    verificationStatus = json['verification_status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['account_id'] = this.accountId;
    data['account_id_field'] = this.accountIdField;
    data['account_name'] = this.accountName;
    data['company_display_name'] = this.companyDisplayName;
    data['company_name'] = this.companyName;
    data['company_type'] = this.companyType;
    data['company_type_id'] = this.companyTypeId;
    data['country'] = this.country;
    data['country_code'] = this.countryCode;
    data['created_at'] = this.createdAt;
    data['id'] = this.id;
    data['is_enabled'] = this.isEnabled;
    data['source'] = this.source;
    data['status'] = this.status;
    data['updated_at'] = this.updatedAt;
    data['verification_status'] = this.verificationStatus;
    return data;
  }
}

class AuthData {
  Null displayName;
  String? email;
  bool? isEmailVerified;
  bool? isAnonymous;
  Metadata? metadata;
  Null phoneNumber;
  Null photoURL;
  List<ProviderData>? providerData;
  String? refreshToken;
  Null tenantId;
  String? uId;

  AuthData(
      {this.displayName,
      this.email,
      this.isEmailVerified,
      this.isAnonymous,
      this.metadata,
      this.phoneNumber,
      this.photoURL,
      this.providerData,
      this.refreshToken,
      this.tenantId,
      this.uId});

  AuthData.fromJson(Map<String, dynamic> json) {
    displayName = json['displayName'];
    email = json['email'];
    isEmailVerified = json['isEmailVerified'];
    isAnonymous = json['isAnonymous'];
    metadata = json['metadata'] != null
        ? new Metadata.fromJson(json['metadata'])
        : null;
    phoneNumber = json['phoneNumber'];
    photoURL = json['photoURL'];
    if (json['providerData'] != null) {
      providerData = <ProviderData>[];
      json['providerData'].forEach((v) {
        providerData!.add(new ProviderData.fromJson(v));
      });
    }
    refreshToken = json['refreshToken'];
    tenantId = json['tenantId'];
    uId = json['uId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['displayName'] = this.displayName;
    data['email'] = this.email;
    data['isEmailVerified'] = this.isEmailVerified;
    data['isAnonymous'] = this.isAnonymous;
    if (this.metadata != null) {
      data['metadata'] = this.metadata!.toJson();
    }
    data['phoneNumber'] = this.phoneNumber;
    data['photoURL'] = this.photoURL;
    if (this.providerData != null) {
      data['providerData'] = this.providerData!.map((v) => v.toJson()).toList();
    }
    data['refreshToken'] = this.refreshToken;
    data['tenantId'] = this.tenantId;
    data['uId'] = this.uId;
    return data;
  }
}

class Metadata {
  String? createdAt;
  String? lastLoginAt;

  Metadata({this.createdAt, this.lastLoginAt});

  Metadata.fromJson(Map<String, dynamic> json) {
    createdAt = json['createdAt'];
    lastLoginAt = json['lastLoginAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['createdAt'] = this.createdAt;
    data['lastLoginAt'] = this.lastLoginAt;
    return data;
  }
}

class ProviderData {
  String? providerId;
  String? uid;
  Null displayName;
  String? email;
  Null phoneNumber;
  Null photoURL;

  ProviderData(
      {this.providerId,
      this.uid,
      this.displayName,
      this.email,
      this.phoneNumber,
      this.photoURL});

  ProviderData.fromJson(Map<String, dynamic> json) {
    providerId = json['providerId'];
    uid = json['uid'];
    displayName = json['displayName'];
    email = json['email'];
    phoneNumber = json['phoneNumber'];
    photoURL = json['photoURL'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['providerId'] = this.providerId;
    data['uid'] = this.uid;
    data['displayName'] = this.displayName;
    data['email'] = this.email;
    data['phoneNumber'] = this.phoneNumber;
    data['photoURL'] = this.photoURL;
    return data;
  }
}
