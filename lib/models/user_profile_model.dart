

import 'package:RiskSphere/models/role_model.dart';

class UserProfileModel {
  String? data;
  UserData? user;

  UserProfileModel({this.data, this.user});

  UserProfileModel.fromJson(Map<String, dynamic> json) {
    data = json['data'];
    user = json['user'] != null ? new UserData.fromJson(json['user']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['data'] = this.data;
    if (this.user != null) {
      data['user'] = this.user!.toJson();
    }
    return data;
  }
}

class UserData {
  int? rating;
  String? email;
  String? displayImageUrl;
  String? displayName;
  bool? isVerified;
  String? userId;
  String? referralCode;
  bool? status;
  String? username;
  String? companyId;
  bool? isIndividual;
  String? countryCode;
  String? phone;
  String? name;
  List<Roles>? role;
  LastSelectedRole? lastSelectedRole;
  List<AcceptedRole>? acceptedRole;
  bool? isExternal;

  UserData(
      {this.rating,
        this.email,
        this.displayImageUrl,
        this.displayName,
        this.isVerified,
        this.userId,
        this.referralCode,
        this.status,
        this.username,
        this.companyId,
        this.isIndividual,
        this.countryCode,
        this.phone,
        this.name,
        this.role,
        this.lastSelectedRole,
        this.acceptedRole, this.isExternal,});

  UserData.fromJson(Map<String, dynamic> json) {
    rating = json['rating'];

    email = json['email'];
    displayImageUrl = json['display_image_url'];
    displayName = json['display_name'];
    isVerified = json['is_verified'];
    userId = json['user_id'];
    referralCode = json['referral_code'];
    status = json['status'];
    username = json['username'];
    companyId = json['company_id'];
    isIndividual = json['isIndividual'];
    displayName = json['displayName'];
    countryCode = json['country_code'];
    phone = json['phone'];
    name = json['name'];lastSelectedRole = json['last_selected_role'] != null
        ? new LastSelectedRole.fromJson(json['last_selected_role'])
        : null;
    if (json['role'] != null) {
      role = <Roles>[];
      json['role'].forEach((v) {
        role!.add(new Roles.fromJson(v));
      });
    }
    if (json['accepted_role'] != null) {
      acceptedRole = <AcceptedRole>[];
      json['accepted_role'].forEach((v) {
        acceptedRole!.add(new AcceptedRole.fromJson(v));
      });
    }
    print('userid: ${json['user_id']}');
    print('isExternal: ${json['is_external']}');
    if(json['is_external'] != null && json['is_external'].runtimeType == bool) {
      isExternal = json['is_external'];
    } else if(json['is_external'] != null && json['is_external'].runtimeType == String) {
      isExternal = json['is_external'] == 'true' ? true : false;
    } else {
      isExternal = false;
    }
    //isExternal = json['is_external'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['rating'] = this.rating;
    data['email'] = this.email;
    data['display_image_url'] = this.displayImageUrl;
    data['displayName'] = this.displayName;
    data['is_verified'] = this.isVerified;
    data['user_id'] = this.userId;
    data['referral_code'] = this.referralCode;
    data['status'] = this.status;
    data['username'] = this.username;
    data['company_id'] = this.companyId;
    data['isIndividual'] = this.isIndividual;
    data['country_code'] = this.countryCode;
    data['phone'] = this.phone;
    data['name'] = this.name;
    data['is_external'] = this.isExternal;
    if (this.role != null) {
      data['role'] = this.role!.map((v) => v.toJson()).toList();
    }
    if (this.lastSelectedRole != null) {
      data['last_selected_role'] = this.lastSelectedRole!.toJson();
    }
    if (this.acceptedRole != null) {
      data['accepted_role'] =
          this.acceptedRole!.map((v) => v?.toJson()).toList();
    }
    return data;
  }
}
class AcceptedRole {
  bool? isForIndividual;
  bool? isMultipleRoleEnabled;
  bool? isApplicableForTrial;
  String? name;
  String? role;
  bool? isApplicableForInternal;
  bool? status;
  String? id;
  Null? updatedAt;
  Null? createdAt;
  String? description;
  bool? isSelectable;

  AcceptedRole(
      {this.isForIndividual,
        this.isMultipleRoleEnabled,
        this.isApplicableForTrial,
        this.name,
        this.role,
        this.isApplicableForInternal,
        this.status,
        this.id,
        this.updatedAt,
        this.createdAt,
        this.description,
        this.isSelectable});

  AcceptedRole.fromJson(Map<String, dynamic> json) {
    isForIndividual = json['is_for_individual'];
    isMultipleRoleEnabled = json['is_multiple_role_enabled'];
    isApplicableForTrial = json['is_applicable_for_trial'];
    name = json['name'];
    role = json['role'];
    isApplicableForInternal = json['is_applicable_for_internal'];
    status = json['status'];
    id = json['id'];
    updatedAt = json['updated_at'];
    createdAt = json['created_at'];
    description = json['description'];
    isSelectable = json['is_selectable'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['is_for_individual'] = this.isForIndividual;
    data['is_multiple_role_enabled'] = this.isMultipleRoleEnabled;
    data['is_applicable_for_trial'] = this.isApplicableForTrial;
    data['name'] = this.name;
    data['role'] = this.role;
    data['is_applicable_for_internal'] = this.isApplicableForInternal;
    data['status'] = this.status;
    data['id'] = this.id;
    data['updated_at'] = this.updatedAt;
    data['created_at'] = this.createdAt;
    data['description'] = this.description;
    data['is_selectable'] = this.isSelectable;
    return data;
  }
}
class LastSelectedRole {
  String? role;
  String? name;

  LastSelectedRole({this.role, this.name});

  LastSelectedRole.fromJson(Map<String, dynamic> json) {
    role = json['role'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['role'] = this.role;
    data['name'] = this.name;
    return data;
  }
}
class CreatedAt {
  int? iSeconds;
  int? iNanoseconds;

  CreatedAt({this.iSeconds, this.iNanoseconds});

  CreatedAt.fromJson(Map<String, dynamic> json) {
    iSeconds = json['_seconds'];
    iNanoseconds = json['_nanoseconds'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_seconds'] = this.iSeconds;
    data['_nanoseconds'] = this.iNanoseconds;
    return data;
  }
}
