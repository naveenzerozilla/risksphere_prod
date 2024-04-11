class CompanyModel {
  /*
  {
  "companies": [
    {
      "id": "dhcjghcjqghdsdcdsjkk",
      "company_name": "ABC",
      "company_type":"risk_managers",
      "company_type_name": "Risk Managers",
      "admin": {
        "id": "sdhjhfhhsjkdahfjk",
        "name": "admin_name",
        "email": "admin_email@gmail.com",
      "image_url": "https://placeholder.com"
      },
      "status": true
    },
    {
      "id": "dehjkchdeojckejoeocj",
      "company_name": "ABC_2",
      "company_type": "Risk Managers",
      "admin": {
        "name": "admin_name_2",
        "email": "admin_email_2@gmail.com"
      },
      "status": true,
      "image_url": "https://placeholder.com"
    }
  ]
}
  */
  final String name;
  final String displayName;
  final String id;
  final String imageUrl;
  final String type;
  final bool status;
  final Admin admin;

  CompanyModel({
    required this.name,
    required this.displayName,
    required this.id,
    required this.imageUrl,
    required this.type,
    required this.status,
    required this.admin,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      name: json['company_name'],
      displayName: json['company_type_name'],
      id: json['id'],
      imageUrl: json['image_url'],
      type: json['company_type'],
      status: json['status'],
      admin: Admin.fromJson(json['admin']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'company_name': name,
      'company_type_name': displayName,
      'id': id,
      'image_url': imageUrl,
      'company_type': type,
      'status': status,
      'admin': admin.toJson(),
    };
  }

}

class Admin {
  final String name;
  final String email;

  Admin({
    required this.name,
    required this.email,
  });

  factory Admin.fromJson(Map<String, dynamic> json) {
    return Admin(
      name: json['name'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
    };
  }

}