

import 'package:RiskSphere/models/role_model.dart';

class ViewEmployeeModel {
  String? data;
  Employee? user;

  ViewEmployeeModel({this.data, this.user});

  ViewEmployeeModel.fromJson(Map<String, dynamic> json) {
    data = json['data'];
    user = json['user'] != null ? new Employee.fromJson(json['user']) : null;
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

class Employee {
  String? displayName;
  int? rating;
  int? createdAt;
  bool? isIndividual;
  String? email;
  String? companyId;
  bool? isVerified;
  String? userId;
  String? phone;
  String? name;
  bool? status;
  String? countryCode;
  List<Roles>? role;
  String? displayImageUrl;

  Employee(
      {this.displayName,
        this.rating,
        this.createdAt,
        this.isIndividual,
        this.email,
        this.companyId,
        this.isVerified,
        this.userId,
        this.phone,
        this.name,
        this.status,
        this.countryCode,
        this.role,
        this.displayImageUrl});

  Employee.fromJson(Map<String, dynamic> json) {
    displayName = json['displayName'];
    rating = json['rating'];
    isIndividual = json['isIndividual'];
    email = json['email'];
    companyId = json['company_id'];

    isVerified = json['is_verified'];
    userId = json['user_id'];
    phone = json['phone'];
    name = json['name'];
    status = json['status'];
    countryCode = json['country_code'];
    if (json['role'] != null) {
      role = <Roles>[];
      json['role'].forEach((v) {
        role!.add(new Roles.fromJson(v));
      });
    }
    displayImageUrl = json['display_image_url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['displayName'] = this.displayName;
    data['rating'] = this.rating;
    data['created_at'] = this.createdAt;
    data['isIndividual'] = this.isIndividual;
    data['email'] = this.email;
    data['company_id'] = this.companyId;

    data['is_verified'] = this.isVerified;
    data['user_id'] = this.userId;
    data['phone'] = this.phone;
    data['name'] = this.name;
    data['status'] = this.status;
    data['country_code'] = this.countryCode;
    if (this.role != null) {
      data['role'] = this.role!.map((v) => v.toJson()).toList();
    }
    data['display_image_url'] = this.displayImageUrl;
    return data;
  }
}

