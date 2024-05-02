class EmployeeListModel {
  String? data;
  Users? users;

  EmployeeListModel({this.data, this.users});

  EmployeeListModel.fromJson(Map<String, dynamic> json) {
    data = json['data'];
    users = json['users'] != null ? new Users.fromJson(json['users']) : null;
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
  List<Employees>? employees;
  Counts? counts;

  Users({this.employees, this.counts});

  Users.fromJson(Map<String, dynamic> json) {
    if (json['employees'] != null) {
      employees = <Employees>[];
      json['employees'].forEach((v) {
        employees!.add(new Employees.fromJson(v));
      });
    }
    counts =
    json['counts'] != null ? new Counts.fromJson(json['counts']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.employees != null) {
      data['employees'] = this.employees!.map((v) => v.toJson()).toList();
    }
    if (this.counts != null) {
      data['counts'] = this.counts!.toJson();
    }
    return data;
  }
}

class Employees {
  String? name;
  String? role;
  bool? status;
  String? email;
  String? displayImageUrl;
  String? id;
  String? phone;
  bool isSelected = false;

  Employees(
      {this.name,
        this.role,
        this.status,
        this.email,
        this.displayImageUrl,
        this.id,
        this.phone, this.isSelected = false});

  Employees.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    role = json['role'];
    status = json['status'];
    email = json['email'];
    displayImageUrl = json['display_image_url'];
    id = json['id'];
    phone = json['phone'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['role'] = this.role;
    data['status'] = this.status;
    data['email'] = this.email;
    data['display_image_url'] = this.displayImageUrl;
    data['id'] = this.id;
    data['phone'] = this.phone;
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
