class Corporate_User_Model {
  List<CorporateUsers>? corporateUsers;
  String? pageToken;
  String? direction;
  bool? nextPageExists;
  Counts? counts;

  Corporate_User_Model(
      {this.corporateUsers,
      this.pageToken,
      this.direction,
      this.nextPageExists,
      this.counts});

  Corporate_User_Model.fromJson(Map<String, dynamic> json) {
    if (json['corporate_users'] != null) {
      corporateUsers = <CorporateUsers>[];
      json['corporate_users'].forEach((v) {
        corporateUsers!.add(new CorporateUsers.fromJson(v, isSearch: false, searchText: ""));
      });
    }
    pageToken = json['pageToken'];
    direction = json['direction'];
    nextPageExists = json['nextPageExists'];
    counts =
        json['counts'] != null ? new Counts.fromJson(json['counts']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.corporateUsers != null) {
      data['corporate_users'] =
          this.corporateUsers!.map((v) => v.toJson()).toList();
    }
    data['pageToken'] = this.pageToken;
    data['direction'] = this.direction;
    data['nextPageExists'] = this.nextPageExists;
    if (this.counts != null) {
      data['counts'] = this.counts!.toJson();
    }
    return data;
  }
}

class CorporateUsers {
  Role? role;
  String? displayName;
  int? rating;
  CreatedAt? createdAt;
  bool? isIndividual;
  String? email;
  // List<dynamic>? requestSent;
  String? displayImageUrl;
  List<String>? myAssignee;
  bool? isVerified;
  String? countryCode;
  String? userId;
  String? phone;
  String? referralCode;
  String? name;
  bool? status;
  String? username;
  bool? isSelected;

  CorporateUsers(
      {this.role,
      this.displayName,
      this.rating,
      this.createdAt,
      this.isIndividual,
      this.email,
      // this.requestSent,
      this.displayImageUrl,
      this.myAssignee,
      this.isVerified,
      this.countryCode,
      this.userId,
      this.phone,
      this.referralCode,
      this.name,
      this.status,
      this.username, this.isSelected = false});

  factory CorporateUsers.fromJson(Map<String, dynamic> json, {required bool isSearch, required String searchText}) {
    Role? role;
    if (isSearch && searchText.isNotEmpty) {
      // For search results where role is an array of strings
      final roleList = json['role'] as List<dynamic>? ?? [];
      if (roleList.isNotEmpty) {
        role = Role(name: roleList.first.toString());
      }
    } else {
      // For other cases where role is an object
      final roleJson = json['role'] as Map<String, dynamic>? ?? {};
      if (roleJson.isNotEmpty) {
        role = Role.fromJson(roleJson);
      }
    }

    return CorporateUsers(
      role: role,
      displayName: json['displayName'] ?? '',
      rating: json['rating'] ?? 0,
      isIndividual: json['isIndividual'] ?? false,
      email: json['email'] ?? '',
      displayImageUrl: json['display_image_url'] ?? '',
      myAssignee: List<String>.from(json['my_assignee'] ?? []),
      isVerified: json['is_verified'] ?? false,
      countryCode: json['country_code'] ?? '',
      userId: json['user_id'] ?? '',
      phone: json['phone'] ?? '',
      referralCode: json['referral_code'] ?? '',
      name: json['name'] ?? '',
      status: json['status'] ?? false,
      username: json['username'] ?? '',
    );
  }


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.role != null) {
      data['role'] = this.role!.toJson();
    }
    data['displayName'] = this.displayName;
    data['rating'] = this.rating;
    if (this.createdAt != null) {
      data['created_at'] = this.createdAt!.toJson();
    }
    data['isIndividual'] = this.isIndividual;
    data['email'] = this.email;
    // if (this.requestSent != null) {
    //   data['request_sent'] = this.requestSent!.map((e) => e).toList(); // Mapping directly to the list
    // }
    data['display_image_url'] = this.displayImageUrl;
    data['my_assignee'] = this.myAssignee;
    data['is_verified'] = this.isVerified;
    data['country_code'] = this.countryCode;
    data['user_id'] = this.userId;
    data['phone'] = this.phone;
    data['referral_code'] = this.referralCode;
    data['name'] = this.name;
    data['status'] = this.status;
    data['username'] = this.username;
    return data;
  }
}

class Role {
  bool? isForIndividual;
  bool? isSelectable;
  String? role;
  bool? isApplicableForTrial;
  String? name;
  String? description;
  bool? isApplicableForInternal;
  bool? isMultipleRoleEnabled;
  bool? status;
  String? id;

  Role(
      {this.isForIndividual,
      this.isSelectable,
      this.role,
      this.isApplicableForTrial,
      this.name,
      this.description,
      this.isApplicableForInternal,
      this.isMultipleRoleEnabled,
      this.status,
      this.id});

  Role.fromJson(Map<String, dynamic> json) {
    isForIndividual = json['is_for_individual'];
    isSelectable = json['is_selectable'];
    role = json['role'];
    isApplicableForTrial = json['is_applicable_for_trial'];
    name = json['name'];
    description = json['description'];
    isApplicableForInternal = json['is_applicable_for_internal'];
    isMultipleRoleEnabled = json['is_multiple_role_enabled'];
    status = json['status'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['is_for_individual'] = this.isForIndividual;
    data['is_selectable'] = this.isSelectable;
    data['role'] = this.role;
    data['is_applicable_for_trial'] = this.isApplicableForTrial;
    data['name'] = this.name;
    data['description'] = this.description;
    data['is_applicable_for_internal'] = this.isApplicableForInternal;
    data['is_multiple_role_enabled'] = this.isMultipleRoleEnabled;
    data['status'] = this.status;
    data['id'] = this.id;
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

class Counts {
  int? active;
  int? users;

  Counts({this.active, this.users});

  Counts.fromJson(Map<String, dynamic> json) {
    active = json['active'];
    users = json['users'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['active'] = this.active;
    data['users'] = this.users;
    return data;
  }
}
