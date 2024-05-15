import 'package:green/models/role_model.dart';

class User_Corporate_Model {
  String? data;
  UsersCorporate? user;

  User_Corporate_Model({this.data, this.user});

  User_Corporate_Model.fromJson(Map<String, dynamic> json) {
    data = json['data'];
    user = json['user'] != null ? new UsersCorporate.fromJson(json['user']) : null;
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

class UsersCorporate {
  List<Roles>? role;
  String? displayName;
  int? rating;
  CreatedAt? createdAt;
  bool? isIndividual;
  String? email;
  String? companyId;
  // List<Null>? requestSent;
  String? displayImageUrl;
  // List<Null>? myAssignee;
  bool? isVerified;
  String? countryCode;
  String? userId;
  String? phone;
  String? referralCode;
  String? name;
  bool? status;
  String? username;
  List<AcceptedRole>? acceptedRole;

  UsersCorporate(
      {this.role,
        this.displayName,
        this.rating,
        this.createdAt,
        this.isIndividual,
        this.email,
        this.companyId,
        // this.requestSent,
        this.displayImageUrl,
        // this.myAssignee,
        this.isVerified,
        this.countryCode,
        this.userId,
        this.phone,
        this.referralCode,
        this.name,
        this.status,
        this.username,
        this.acceptedRole});

  UsersCorporate.fromJson(Map<String, dynamic> json) {
    role = json['role'] is List
        ? (json['role'] as List).map((v) => Roles.fromJson(v as Map<String, dynamic>)).toList()
        : [];
    displayName = json['displayName'] ?? '';
    rating = json['rating'] ?? 0;
    createdAt = json['created_at'] != null
        ? CreatedAt.fromJson(json['created_at'] as Map<String, dynamic>)
        : null;
    isIndividual = json['isIndividual'] ?? false;
    email = json['email'] ?? '';
    companyId = json['company_id'] ?? '';
    displayImageUrl = json['display_image_url'];
    // requestSent = json['request_sent'] is List ? (json['request_sent'] as List).cast<dynamic>() : [];
    // myAssignee = json['my_assignee'] is List ? (json['my_assignee'] as List).cast<dynamic>() : [];
    isVerified = json['is_verified'] ?? false;
    countryCode = json['country_code'] ?? '';
    userId = json['user_id'] ?? '';
    phone = json['phone'] ?? '';
    referralCode = json['referral_code'] ?? '';
    name = json['name'] ?? '';
    status = json['status'] ?? false;
    username = json['username'] ?? '';
    acceptedRole = json['accepted_role'] is List
        ? (json['accepted_role'] as List).map((v) => AcceptedRole.fromJson(v as Map<String, dynamic>)).toList()
        : [];
  }


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.role != null) {
      data['role'] = this.role!.map((v) => v.toJson()).toList();
    }
    data['displayName'] = this.displayName;
    data['rating'] = this.rating;
    if (this.createdAt != null) {
      data['created_at'] = this.createdAt!.toJson();
    }
    data['isIndividual'] = this.isIndividual;
    data['email'] = this.email;
    data['company_id'] = this.companyId;
    // if (this.requestSent != null) {
    //   data['request_sent'] = this.requestSent!.map((v) => v.toJson()).toList();
    // }
    // data['display_image_url'] = this.displayImageUrl;
    // if (this.myAssignee != null) {
    //   data['my_assignee'] = this.myAssignee!.map((v) => v.toJson()).toList();
    // }
    data['is_verified'] = this.isVerified;
    data['country_code'] = this.countryCode;
    data['user_id'] = this.userId;
    data['phone'] = this.phone;
    data['referral_code'] = this.referralCode;
    data['name'] = this.name;
    data['status'] = this.status;
    data['username'] = this.username;
    if (this.acceptedRole != null) {
      data['accepted_role'] =
          this.acceptedRole!.map((v) => v.toJson()).toList();
    }
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

class AcceptedRole {
  String? id;
  bool? isForIndividual;
  String? role;
  bool? isApplicableForTrial;
  String? name;
  String? description;
  bool? isMultipleRoleEnabled;
  bool? status;
  bool? isApplicableForInternal;
  bool? isSelectable;

  AcceptedRole(
      {this.id,
        this.isForIndividual,
        this.role,
        this.isApplicableForTrial,
        this.name,
        this.description,
        this.isMultipleRoleEnabled,
        this.status,
        this.isApplicableForInternal,
        this.isSelectable});

  AcceptedRole.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    isForIndividual = json['is_for_individual'];
    role = json['role'];
    isApplicableForTrial = json['is_applicable_for_trial'];
    name = json['name'];
    description = json['description'];
    isMultipleRoleEnabled = json['is_multiple_role_enabled'];
    status = json['status'];
    isApplicableForInternal = json['is_applicable_for_internal'];
    isSelectable = json['is_selectable'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['is_for_individual'] = this.isForIndividual;
    data['role'] = this.role;
    data['is_applicable_for_trial'] = this.isApplicableForTrial;
    data['name'] = this.name;
    data['description'] = this.description;
    data['is_multiple_role_enabled'] = this.isMultipleRoleEnabled;
    data['status'] = this.status;
    data['is_applicable_for_internal'] = this.isApplicableForInternal;
    data['is_selectable'] = this.isSelectable;
    return data;
  }
}
