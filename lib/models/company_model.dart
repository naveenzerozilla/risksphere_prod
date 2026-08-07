class CompanyModel {
  String? data;
  List<Companies>? companies;

  String? pageToken;
  String? direction;
  bool? nextPageExists;

  CompanyModel({this.data, this.companies});

  CompanyModel.fromJson(Map<String, dynamic> json) {
    data = json['data'];
    if (json['companies'] != null) {
      companies = <Companies>[];
      json['companies'].forEach((v) {
        companies!.add(new Companies.fromJson(v));
      });
    }
    if (json['pageToken'] != null) {
      pageToken = json['pageToken'];
    }
    if (json['direction'] != null) {
      direction = json['direction'];
    }
    if (json['nextPageExists'] != null) {
      nextPageExists = json['nextPageExists'];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['data'] = this.data;
    if (this.companies != null) {
      data['companies'] = this.companies!.map((v) => v.toJson()).toList();
    }
    if (this.pageToken != null) {
      data['pageToken'] = this.pageToken;
    }
    if (this.direction != null) {
      data['direction'] = this.direction;
    }
    if (this.nextPageExists != null) {
      data['nextPageExists'] = this.nextPageExists;
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

  //Admins? admins;
  bool? status;
  String? id;
  bool? isSelected = false;
  bool? enableDomainCheck;
  String? countryName;
  String? adminName;
  String? adminEmail;
  String? adminMobile;
  String? adminCountryCode;
  List<CorporateAdmins>? admins = [];

  Companies({
    this.companyType,
    this.companyTypeName,
    this.domainList,
    this.displayName,
    this.companyImageUrl,
    this.isEnabled,
    this.updatedAt,
    this.name,
    //this.admins,
    this.status,
    this.id,
    this.isSelected,
    this.enableDomainCheck,
    this.countryName,
    this.adminName,
    this.adminEmail,
    this.adminMobile,
    this.adminCountryCode,
    this.admins,
  });

  Companies.fromJson(Map<String, dynamic> json) {
    companyType = json['company_type'];
    companyTypeName = json['company_type_name'];
    domainList = List<String>.from(json['domain_list'] ?? []);
    displayName = json['company_display_name'];
    companyImageUrl = json['display_image_url'];
    isEnabled = json['is_enabled'];

    name = json['company_name'];
/*    admins =
    json['admins'] != null ? Admins.fromJson(json['admins']) : null;*/
    status = json['status'];
    id = json['id'];
    enableDomainCheck = json['enable_domain_check'];
    if (json['country'] == null) {
      countryName = "";
    } else if (json['country'].runtimeType == String) {
      countryName = json['country'];
    } else {
      countryName = json['country']['name'];
    }
    adminName = json['admin_name'];
    adminEmail = json['admin_email'];
    adminMobile = json['admin_phone'];
    adminCountryCode = json['admin_country_code'];
    if (json['admins'] != null) {
      admins = <CorporateAdmins>[];
      json['admins'].forEach((v) {
        admins!.add(new CorporateAdmins.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['company_type'] = companyType;
    data['company_type_name'] = companyTypeName;
    data['domain_list'] = domainList;
    data['company_display_name'] = displayName;
    data['display_image_url'] = companyImageUrl;
    data['is_enabled'] = isEnabled;
    if (updatedAt != null) {
      data['updated_at'] = updatedAt!.toJson();
    }
    data['company_name'] = name;
    /*if (admins != null) {
      data['admins'] = admins!.toJson();
    }*/
    data['status'] = status;
    data['enable_domain_check'] = enableDomainCheck;
    data['id'] = id;
    data['country'] = countryName;
    data['admin_name'] = adminName;
    data['admin_email'] = adminEmail;
    data['admin_phone'] = adminMobile;
    data['admin_country_code'] = adminCountryCode;
    if (admins != null) {
      data['admins'] = admins!.map((v) => v.toJson()).toList();
    }
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

class CorporateAdmins {
  String? name;
  String? displayName;
  String? email;
  String? userId;
  String? mobile;
  String? countryCode;
  String? imageUrl;

  CorporateAdmins(
      {this.name,
      this.displayName,
      this.email,
      this.userId,
      this.mobile,
      this.countryCode,
      this.imageUrl});

  CorporateAdmins.fromJson(Map<String, dynamic> json) {
    name = json['name'];

    displayName = json['displayName'] ?? "";
    email = json['email'];
    userId = json['user_id'];
    mobile = json['phone'] ?? "";
    countryCode = json['country_code'] ?? "";
    imageUrl = json['display_image_url'] ?? "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = name;
    data['displayName'] = displayName;
    data['email'] = email;
    data['user_id'] = userId;
    data['phone'] = mobile;
    data['country_code'] = countryCode;
    data['display_image_url'] = imageUrl;
    return data;
  }

  @override
  toString() {
    return 'Admins(name: $name, displayName: $displayName, email: $email, userId: $userId, mobile: $mobile, countryCode: $countryCode, imageUrl: $imageUrl)';
  }
}
