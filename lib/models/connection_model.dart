class ConnectionModel {
  String? data;
  ConnectionUsers? users;

  ConnectionModel({this.data, this.users});

  ConnectionModel.fromJson(Map<String, dynamic> json) {
    data = json['data'];
    users = json['users'] != null ? new ConnectionUsers.fromJson(json['users']) : null;
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

class ConnectionUsers {
  List<CorporateConnection>? corporate;
  List<NonCorporateConnection>? nonCorporate;
  int? totalConnections;
  int? requestReceivedCount;

  ConnectionUsers(
      {this.corporate,
        this.nonCorporate,
        this.totalConnections,
        this.requestReceivedCount});

  ConnectionUsers.fromJson(Map<String, dynamic> json) {
    if (json['corporate'] != null) {
      corporate = <CorporateConnection>[];
      json['corporate'].forEach((v) {
        corporate!.add(new CorporateConnection.fromJson(v));
      });
    }
    if (json['non-corporate'] != null) {
      nonCorporate = <NonCorporateConnection>[];
      json['non-corporate'].forEach((v) {
        nonCorporate!.add(new NonCorporateConnection.fromJson(v));
      });
    }
    totalConnections = json['total_connections'];
    requestReceivedCount = json['request_received_count'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.corporate != null) {
      data['corporate'] = this.corporate!.map((v) => v.toJson()).toList();
    }
    if (this.nonCorporate != null) {
      data['non-corporate'] =
          this.nonCorporate!.map((v) => v.toJson()).toList();
    }
    data['total_connections'] = this.totalConnections;
    data['request_received_count'] = this.requestReceivedCount;
    return data;
  }
}

class CorporateConnection {
  String? name;
  String? companyTypeName;
  String? companyName;
  List<String>? role;
  int? rating;
  String? id;
  String? displayImageUrl;
  bool? requestPending;

  CorporateConnection(
      {this.name,
        this.companyTypeName,
        this.companyName,
        this.role,
        this.rating,
        this.id,
        this.displayImageUrl,
        this.requestPending});

  CorporateConnection.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    companyTypeName = json['company_type_name'];
    companyName = json['company_name'];
    if(json['role'] != null){
      role = json['role'].cast<String>();
    }
    rating = json['rating'];
    id = json['id'];
    displayImageUrl = json['display_image_url'];
    requestPending = json['request_pending'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['company_type_name'] = this.companyTypeName;
    data['company_name'] = this.companyName;
    data['role'] = this.role;
    data['rating'] = this.rating;
    data['id'] = this.id;
    data['display_image_url'] = this.displayImageUrl;
    data['request_pending'] = this.requestPending;
    return data;
  }
}

class NonCorporateConnection {
  String? name;
  String? companyTypeName;
  String? companyName;
  List<String>? role;
  int? rating;
  String? id;
  String? displayImageUrl;
  bool? requestPending;

  NonCorporateConnection(
      {this.name,
        this.companyTypeName,
        this.companyName,
        this.role,
        this.rating,
        this.id,
        this.displayImageUrl,
        this.requestPending});

  NonCorporateConnection.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    companyTypeName = json['company_type_name'];
    companyName = json['company_name'];
    if(json['role'] != null) {
      role = json['role'].cast<String>();
    }
    rating = json['rating'];
    id = json['id'];
    displayImageUrl = json['display_image_url'];
    requestPending = json['request_pending'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['company_type_name'] = this.companyTypeName;
    data['company_name'] = this.companyName;
    data['role'] = this.role;
    data['rating'] = this.rating;
    data['id'] = this.id;
    data['display_image_url'] = this.displayImageUrl;
    data['request_pending'] = this.requestPending;
    return data;
  }
}
