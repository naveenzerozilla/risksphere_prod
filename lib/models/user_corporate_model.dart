import 'package:RiskSphere/models/role_model.dart';

class UserCorporateModel {
  String? data;
  UsersCorporate? user;

  UserCorporateModel({this.data, this.user});

  UserCorporateModel.fromJson(Map<String, dynamic> json) {
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
  // List<AcceptedRole>? acceptedRole;

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
        });

  UsersCorporate.fromJson(Map<String, dynamic> json) {
    role = json['role'] is List
        ? (json['role'] as List).map((v) => Roles.fromJson(v as Map<String, dynamic>)).toList()
        : [];
    displayName = json['displayName'] ?? '';
    rating = json['rating'] ?? 0;
/*    createdAt = json['created_at'] != null
        ? CreatedAt.fromJson(json['created_at'] as Map<String, dynamic>)
        : null;*/
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
    // acceptedRole = json['accepted_role'] is List
    //     ? (json['accepted_role'] as List).map((v) => AcceptedRole.fromJson(v as Map<String, dynamic>)).toList()
    //     : [];
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
    // if (this.acceptedRole != null) {
    //   data['accepted_role'] =
    //       this.acceptedRole!.map((v) => v.toJson()).toList();
    // }
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

