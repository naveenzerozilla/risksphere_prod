import 'company_type_model.dart';

class TransferAutocompleteModel {
  final String id;
  final String userid;
  final String displayName;
  final String name;
  final String email;
  final String imageUrl;
  final String phone;
  final String role;
  List<Roles>? roles;
  final bool isEnabled;


  TransferAutocompleteModel({
    required this.id,
    required this.userid,
    required this.displayName,
    required this.name,
    required this.email,
    required this.imageUrl,
    required this.phone,
    required this.role,
    required this.roles,
    required this.isEnabled,
  });

  factory TransferAutocompleteModel.fromJson(Map<String, dynamic> json) {
    return TransferAutocompleteModel(
      id: json['id'] ?? '',
      userid: json['user_id'] ?? '',
      displayName: json['displayName'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      imageUrl: json['display_image_url'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? '',
      roles: json['roles'] != null
          ? List<Roles>.from(json['roles'].map((role) => Roles.fromJson(role)))
          : [],
      isEnabled: json['is_enabled'] ?? false,

    );
  }
}