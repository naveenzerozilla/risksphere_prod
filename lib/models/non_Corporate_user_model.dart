class Non_Corporate_User_Model {
  String? data;
  List<IndividualUsers>? individualUsers;
  //Users? users;

  // List<Null>? corporateUsers;
  String? pageToken;
  String? direction;
  bool? nextPageExists;
  Counts? counts;

  Non_Corporate_User_Model({this.data, this.individualUsers,
    // this.corporateUsers,
    this.pageToken,
    this.direction,
    this.nextPageExists,
    this.counts,});

  Non_Corporate_User_Model.fromJson(Map<String, dynamic> json, {bool isSearch = false}) {
    data = json['data'];
   /* if(isSearch) {
      users = json['users'] != null ? new Users.fromJson(json['users']) : null;
    } else {*/
      if (json['individual_users'] != null) {
        individualUsers = <IndividualUsers>[];
        json['individual_users'].forEach((v) {
          individualUsers!.add(new IndividualUsers.fromJson(v));
        });
      }

      pageToken = json['pageToken'];
      direction = json['direction'];
      nextPageExists = json['nextPageExists'];
      counts =
      json['counts'] != null ? new Counts.fromJson(json['counts']) : null;
  //  }
    // if (json['corporate_users'] != null) {
    //   corporateUsers = <Null>[];
    //   json['corporate_users'].forEach((v) {
    //     corporateUsers!.add(null);
    //   });
    // }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['data'] = this.data;
    if (this.individualUsers != null) {
      data['individual_users'] =
          this.individualUsers!.map((v) => v.toJson()).toList();
    }
    // if (this.corporateUsers != null) {
    //   data['corporate_users'] =
    //       this.corporateUsers!.map((v) => v!.toJson()).toList();
    // }
    data['pageToken'] = this.pageToken;
    data['direction'] = this.direction;
    data['nextPageExists'] = this.nextPageExists;
    if (this.counts != null) {
      data['counts'] = this.counts!.toJson();
    }
    return data;
  }
}
/*
class Users {
  List<IndividualUsers>? individualUsers;

  // List<Null>? corporateUsers;
  String? pageToken;
  String? direction;
  bool? nextPageExists;
  Counts? counts;

  Users(
      {this.individualUsers,
      // this.corporateUsers,
      this.pageToken,
      this.direction,
      this.nextPageExists,
      this.counts});

  Users.fromJson(Map<String, dynamic> json) {
    if (json['individual_users'] != null) {
      individualUsers = <IndividualUsers>[];
      json['individual_users'].forEach((v) {
        individualUsers!.add(new IndividualUsers.fromJson(v));
      });
    }
    // if (json['corporate_users'] != null) {
    //   corporateUsers = <Null>[];
    //   json['corporate_users'].forEach((v) {
    //     corporateUsers!.add(null);
    //   });
    // }
    pageToken = json['pageToken'];
    direction = json['direction'];
    nextPageExists = json['nextPageExists'];
    counts =
        json['counts'] != null ? new Counts.fromJson(json['counts']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.individualUsers != null) {
      data['individual_users'] =
          this.individualUsers!.map((v) => v.toJson()).toList();
    }
    // if (this.corporateUsers != null) {
    //   data['corporate_users'] =
    //       this.corporateUsers!.map((v) => v!.toJson()).toList();
    // }
    data['pageToken'] = this.pageToken;
    data['direction'] = this.direction;
    data['nextPageExists'] = this.nextPageExists;
    if (this.counts != null) {
      data['counts'] = this.counts!.toJson();
    }
    return data;
  }
}*/

class IndividualUsers {
  List<Role>? role;
  String? displayName;
  int? rating;
  bool? isIndividual;
  String? email;
  bool? isSelected;

  // List<Null>? requestSent;
  String? displayImageUrl;

  // List<Null>? myAssignee;
  bool? isVerified;
  String? countryCode;
  String? userId;
  String? phone;
  String? name;
  bool? isTrailUser;
  bool? status;

  IndividualUsers(
      {this.role,
      this.displayName,
      this.rating,
      this.isIndividual,
      this.email,
      // this.requestSent,
      this.displayImageUrl,
      // this.myAssignee,
      this.isVerified,
      this.countryCode,
      this.userId,
      this.phone,
      this.name,
      this.isTrailUser,
      this.status, this.isSelected = false});

  IndividualUsers.fromJson(Map<String, dynamic> json) {
    if (json['role'] != null) {
      role = <Role>[];
      json['role'].forEach((v) {
        role!.add(new Role.fromJson(v));
      });
    }
    displayName = json['displayName'];
    rating = json['rating'];
    isIndividual = json['isIndividual'];
    email = json['email'];
    // if (json['request_sent'] != null) {
    //   requestSent = <Null>[];
    //   json['request_sent'].forEach((v) {
    //     requestSent!.add(null);
    //   });
    // }
    displayImageUrl = json['display_image_url'];
    // if (json['my_assignee'] != null) {
    //   myAssignee = <Null>[];
    //   json['my_assignee'].forEach((v) {
    //     myAssignee!.add( null);
    //   });
    // }
    isVerified = json['is_verified'];
    countryCode = json['country_code'];
    userId = json['user_id'];
    phone = json['phone'];
    name = json['name'];
    isTrailUser = json['is_trail_user'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.role != null) {
      data['role'] = this.role!.map((v) => v.toJson()).toList();
    }
    data['displayName'] = this.displayName;
    data['rating'] = this.rating;
    data['isIndividual'] = this.isIndividual;
    data['email'] = this.email;
    // if (this.requestSent != null) {
    //   data['request_sent'] = this.requestSent!.map((v) => v.toJson()).toList();
    // }
    data['display_image_url'] = this.displayImageUrl;
    // if (this.myAssignee != null) {
    //   data['my_assignee'] = this.myAssignee!.map((v) => v.toJson()).toList();
    // }
    data['is_verified'] = this.isVerified;
    data['country_code'] = this.countryCode;
    data['user_id'] = this.userId;
    data['phone'] = this.phone;
    data['name'] = this.name;
    data['is_trail_user'] = this.isTrailUser;
    data['status'] = this.status;
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
  String? id;
  bool? isMultipleRoleEnabled;
  bool? status;

  Role(
      {this.isForIndividual,
      this.isSelectable,
      this.role,
      this.isApplicableForTrial,
      this.name,
      this.description,
      this.isApplicableForInternal,
      this.id,
      this.isMultipleRoleEnabled,
      this.status});

  Role.fromJson(Map<String, dynamic> json) {
    isForIndividual = json['is_for_individual'];
    isSelectable = json['is_selectable'];
    role = json['role'];
    isApplicableForTrial = json['is_applicable_for_trial'];
    name = json['name'];
    description = json['description'];
    isApplicableForInternal = json['is_applicable_for_internal'];
    id = json['id'];
    isMultipleRoleEnabled = json['is_multiple_role_enabled'];
    status = json['status'];
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
    data['id'] = this.id;
    data['is_multiple_role_enabled'] = this.isMultipleRoleEnabled;
    data['status'] = this.status;
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
