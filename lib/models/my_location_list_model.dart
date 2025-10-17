import 'package:google_maps_cluster_manager_2/google_maps_cluster_manager_2.dart';
import 'package:google_maps_flutter_platform_interface/src/types/location.dart';

import 'location_profile_model.dart';

class MyLocationModel {
  int? totalRecords;
  int? totalCertified;
  int? page;
  int? pageSize;
  bool? isConflict;
  bool? isHazardCanStart;
  bool? isAnyHazardProcessing;
  List<MyLocation>? results;
  List<MyLocation>? filterByLocationResult;
  GraphData? graphData;

  MyLocationModel(
      {this.totalRecords,
      this.totalCertified,
      this.page,
      this.pageSize,
      this.isConflict,
      this.isHazardCanStart,
      this.isAnyHazardProcessing,
      this.results,
      this.filterByLocationResult,
      this.graphData});

  MyLocationModel.fromJson(Map<String, dynamic> json) {
    totalRecords = json['totalRecords'];
    totalCertified = json['totalCertified'];
    page = json['page'];
    pageSize = json['pageSize'];
    if (json['result'] != null) {
      results = <MyLocation>[];
      json['result'].forEach((v) {
        results!.add(MyLocation.fromJson(v));
      });
    }
    isConflict = json['is_conflict'];
    isHazardCanStart = json['hazard_can_start'];
    isAnyHazardProcessing = json['is_any_hazard_processing'];
    if (json['filter_by_location_result'] != null) {
      filterByLocationResult = <MyLocation>[];
      json['filter_by_location_result'].forEach((v) {
        filterByLocationResult!.add(MyLocation.fromJson(v));
      });
    }
    graphData = json['graph_data'] != null
        ? new GraphData.fromJson(json['graph_data'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['totalRecords'] = totalRecords;
    data['totalCertified'] = totalCertified;
    data['page'] = page;
    data['pageSize'] = pageSize;
    if (results != null) {
      data['result'] = results!.map((v) => v.toJson()).toList();
    }
    data['is_conflict'] = isConflict;
    data['hazard_can_start'] = isHazardCanStart;
    data['is_any_hazard_processing'] = isAnyHazardProcessing;
    if (filterByLocationResult != null) {
      data['filter_by_location_result'] =
          filterByLocationResult!.map((v) => v.toJson()).toList();
    }
    data['graph_data'] = this.graphData!.toJson();
    return data;
  }

  @override
  String toString() {
    return 'MyLocationModel(totalRecords: $totalRecords, totalCertified: $totalCertified, page: $page, pageSize: $pageSize, results: $results, filterByLocationResult: $filterByLocationResult)';
  }
}

class MyLocation with ClusterItem {
  String? id;
  FinalAddress? finalAddress;
  dynamic overallScore;
  int? geocodingScore;
  bool? isSelected;
  bool? isConflict;
  List<Conflicts>? conflicts;
  int? defaultConflictindex;
  List<String>? tags;
  Map<String, HazardDetails>? hazard; // Updated to hold vendor-specific data
  String? geocodedAddress;
  List<LocationComments>? locationComments;
  List<ActivityLogs>? activityLogs;List<AllActivityLogs>? allActivityLogs;
  List<Subdestination>? subdestinations;
  List<Screenshots>? screenshots;
  bool? isHazardProcess;
  DataCompleteness? dataCompleteness;

  MyLocation(
      {this.id,
      this.finalAddress,
      this.geocodingScore,
      this.overallScore,
      this.isSelected = false,
      this.isConflict,
      this.conflicts,
      this.defaultConflictindex,
      this.tags,
      this.hazard,
      this.geocodedAddress,
      this.locationComments,
      this.activityLogs,
        this.allActivityLogs,
      this.subdestinations,
      this.screenshots,
      this.isHazardProcess,
      this.dataCompleteness});

  MyLocation.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    finalAddress = json['final_address'] != null
        ? FinalAddress.fromJson(json['final_address'])
        : null;
    geocodingScore = json['geocoding_score'] is int
        ? json['geocoding_score']
        : int.tryParse(json['geocoding_score']?.toString() ?? '');
    overallScore = json['overall_score'];
    isConflict = json['is_conflict'];
    if (json['conflicts'] != null) {
      conflicts = <Conflicts>[];
      json['conflicts'].forEach((v) {
        conflicts!.add(new Conflicts.fromJson(v));
      });
    }
    if (json['location_comments'] != null) {
      locationComments = <LocationComments>[];
      json['location_comments'].forEach((v) {
        locationComments!.add(new LocationComments.fromJson(v));
      });
    }
    if (json['activity_logs'] != null) {
      activityLogs = <ActivityLogs>[];
      json['activity_logs'].forEach((v) {
        activityLogs!.add(new ActivityLogs.fromJson(v));
      });
    }
    if (json['all_activity_logs'] != null) {
      allActivityLogs = <AllActivityLogs>[];
      json['all_activity_logs'].forEach((v) { allActivityLogs!.add(new AllActivityLogs.fromJson(v)); });
    }

    defaultConflictindex = json['default_conflict_index'] is int
        ? json['default_conflict_index']
        : int.tryParse(json['default_conflict_index']?.toString() ?? '');
    if (json['tags'] != null) {
      if (json['tags'] is List) {
        // If it's already a List, directly convert it
        tags = List<String>.from(json['tags']);
      } else if (json['tags'] is Map) {
        // If it's a Map, extract the values as a List
        tags = List<String>.from((json['tags'] as Map).values);
      }
    } else {
      tags = null;
    }

    geocodedAddress = json['geocoded_address'] ?? '';

    // Parse hazard as Map<String, HazardDetails>
    if (json['hazard'] != null) {
      hazard = {};
      json['hazard'].forEach((key, value) {
        hazard![key] = HazardDetails.fromJson(value);
      });
    }

    if (json['subdestinations'] != null) {
      subdestinations = <Subdestination>[];
      json['subdestinations'].forEach((v) {
        subdestinations!.add(Subdestination.fromJson(v));
      });
    }

    if (json['screen_shots'] != null) {
      // Corrected condition here
      screenshots = <Screenshots>[];
      json['screen_shots'].forEach((v) {
        screenshots!.add(Screenshots.fromJson(v));
      });
    }
    isHazardProcess = json['is_hazard_processed'] ?? false;
    dataCompleteness = json['data_completeness'] != null
        ? new DataCompleteness.fromJson(json['data_completeness'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    if (finalAddress != null) {
      data['final_address'] = finalAddress!.toJson();
    }
    data['geocoding_score'] = geocodingScore;
    data['overall_score'] = overallScore;
    data['is_conflict'] = this.isConflict;
    if (this.conflicts != null) {
      data['conflicts'] = this.conflicts!.map((v) => v.toJson()).toList();
    }
    data['default_conflict_index'] = defaultConflictindex;
    data['tags'] = tags;

    data['geocoded_address'] = geocodedAddress;
    if (this.locationComments != null) {
      data['location_comments'] =
          this.locationComments!.map((v) => v.toJson()).toList();
    }
    if (this.activityLogs != null) {
      data['activity_logs'] =
          this.activityLogs!.map((v) => v.toJson()).toList();
    }
    if (this.allActivityLogs != null) {
      data['all_activity_logs'] = this.allActivityLogs!.map((v) => v.toJson()).toList();
    }
    if (hazard != null) {
      data['hazard'] =
          hazard!.map((key, value) => MapEntry(key, value.toJson()));
    }
    if (subdestinations != null) {
      data['subdestinations'] =
          subdestinations!.map((v) => v.toJson()).toList();
    }
    if (screenshots != null) {
      data['screen_shots'] = screenshots!.map((v) => v.toJson()).toList();
    }
    data['is_hazard_processed'] = isHazardProcess;
    if (this.dataCompleteness != null) {
      data['data_completeness'] = this.dataCompleteness!.toJson();
    }
    return data;
  }

  @override
  String toString() {
    return 'MyLocation(id: $id, finalAddress: $finalAddress, overallScore: $overallScore, geocodingScore: $geocodingScore, hazard: $hazard, tags: $tags, geocodedAddress: $geocodedAddress, subdestinations: $subdestinations, screen_shots: $screenshots)';
  }

  @override
  LatLng get location => LatLng(
        finalAddress?.latitude ?? 0.0,
        finalAddress?.longitude ?? 0.0,
      );
}
class AllActivityLogs {
  Null? actorUserId;
  String? eventId;
  CreatedAt? at;
  Null? companyId;
  String? targetType;
  String? action;
  String? targetId;
  Event? event;
  // After? after;

  AllActivityLogs({this.actorUserId, this.eventId, this.at, this.companyId, this.targetType, this.action, this.targetId, this.event});

  AllActivityLogs.fromJson(Map<String, dynamic> json) {
    actorUserId = json['actor_user_id'];
    eventId = json['event_id'];
    at = json['at'] != null ? new CreatedAt.fromJson(json['at']) : null;
    companyId = json['company_id'];
    targetType = json['target_type'];
    action = json['action'];
    targetId = json['target_id'];
    event = json['event'] != null ? new Event.fromJson(json['event']) : null;
    // after = json['after'] != null ? new After.fromJson(json['after']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['actor_user_id'] = this.actorUserId;
    data['event_id'] = this.eventId;
    if (this.at != null) {
      data['at'] = this.at!.toJson();
    }
    data['company_id'] = this.companyId;
    data['target_type'] = this.targetType;
    data['action'] = this.action;
    data['target_id'] = this.targetId;
    if (this.event != null) {
      data['event'] = this.event!.toJson();
    }
    // if (this.after != null) {
    //   data['after'] = this.after!.toJson();
    // }
    return data;
  }
}
class Params {
  String? locationId;

  Params({this.locationId});

  Params.fromJson(Map<String, dynamic> json) {
    locationId = json['locationId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['locationId'] = this.locationId;
    return data;
  }
}
class Event {
  Params? params;
  Null? timestamp;

  Event({this.params, this.timestamp});

  Event.fromJson(Map<String, dynamic> json) {
    params = json['params'] != null ? new Params.fromJson(json['params']) : null;
    timestamp = json['timestamp'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.params != null) {
      data['params'] = this.params!.toJson();
    }
    data['timestamp'] = this.timestamp;
    return data;
  }
}

class Conflicts {
  String? subAccountId;
  String? countryIsoCode;
  int? lineNo;
  int? retryAttempts;
  bool? leased;
  String? locationId;
  String? address;
  String? state;
  String? pgKey;
  String? zip;
  dynamic processingTime;
  String? county;
  double? longitude;
  double? latitude;
  String? description;
  bool? usFlag;
  String? percent;
  String? companyId;
  GeocodeInputAddress? geocodeInputAddress;
  String? ownerEmail;
  String? city;
  String? subAccountName;
  Owner? owner;
  List<String>? placeTypes;
  String? locationIdForRef;
  bool? rented;
  int? score;
  String? country;
  String? ownerId;
  String? tags;
  String? placeId;
  bool? autoCertified;
  String? accountName;
  String? locationType;
  String? ownerName;
  String? accountId;
  String? id;

  Conflicts(
      {this.subAccountId,
      this.countryIsoCode,
      this.lineNo,
      this.retryAttempts,
      this.leased,
      this.locationId,
      this.address,
      this.state,
      this.pgKey,
      this.zip,
      this.processingTime,
      this.county,
      this.longitude,
      this.latitude,
      this.description,
      this.usFlag,
      this.percent,
      this.companyId,
      this.geocodeInputAddress,
      this.ownerEmail,
      this.city,
      this.subAccountName,
      this.owner,
      this.placeTypes,
      this.locationIdForRef,
      this.rented,
      this.score,
      this.country,
      this.ownerId,
      this.tags,
      this.placeId,
      this.autoCertified,
      this.accountName,
      this.locationType,
      this.ownerName,
      this.accountId,
      this.id});

  Conflicts.fromJson(Map<String, dynamic> json) {
    subAccountId = json['sub_account_id'];
    countryIsoCode = json['country_iso_code'];
    lineNo = json['line_no'];
    retryAttempts = json['retry_attempts'];
    leased = json['leased'];
    locationId = json['location_id'];
    address = json['address'];
    state = json['state'];
    pgKey = json['pg_key'];
    zip = json['zip'];
    processingTime = json['processing_time'];
    county = json['county'];
    longitude = json['longitude'];
    latitude = json['latitude'];
    description = json['description'];
    usFlag = json['us_flag'];
    percent = json['percent'];
    companyId = json['company_id'];
    geocodeInputAddress = json['geocode_input_address'] != null
        ? new GeocodeInputAddress.fromJson(json['geocode_input_address'])
        : null;
    ownerEmail = json['owner_email'];
    city = json['city'];
    subAccountName = json['sub_account_name'];
    owner = json['owner'] != null ? new Owner.fromJson(json['owner']) : null;
    placeTypes = json['place_types'].cast<String>();
    locationIdForRef = json['location_id_for_ref'];
    rented = json['rented'];
    score = json['score'];
    country = json['country'];
    ownerId = json['owner_id'];
    tags = json['tags'];
    placeId = json['place_id'];
    autoCertified = json['auto_certified'];
    accountName = json['account_name'];
    locationType = json['location_type'];
    ownerName = json['owner_name'];
    accountId = json['account_id'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['sub_account_id'] = this.subAccountId;
    data['country_iso_code'] = this.countryIsoCode;
    data['line_no'] = this.lineNo;
    data['retry_attempts'] = this.retryAttempts;
    data['leased'] = this.leased;
    data['location_id'] = this.locationId;
    data['address'] = this.address;
    data['state'] = this.state;
    data['pg_key'] = this.pgKey;
    data['zip'] = this.zip;
    data['processing_time'] = this.processingTime;
    data['county'] = this.county;
    data['longitude'] = this.longitude;
    data['latitude'] = this.latitude;
    data['description'] = this.description;
    data['us_flag'] = this.usFlag;
    data['percent'] = this.percent;
    data['company_id'] = this.companyId;
    if (this.geocodeInputAddress != null) {
      data['geocode_input_address'] = this.geocodeInputAddress!.toJson();
    }
    data['owner_email'] = this.ownerEmail;
    data['city'] = this.city;
    data['sub_account_name'] = this.subAccountName;
    if (this.owner != null) {
      data['owner'] = this.owner!.toJson();
    }
    data['place_types'] = this.placeTypes;
    data['location_id_for_ref'] = this.locationIdForRef;
    data['rented'] = this.rented;
    data['score'] = this.score;
    data['country'] = this.country;
    data['owner_id'] = this.ownerId;
    data['tags'] = this.tags;
    data['place_id'] = this.placeId;
    data['auto_certified'] = this.autoCertified;
    data['account_name'] = this.accountName;
    data['location_type'] = this.locationType;
    data['owner_name'] = this.ownerName;
    data['account_id'] = this.accountId;
    data['id'] = this.id;
    return data;
  }
}

class GeocodeInputAddress {
  String? type;
  int? lineNo;
  String? propertyAddress;
  String? locationId;
  String? state;
  String? propertyCity;
  String? country;
  String? docId;
  String? locationName;
  Null? duplicates;
  bool? isDuplicate;
  String? postalCode;
  String? formattedAddress;
  String? processId;
  String? id;

  GeocodeInputAddress(
      {this.type,
      this.lineNo,
      this.propertyAddress,
      this.locationId,
      this.state,
      this.propertyCity,
      this.country,
      this.docId,
      this.locationName,
      this.duplicates,
      this.isDuplicate,
      this.postalCode,
      this.formattedAddress,
      this.processId,
      this.id});

  GeocodeInputAddress.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    lineNo = json['line_no'];
    propertyAddress = json['property Address'];
    locationId = json['location_id'];
    state = json['State'];
    propertyCity = json['property City'];
    country = json['Country'];
    docId = json['doc_id'];
    locationName = json['Location Name'];
    duplicates = json['duplicates'];
    isDuplicate = json['is_duplicate'];
    postalCode = json['Postal code'];
    formattedAddress = json['formatted_address'];
    processId = json['process_id'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['type'] = this.type;
    data['line_no'] = this.lineNo;
    data['property Address'] = this.propertyAddress;
    data['location_id'] = this.locationId;
    data['State'] = this.state;
    data['property City'] = this.propertyCity;
    data['Country'] = this.country;
    data['doc_id'] = this.docId;
    data['Location Name'] = this.locationName;
    data['duplicates'] = this.duplicates;
    data['is_duplicate'] = this.isDuplicate;
    data['Postal code'] = this.postalCode;
    data['formatted_address'] = this.formattedAddress;
    data['process_id'] = this.processId;
    data['id'] = this.id;
    return data;
  }
}

class LocationComments {
  String? commentId;
  String? comment;
  Date? updatedAt;
  User? user;

  LocationComments({this.commentId, this.comment, this.updatedAt, this.user});

  LocationComments.fromJson(Map<String, dynamic> json) {
    commentId = json['comment_id'];
    comment = json['comment'];
    updatedAt = json['updated_at'] != null
        ? new Date.fromJson(json['updated_at'])
        : null;
    user = json['user'] != null ? new User.fromJson(json['user']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['comment_id'] = this.commentId;
    data['comment'] = this.comment;
    if (this.updatedAt != null) {
      data['updated_at'] = this.updatedAt!.toJson();
    }
    if (this.user != null) {
      data['user'] = this.user!.toJson();
    }
    return data;
  }
}

class ActivityLogs {
  String? id;
  String? type;
  String? field;
  String? previousValue;
  String? newValue;
  User? actor;
  String? locationId;
  Date? timestamp;

  ActivityLogs(
      {this.id,
      this.type,
      this.field,
      this.previousValue,
      this.newValue,
      this.actor,
      this.locationId,
      this.timestamp});

  ActivityLogs.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    type = json['type'];
    field = json['field'];
    previousValue = json['previous_value'];
    newValue = json['new_value'];
    actor = json['actor'] != null ? new User.fromJson(json['actor']) : null;
    locationId = json['location_id'];
    timestamp =
        json['timestamp'] != null ? new Date.fromJson(json['timestamp']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['type'] = this.type;
    data['field'] = this.field;
    data['previous_value'] = this.previousValue;
    data['new_value'] = this.newValue;
    if (this.actor != null) {
      data['actor'] = this.actor!.toJson();
    }
    data['location_id'] = this.locationId;
    if (this.timestamp != null) {
      data['timestamp'] = this.timestamp!.toJson();
    }
    return data;
  }
}

class User {
  Null? imageUrl;
  String? userId;
  String? email;
  String? name;

  User({this.imageUrl, this.userId, this.email, this.name});

  User.fromJson(Map<String, dynamic> json) {
    imageUrl = json['image_url'];
    userId = json['user_id'];
    email = json['email'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['image_url'] = this.imageUrl;
    data['user_id'] = this.userId;
    data['email'] = this.email;
    data['name'] = this.name;
    return data;
  }
}

class Date {
  int? iSeconds;
  int? iNanoseconds;

  Date({this.iSeconds, this.iNanoseconds});

  Date.fromJson(Map<String, dynamic> json) {
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
// class Conflicts {
//   List<UserAccounts>? userAccounts;
//   EmbeddedAddress? embeddedAddress;
//   FinalAddress? finalAddress;
//   String? processId;
//   List<String>? accountIndex;
//   List<String>? subAccountIndex;
//
//   // EnabledHazards? enabledHazards;
//   List<Null>? dataParameters;
//   String? geocodedAddress;
//   bool? isHazardProcessed;
//   String? mappedAddress;
//
//   // List<History>? history;
//   String? subProcessId;
//   String? originalAddress;
//
//   // EnabledHazards? dataParamIndex;
//   String? locationId;
//
//   Conflicts(
//       {this.userAccounts,
//       this.embeddedAddress,
//       this.finalAddress,
//       this.processId,
//       this.accountIndex,
//       this.subAccountIndex,
//       this.dataParameters,
//       this.geocodedAddress,
//       this.isHazardProcessed,
//       this.mappedAddress,
//       this.subProcessId,
//       this.originalAddress,
//       this.locationId});
//
//   Conflicts.fromJson(Map<String, dynamic> json) {
//     if (json['userAccounts'] != null) {
//       userAccounts = <UserAccounts>[];
//       json['userAccounts'].forEach((v) {
//         userAccounts!.add(new UserAccounts.fromJson(v));
//       });
//     }
//     embeddedAddress = json['embedded_address'] != null
//         ? new EmbeddedAddress.fromJson(json['embedded_address'])
//         : null;
//     finalAddress = json['final_address'] != null
//         ? new FinalAddress.fromJson(json['final_address'])
//         : null;
//     processId = json['process_id'];
//     accountIndex = json['account_index'].cast<String>();
//     subAccountIndex = json['sub_account_index'].cast<String>();
//     // enabledHazards = json['enabled_hazards'] != null ? new EnabledHazards.fromJson(json['enabled_hazards']) : null;
//     // if (json['data_parameters'] != null) {
//     //   dataParameters = <Null>[];
//     //   json['data_parameters'].forEach((v) { dataParameters!.add(new Null.fromJson(v)); });
//     // }
//     geocodedAddress = json['geocoded_address'];
//     isHazardProcessed = json['is_hazard_processed'];
//     mappedAddress = json['mapped_address'];
//     // if (json['history'] != null) {
//     //   history = <History>[];
//     //   json['history'].forEach((v) { history!.add(new History.fromJson(v)); });
//     // }
//     subProcessId = json['sub_process_id'];
//     originalAddress = json['original_address'];
//     // dataParamIndex = json['data_param_index'] != null ? new EnabledHazards.fromJson(json['data_param_index']) : null;
//     locationId = json['location_id'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     if (this.userAccounts != null) {
//       data['userAccounts'] = this.userAccounts!.map((v) => v.toJson()).toList();
//     }
//     if (this.embeddedAddress != null) {
//       data['embedded_address'] = this.embeddedAddress!.toJson();
//     }
//     if (this.finalAddress != null) {
//       data['final_address'] = this.finalAddress!.toJson();
//     }
//     data['process_id'] = this.processId;
//     data['account_index'] = this.accountIndex;
//     data['sub_account_index'] = this.subAccountIndex;
//     // if (this.enabledHazards != null) {
//     //   data['enabled_hazards'] = this.enabledHazards!.toJson();
//     // }
//     // if (this.dataParameters != null) {
//     //   data['data_parameters'] = this.dataParameters!.map((v) => v.toJson()).toList();
//     // }
//     data['geocoded_address'] = this.geocodedAddress;
//     data['is_hazard_processed'] = this.isHazardProcessed;
//     data['mapped_address'] = this.mappedAddress;
//     // if (this.history != null) {
//     //   data['history'] = this.history!.map((v) => v.toJson()).toList();
//     // }
//     data['sub_process_id'] = this.subProcessId;
//     data['original_address'] = this.originalAddress;
//     // if (this.dataParamIndex != null) {
//     //   data['data_param_index'] = this.dataParamIndex!.toJson();
//     // }
//     data['location_id'] = this.locationId;
//     return data;
//   }
// }

class UserAccounts {
  String? folder;
  String? subaccount;
  String? account;

  UserAccounts({this.folder, this.subaccount, this.account});

  UserAccounts.fromJson(Map<String, dynamic> json) {
    folder = json['folder'];
    subaccount = json['subaccount'];
    account = json['account'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['folder'] = this.folder;
    data['subaccount'] = this.subaccount;
    data['account'] = this.account;
    return data;
  }
}

class EmbeddedAddress {
  String? sType;
  List<double>? value;

  EmbeddedAddress({this.sType, this.value});

  EmbeddedAddress.fromJson(Map<String, dynamic> json) {
    sType = json['__type__'];
    value = json['value'].cast<double>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['__type__'] = this.sType;
    data['value'] = this.value;
    return data;
  }
}

class Hazard {
  int? priority;
  String? vendorName; // Vendor providing the data (e.g., Kineticast, USGS)
  dynamic value; // Raw value from the vendor (can be String, double, or null)
  int? rating; // Rating of the hazard
  DateTime? date; // Hazard date, if provided

  Hazard({
    this.priority,
    this.vendorName,
    this.value,
    this.rating,
    this.date,
  });

  Hazard.fromJson(Map<String, dynamic> json) {
    priority = json['priority'];
    vendorName = json['vendor_name'];
    value = json['value'];
    rating = json['rating'];
    date = json['date'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['date']['_seconds'] * 1000)
        : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'priority': priority,
      'vendor_name': vendorName,
      'value': value,
      'rating': rating,
      'date': date?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Hazard(priority: $priority, vendorName: $vendorName, value: $value, rating: $rating, date: $date)';
  }
}

class VendorData {
  String?
      key; // Key representing the type of information (e.g., "PGA", "Risk Impact")
  String? value; // Value corresponding to the key (e.g., "Moderate", "0.31")
  String? vendorName; // Vendor providing the data (e.g., "Kineticast", "USGS")
  int? rating; // Rating of the hazard provided by the vendor, if applicable

  VendorData({this.key, this.value, this.vendorName, this.rating});

  VendorData.fromJson(Map<String, dynamic> json) {
    key = json['key'];
    value = json['value'];
    vendorName = json['vendor_name'];
    rating = json['rating']; // Ensure 'rating' is being parsed from JSON
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'value': value,
      'vendor_name': vendorName,
      'rating': rating,
    };
  }

  @override
  String toString() {
    return 'VendorData(key: $key, value: $value, vendorName: $vendorName, rating: $rating)';
  }
}

class HazardDetails {
  String? vendorName; // Primary vendor providing the data
  dynamic value; // The hazard value (can be String, int, or double)
  dynamic rating; // Hazard rating
  int? priority; // Hazard priority
  DateTime? date; // Date of hazard information
  Map<String, HazardDetails>? others; // Additional vendor-specific data

  HazardDetails({
    this.vendorName,
    this.value,
    this.rating,
    this.priority,
    this.date,
    this.others,
  });

  HazardDetails.fromJson(Map<String, dynamic> json) {
    vendorName = json['vendor_name'];
    value = json['value'];
    rating = json['rating'];
    priority = json['priority'];
    date = json['date'] != null
        ? DateTime.fromMillisecondsSinceEpoch(
            json['date']['_seconds'] * 1000 +
                (json['date']['_nanoseconds'] ~/ 1000000),
          )
        : null;

    // Parsing the `others` field
    if (json['others'] != null) {
      others = {};
      json['others'].forEach((key, value) {
        others![key] = HazardDetails.fromJson(value);
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['vendor_name'] = vendorName;
    data['value'] = value;
    data['rating'] = rating;
    data['priority'] = priority;
    if (date != null) {
      data['date'] = {
        '_seconds': date!.millisecondsSinceEpoch ~/ 1000,
        '_nanoseconds': (date!.microsecondsSinceEpoch % 1000000) * 1000,
      };
    }

    if (others != null) {
      data['others'] =
          others!.map((key, value) => MapEntry(key, value.toJson()));
    }

    return data;
  }

  @override
  String toString() {
    return 'HazardDetails(vendorName: $vendorName, value: $value, rating: $rating, priority: $priority, date: $date, others: $others)';
  }
}

class FinalAddress {
  String? campusId;
  String? campusKey;
  String? country;
  String? locationIdForRef;
  bool? autoCertified;
  String? city;
  String? ownerId;
  double? latitude;
  String? description;
  String? percent;
  String? subAccountId;
  String? locationId;
  int? score;
  String? sovName;
  String? accountName;
  String? state;
  List<String>? placeTypes;
  String? placeId;
  String? ownerEmail;
  String? zip;
  Owner? owner;
  String? address;
  String? ownerName;
  String? subAccountName;
  String? companyId;
  int? lineNo;
  String? locationType;
  String? sovId;
  String? locationName;
  String? accountId;
  String? countryIsoCode;
  double? longitude;
  bool? rented;
  String ? companyName;

  FinalAddress({
    this.country,
    this.locationIdForRef,
    this.autoCertified,
    this.city,
    this.ownerId,
    this.latitude,
    this.description,
    this.percent,
    this.subAccountId,
    this.locationId,
    this.score,
    this.sovName,
    this.accountName,
    this.placeTypes,
    this.placeId,
    this.ownerEmail,
    this.zip,
    this.owner,
    this.address,
    this.ownerName,
    this.subAccountName,
    this.companyId,
    this.lineNo,
    this.locationType,
    this.sovId,
    this.locationName,
    this.accountId,
    this.countryIsoCode,
    this.longitude,
    this.state,
    this.campusId,
    this.campusKey,
    this.rented,
    this.companyName
  });

  FinalAddress.fromJson(Map<String, dynamic> json) {
    country = json['country'];
    locationIdForRef = json['location_id_for_ref'];
    autoCertified = json['auto_certified'];
    city = json['city'];
    ownerId = json['owner_id'];
    latitude = json['latitude']?.toDouble();
    description = json['description'];
    percent = json['percent'];
    subAccountId = json['sub_account_id'];
    locationId = json['location_id'];
    score = json['score'] is int
        ? json['score']
        : int.tryParse(json['score']?.toString() ?? '');
    sovName = json['sov_name'];
    accountName = json['account_name'];
    placeTypes = json['place_types'] != null
        ? List<String>.from(json['place_types'])
        : null;
    placeId = json['place_id'];
    ownerEmail = json['owner_email'];
    zip = json['zip'];
    owner = json['owner'] != null ? Owner.fromJson(json['owner']) : null;
    address = json['address'];
    ownerName = json['owner_name'];
    subAccountName = json['sub_account_name'];
    companyId = json['company_id'];
    lineNo = json['line_no']?.runtimeType == int
        ? json['line_no']
        : int.tryParse(json['line_no']?.toString() ?? '');
    locationType = json['location_type'];
    sovId = json['sov_id'];
    locationName = json['location_name'];
    accountId = json['account_id'];
    countryIsoCode = json['country_iso_code'];
    longitude = json['longitude']?.toDouble();
    state = json['state'];
    campusId = json['campus_name'];
    campusKey = json['campus_id'];
    rented = json['rented'];
    companyName=json['company_name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['country'] = country;
    data['location_id_for_ref'] = locationIdForRef;
    data['auto_certified'] = autoCertified;
    data['city'] = city;
    data['owner_id'] = ownerId;
    data['latitude'] = latitude;
    data['description'] = description;
    data['percent'] = percent;
    data['sub_account_id'] = subAccountId;
    data['location_id'] = locationId;
    data['score'] = score;
    data['sov_name'] = sovName;
    data['account_name'] = accountName;
    data['place_types'] = placeTypes;
    data['place_id'] = placeId;
    data['owner_email'] = ownerEmail;
    data['zip'] = zip;
    if (owner != null) {
      data['owner'] = owner!.toJson();
    }
    data['address'] = address;
    data['owner_name'] = ownerName;
    data['sub_account_name'] = subAccountName;
    data['company_id'] = companyId;
    data['line_no'] = lineNo;
    data['location_type'] = locationType;
    data['sov_id'] = sovId;
    data['location_name'] = locationName;
    data['account_id'] = accountId;
    data['country_iso_code'] = countryIsoCode;
    data['longitude'] = longitude;
    data['state'] = state;
    data['campus_name'] = campusId;
    data['campus_id'] = campusKey;
    data['rented'] = rented;
    data['company_name']=companyName;
    return data;
  }

  @override
  String toString() {
    return 'FinalAddress(country: $country, locationIdForRef: $locationIdForRef, autoCertified: $autoCertified, city: $city, ownerId: $ownerId, latitude: $latitude, description: $description, percent: $percent, subAccountId: $subAccountId, locationId: $locationId, score: $score, sovName: $sovName, accountName: $accountName, placeTypes: $placeTypes, placeId: $placeId, ownerEmail: $ownerEmail, zip: $zip, owner: $owner, address: $address, ownerName: $ownerName, subAccountName: $subAccountName, companyId: $companyId, lineNo: $lineNo, locationType: $locationType, sovId: $sovId, locationName: $locationName, accountId: $accountId, countryIsoCode: $countryIsoCode, longitude: $longitude, state: $state, campusId: $campusId, campusKey: $campusKey, rented: $rented)';
  }
}

class Owner {
  String? name;
  String? id;
  String? email;

  Owner({
    this.name,
    this.id,
    this.email,
  });

  Owner.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    id = json['id'];
    email = json['email'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['id'] = id;
    data['email'] = email;
    return data;
  }

  @override
  String toString() {
    return 'Owner(name: $name, id: $id, email: $email)';
  }
}

class DataCompleteness {
  int? scorePd;
  int? scoreTe;
  int? finalScore;

  DataCompleteness({this.scorePd, this.scoreTe, this.finalScore});

  DataCompleteness.fromJson(Map<String, dynamic> json) {
    scorePd = json['score_pd'];
    scoreTe = json['score_te'];
    finalScore = json['final_score'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['score_pd'] = this.scorePd;
    data['score_te'] = this.scoreTe;
    data['final_score'] = this.finalScore;
    return data;
  }
}

class GraphData {
  List<SovResults>? sovResults;
  GeocodeCounts? geocodeCounts;
  GlobalPerilCounts? globalPerilCounts;
  GlobalValueCounts? globalValueCounts;

  GraphData(
      {this.sovResults,
      this.geocodeCounts,
      this.globalPerilCounts,
      this.globalValueCounts});

  GraphData.fromJson(Map<String, dynamic> json) {
    if (json['sov_results'] != null) {
      sovResults = <SovResults>[];
      json['sov_results'].forEach((v) {
        sovResults!.add(new SovResults.fromJson(v));
      });
    }
    geocodeCounts = json['geocode_counts'] != null
        ? new GeocodeCounts.fromJson(json['geocode_counts'])
        : null;
    globalPerilCounts = json['global_peril_counts'] != null
        ? new GlobalPerilCounts.fromJson(json['global_peril_counts'])
        : null;
    globalValueCounts = json['global_value_counts'] != null
        ? new GlobalValueCounts.fromJson(json['global_value_counts'])
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
    if (this.globalPerilCounts != null) {
      data['global_peril_counts'] = this.globalPerilCounts!.toJson();
    }
    if (this.globalValueCounts != null) {
      data['global_value_counts'] = this.globalValueCounts!.toJson();
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

class Hurricane {
  int? total;
  int? completedData;

  Hurricane({this.total, this.completedData});

  Hurricane.fromJson(Map<String, dynamic> json) {
    total = json['total'];
    completedData = json['completed_data'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['total'] = this.total;
    data['completed_data'] = this.completedData;
    return data;
  }
}

class GlobalValueCounts {
  Loc25bfcd796acb71e8f9129a7c0ae26c4b6d2b18af?
      loc25bfcd796acb71e8f9129a7c0ae26c4b6d2b18af;
  Loc25bfcd796acb71e8f9129a7c0ae26c4b6d2b18af?
      loc351a6934fd19de8ce05e5115f69ffde105ea78b3;
  Loc25bfcd796acb71e8f9129a7c0ae26c4b6d2b18af?
      loc3626762930054003d3fd6c725c74c021c6a21915;
  LocA155789496fde8a79f2f3c4baf4949d8765fe752?
      locA155789496fde8a79f2f3c4baf4949d8765fe752;
  Loc25bfcd796acb71e8f9129a7c0ae26c4b6d2b18af?
      locD7ac9d1bc367b0d2232401eefb95cb4948030b4d;
  Loc25bfcd796acb71e8f9129a7c0ae26c4b6d2b18af?
      locFacc742ed5404e9084e4c755a95d895b9f801eda;

  GlobalValueCounts(
      {this.loc25bfcd796acb71e8f9129a7c0ae26c4b6d2b18af,
      this.loc351a6934fd19de8ce05e5115f69ffde105ea78b3,
      this.loc3626762930054003d3fd6c725c74c021c6a21915,
      this.locA155789496fde8a79f2f3c4baf4949d8765fe752,
      this.locD7ac9d1bc367b0d2232401eefb95cb4948030b4d,
      this.locFacc742ed5404e9084e4c755a95d895b9f801eda});

  GlobalValueCounts.fromJson(Map<String, dynamic> json) {
    loc25bfcd796acb71e8f9129a7c0ae26c4b6d2b18af =
        json['loc-25bfcd796acb71e8f9129a7c0ae26c4b6d2b18af'] != null
            ? new Loc25bfcd796acb71e8f9129a7c0ae26c4b6d2b18af.fromJson(
                json['loc-25bfcd796acb71e8f9129a7c0ae26c4b6d2b18af'])
            : null;
    loc351a6934fd19de8ce05e5115f69ffde105ea78b3 =
        json['loc-351a6934fd19de8ce05e5115f69ffde105ea78b3'] != null
            ? new Loc25bfcd796acb71e8f9129a7c0ae26c4b6d2b18af.fromJson(
                json['loc-351a6934fd19de8ce05e5115f69ffde105ea78b3'])
            : null;
    loc3626762930054003d3fd6c725c74c021c6a21915 =
        json['loc-3626762930054003d3fd6c725c74c021c6a21915'] != null
            ? new Loc25bfcd796acb71e8f9129a7c0ae26c4b6d2b18af.fromJson(
                json['loc-3626762930054003d3fd6c725c74c021c6a21915'])
            : null;
    locA155789496fde8a79f2f3c4baf4949d8765fe752 =
        json['loc-a155789496fde8a79f2f3c4baf4949d8765fe752'] != null
            ? new LocA155789496fde8a79f2f3c4baf4949d8765fe752.fromJson(
                json['loc-a155789496fde8a79f2f3c4baf4949d8765fe752'])
            : null;
    locD7ac9d1bc367b0d2232401eefb95cb4948030b4d =
        json['loc-d7ac9d1bc367b0d2232401eefb95cb4948030b4d'] != null
            ? new Loc25bfcd796acb71e8f9129a7c0ae26c4b6d2b18af.fromJson(
                json['loc-d7ac9d1bc367b0d2232401eefb95cb4948030b4d'])
            : null;
    locFacc742ed5404e9084e4c755a95d895b9f801eda =
        json['loc-facc742ed5404e9084e4c755a95d895b9f801eda'] != null
            ? new Loc25bfcd796acb71e8f9129a7c0ae26c4b6d2b18af.fromJson(
                json['loc-facc742ed5404e9084e4c755a95d895b9f801eda'])
            : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.loc25bfcd796acb71e8f9129a7c0ae26c4b6d2b18af != null) {
      data['loc-25bfcd796acb71e8f9129a7c0ae26c4b6d2b18af'] =
          this.loc25bfcd796acb71e8f9129a7c0ae26c4b6d2b18af!.toJson();
    }
    if (this.loc351a6934fd19de8ce05e5115f69ffde105ea78b3 != null) {
      data['loc-351a6934fd19de8ce05e5115f69ffde105ea78b3'] =
          this.loc351a6934fd19de8ce05e5115f69ffde105ea78b3!.toJson();
    }
    if (this.loc3626762930054003d3fd6c725c74c021c6a21915 != null) {
      data['loc-3626762930054003d3fd6c725c74c021c6a21915'] =
          this.loc3626762930054003d3fd6c725c74c021c6a21915!.toJson();
    }
    if (this.locA155789496fde8a79f2f3c4baf4949d8765fe752 != null) {
      data['loc-a155789496fde8a79f2f3c4baf4949d8765fe752'] =
          this.locA155789496fde8a79f2f3c4baf4949d8765fe752!.toJson();
    }
    if (this.locD7ac9d1bc367b0d2232401eefb95cb4948030b4d != null) {
      data['loc-d7ac9d1bc367b0d2232401eefb95cb4948030b4d'] =
          this.locD7ac9d1bc367b0d2232401eefb95cb4948030b4d!.toJson();
    }
    if (this.locFacc742ed5404e9084e4c755a95d895b9f801eda != null) {
      data['loc-facc742ed5404e9084e4c755a95d895b9f801eda'] =
          this.locFacc742ed5404e9084e4c755a95d895b9f801eda!.toJson();
    }
    return data;
  }
}

class Loc25bfcd796acb71e8f9129a7c0ae26c4b6d2b18af {
  String? bIValue;
  String? name;
  String? pDValue;

  Loc25bfcd796acb71e8f9129a7c0ae26c4b6d2b18af(
      {this.bIValue, this.name, this.pDValue});

  Loc25bfcd796acb71e8f9129a7c0ae26c4b6d2b18af.fromJson(
      Map<String, dynamic> json) {
    bIValue = json['BI Value'];
    name = json['name'];
    pDValue = json['PD Value'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['BI Value'] = this.bIValue;
    data['name'] = this.name;
    data['PD Value'] = this.pDValue;
    return data;
  }
}

class LocA155789496fde8a79f2f3c4baf4949d8765fe752 {
  String? bIValue;
  Null? name;
  String? pDValue;

  LocA155789496fde8a79f2f3c4baf4949d8765fe752(
      {this.bIValue, this.name, this.pDValue});

  LocA155789496fde8a79f2f3c4baf4949d8765fe752.fromJson(
      Map<String, dynamic> json) {
    bIValue = json['BI Value'];
    name = json['name'];
    pDValue = json['PD Value'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['BI Value'] = this.bIValue;
    data['name'] = this.name;
    data['PD Value'] = this.pDValue;
    return data;
  }
}

class Context {
  String? accountId;
  String? subAccountId;
  String? companyId;

  Context({this.accountId, this.subAccountId, this.companyId});

  Context.fromJson(Map<String, dynamic> json) {
    accountId = json['account_id'];
    subAccountId = json['sub_account_id'];
    companyId = json['company_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['account_id'] = this.accountId;
    data['sub_account_id'] = this.subAccountId;
    data['company_id'] = this.companyId;
    return data;
  }
}

class Locations {
  String? id;
  GlobalPerilCounts? perilCounts;
  ValueCounts? valueCounts;
  List<String>? distinctPerils;

  Locations({this.id, this.perilCounts, this.valueCounts, this.distinctPerils});

  Locations.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    perilCounts = json['peril_counts'] != null
        ? new GlobalPerilCounts.fromJson(json['peril_counts'])
        : null;
    valueCounts = json['value_counts'] != null
        ? new ValueCounts.fromJson(json['value_counts'])
        : null;
    distinctPerils = json['distinct_perils'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    if (this.perilCounts != null) {
      data['peril_counts'] = this.perilCounts!.toJson();
    }
    if (this.valueCounts != null) {
      data['value_counts'] = this.valueCounts!.toJson();
    }
    data['distinct_perils'] = this.distinctPerils;
    return data;
  }
}

class ValueCounts {
  String? bIValue;
  String? pDValue;

  ValueCounts({this.bIValue, this.pDValue});

  ValueCounts.fromJson(Map<String, dynamic> json) {
    bIValue = json['BI Value'];
    pDValue = json['PD Value'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['BI Value'] = this.bIValue;
    data['PD Value'] = this.pDValue;
    return data;
  }
}

class GeocodeCounts {
  int? i1;
  int? i2;
  int? i3;
  int? i4;
  int? i5;

  GeocodeCounts({this.i1, this.i2, this.i3, this.i4, this.i5});

  GeocodeCounts.fromJson(Map<String, dynamic> json) {
    i1 = json['1'];
    i2 = json['2'];
    i3 = json['3'];
    i4 = json['4'];
    i5 = json['5'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['1'] = this.i1;
    data['2'] = this.i2;
    data['3'] = this.i3;
    data['4'] = this.i4;
    data['5'] = this.i5;
    return data;
  }
}
