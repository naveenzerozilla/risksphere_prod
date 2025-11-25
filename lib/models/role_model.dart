class RoleModel {
  List<Roles>? roles;

  RoleModel({this.roles});

  RoleModel.fromJson(Map<String, dynamic> json) {
    if (json['roles'] != null) {
      roles = <Roles>[];
      json['roles'].forEach((v) {
        roles!.add(new Roles.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.roles != null) {
      data['roles'] = this.roles!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Roles {
  bool? isForIndividual;
  bool? isMultipleRoleEnabled;
  bool? isApplicableForTrial;
  String? name;
  String? role;
  bool? isApplicableForInternal;
  bool? status;
  String? id;
  int? updatedAt;
  int? createdAt;
  String? description;
  bool? isSelectable;

  Roles(
      {this.isForIndividual,
        this.isMultipleRoleEnabled,
        this.isApplicableForTrial,
        this.name,
        this.role,
        this.isApplicableForInternal,
        this.status,
        this.id,
        this.updatedAt,
        this.createdAt, this.description, this.isSelectable});

  Roles.fromJson(Map<String, dynamic> json) {
    isForIndividual = json['is_for_individual'];
    isMultipleRoleEnabled = json['is_multiple_role_enabled'];
    isApplicableForTrial = json['is_applicable_for_trial'];
    name = json['name'];
    role = json['role'];
    isApplicableForInternal = json['is_applicable_for_internal'];
    status = json['status'];
    id = json['id'];
    updatedAt = json['updated_at'];
    createdAt = json['created_at'];
    description = json['description']??"";
    isSelectable = json['is_selectable']??false;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['is_for_individual'] = this.isForIndividual;
    data['is_multiple_role_enabled'] = this.isMultipleRoleEnabled;
    data['is_applicable_for_trial'] = this.isApplicableForTrial;
    data['name'] = this.name;
    data['role'] = this.role;
    data['is_applicable_for_internal'] = this.isApplicableForInternal;
    data['status'] = this.status;
    data['id'] = this.id;
    data['updated_at'] = this.updatedAt;
    data['created_at'] = this.createdAt;
    data['description'] = this.description;
    data['is_selectable'] = this.isSelectable;
    return data;
  }
}
// class RoleModel1 {
//   final String id;
//   final String role;
//   final String name;
//   final String? description;
//
//   final bool isForIndividual;
//   final bool isSelectable;
//   final bool isApplicableForTrial;
//   final bool isApplicableForInternal;
//   final bool isMultipleRoleEnabled;
//   final bool status;
//
//   final int? trialPeriodDays;
//
//   // final SovOperations? sovOperations;
//
//   RoleModel1({
//     required this.id,
//     required this.role,
//     required this.name,
//     this.description,
//     required this.isForIndividual,
//     required this.isSelectable,
//     required this.isApplicableForTrial,
//     required this.isApplicableForInternal,
//     required this.isMultipleRoleEnabled,
//     required this.status,
//     this.trialPeriodDays,
//     // this.sovOperations,
//   });
//
//   factory RoleModel1.fromJson(Map<String, dynamic> json) {
//     return RoleModel1(
//       id: json['id'] ?? "",
//       role: json['role'] ?? "",
//       name: json['name'] ?? "",
//       description: json['description'] ?? "",
//
//       isForIndividual: json['is_for_individual'] ?? false,
//       isSelectable: json['is_selectable'] ?? false,
//       isApplicableForTrial: json['is_applicable_for_trial'] ?? false,
//       isApplicableForInternal: json['is_applicable_for_internal'] ?? false,
//       isMultipleRoleEnabled: json['is_multiple_role_enabled'] ?? false,
//       status: json['status'] ?? false,
//
//       trialPeriodDays: json['trial_period_days'] ?? 0,
//
//       // sovOperations: json['sov_operations'] != null
//       //     ? SovOperations.fromJson(json['sov_operations'])
//       //     : null,
//     );
//   }
// }

