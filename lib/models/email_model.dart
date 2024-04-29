class EmailModel {
  Email? email;

  EmailModel({this.email});

  EmailModel.fromJson(Map<String, dynamic> json) {
    email = json['email'] != null ? new Email.fromJson(json['email']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.email != null) {
      data['email'] = this.email!.toJson();
    }
    return data;
  }
}

class Email {
  String? password;
  String? emailType;
  UpdatedAt? updatedAt;
  String? port;
  String? host;
  UpdatedAt? createdAt;
  String? email;

  Email(
      {this.password,
        this.emailType,
        this.updatedAt,
        this.port,
        this.host,
        this.createdAt,
        this.email});

  Email.fromJson(Map<String, dynamic> json) {
    password = json['password']??"";
    emailType = json['email_type'];
    updatedAt = json['updated_at'] != null
        ? new UpdatedAt.fromJson(json['updated_at'])
        : null;
    port = json['port']!=null?json['port'].toString():"";
    host = json['host']??"";
    createdAt = json['created_at'] != null
        ? new UpdatedAt.fromJson(json['created_at'])
        : null;
    email = json['email']??"";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['password'] = this.password;
    data['email_type'] = this.emailType;
    if (this.updatedAt != null) {
      data['updated_at'] = this.updatedAt!.toJson();
    }
    if (this.port != null) {
      data['port'] = int.parse(this.port!);
    } else {
      data['port'] = 0;
    }
    data['host'] = this.host;
    if (this.createdAt != null) {
      data['created_at'] = this.createdAt!.toJson();
    }
    data['email'] = this.email;
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
    data['_seconds'] = this.iSeconds;
    data['_nanoseconds'] = this.iNanoseconds;
    return data;
  }
}
