class CorporateVerificationListModel {
  String? data;
  List<Company>? company;

  CorporateVerificationListModel({this.data, this.company});

  CorporateVerificationListModel.fromJson(Map<String, dynamic> json) {
    data = json['data'];
    if (json['company'] != null) {
      company = <Company>[];
      json['company'].forEach((v) {
        company!.add(new Company.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['data'] = this.data;
    if (this.company != null) {
      data['company'] = this.company!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Company {
  Admin? admin;
  bool? ignore;
  String? companyName;
  String? companyTypeName;
  String? id;
  CreatedAt? createdAt;

  Company(
      {this.admin,
        this.ignore,
        this.companyName,
        this.companyTypeName,
        this.id, this.createdAt});

  Company.fromJson(Map<String, dynamic> json) {
    admin = json['admin'] != null ? new Admin.fromJson(json['admin']) : null;
    ignore = json['ignore'];
    companyName = json['company_name'];
    companyTypeName = json['company_type_name'];
    id = json['id'];
    createdAt = json['created_at'] != null ? json['created_at'].runtimeType == int?CreatedAt(iSeconds: json['created_at']):new CreatedAt.fromJson(json['created_at']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.admin != null) {
      data['admin'] = this.admin!.toJson();
    }
    if (this.createdAt != null) {
      data['created_at'] = this.createdAt!.toJson();
    }
    data['ignore'] = this.ignore;
    data['company_name'] = this.companyName;
    data['company_type_name'] = this.companyTypeName;
    data['id'] = this.id;
    return data;
  }
}

class Admin {
  String? name;
  String? email;
  String? phone;

  Admin({this.name, this.email, this.phone});

  Admin.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    email = json['email'];
    phone = json['phone'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['email'] = this.email;
    data['phone'] = this.phone;
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

  DateTime toDateTime() {
    return DateTime.fromMillisecondsSinceEpoch(
      (iSeconds ?? 0) * 1000 + (iNanoseconds ?? 0) ~/ 1000000,
      isUtc: true,
    );
  }
}
