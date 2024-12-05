class DashboardModel {
  int? max;
  List<CompanyType>? companyType;
  List<DashboardRoles>? roles;
  Signups? signups;
  int? verificationCount;
  String? rolePercent;
  String? companyPercent;
  int? requests;
  int? companyUserLeadCount;

  DashboardModel(
      {this.max,
        this.companyType,
        this.roles,
        this.signups,
        this.verificationCount, this.rolePercent, this.companyPercent, this.requests, this.companyUserLeadCount});

  DashboardModel.fromJson(Map<String, dynamic> json) {
    max = json['max']??0;
    if (json['company_type'] != null) {
      companyType = <CompanyType>[];
      json['company_type'].forEach((v) {
        companyType!.add(new CompanyType.fromJson(v));
      });
    }
    if (json['roles'] != null) {
      roles = <DashboardRoles>[];
      json['roles'].forEach((v) {
        roles!.add(new DashboardRoles.fromJson(v));
      });
    }
    signups =
    json['signups'] != null ? new Signups.fromJson(json['signups']) : null;
    verificationCount = json['verification_count']??0;
    rolePercent = json['role_percent'];
    companyPercent = json['company_percent'];
    requests = json['request']??0;
    if(json['company_user_lead_count'] is int) {
      companyUserLeadCount = json['company_user_lead_count']??0;
    } else {
      companyUserLeadCount = 0;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['max'] = this.max;
    if (this.companyType != null) {
      data['company_type'] = this.companyType!.map((v) => v.toJson()).toList();
    }
    if (this.roles != null) {
      data['roles'] = this.roles!.map((v) => v.toJson()).toList();
    }
    if (this.signups != null) {
      data['signups'] = this.signups!.toJson();
    }
    data['verification_count'] = this.verificationCount;
    data['role_percent'] = this.rolePercent;
    data['company_percent'] = this.companyPercent;
    data['requests'] = this.requests;
    data['company_user_lead_count'] = this.companyUserLeadCount;
    return data;
  }
}

class CompanyType {
  String? name;
  String? id;
  int? count;

  CompanyType({this.name, this.id, this.count});

  CompanyType.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    id = json['id'];
    count = json['count']??0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['id'] = this.id;
    data['count'] = this.count;
    return data;
  }
}

class Signups {
  Current? current;
  Current? past;

  Signups({this.current, this.past});

  Signups.fromJson(Map<String, dynamic> json) {
    current =
    json['current'] != null ? new Current.fromJson(json['current']) : null;
    past = json['past'] != null ? new Current.fromJson(json['past']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.current != null) {
      data['current'] = this.current!.toJson();
    }
    if (this.past != null) {
      data['past'] = this.past!.toJson();
    }
    return data;
  }
}

class Current {
  int? signup;
  int? csignup;

  Current({this.signup, this.csignup});

  Current.fromJson(Map<String, dynamic> json) {
    signup = json['signup']??0;
    csignup = json['csignup']??0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['signup'] = this.signup;
    data['csignup'] = this.csignup;
    return data;
  }
}

class DashboardRoles {
  String? name;
  int? count;
  String? id;

  DashboardRoles({this.name, this.count, this.id});

  DashboardRoles.fromJson(Map<String, dynamic> json) {
    name = json['name']??"";
    count = json['count']??0;
    id = json['id']??"";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['count'] = this.count;
    data['id'] = this.id;
    return data;
  }
}
