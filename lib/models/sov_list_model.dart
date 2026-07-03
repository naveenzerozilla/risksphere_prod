import 'my_location_list_model.dart';

class SovListModel {
  List<SovItem>? events;
  int? totalRecords;
  int? page;
  int? pageSize;
  Filters? filters;
  Cards? cards;
  List<Result>? result;
  List<Results>? results;
  Settings? settings;
  List<Role>? role;
  TotalCountHeader? totalCountHeader;
  AggregationCounts? aggregationCounts;

  SovListModel({
    this.events,
    this.totalRecords,
    this.page,
    this.pageSize,
    this.filters,
    this.cards,
    this.result,
    this.results,
    this.settings,
    this.role,
    this.totalCountHeader,
    this.aggregationCounts,
  });

  SovListModel.fromJson(Map<String, dynamic> json) {
    totalRecords = json['totalRecords'] is int ? json['totalRecords'] : 0;
    page = json['page'] is int ? json['page'] : 1;
    pageSize = json['pageSize'] is int ? json['pageSize'] : 0;

    filters =
        json['filters'] != null ? Filters.fromJson(json['filters']) : null;
    cards = json['cards'] != null ? Cards.fromJson(json['cards']) : null;

    //Safe 'result' parsing
    if (json['result'] is List) {
      result = (json['result'] as List)
          .whereType<Map<String, dynamic>>()
          .map((v) => Result.fromJson(v))
          .toList();
    } else {
      result = [];
    }

    //  Safe 'results' parsing
    if (json['results'] is List) {
      results = <Results>[];
      (json['results'] as List).forEach((v) {
        if (v is Map<String, dynamic>) {
          results!.add(Results.fromJson(v));
        }
      });
    }

    //  Safe 'settings' parsing
    settings = (json['settings'] is Map<String, dynamic>)
        ? Settings.fromJson(json['settings'])
        : null;

    // Safe 'role' parsing
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
        roleData.forEach((k, v) {
          if (v is Map<String, dynamic>) {
            role!.add(Role.fromJson(v));
          }
        });
      }
    }

    // Safe 'total_count_header' parsing
    totalCountHeader = (json['total_count_header'] is Map<String, dynamic>)
        ? TotalCountHeader.fromJson(json['total_count_header'])
        : null;

    // Safe 'events' parsing (ADD THIS)
    if (json['events'] is List) {
      events = <SovItem>[];
      (json['events'] as List).forEach((v) {
        if (v is Map<String, dynamic>) {
          events!.add(SovItem.fromJson(v));
        }
      });
    } else {
      events = [];
    }

    // Safe 'aggregation_counts' parsing (FIXED)
    aggregationCounts = (json['aggregation_counts'] is Map<String, dynamic>)
        ? AggregationCounts.fromJson(json['aggregation_counts'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['totalRecords'] = totalRecords ?? 0;
    data['page'] = page ?? 1;
    data['pageSize'] = pageSize ?? 0;

    if (filters != null) {
      data['filters'] = filters!.toJson();
    }
    if (cards != null) {
      data['cards'] = cards!.toJson();
    }

    data['result'] = result?.map((v) => v.toJson()).toList() ?? [];

    if (results != null) {
      data['results'] = results!.map((v) => v.toJson()).toList();
    }

    if (settings != null) {
      data['settings'] = settings!.toJson();
    }

    data['role'] = role?.map((v) => v.toJson()).toList() ?? [];

    if (totalCountHeader != null) {
      data['total_count_header'] = totalCountHeader!.toJson();
    }

    // if (events != null) {
    //   data['events'] = events!.map((v) => v.toJson()).toList();
    // }

    if (aggregationCounts != null) {
      data['aggregation_counts'] = aggregationCounts!.toJson();
    }

    return data;
  }
}

//  AggregationCounts class (ADD THIS if it doesn't exist)
class AggregationCounts {
  dynamic totalNoOfEvents;
  dynamic totalImpactedLocations;
  dynamic hurricaneMonitoringLocations;
  dynamic earthquakeMonitoringLocations;

  AggregationCounts({
    this.totalNoOfEvents,
    this.totalImpactedLocations,
    this.hurricaneMonitoringLocations,
    this.earthquakeMonitoringLocations,
  });

