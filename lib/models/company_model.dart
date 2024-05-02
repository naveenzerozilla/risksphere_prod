class CompanyModel {
  String? data;
  List<Companies>? companies;

  CompanyModel({this.data, this.companies});

  CompanyModel.fromJson(Map<String, dynamic> json) {
    data = json['data'];
    if (json['companies'] != null) {
      companies = <Companies>[];
      json['companies'].forEach((v) {
        companies!.add(new Companies.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['data'] = this.data;
    if (this.companies != null) {
      data['companies'] = this.companies!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Companies {
  String? companyType;
  String? companyTypeName;
  List<String>? domainList;
  String? displayName;
  String? companyImageUrl;
  bool? isEnabled;
  UpdatedAt? updatedAt;
  String? name;
  Admins? admins;
  bool? status;
  String? id;
  bool? isSelected = false;
  bool? enableDomainCheck;

  Companies(
      {this.companyType,
        this.companyTypeName,
        this.domainList,
        this.displayName,
        this.companyImageUrl,
        this.isEnabled,
        this.updatedAt,
        this.name,
        this.admins,
        this.status,
        this.id, this.isSelected,
        this.enableDomainCheck});

  Companies.fromJson(Map<String, dynamic> json) {
    companyType = json['company_type'];
    companyTypeName = json['company_type_name'];
    domainList = List<String>.from(json['domain_list'] ?? []);
    displayName = json['company_display_name'];
    companyImageUrl = json['company_image_url'];
    isEnabled = json['is_enabled'];
    updatedAt = json['updated_at'] != null
        ? UpdatedAt.fromJson(json['updated_at'])
        : null;
    name = json['company_name'];
    admins =
    json['admins'] != null ? Admins.fromJson(json['admins']) : null;
    status = json['status'];
    id = json['id'];
    enableDomainCheck = json['enable_domain_check'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['company_type'] = companyType;
    data['company_type_name'] = companyTypeName;
    data['domain_list'] = domainList;
    data['company_display_name'] = displayName;
    data['company_image_url'] = companyImageUrl;
    data['is_enabled'] = isEnabled;
    if (updatedAt != null) {
      data['updated_at'] = updatedAt!.toJson();
    }
    data['company_name'] = name;
    if (admins != null) {
      data['admins'] = admins!.toJson();
    }
    data['status'] = status;
    data['enable_domain_check'] = enableDomainCheck;
    data['id'] = id;
    return data;
  }
}

class UpdatedAt {
  int? iSeconds;
  int? iNanoseconds;

  UpdatedAt({this.iSeconds, this.iNanoseconds});

  UpdatedAt.fromJson(Map<String, dynamic> json) {
    iSeconds = json['_seconds'];
    iNanoseconds = json['_nanoseconds'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_seconds'] = iSeconds;
    data['_nanoseconds'] = iNanoseconds;
    return data;
  }
}

class Admins {
  String? name;
  String? displayName;
  String? email;
  String? userId;
  String? mobile;
  String? countryCode;

  Admins({this.name, this.displayName, this.email, this.userId, this.mobile, this.countryCode});

  Admins.fromJson(Map<String, dynamic> json) {
    name = json['name'];

    displayName = json['displayName']??"";
    email = json['email'];
    userId = json['user_id'];
    mobile = json['phone']??"";
    countryCode = json['country_code']??"";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = name;
    data['displayName'] = displayName;
    data['email'] = email;
    data['user_id'] = userId;
    data['phone'] = mobile;
    data['country_code'] = countryCode;
    return data;
  }
}
