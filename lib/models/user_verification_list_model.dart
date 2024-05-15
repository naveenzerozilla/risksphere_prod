class UserVerificationListModel {
  String? data;
  List<Users>? users;

  UserVerificationListModel({this.data, this.users});

  UserVerificationListModel.fromJson(Map<String, dynamic> json) {
    data = json['data'];
    if (json['users'] != null) {
      users = <Users>[];
      json['users'].forEach((v) {
        users!.add(new Users.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['data'] = this.data;
    if (this.users != null) {
      data['users'] = this.users!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Users {
  String? name;
  String? email;
  String? role;
  String? phone;
  String? id;
  CreatedAt? createdAt;

  Users(
      {this.name, this.email, this.role, this.phone, this.id, this.createdAt});

  Users.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    email = json['email'];
    role = json['role'];
    phone = json['phone'];
    id = json['id'];
    if (json['created_at'] != null) {
      createdAt = new CreatedAt.fromJson(json['created_at'] );
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['email'] = this.email;
    data['role'] = this.role;
    data['phone'] = this.phone;
    data['id'] = this.id;
    data['created_at'] = this.createdAt;
    if (this.createdAt != null) {
      data['created_at'] = this.createdAt!.toJson();
    }
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