  factory AggregationCounts.fromJson(
      Map<String, dynamic> json) {
    return AggregationCounts(
      totalNoOfEvents: json['total_no_of_events'],
      totalImpactedLocations:
      json['total_impacted_locations'],
      hurricaneMonitoringLocations:
      json['hurricane_monitoring_locations'],
      earthquakeMonitoringLocations:
      json['earthquake_monitoring_locations'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_no_of_events': totalNoOfEvents,
      'total_impacted_locations':
      totalImpactedLocations,
      'hurricane_monitoring_locations':
      hurricaneMonitoringLocations,
      'earthquake_monitoring_locations':
      earthquakeMonitoringLocations,
    };
  }
}

class SovItem {
  String? id;
  String? eventName;
  String? hazardName;
  String? vendorName;
  String? status;
  int? impactedLocCount;
  LocationCoordinates? locationCoordinates;
  CreatedAt? updatedAt;

  SovItem({
    this.id,
    this.eventName,
    this.hazardName,
    this.vendorName,
    this.status,
    this.impactedLocCount,
    this.locationCoordinates,
    this.updatedAt,
  });

  factory SovItem.fromJson(Map<String, dynamic> json) {
    return SovItem(
      id: json['id'],
      eventName: json['event_name'],
      hazardName: json['hazard_name'],
      vendorName: json['vendor_name'],
      status: json['status'],
      impactedLocCount: json['impacted_locations'],
      locationCoordinates: json['location_coordinates'] != null
          ? LocationCoordinates.fromJson(json['location_coordinates'])
          : null,
      updatedAt: json['updated_at'] != null
          ? CreatedAt.fromJson(json['updated_at'])
          : null,
    );
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

class LocationCoordinates {
  double? longitude;
  double? latitude;

  LocationCoordinates({this.longitude, this.latitude});

  LocationCoordinates.fromJson(Map<String, dynamic> json) {
    longitude = json['longitude'];
    latitude = json['latitude'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['longitude'] = this.longitude;
    data['latitude'] = this.latitude;
    return data;
  }
}

class Results {
  String? companyId;
  String? companyName;
  String? hazardName;
  String? locationId;
  String? locationName;
  String? locationAddress;
  String? locationImage;
  double? locationLatitude;
  double? locationLongitude;
  double? latitude;
  double? longitude;
  Users? users;
  String? userId;
  String? userName;
  UserRole? userRole;
  String? date;
  String? vendorName;
  int? apisUsed;
  dynamic totalCost;
  String? sovId;
  String? name;
  int? locationCount;

  Results({
    this.companyId,
    this.companyName,
    this.hazardName,
    this.locationImage,
    this.locationLatitude,
    this.locationLongitude,
    this.locationId,
    this.locationName,
    this.locationAddress,
    this.latitude,
    this.longitude,
    this.users,
    this.userId,
    this.userName,
    this.userRole,
    this.date,
    this.vendorName,
    this.apisUsed,
    this.totalCost,
    this.sovId,
    this.name,
    this.locationCount,
  });

  Results.fromJson(Map<String, dynamic> json) {
    companyId = json['company_id'];
    companyName = json['company_name'];
    hazardName = json['hazard_name'];
    locationId = json['location_id'];
    locationName = json['location_name'];
    locationAddress = json['location_address'];
    locationImage = json['location_image'];
    locationLatitude = json['location_latitude'];
    locationLongitude = json['location_longitude'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    users = json['users'] != null ? new Users.fromJson(json['users']) : null;
    userId = json['user_id'];
    userName = json['user_name'];
  if (json['user_role'] is Map<String, dynamic>) {
    userRole = UserRole.fromJson(json['user_role']);
  } else {
    userRole = null;
  }
    date = json['date'];
    vendorName = json['vendor_name'];
    apisUsed = json['apis_used'];
    totalCost = json['total_cost'];
    sovId = json['sov_id'];
    name = json['name'];
    locationCount = json['location_count'];
    companyName = json['company_name'];
    date = json['date'];
    vendorName = json['vendor_name'];
    apisUsed = json['apis_used'];
    totalCost = json['total_cost'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['company_id'] = this.companyId;
    data['company_name'] = this.companyName;
    data['hazard_name'] = this.hazardName;
    data['location_id'] = this.locationId;
    data['location_name'] = this.locationName;
    data['location_address'] = this.locationAddress;
    data['location_image'] = this.locationImage;
    data['location_latitude'] = this.locationLatitude;
    data['location_longitude'] = this.locationLongitude;
    data['latitude'] = this.latitude;
    data['longitude'] = this.longitude;
    if (this.users != null) {
      data['users'] = this.users!.toJson();
    }
    data['user_id'] = this.userId;
    data['user_name'] = this.userName;
    if (this.userRole != null) {
      data['user_role'] = this.userRole!.toJson();
    }
    data['date'] = this.date;
    data['vendor_name'] = this.vendorName;
    data['apis_used'] = this.apisUsed;
    data['total_cost'] = this.totalCost;
    data['sov_id'] = this.sovId;
    data['name'] = this.name;
    data['location_count'] = this.locationCount;
    data['company_name'] = this.companyName;
    data['date'] = this.date;
    data['vendor_name'] = this.vendorName;
    data['apis_used'] = this.apisUsed;
    data['total_cost'] = this.totalCost;
    return data;
  }
}

class Users {
  HRUMQK6MdthFmvsKv9lgbrRUdtC3? hRUMQK6MdthFmvsKv9lgbrRUdtC3;

  Users({this.hRUMQK6MdthFmvsKv9lgbrRUdtC3});

  Users.fromJson(Map<String, dynamic> json) {
    hRUMQK6MdthFmvsKv9lgbrRUdtC3 = json['hRUMQK6MdthFmvsKv9lgbrRUdtC3'] != null
        ? new HRUMQK6MdthFmvsKv9lgbrRUdtC3.fromJson(
            json['hRUMQK6MdthFmvsKv9lgbrRUdtC3'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.hRUMQK6MdthFmvsKv9lgbrRUdtC3 != null) {
      data['hRUMQK6MdthFmvsKv9lgbrRUdtC3'] =
          this.hRUMQK6MdthFmvsKv9lgbrRUdtC3!.toJson();
    }
    return data;
  }
}

class HRUMQK6MdthFmvsKv9lgbrRUdtC3 {
  UserRole? userRole;
  int? cost;
  String? userName;
  int? apisUsed;

  HRUMQK6MdthFmvsKv9lgbrRUdtC3(
      {this.userRole, this.cost, this.userName, this.apisUsed});

  HRUMQK6MdthFmvsKv9lgbrRUdtC3.fromJson(Map<String, dynamic> json) {
    userRole = json['user_role'] != null
        ? new UserRole.fromJson(json['user_role'])
        : null;
    cost = json['cost'];
    userName = json['user_name'];
    apisUsed = json['apis_used'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.userRole != null) {
      data['user_role'] = this.userRole!.toJson();
    }
    data['cost'] = this.cost;
    data['user_name'] = this.userName;
    data['apis_used'] = this.apisUsed;
    return data;
  }
}

class UserRole {
  String? role;
  String? name;

  UserRole({this.role, this.name});

  UserRole.fromJson(Map<String, dynamic> json) {
    role = json['role'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['role'] = this.role;
    data['name'] = this.name;
    return data;
  }
}

class Autogenerated {
  String? companyId;
  String? companyName;
  String? hazardName;
  String? locationId;
  String? locationName;
  String? locationAddress;
  double? latitude;
  double? longitude;
  Users? users;
  String? userId;
  String? userName;
  String? userRole;
  String? date;
  String? vendorName;
  int? apisUsed;
  int? totalCost;

  Autogenerated(
      {this.companyId,
      this.companyName,
      this.hazardName,
      this.locationId,
      this.locationName,
      this.locationAddress,
      this.latitude,
      this.longitude,
      this.users,
      this.userId,
      this.userName,
      this.userRole,
      this.date,
      this.vendorName,
      this.apisUsed,
      this.totalCost});

  Autogenerated.fromJson(Map<String, dynamic> json) {
    companyId = json['company_id'];
    companyName = json['company_name'];
    hazardName = json['hazard_name'];
    locationId = json['location_id'];
    locationName = json['location_name'];
    locationAddress = json['location_address'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    users = json['users'] != null ? new Users.fromJson(json['users']) : null;
    userId = json['user_id'];
    userName = json['user_name'];
    userRole = json['user_role'];
    date = json['date'];
    vendorName = json['vendor_name'];
    apisUsed = json['apis_used'];
    totalCost = json['total_cost'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['company_id'] = this.companyId;
    data['company_name'] = this.companyName;
    data['hazard_name'] = this.hazardName;
    data['location_id'] = this.locationId;
    data['location_name'] = this.locationName;
    data['location_address'] = this.locationAddress;
    data['latitude'] = this.latitude;
    data['longitude'] = this.longitude;
    if (this.users != null) {
      data['users'] = this.users!.toJson();
    }
    data['user_id'] = this.userId;
    data['user_name'] = this.userName;
    data['user_role'] = this.userRole;
    data['date'] = this.date;
    data['vendor_name'] = this.vendorName;
    data['apis_used'] = this.apisUsed;
    data['total_cost'] = this.totalCost;
    return data;
  }
}

class Cards {
  dynamic totalApisUsed;
  dynamic totalApiCost;
  dynamic avgCostPerApi;
  dynamic activeVendors;

  Cards(
      {this.totalApisUsed,
      this.totalApiCost,
      this.avgCostPerApi,
      this.activeVendors});

  Cards.fromJson(Map<String, dynamic> json) {
    totalApisUsed = json['total_apis_used'];
    totalApiCost = json['total_cost_incurred'];
    avgCostPerApi = json['avg_cost_per_api'];
    activeVendors = json['active_users'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['total_apis_used'] = this.totalApisUsed;
    data['total_cost_incurred'] = this.totalApiCost;
    data['avg_cost_per_api'] = this.avgCostPerApi;
    data['active_users'] = this.activeVendors;
    return data;
  }
}

class Filters {
  String? startDate;
  String? endDate;
  String? vendorName;
  String? groupBy;
  String? dateView;
  String? search;
  String? sortBy;
  String? sortOrder;
  int? page;
  int? pageSize;

  Filters(
      {this.startDate,
      this.endDate,
      this.vendorName,
      this.groupBy,
      this.dateView,
      this.search,
      this.sortBy,
      this.sortOrder,
      this.page,
      this.pageSize});

  Filters.fromJson(Map<String, dynamic> json) {
    startDate = json['start_date'];
    endDate = json['end_date'];
    vendorName = json['vendor_name'];
    groupBy = json['group_by'];
    dateView = json['date_view'];
    search = json['search'];
    sortBy = json['sort_by'];
    sortOrder = json['sort_order'];
    page = json['page'];
    pageSize = json['page_size'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['start_date'] = this.startDate;
    data['end_date'] = this.endDate;
    data['vendor_name'] = this.vendorName;
    data['group_by'] = this.groupBy;
    data['date_view'] = this.dateView;
    data['search'] = this.search;
    data['sort_by'] = this.sortBy;
    data['sort_order'] = this.sortOrder;
    data['page'] = this.page;
    data['page_size'] = this.pageSize;
    return data;
  }
}

class UserResult {
  final String? userId;
  final String? name;
  final String? email;
  final String? userType;
  final List<String>? roles;
  final String? creditsIdentifier;
  final String? companyId;
  final String? companyName;
  final bool? isCompanySuperadmin;
  final dynamic status;
  final bool? isExternal;
  final bool? isVerified;
  final DateTime? lastLogin;
  final int? membersOfCorporate;

  UserResult({
    this.userId,
    this.name,
    this.email,
    this.userType,
    this.roles,
    this.creditsIdentifier,
    this.companyId,
    this.companyName,
    this.isCompanySuperadmin,
    this.status,
    this.isExternal,
    this.isVerified,
    this.lastLogin,
    this.membersOfCorporate,
  });

  factory UserResult.fromJson(Map<String, dynamic> json) {
    return UserResult(
      userId: json['user_id'],
      name: json['name'],
      email: json['email'],
      userType: json['user_type'],
      roles: (json['roles'] as List?)?.map((e) => e.toString()).toList(),
      creditsIdentifier: json['credits_identifier'],
      companyId: json['company_id'],
      companyName: json['company_name'],
      isCompanySuperadmin: json['is_company_superadmin'],
      status: json['status'],
      isExternal: json['is_external'],
      isVerified: json['is_verified'],
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'])
          : null,
      membersOfCorporate: json['members_of_corporate'],
    );
  }
}

class Result {
  String? companyId;
  String? companyName;
  String? hazardName;
  String? locationId;
  String? locationName;
  String? locationAddress;
  double? latitude;
  double? longitude;
  String? userId;
  String? userName;
  String? userRole;
  String? date;
  String? vendorName;
  int? apisUsed;
  int? totalCost;
  String? sovId;
  Owner? owner;
  String? subAccountId;
  String? accountName;
  String? subAccountName;
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
  dynamic status;
  int? geocodeAvg;
  int? overallAvg;
  SovGraphData? sovGraphData;
  int? dataCompleteness;

  Result(
      {this.companyId,
      this.companyName,
      this.hazardName,
      this.locationId,
      this.locationName,
      this.locationAddress,
      this.latitude,
      this.longitude,
      this.userId,
      this.userName,
      this.userRole,
      this.date,
      this.vendorName,
      this.apisUsed,
      this.totalCost,
      this.sovId,
      this.owner,
      this.subAccountId,
      this.accountName,
      this.subAccountName,
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
      this.status,
      this.geocodeAvg,
      this.overallAvg,
      this.sovGraphData,
      this.dataCompleteness});

  Result.fromJson(Map<String, dynamic> json) {
    companyId = json['company_id'];
    companyName = json['company_name'];
    hazardName = json['hazard_name'];
    locationId = json['location_id'];
    locationName = json['location_name'];
    locationAddress = json['location_address'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    userId = json['user_id'];
    userName = json['user_name'];
    userRole = json['user_role'];
    date = json['date'];
    vendorName = json['vendor_name'];
    apisUsed = json['apis_used'];
    totalCost = json['total_cost'];

    sovId = json['sov_id'];
    owner = json['owner'] != null ? Owner.fromJson(json['owner']) : null;
    companyId = json['company_id'];
    subAccountId = json['sub_account_id'];
    accountName = json['account_name'];
    subAccountName = json['sub_account_name'];
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

    // Handle all possible 'role' cases safely
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
    geocodeAvg = json['geocode_avg'];
    overallAvg = json['overall_avg'];
    sovGraphData = json['sov_graph_data'] != null
        ? new SovGraphData.fromJson(json['sov_graph_data'])
        : null;
    dataCompleteness = json['total_data_completeness'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();

    data['company_id'] = this.companyId;
    data['company_name'] = this.companyName;
    data['hazard_name'] = this.hazardName;
    data['location_id'] = this.locationId;
    data['location_name'] = this.locationName;
    data['location_address'] = this.locationAddress;
    data['latitude'] = this.latitude;
    data['longitude'] = this.longitude;

    data['user_id'] = this.userId;
    data['user_name'] = this.userName;
    data['user_role'] = this.userRole;
    data['date'] = this.date;
    data['vendor_name'] = this.vendorName;
    data['apis_used'] = this.apisUsed;
    data['total_cost'] = this.totalCost;
    data['sov_id'] = this.sovId;
    if (this.owner != null) {
      data['owner'] = this.owner!.toJson();
    }
    data['company_id'] = this.companyId;
    data['sub_account_id'] = this.subAccountId;
    data['account_name'] = this.accountName;
    data['sub_account_name'] = this.subAccountName;
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
      data['sharing_status'] = this.sharingStatus;
    }
    data['location_count'] = this.locationCount;
    if (this.role != null) {
      data['role'] = this.role!.map((v) => v.toJson()).toList();
    }
    data['company_name'] = this.companyName;
    data['status'] = this.status;
    data['geocode_avg'] = this.geocodeAvg;
    data['overall_avg'] = this.overallAvg;

    if (this.sovGraphData != null) {
      data['sov_graph_data'] = this.sovGraphData!.toJson();
    }
    data['total_data_completeness'] = this.dataCompleteness;
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
  Null isApplicableForTrial;
  Null id;
  dynamic role;
  String? name;
  dynamic isMultipleRoleEnabled;
  dynamic isForIndividual;

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

class SharingStatus {
  String? email;
  String? userId;
  String? status;
  String? comment;
  Role? role;
  DateTime? shareExpiry;
  CreatedAt? updatedAt;
  String? updatedBy;

  SharingStatus({
    this.email,
    this.userId,
    this.status,
    this.comment,
    this.role,
    this.shareExpiry,
    this.updatedAt,
    this.updatedBy,
  });

  factory SharingStatus.fromJson(Map<String, dynamic> json) {
    return SharingStatus(
      email: json['email'],
      userId: json['user_id'],
      status: json['status'],
      comment: json['comment'],
      role: json['role'] != null ? Role.fromJson(json['role']) : null,
      shareExpiry: json['share_expiry'] != null
          ? DateTime.tryParse(json['share_expiry'])
          : null,
      updatedAt: json['updated_at'] != null
          ? CreatedAt.fromJson(json['updated_at'])
          : null,
      updatedBy: json['updated_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'user_id': userId,
      'status': status,
      'comment': comment,
      'role': role?.toJson(),
      'share_expiry': shareExpiry?.toIso8601String(),
      'updated_at': updatedAt?.toJson(),
      'updated_by': updatedBy,
    };
  }
}

// class SharingStatus {
//   final Map<String, SharingUser> users;
//
//   SharingStatus({required this.users});
//
//   factory SharingStatus.fromJson(Map<String, dynamic>? json) {
//     if (json == null) {
//       return SharingStatus(users: {});
//     }
//
//     final map = <String, SharingUser>{};
//
//     json.forEach((key, value) {
//       map[key] = SharingUser.fromJson(value);
//     });
//
//     return SharingStatus(users: map);
//   }
//
//   ///  Total count
//   int get count => users.length;
// }

class SharingUser {
  String? userId;
  String? status;
  String? comment;
  Role? role;
  CreatedAt? updatedAt;
  String? updatedBy;
  String? user;
  String? email;

  SharingUser(
      {this.userId,
      this.status,
      this.comment,
      this.role,
      this.updatedAt,
      this.updatedBy,
      this.user,
      this.email});

  SharingUser.fromJson(Map<String, dynamic> json) {
    userId = json['user_id'];
    status = json['status'];
    comment = json['comment'];
    role = json['role'] != null ? new Role.fromJson(json['role']) : null;
    updatedAt = json['updated_at'] != null
        ? new CreatedAt.fromJson(json['updated_at'])
        : null;
    updatedBy = json['updated_by'];
    user = json['user'];
    email = json['email'];
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
    data['email'] = this.email;
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

class UserListModel {
  final int? totalRecords;
  final int? page;
  final int? pageSize;
  final List<UserResult>? result;

  UserListModel({
    this.totalRecords,
    this.page,
    this.pageSize,
    this.result,
  });

  factory UserListModel.fromJson(Map<String, dynamic> json) {
    return UserListModel(
      totalRecords: json['totalRecords'],
      page: json['page'],
      pageSize: json['pageSize'],
      result: (json['result'] as List?)
          ?.map((e) => UserResult.fromJson(e))
          .toList(),
    );
  }
}

class CreditItem {
  final int total;
  final int used;
  final int remaining;

  CreditItem({
    required this.total,
    required this.used,
    required this.remaining,
  });

  factory CreditItem.fromJson(Map<String, dynamic> json) {
    return CreditItem(
      total: json['total'] ?? 0,
      used: json['used'] ?? 0,
      remaining: json['remaining'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "total": total,
      "used": used,
      "remaining": remaining,
    };
  }
}

class CompanyCreditsModel {
  final CreditItem locationCredits;
  final CreditItem improvementCredits;
  final CreditItem userCredits;

  CompanyCreditsModel({
    required this.locationCredits,
    required this.improvementCredits,
    required this.userCredits,
  });

  factory CompanyCreditsModel.fromJson(Map<String, dynamic> json) {
    return CompanyCreditsModel(
      locationCredits: CreditItem.fromJson(json['location_credits'] ?? {}),
      improvementCredits:
          CreditItem.fromJson(json['improvement_credits'] ?? {}),
      userCredits: CreditItem.fromJson(json['user_credits'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "location_credits": locationCredits.toJson(),
      "improvement_credits": improvementCredits.toJson(),
      "user_credits": userCredits.toJson(),
    };
  }
}
