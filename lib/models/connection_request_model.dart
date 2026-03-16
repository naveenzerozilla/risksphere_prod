class ConnectionRequestModel {
  String? data;
  ConnectionRequestUsers? users;

  ConnectionRequestModel({this.data, this.users});

  ConnectionRequestModel.fromJson(Map<String, dynamic> json) {
    data = json['data'];
    users = json['users'] != null ? new ConnectionRequestUsers.fromJson(json['users']) : null;
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

class ConnectionRequestUsers {
  List<RequestUser>? users;
  int? totalConnections;
  int? requestReceivedCount;

  ConnectionRequestUsers({this.users, this.totalConnections, this.requestReceivedCount});

  ConnectionRequestUsers.fromJson(Map<String, dynamic> json) {
    if (json['users'] != null) {
      users = <RequestUser>[];
      json['users'].forEach((v) {
        users!.add(new RequestUser.fromJson(v));
      });
    }
    totalConnections = json['total_connections'];
    requestReceivedCount = json['request_received_count'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.users != null) {
      data['users'] = this.users!.map((v) => v.toJson()).toList();
    }
    data['total_connections'] = this.totalConnections;
    data['request_received_count'] = this.requestReceivedCount;
    return data;
  }
}

class RequestUser {
  String? name;
  String? companyTypeName;
  String? companyName;
  String? id;
  String? displayImageUrl;
  String? message;
  bool? requestPending;
  dynamic role;

  RequestUser(
      {this.name,
        this.companyTypeName,
        this.companyName,
        this.id,
        this.displayImageUrl,
        this.message,
        this.requestPending,
        this.role});

  RequestUser.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    companyTypeName = json['company_type_name'];
    companyName = json['company_name'];
    id = json['id'];
    displayImageUrl = json['display_image_url'];
    message = json['message'];
    requestPending = json['request_pending'];
    if(json['role'] != null) {
      role = json['role'];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['company_type_name'] = this.companyTypeName;
    data['company_name'] = this.companyName;
    data['id'] = this.id;
    data['display_image_url'] = this.displayImageUrl;
    data['message'] = this.message;
    data['request_pending'] = this.requestPending;
    data['role'] = this.role;
    return data;
  }
}
