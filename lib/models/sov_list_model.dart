import 'my_location_list_model.dart';

class SovListModel {
  int? totalRecords;
  int? page;
  int? pageSize;
  List<Result>? result;
  Settings? settings;
  List<Role>? role;
  TotalCountHeader? totalCountHeader;

  SovListModel({
    this.totalRecords,
    this.page,
    this.pageSize,
    this.result,
    this.settings,
    this.role,
    this.totalCountHeader,
  });

  SovListModel.fromJson(Map<String, dynamic> json) {
    totalRecords = json['totalRecords'] is int ? json['totalRecords'] : 0;
    page = json['page'] is int ? json['page'] : 1;
    pageSize = json['pageSize'] is int ? json['pageSize'] : 0;

    // ✅ Safe 'result' parsing
    if (json['result'] is List) {
      result = (json['result'] as List)
          .whereType<Map<String, dynamic>>() // ensures each item is a Map
          .map((v) => Result.fromJson(v))
          .toList();
    } else {
      result = [];
    }

    // ✅ Safe 'settings' parsing
    settings = (json['settings'] is Map<String, dynamic>)
        ? Settings.fromJson(json['settings'])
        : null;

    // ✅ Safe 'role' parsing
    role = [];
    final roleData = json['role'];
    if (roleData != null && roleData is! bool) {
      if (roleData is List) {
        for (var v in roleData) {
          if (v is Map<String, dynamic>) {
            role!.add(Role.fromJson(v));
          }
        }
      } else if (roleData is Map<String, dynamic>) {
        // Sometimes role is an object instead of a list
        roleData.forEach((k, v) {
          if (v is Map<String, dynamic>) {
            role!.add(Role.fromJson(v));
          }
        });
      }
    }

    // ✅ Safe 'total_count_header' parsing
    totalCountHeader = (json['total_count_header'] is Map<String, dynamic>)
        ? TotalCountHeader.fromJson(json['total_count_header'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['totalRecords'] = totalRecords ?? 0;
    data['page'] = page ?? 1;
    data['pageSize'] = pageSize ?? 0;

    data['result'] = result?.map((v) => v.toJson()).toList() ?? [];
    if (settings != null) data['settings'] = settings!.toJson();
    data['role'] = role?.map((v) => v.toJson()).toList() ?? [];
    if (totalCountHeader != null) {
      data['total_count_header'] = totalCountHeader!.toJson();
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
  String? status;
  SovGraphData? sovGraphData;
  TotalDataCompleteness? totalDataCompleteness;

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
      this.companyName,
      this.status,
      this.sovGraphData,
      this.totalDataCompleteness});

  Result.fromJson(Map<String, dynamic> json) {
    sovId = json['sov_id'];
    owner = json['owner'] != null ? Owner.fromJson(json['owner']) : null;
    companyId = json['company_id'];
    subAccountId = json['sub_account_id'];
    accountId = json['account_id'];
    name = json['name'];
    createdAt = json['created_at'] != null
        ? CreatedAt.fromJson(json['created_at'])
        : null;

    isShared = json['is_shared'];
    accessibleTo = (json['accessible_to'] is List)
        ? List<String>.from(json['accessible_to'])
        : [];

    sharingStatus = json['sharing_status'] != null
        ? SharingStatus.fromJson(json['sharing_status'])
        : null;

    locationCount = json['location_count'];

    // ✅ Handle all possible 'role' cases safely
    if (json['role'] != null && json['role'] is! bool) {
      if (json['role'] is List) {
        role = (json['role'] as List).map((v) => Roles.fromJson(v)).toList();
      } else if (json['role'] is Map) {
        // Sometimes APIs return object instead of list
        role = [Roles.fromJson(json['role'])];
      } else {
        role = [];
      }
    } else {
      role = []; // default empty list if null or bool
    }

    companyName = json['company_name'];
    status = json['status'];
    sovGraphData = json['sov_graph_data'] != null
        ? new SovGraphData.fromJson(json['sov_graph_data'])
        : null;
    totalDataCompleteness = json['total_data_completeness'] != null
        ? new TotalDataCompleteness.fromJson(json['total_data_completeness'])
        : null;
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
    data['status'] = this.status;
    if (this.sovGraphData != null) {
      data['sov_graph_data'] = this.sovGraphData!.toJson();
    }
    if (this.totalDataCompleteness != null) {
      data['total_data_completeness'] = this.totalDataCompleteness!.toJson();
    }
    return data;
  }
}

class TotalDataCompleteness {
  int? averageScore;
  int? averageScorePd;
  int? averageScoreTe;
  List<Scores>? scores;
  int? scorePd;
  int? scoreTe;

  TotalDataCompleteness(
      {this.averageScore,
      this.averageScorePd,
      this.averageScoreTe,
      this.scores,
      this.scorePd,
      this.scoreTe});

  TotalDataCompleteness.fromJson(Map<String, dynamic> json) {
    averageScore = json['average_score'];
    averageScorePd = json['average_score_pd'];
    averageScoreTe = json['average_score_te'];
    if (json['scores'] != null) {
      scores = <Scores>[];
      json['scores'].forEach((v) {
        scores!.add(new Scores.fromJson(v));
      });
    }
    scorePd = json['score_pd'];
    scoreTe = json['score_te'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['average_score'] = this.averageScore;
    data['average_score_pd'] = this.averageScorePd;
    data['average_score_te'] = this.averageScoreTe;
    if (this.scores != null) {
      data['scores'] = this.scores!.map((v) => v.toJson()).toList();
    }
    data['score_pd'] = this.scorePd;
    data['score_te'] = this.scoreTe;
    return data;
  }
}

class Scores {
  String? locationId;
  int? scorePd;
  int? scoreTe;
  int? finalScore;

  Scores({this.locationId, this.scorePd, this.scoreTe, this.finalScore});

  Scores.fromJson(Map<String, dynamic> json) {
    locationId = json['location_id'];
    scorePd = json['score_pd'];
    scoreTe = json['score_te'];
    finalScore = json['final_score'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['location_id'] = this.locationId;
    data['score_pd'] = this.scorePd;
    data['score_te'] = this.scoreTe;
    data['final_score'] = this.finalScore;
    return data;
  }
}

class SovGraphData {
  List<SovResults>? sovResults;
  GeocodeCounts? geocodeCounts;
  GlobalPerilCounts? globalSovPerilCounts;

  SovGraphData(
      {this.sovResults, this.geocodeCounts, this.globalSovPerilCounts});

  SovGraphData.fromJson(Map<String, dynamic> json) {
    if (json['sov_results'] != null) {
      sovResults = <SovResults>[];
      json['sov_results'].forEach((v) {
        sovResults!.add(new SovResults.fromJson(v));
      });
    }
    geocodeCounts = json['geocode_counts'] != null
        ? new GeocodeCounts.fromJson(json['geocode_counts'])
        : null;
    globalSovPerilCounts = json['global_sov_peril_counts'] != null
        ? new GlobalPerilCounts.fromJson(json['global_sov_peril_counts'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.sovResults != null) {
      data['sov_results'] = this.sovResults!.map((v) => v.toJson()).toList();
    }
    if (this.geocodeCounts != null) {
      data['geocode_counts'] = this.geocodeCounts!.toJson();
    }
    if (this.globalSovPerilCounts != null) {
      data['global_sov_peril_counts'] = this.globalSovPerilCounts!.toJson();
    }
    return data;
  }
}

class SovResults {
  int? geocodeAvg;
  int? overallAvg;
  String? sovId;
  GlobalPerilCounts? globalPerilCounts;
  GlobalValueCounts? globalValueCounts;
  Context? context;
  List<Locations>? locations;

  SovResults(
      {this.geocodeAvg,
      this.overallAvg,
      this.sovId,
      this.globalPerilCounts,
      this.globalValueCounts,
      this.context,
      this.locations});

  SovResults.fromJson(Map<String, dynamic> json) {
    geocodeAvg = json['geocode_avg'];
    overallAvg = json['overall_avg'];
    sovId = json['sov_id'];
    globalPerilCounts = json['global_peril_counts'] != null
        ? new GlobalPerilCounts.fromJson(json['global_peril_counts'])
        : null;
    globalValueCounts = json['global_value_counts'] != null
        ? new GlobalValueCounts.fromJson(json['global_value_counts'])
        : null;
    context =
        json['context'] != null ? new Context.fromJson(json['context']) : null;
    if (json['locations'] != null) {
      locations = <Locations>[];
      json['locations'].forEach((v) {
        locations!.add(new Locations.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['geocode_avg'] = this.geocodeAvg;
    data['overall_avg'] = this.overallAvg;
    data['sov_id'] = this.sovId;
    if (this.globalPerilCounts != null) {
      data['global_peril_counts'] = this.globalPerilCounts!.toJson();
    }
    if (this.globalValueCounts != null) {
      data['global_value_counts'] = this.globalValueCounts!.toJson();
    }
    if (this.context != null) {
      data['context'] = this.context!.toJson();
    }
    if (this.locations != null) {
      data['locations'] = this.locations!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class GlobalPerilCounts {
  Hurricane? hurricane;
  Hurricane? earthquake;

  GlobalPerilCounts({this.hurricane, this.earthquake});

  GlobalPerilCounts.fromJson(Map<String, dynamic> json) {
    hurricane = json['Hurricane'] != null
        ? new Hurricane.fromJson(json['Hurricane'])
        : null;
    earthquake = json['Earthquake'] != null
        ? new Hurricane.fromJson(json['Earthquake'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.hurricane != null) {
      data['Hurricane'] = this.hurricane!.toJson();
    }
    if (this.earthquake != null) {
      data['Earthquake'] = this.earthquake!.toJson();
    }
    return data;
  }
}

class Roles {
  Null? isApplicableForTrial;
  Null? id;
  dynamic? role;
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
  int? completed;

  TotalCountHeader(
      {this.my, this.shared, this.received, this.all, this.completed});

  TotalCountHeader.fromJson(Map<String, dynamic> json) {
    my = json['my'];
    shared = json['shared'];
    received = json['received'];
    all = json['all'];
    completed = json['completed'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['my'] = this.my;
    data['shared'] = this.shared;
    data['received'] = this.received;
    data['all'] = this.all;
    data['completed'] = this.completed;
    return data;
  }
}
