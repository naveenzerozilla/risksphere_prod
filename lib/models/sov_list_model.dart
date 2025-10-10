class SovListModel {
  int? totalRecords;
  int? page;
  int? pageSize;
  List<Result>? result;
  Settings? settings;
  List<Role>? role;
  TotalCountHeader? totalCountHeader;

  SovListModel(
      {this.totalRecords,
      this.page,
      this.pageSize,
      this.result,
      this.settings,
      this.role,
      this.totalCountHeader});

  SovListModel.fromJson(Map<String, dynamic> json) {
    totalRecords = json['totalRecords'];
    page = json['page'];
    pageSize = json['pageSize'];
    if (json['result'] != null) {
      result = <Result>[];
      json['result'].forEach((v) {
        result!.add(new Result.fromJson(v));
      });
    }
    settings = json['settings'] != null
        ? new Settings.fromJson(json['settings'])
        : null;
    if (json['role'] != null) {
      role = <Role>[];
      json['role'].forEach((v) { role!.add(new Role.fromJson(v)); });
    }
    totalCountHeader = json['total_count_header'] != null
        ? new TotalCountHeader.fromJson(json['total_count_header'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['totalRecords'] = this.totalRecords;
    data['page'] = this.page;
    data['pageSize'] = this.pageSize;
    if (this.result != null) {
      data['result'] = this.result!.map((v) => v.toJson()).toList();
    }
    if (this.settings != null) {
      data['settings'] = this.settings!.toJson();
    }
    if (this.role != null) {
      data['role'] = this.role!.map((v) => v.toJson()).toList();
    }
    if (this.totalCountHeader != null) {
      data['total_count_header'] = this.totalCountHeader!.toJson();
    }
    return data;
  }
}

class Result {
  String? sovId;
  Owner? owner;
  String? companyId;
  String? subAccountId;
  String? accountId;
  String? name;
  CreatedAt? createdAt;

  // DataParamIndex? dataParamIndex;
  List<Null>? allDataParameters;
  List<Null>? dataParameters;
  bool? isShared;
  List<String>? accessibleTo;
  SharingStatus? sharingStatus;
  int? locationCount;
  dynamic role;
  String? companyName;

  Result(
      {this.sovId,
      this.owner,
      this.companyId,
      this.subAccountId,
      this.accountId,
      this.name,
      this.createdAt,
      this.allDataParameters,
      this.dataParameters,
      this.isShared,
      this.accessibleTo,
      this.sharingStatus,
      this.locationCount,
        this.role,
      this.companyName});

  Result.fromJson(Map<String, dynamic> json) {
    sovId = json['sov_id'];
    owner = json['owner'] != null ? new Owner.fromJson(json['owner']) : null;
    companyId = json['company_id'];
    subAccountId = json['sub_account_id'];
    accountId = json['account_id'];
    name = json['name'];
    createdAt = json['created_at'] != null
        ? new CreatedAt.fromJson(json['created_at'])
        : null;
    // dataParamIndex = json['data_param_index'] != null ? new DataParamIndex.fromJson(json['data_param_index']) : null;
    // if (json['all_data_parameters'] != null) {
    //   allDataParameters = <Null>[];
    //   json['all_data_parameters'].forEach((v) { allDataParameters!.add(new Null.fromJson(v)); });
    // }
    // if (json['data_parameters'] != null) {
    //   dataParameters = <Null>[];
    //   json['data_parameters'].forEach((v) { dataParameters!.add(new Null.fromJson(v)); });
    // }
    isShared = json['is_shared'];
    accessibleTo = json['accessible_to'].cast<String>();
    sharingStatus = json['sharing_status'] != null
        ? new SharingStatus.fromJson(json['sharing_status'])
        : null;
    locationCount = json['location_count'];
    if (json['role'] != null) {
      role = <Roles>[];
      json['role'].forEach((v) {
        role!.add(new Roles.fromJson(v));
      });
    }
    companyName = json['company_name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['sov_id'] = this.sovId;
    if (this.owner != null) {
      data['owner'] = this.owner!.toJson();
    }
    data['company_id'] = this.companyId;
    data['sub_account_id'] = this.subAccountId;
    data['account_id'] = this.accountId;
    data['name'] = this.name;
    if (this.createdAt != null) {
      data['created_at'] = this.createdAt!.toJson();
    }
    // if (this.dataParamIndex != null) {
    //   data['data_param_index'] = this.dataParamIndex!.toJson();
    // }
    // if (this.allDataParameters != null) {
    //   data['all_data_parameters'] = this.allDataParameters!.map((v) => v.toJson()).toList();
    // }
    // if (this.dataParameters != null) {
    //   data['data_parameters'] = this.dataParameters!.map((v) => v.toJson()).toList();
    // }
    data['is_shared'] = this.isShared;
    data['accessible_to'] = this.accessibleTo;
    if (this.sharingStatus != null) {
      data['sharing_status'] = this.sharingStatus!.toJson();
    }
    data['location_count'] = this.locationCount;
    if (this.role != null) {
      data['role'] = this.role!.map((v) => v.toJson()).toList();
    }
    data['company_name'] = this.companyName;
    return data;
  }
}

class Roles {
  Null? isApplicableForTrial;
  Null? id;
  String? role;
  String? name;
  Null? isMultipleRoleEnabled;
  Null? isForIndividual;

  Roles(
      {this.isApplicableForTrial,
      this.id,
      this.role,
      this.name,
      this.isMultipleRoleEnabled,
      this.isForIndividual});

  Roles.fromJson(Map<String, dynamic> json) {
    isApplicableForTrial = json['is_applicable_for_trial'];
    id = json['id'];
    role = json['role'];
    name = json['name'];
    isMultipleRoleEnabled = json['is_multiple_role_enabled'];
    isForIndividual = json['is_for_individual'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['is_applicable_for_trial'] = this.isApplicableForTrial;
    data['id'] = this.id;
    data['role'] = this.role;
    data['name'] = this.name;
    data['is_multiple_role_enabled'] = this.isMultipleRoleEnabled;
    data['is_for_individual'] = this.isForIndividual;
    return data;
  }
}

class Owner {
  String? date;
  String? name;
  String? id;
  String? email;

  Owner({this.date, this.name, this.id, this.email});

  Owner.fromJson(Map<String, dynamic> json) {
    date = json['date'];
    name = json['name'];
    id = json['id'];
    email = json['email'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['date'] = this.date;
    data['name'] = this.name;
    data['id'] = this.id;
    data['email'] = this.email;
    return data;
  }
}

class CreatedAt {
  int? iSeconds;
  int? iNanoseconds;

  CreatedAt({this.iSeconds, this.iNanoseconds});

  CreatedAt.fromJson(Map<String, dynamic> json) {
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

class SharingStatus {
  WyoNUpPF1DZbdKX3HCKIE7IGjyA3? wyoNUpPF1DZbdKX3HCKIE7IGjyA3;
  Fkdol2eUvvN6HX0EPFQAClhDSgv1? fkdol2eUvvN6HX0EPFQAClhDSgv1;

  SharingStatus(
      {this.wyoNUpPF1DZbdKX3HCKIE7IGjyA3, this.fkdol2eUvvN6HX0EPFQAClhDSgv1});

  SharingStatus.fromJson(Map<String, dynamic> json) {
    wyoNUpPF1DZbdKX3HCKIE7IGjyA3 = json['WyoNUpPF1DZbdKX3HCKIE7IGjyA3'] != null
        ? new WyoNUpPF1DZbdKX3HCKIE7IGjyA3.fromJson(
            json['WyoNUpPF1DZbdKX3HCKIE7IGjyA3'])
        : null;
    fkdol2eUvvN6HX0EPFQAClhDSgv1 = json['fkdol2eUvvN6HX0EPFQAClhDSgv1'] != null
        ? new Fkdol2eUvvN6HX0EPFQAClhDSgv1.fromJson(
            json['fkdol2eUvvN6HX0EPFQAClhDSgv1'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.wyoNUpPF1DZbdKX3HCKIE7IGjyA3 != null) {
      data['WyoNUpPF1DZbdKX3HCKIE7IGjyA3'] =
          this.wyoNUpPF1DZbdKX3HCKIE7IGjyA3!.toJson();
    }
    if (this.fkdol2eUvvN6HX0EPFQAClhDSgv1 != null) {
      data['fkdol2eUvvN6HX0EPFQAClhDSgv1'] =
          this.fkdol2eUvvN6HX0EPFQAClhDSgv1!.toJson();
    }
    return data;
  }
}

class WyoNUpPF1DZbdKX3HCKIE7IGjyA3 {
  String? userId;
  String? status;
  String? comment;
  Role? role;
  CreatedAt? updatedAt;
  String? updatedBy;
  String? user;

  WyoNUpPF1DZbdKX3HCKIE7IGjyA3(
      {this.userId,
      this.status,
      this.comment,
      this.role,
      this.updatedAt,
      this.updatedBy,
      this.user});

  WyoNUpPF1DZbdKX3HCKIE7IGjyA3.fromJson(Map<String, dynamic> json) {
    userId = json['user_id'];
    status = json['status'];
    comment = json['comment'];
    role = json['role'] != null ? new Role.fromJson(json['role']) : null;
    updatedAt = json['updated_at'] != null
        ? new CreatedAt.fromJson(json['updated_at'])
        : null;
    updatedBy = json['updated_by'];
    user = json['user'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['user_id'] = this.userId;
    data['status'] = this.status;
    data['comment'] = this.comment;
    if (this.role != null) {
      data['role'] = this.role!.toJson();
    }
    if (this.updatedAt != null) {
      data['updated_at'] = this.updatedAt!.toJson();
    }
    data['updated_by'] = this.updatedBy;
    data['user'] = this.user;
    return data;
  }
}

class Role {
  String? roleId;
  String? roleName;
  bool? isForIndividual;
  bool? isSelectable;
  bool? isApplicableForTrial;
  String? role;
  String? name;
  String? description;
  bool? isApplicableForInternal;
  int? trialPeriodDays;
  bool? isMultipleRoleEnabled;
  bool? status;

  Role(
      {this.roleId,
      this.isForIndividual,
      this.isSelectable,
      this.isApplicableForTrial,
      this.role,
      this.name,
      this.description,
      this.isApplicableForInternal,
      this.trialPeriodDays,
      this.isMultipleRoleEnabled,
      this.status,
      this.roleName});

  Role.fromJson(Map<String, dynamic> json) {
    roleId = json['role_id'];
    roleName = json['role_name'];
    isForIndividual = json['is_for_individual'];
    isSelectable = json['is_selectable'];
    isApplicableForTrial = json['is_applicable_for_trial'];
    role = json['role'];
    name = json['name'];
    description = json['description'];
    isApplicableForInternal = json['is_applicable_for_internal'];
    trialPeriodDays = json['trial_period_days'];
    isMultipleRoleEnabled = json['is_multiple_role_enabled'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['role_id'] = this.roleId;
    data['role_name'] = this.roleName;
    data['is_for_individual'] = this.isForIndividual;
    data['is_selectable'] = this.isSelectable;
    data['is_applicable_for_trial'] = this.isApplicableForTrial;
    data['role'] = this.role;
    data['name'] = this.name;
    data['description'] = this.description;
    data['is_applicable_for_internal'] = this.isApplicableForInternal;
    data['trial_period_days'] = this.trialPeriodDays;
    data['is_multiple_role_enabled'] = this.isMultipleRoleEnabled;
    data['status'] = this.status;
    return data;
  }
}

class Fkdol2eUvvN6HX0EPFQAClhDSgv1 {
  String? status;
  String? comment;
  String? user;

  Fkdol2eUvvN6HX0EPFQAClhDSgv1({this.status, this.comment, this.user});

  Fkdol2eUvvN6HX0EPFQAClhDSgv1.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    comment = json['comment'];
    user = json['user'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['comment'] = this.comment;
    data['user'] = this.user;
    return data;
  }
}

class Settings {
  bool? locationCount;
  bool? overAllScore;

  Settings({this.locationCount, this.overAllScore});

  Settings.fromJson(Map<String, dynamic> json) {
    locationCount = json['location_count'];
    overAllScore = json['over_all_score'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['location_count'] = this.locationCount;
    data['over_all_score'] = this.overAllScore;
    return data;
  }
}

class TotalCountHeader {
  int? my;
  int? shared;
  int? received;
  int? all;

  TotalCountHeader({this.my, this.shared, this.received, this.all});

  TotalCountHeader.fromJson(Map<String, dynamic> json) {
    my = json['my'];
    shared = json['shared'];
    received = json['received'];
    all = json['all'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['my'] = this.my;
    data['shared'] = this.shared;
    data['received'] = this.received;
    data['all'] = this.all;
    return data;
  }
}
