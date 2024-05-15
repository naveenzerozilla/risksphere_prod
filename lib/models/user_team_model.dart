class UserTeamModel {
  String? data;
  Users? users;

  UserTeamModel({this.data, this.users});

  UserTeamModel.fromJson(Map<String, dynamic> json) {
    data = json['data'];
    users = json['users'] != null ? Users.fromJson(json['users']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['data'] = this.data;
    if (this.users != null) {
      data['users'] = this.users!.toJson();
    }
    return data;
  }
}

class Users {
  List<Manager?>? myManager;
  List<Reportee?>? myReportee;
  List<Delegate?>? myDeligate;
  List<Reportee?>? myAssignee;

  Users({this.myManager, this.myReportee, this.myDeligate, this.myAssignee});

  Users.fromJson(Map<String, dynamic> json) {
    if (json['my_manager'] != null) {
      myManager = (json['my_manager'] as List?)
          ?.map((manager) => Manager.fromJson(manager))
          .toList() ?? [];
    }
    if (json['my_reportee'] != null) {
      myReportee = (json['my_reportee'] as List?)
          ?.map((reportee) => Reportee.fromJson(reportee))
          .toList() ?? [];
    }
    if (json['my_deligate'] != null) {
      myDeligate = (json['my_deligate'] as List?)
          ?.map((delegate) => Delegate.fromJson(delegate))
          .toList() ?? [];
    }
    if (json['my_assignee'] != null) {
      myAssignee = (json['my_assignee'] as List?)
          ?.map((assignee) => Reportee.fromJson(assignee))
          .toList() ?? [];
    }
  }


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.myManager != null) {
      data['my_manager'] = this.myManager!.map((v) => v?.toJson()).toList();
    }
    if (this.myReportee != null) {
      data['my_reportee'] = this.myReportee!.map((v) => v?.toJson()).toList();
    }
    if (this.myDeligate != null) {
      data['my_deligate'] = this.myDeligate!.map((v) => v?.toJson()).toList();
    }
    if (this.myAssignee != null) {
      data['my_assignee'] = this.myAssignee!.map((v) => v?.toJson()).toList();
    }
    return data;
  }
}

class Manager {
  String? name;
  String? companyTypeName;
  String? email;
  int? rating;
  String? displayImageUrl;
  String? id;
  String? role;

  Manager({this.name, this.companyTypeName, this.email, this.rating, this.displayImageUrl, this.id, this.role});

  Manager.fromJson(Map<String, dynamic>? json) {
    if (json != null) {
      name = json['name'];
      companyTypeName = json['company_type_name'];
      email = json['email'];
      rating = json['rating'];
      displayImageUrl = json['display_image_url'];
      id = json['id'];
      role = json['role'];
    }
  }


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['company_type_name'] = this.companyTypeName;
    data['email'] = this.email;
    data['rating'] = this.rating;
    data['display_image_url'] = this.displayImageUrl;
    data['id'] = this.id;
    data['role'] = this.role;
    return data;
  }
}

class Delegate {
  String? name;
  String? companyTypeName;
  String? email;
  int? rating;
  String? displayImageUrl;
  String? id;
  String? role;

  Delegate({this.name, this.companyTypeName, this.email, this.rating, this.displayImageUrl, this.id, this.role});

  Delegate.fromJson(Map<String, dynamic>? json) {
    if (json != null) {
      name = json['name'];
      companyTypeName = json['company_type_name'];
      email = json['email'];
      rating = json['rating'];
      displayImageUrl = json['display_image_url'];
      id = json['id'];
      role = json['role'];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['company_type_name'] = this.companyTypeName;
    data['email'] = this.email;
    data['rating'] = this.rating;
    data['display_image_url'] = this.displayImageUrl;
    data['id'] = this.id;
    data['role'] = this.role;
    return data;
  }
}


class Reportee {
  String? name;
  String? companyTypeName;
  String? email;
  int? rating;
  String? displayImageUrl;
  String? id;
  String? role;

  Reportee({this.name, this.companyTypeName, this.email, this.rating, this.displayImageUrl, this.id, this.role});

  Reportee.fromJson(Map<String, dynamic>? json) {
    if (json != null) {
      name = json['name'];
      companyTypeName = json['company_type_name'];
      email = json['email'];
      rating = json['rating'];
      displayImageUrl = json['display_image_url'];
      id = json['id'];
      role = json['role'];
    }
  }


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['company_type_name'] = this.companyTypeName;
    data['email'] = this.email;
    data['rating'] = this.rating;
    data['display_image_url'] = this.displayImageUrl;
    data['id'] = this.id;
    data['role'] = this.role;
    return data;
  }
}
