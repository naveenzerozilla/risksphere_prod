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

