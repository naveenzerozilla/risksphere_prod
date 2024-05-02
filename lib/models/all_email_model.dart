class AllEmailModel {
  List<Emails>? emails;

  AllEmailModel({this.emails});

  AllEmailModel.fromJson(Map<String, dynamic> json) {
    if (json['emails'] != null) {
      emails = <Emails>[];
      json['emails'].forEach((v) {
        emails!.add(new Emails.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.emails != null) {
      data['emails'] = this.emails!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Emails {
  String? password;
  String? emailType;
  UpdatedAt? updatedAt;
  int? port;
  String? host;
  UpdatedAt? createdAt;
  String? email;
  String? id;

  Emails(
      {this.password,
        this.emailType,
        this.updatedAt,
        this.port,
        this.host,
        this.createdAt,
        this.email,
        this.id});

  Emails.fromJson(Map<String, dynamic> json) {
    password = json['password'];
    emailType = json['email_type'];
    updatedAt = json['updated_at'] != null
        ? new UpdatedAt.fromJson(json['updated_at'])
        : null;
    port = json['port'];
    host = json['host'];
    createdAt = json['created_at'] != null
        ? new UpdatedAt.fromJson(json['created_at'])
        : null;
    email = json['email'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['password'] = this.password;
    data['email_type'] = this.emailType;
    if (this.updatedAt != null) {
      data['updated_at'] = this.updatedAt!.toJson();
    }
    data['port'] = this.port;
    data['host'] = this.host;
    if (this.createdAt != null) {
      data['created_at'] = this.createdAt!.toJson();
    }
    data['email'] = this.email;
    data['id'] = this.id;
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
