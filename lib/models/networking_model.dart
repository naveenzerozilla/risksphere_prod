class NetworkingModel {
  String? data;
  List<NetworkingUsers>? users;

  NetworkingModel({this.data, this.users});

  NetworkingModel.fromJson(Map<String, dynamic> json) {
    data = json['data'];
    if (json['users'] != null) {
      users = <NetworkingUsers>[];
      json['users'].forEach((v) {
        users!.add(NetworkingUsers.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['data'] = this.data;
    if (this.users != null) {
      data['users'] = this.users!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class NetworkingUsers {
  String? name;
  String? email;
  String? displayName;
  bool? isIndividual;
  String? displayImageUrl;
  bool? status;
  List<String>? role;
  String? phone;
  String? countryCode;
  String? companyTypeName;
  int? rating;
  String? objectID;
  String? id;
  String? companyName;

  NetworkingUsers(
      {this.name,
        this.email,
        this.displayName,
        this.isIndividual,
        this.displayImageUrl,
        this.status,
        this.role,
        this.phone,
        this.countryCode,
        this.companyTypeName,
        this.rating,
        this.objectID,
        this.id,
        this.companyName});

  NetworkingUsers.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    email = json['email'];
    displayName = json['displayName'];
    isIndividual = json['isIndividual'];
    displayImageUrl = json['display_image_url'];
    status = json['status'];
    if (json['role'] != null) {
      role = json['role'].cast<String>();
    }
    phone = json['phone'];
    countryCode = json['country_code'];
    companyTypeName = json['company_type_name'];
    rating = json['rating'];
    objectID = json['objectID'];
    id = json['id'];
    companyName = json['company_name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['email'] = this.email;
    data['displayName'] = this.displayName;
    data['isIndividual'] = this.isIndividual;
    data['display_image_url'] = this.displayImageUrl;
    data['status'] = this.status;
    data['role'] = this.role;
    data['phone'] = this.phone;
    data['country_code'] = this.countryCode;
    data['company_type_name'] = this.companyTypeName;
    data['rating'] = this.rating;
    data['objectID'] = this.objectID;
    data['id'] = this.id;
    data['company_name'] = this.companyName;
    return data;
  }
}
