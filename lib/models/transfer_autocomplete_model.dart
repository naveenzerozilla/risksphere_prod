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
  bool? isIndividual;
  bool? belongsToCompany;
  bool? isConnected;
  bool? trailUser;
  LastSelectedRole? lastSelectedRole;

  TransferAutocompleteModel(
      {required this.id,
      required this.userid,
      required this.displayName,
      required this.name,
      required this.email,
      required this.imageUrl,
      required this.phone,
      required this.role,
      required this.roles,
      required this.isEnabled,
      this.isIndividual,
      this.belongsToCompany,
      this.isConnected,
      this.trailUser,
      this.lastSelectedRole,
      });

  factory TransferAutocompleteModel.fromJson(Map<String, dynamic> json) {
    List<Roles> parsedRoles = [];

    //  Case 1: roles field exists
    if (json['roles'] != null) {
      if (json['roles'] is List) {
        parsedRoles =
            (json['roles'] as List).map((e) => Roles.fromJson(e)).toList();
      } else if (json['roles'] is Map) {
        parsedRoles = [Roles.fromJson(json['roles'])];
      }
    }

    //  Case 2: only role string exists (fallback)
    else if (json['role'] != null && json['role'] is String) {
      parsedRoles = [
        Roles(
          role: json['role'],
          name: json['role'],
        )
      ];

    }

    return TransferAutocompleteModel(
      id: json['id'] ?? '',
      userid: json['user_id'] ?? '',
      displayName: json['displayName'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      imageUrl: json['display_image_url'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? '',
      roles: parsedRoles,
      isEnabled: json['is_enabled'] ?? false,
      isIndividual: json['isIndividual'],
      belongsToCompany: json['belongs_to_company'],
      isConnected: json['is_connected'],
      trailUser: json['is_trail_user'],
      lastSelectedRole: json['last_selected_role'] != null
          ? LastSelectedRole.fromJson(json['last_selected_role'])
          : null,
    );
  }
}
class LastSelectedRole {
  String? name;
  String? role;

  LastSelectedRole({this.name, this.role});

  LastSelectedRole.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    role = json['role'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['role'] = this.role;
    return data;
  }
}