import 'package:RiskSphere/models/role_model.dart';

class CorporateTypeModel {
  List<CorporateType>? corporateType;

  CorporateTypeModel({this.corporateType});

  CorporateTypeModel.fromJson(Map<String, dynamic>? json) {
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
  bool? adminSelfRegistration;
  String? type;
  String? usedBy;
  bool? enableCorporateVerification;
  bool? corporateUserSelfRegistration;
  String? name;
  bool? corporateUserVerificationByAdmin;
  bool? isEnabled;
  String? id;

  CorporateType(
      {this.isApplicableForTrial,
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
      isApplicableForTrial = json['is_applicable_for_trial']??"";
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
      canBeListed = json['can_be_listed'];
      trialPeriodDays = json['trial_period_days'];
      adminSelfRegistration = json['admin_self_registration'];
      type = json['type'];
      usedBy = json['used_by'];
      enableCorporateVerification = json['enable_corporate_verification'];
      corporateUserSelfRegistration = json['corporate_user_self_registration'];
      name = json['name'];
      corporateUserVerificationByAdmin =
      json['corporate_user_verification_by_admin'];
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

