class CompanyTypeModel {
  List<CorporateType>? corporateType;

  CompanyTypeModel({this.corporateType});

  CompanyTypeModel.fromJson(Map<String, dynamic>? json) {
    if (json != null && json['corporate_type'] != null) {
      corporateType = <CorporateType>[];
      json['corporate_type'].forEach((v) {
        if (v != null) {
          corporateType!.add(new CorporateType.fromJson(v));
        }
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.corporateType != null) {
      data['corporate_type'] =
          this.corporateType!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class CorporateType {
  bool? isApplicableForTrial;
  bool? isActive;
  bool? dataSharing;
  List<Roles>? roles;
  bool? canBeListed;
  int? trialPeriodDays;
  var adminSelfRegistration;
  String? type;
  String? usedBy;
  bool? enableCorporateVerification;
  bool? corporateUserSelfRegistration;
  String? name;
  bool? corporateUserVerificationByAdmin;
  bool? isEnabled;
  String? id;

  CorporateType({this.isApplicableForTrial,
    this.isActive,
    this.dataSharing,
    this.roles,
    this.canBeListed,
    this.trialPeriodDays,
    this.adminSelfRegistration,
    this.type,
    this.usedBy,
    this.enableCorporateVerification,
    this.corporateUserSelfRegistration,
    this.name,
    this.corporateUserVerificationByAdmin,
    this.isEnabled,
    this.id});

  CorporateType.fromJson(Map<String, dynamic>? json) {
    if (json != null) {
      if (json['is_applicable_for_trial'] != null &&
          json['is_applicable_for_trial'] is String) {
        isApplicableForTrial =
            json['is_applicable_for_trial'].toLowerCase() == 'true';
      } else {
        isApplicableForTrial = json['is_applicable_for_trial'] ?? false;
      }
      isActive = json['is_active'];
      dataSharing = json['data_sharing'];
      if (json['roles'] != null) {
        roles = <Roles>[];
        json['roles'].forEach((v) {
          if (v != null) {
            roles!.add(new Roles.fromJson(v));
          }
        });
      }
      if (json['can_be_listed'] != null && json['can_be_listed'] is String) {
        canBeListed = json['can_be_listed'].toLowerCase() == 'true';
      } else {
        canBeListed = json['can_be_listed'] ?? false;
      }
      trialPeriodDays = json['trial_period_days'];
      adminSelfRegistration = json['admin_self_registration'];
      type = json['type'];
      usedBy = json['used_by'];
      if (json['enable_corporate_verification'] != null &&
          json['enable_corporate_verification'] is String) {
        enableCorporateVerification =
            json['enable_corporate_verification'].toLowerCase() == 'true';
      } else {
        enableCorporateVerification =
            json['enable_corporate_verification'] ?? false;
      }
      if (json['corporate_user_self_registration'] != null &&
          json['corporate_user_self_registration'] is String) {
        corporateUserSelfRegistration =
            json['corporate_user_self_registration'].toLowerCase() == 'true';
      } else {
        corporateUserSelfRegistration =
            json['corporate_user_self_registration'] ?? false;
      }
      name = json['name'];
      if (json['corporate_user_verification_by_admin'] != null &&
          json['corporate_user_verification_by_admin'] is String) {
        corporateUserVerificationByAdmin =
            json['corporate_user_verification_by_admin'].toLowerCase() ==
                'true';
      } else {
        corporateUserVerificationByAdmin =
            json['corporate_user_verification_by_admin'] ?? false;
      }
      isEnabled = json['is_enabled'];
      id = json['id'];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['is_applicable_for_trial'] = this.isApplicableForTrial;
    data['is_active'] = this.isActive;
    data['data_sharing'] = this.dataSharing;
    if (this.roles != null) {
      data['roles'] = this.roles!.map((v) => v.toJson()).toList();
    }
    data['can_be_listed'] = this.canBeListed;
    data['trial_period_days'] = this.trialPeriodDays;
    data['admin_self_registration'] = this.adminSelfRegistration;
    data['type'] = this.type;
    data['used_by'] = this.usedBy;
    data['enable_corporate_verification'] = this.enableCorporateVerification;
    data['corporate_user_self_registration'] =
        this.corporateUserSelfRegistration;
    data['name'] = this.name;
    data['corporate_user_verification_by_admin'] =
        this.corporateUserVerificationByAdmin;
    data['is_enabled'] = this.isEnabled;
    data['id'] = this.id;
    return data;
  }
}

class Roles {
  bool? isForIndividual;
  bool? isMultipleRoleEnabled;
  bool? isApplicableForTrial;
  String? name;
  String? id;

  String? role;
  bool? isApplicableForInternal;
  bool? status;

  Roles({this.isForIndividual,
    this.isMultipleRoleEnabled,
    this.isApplicableForTrial,
    this.name,
    this.id,
    this.role,
    this.isApplicableForInternal,
    this.status});

  Roles.fromJson(Map<String, dynamic>? json) {
    if (json != null) {
      isForIndividual = json['is_for_individual'];
      isMultipleRoleEnabled = json['is_multiple_role_enabled'];
      isApplicableForTrial = json['is_applicable_for_trial'];
      name = json['name'];
      id = json['id'];
      role = json['role'];
      isApplicableForInternal = json['is_applicable_for_internal'];
      status = json['status'];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['is_for_individual'] = this.isForIndividual;
    data['is_multiple_role_enabled'] = this.isMultipleRoleEnabled;
    data['is_applicable_for_trial'] = this.isApplicableForTrial;
    data['name'] = this.name;
    data['id'] = this.id;
    data['role'] = this.role;
    data['is_applicable_for_internal'] = this.isApplicableForInternal;
    data['status'] = this.status;
    return data;
  }
}
