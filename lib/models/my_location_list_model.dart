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
  MyLocation? filterByLocationResult;
  GraphData? graphData;
  String? message;
  String? locationId;
  List<LocationComments>? locationComments;
  List<ActivityLogs>? activityLogs;

  MyLocationModel({
    this.totalRecords,
    this.totalCertified,
    this.page,
    this.pageSize,
    this.isConflict,
    this.isHazardCanStart,
    this.isAnyHazardProcessing,
    this.results,
    this.filterByLocationResult,
    this.graphData,
    this.message,
    this.locationId,
    this.locationComments,
    this.activityLogs,
  });

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
    filterByLocationResult = json['filter_by_location_result'] != null
        ? new MyLocation.fromJson(json['filter_by_location_result'])
        : null;
    graphData = json['graph_data'] != null
        ? new GraphData.fromJson(json['graph_data'])
        : null;
    message = json['message'];
    locationId = json['location_id'];
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
    if (this.filterByLocationResult != null) {
      data['filter_by_location_result'] = this.filterByLocationResult!.toJson();
    }
    data['graph_data'] = this.graphData!.toJson();
    data['message'] = this.message;
    data['location_id'] = this.locationId;
    if (this.locationComments != null) {
      data['location_comments'] =
          this.locationComments!.map((v) => v.toJson()).toList();
    }
    if (this.activityLogs != null) {
      data['activity_logs'] =
          this.activityLogs!.map((v) => v.toJson()).toList();
    }

    return data;
  }

  @override
  String toString() {
    return 'MyLocationModel(totalRecords: $totalRecords, totalCertified: $totalCertified, page: $page, pageSize: $pageSize, results: $results, filterByLocationResult: $filterByLocationResult)';
  }
}

class MyLocation with ClusterItem {
  String? accountId;
  String? accountName;
  String? subAccountId;
  String? subAccountName;
  String? locationId;
  double? latitude;
  double? longitude;
  String? placeId;
  String? locationName;
  String? address;
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
  List<ActivityLogs>? activityLogs;
  List<AllActivityLogs>? allActivityLogs;
  List<Subdestination>? subdestinations;
  List<Screenshots>? screenshots;
  bool? isHazardProcess;
  var dataCompleteness;
  bool? hasVendorData;
  bool? usFlag;
  bool? hasSov;

  MyLocation(
      {this.accountId,
      this.accountName,
      this.subAccountId,
      this.subAccountName,
      this.locationId,
      this.latitude,
      this.longitude,
      this.placeId,
      this.locationName,
      this.address,
      this.id,
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
      this.dataCompleteness,
      this.hasVendorData,
      this.hasSov,
      this.usFlag,
      required LatLng location});

  MyLocation.fromJson(Map<String, dynamic> json) {
    accountId = json['account_id'];
    accountName = json['account_name'];
    subAccountId = json['sub_account_id'];
    subAccountName = json['sub_account_name'];

    locationId = json['location_id'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    placeId = json['place_id'];
    locationName = json['location_name'];
    address = json['address'];
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
      json['all_activity_logs'].forEach((v) {
        allActivityLogs!.add(new AllActivityLogs.fromJson(v));
      });
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
    dataCompleteness = json['data_completeness'];
    hasVendorData = json['has_vendor_data'];
    usFlag = json['us_flag'];
    hasSov = json['has_sov'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['account_id'] = this.accountId;
    data['account_name'] = this.accountName;
    data['sub_account_id'] = this.subAccountId;
    data['sub_account_name'] = this.subAccountName;
    data['location_id'] = this.locationId;
    data['latitude'] = this.latitude;
    data['longitude'] = this.longitude;
    data['place_id'] = this.placeId;
    data['location_name'] = this.locationName;
    data['address'] = this.address;
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
      data['all_activity_logs'] =
          this.allActivityLogs!.map((v) => v.toJson()).toList();
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
    data['data_completeness'] = this.dataCompleteness;
    data['has_vendor_data'] = this.hasVendorData;
    data['us_flag'] = this.usFlag;
    data['has_sov'] = this.hasSov;
    return data;
  }

  @override
  String toString() {
    return 'MyLocation(id: $id, finalAddress: $finalAddress, overallScore: $overallScore, geocodingScore: $geocodingScore, hazard: $hazard, tags: $tags, geocodedAddress: $geocodedAddress, subdestinations: $subdestinations, screen_shots: $screenshots)';
  }

  @override
  LatLng get location => LatLng(
    latitude ?? finalAddress?.latitude ?? 0.0,
    longitude ?? finalAddress?.longitude ?? 0.0,
  );
}

class AllActivityLogs {
  dynamic actorUserId;
  String? eventId;
  At? at;
  dynamic companyId;
  String? targetType;
  String? action;
  String? targetId;
  DetailedChanges? detailedChanges;
  Event? event;

  AllActivityLogs(
      {this.actorUserId,
      this.eventId,
      this.at,
      this.companyId,
      this.targetType,
      this.action,
      this.targetId,
      this.detailedChanges,
      this.event});

  AllActivityLogs.fromJson(Map<String, dynamic> json) {
    actorUserId = json['actor_user_id'];
    eventId = json['event_id'];
    at = json['at'] != null ? new At.fromJson(json['at']) : null;
    companyId = json['company_id'];
    targetType = json['target_type'];
    action = json['action'];
    targetId = json['target_id'];
    detailedChanges = json['detailed_changes'] != null
        ? new DetailedChanges.fromJson(json['detailed_changes'])
        : null;
    event = json['event'] != null ? new Event.fromJson(json['event']) : null;
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
    if (this.detailedChanges != null) {
      data['detailed_changes'] = this.detailedChanges!.toJson();
    }
    if (this.event != null) {
      data['event'] = this.event!.toJson();
    }
    return data;
  }
}

class DetailedChanges {
  Added? added;
  Meta? meta;
  List<ChangesFlat>? changesFlat;
  dynamic modified;

  DetailedChanges({this.added, this.meta, this.changesFlat, this.modified});

  DetailedChanges.fromJson(Map<String, dynamic> json) {
    // removed = json['removed'] != null ? new Removed.fromJson(json['removed']) : null;
    added = json['added'] != null ? new Added.fromJson(json['added']) : null;
    meta = json['meta'] != null ? new Meta.fromJson(json['meta']) : null;
    if (json['changes_flat'] != null) {
      changesFlat = <ChangesFlat>[];
      json['changes_flat'].forEach((v) {
        changesFlat!.add(new ChangesFlat.fromJson(v));
      });
    }
    // modified = json['modified'] != null ? new Removed.fromJson(json['modified']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();

    if (this.added != null) {
      data['added'] = this.added!.toJson();
    }
    if (this.meta != null) {
      data['meta'] = this.meta!.toJson();
    }
    if (this.changesFlat != null) {
      data['changes_flat'] = this.changesFlat!.map((v) => v.toJson()).toList();
    }

    return data;
  }
}

class Added {
  List<Subdestinations>? subdestinations;

  Added({this.subdestinations});

  Added.fromJson(Map<String, dynamic> json) {
    if (json['subdestinations'] != null) {
      subdestinations = <Subdestinations>[];
      json['subdestinations'].forEach((v) {
        subdestinations!.add(new Subdestinations.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.subdestinations != null) {
      data['subdestinations'] =
          this.subdestinations!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Subdestinations {
  String? address;
  String? id;
  double? lat;
  double? lng;
  String? name;
  String? placeId;
  List<String>? types;

  Subdestinations(
      {this.address,
      this.id,
      this.lat,
      this.lng,
      this.name,
      this.placeId,
      this.types});

  Subdestinations.fromJson(Map<String, dynamic> json) {
    address = json['address'];
    id = json['id'];
    lat = json['lat'];
    lng = json['lng'];
    name = json['name'];
    placeId = json['place_id'];
    types = json['types'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['address'] = this.address;
    data['id'] = this.id;
    data['lat'] = this.lat;
    data['lng'] = this.lng;
    data['name'] = this.name;
    data['place_id'] = this.placeId;
    data['types'] = this.types;
    return data;
  }
}

class Meta {
  bool? addedOnly;
  bool? firstWriteForDoc;

  Meta({this.addedOnly, this.firstWriteForDoc});

  Meta.fromJson(Map<String, dynamic> json) {
    addedOnly = json['added_only'];
    firstWriteForDoc = json['first_write_for_doc'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['added_only'] = this.addedOnly;
    data['first_write_for_doc'] = this.firstWriteForDoc;
    return data;
  }
}

class ChangesFlat {
  String? field;
  String? type;
  dynamic before;

  ChangesFlat({this.field, this.type, this.before});

  ChangesFlat.fromJson(Map<String, dynamic> json) {
    field = json['field'];
    type = json['type'];
    before = json['before'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['field'] = this.field;
    data['type'] = this.type;
    data['before'] = this.before;

    return data;
  }
}

class Event {
  Params? params;
  dynamic timestamp;

  Event({this.params, this.timestamp});

  Event.fromJson(Map<String, dynamic> json) {
    params =
        json['params'] != null ? new Params.fromJson(json['params']) : null;
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

class UpdatedAt {
  At? before;

// Removed? after;

  UpdatedAt({this.before});

  UpdatedAt.fromJson(Map<String, dynamic> json) {
    before = json['before'] != null ? new At.fromJson(json['before']) : null;
// after = json['after'] != null ? new Removed.fromJson(json['after']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.before != null) {
      data['before'] = this.before!.toJson();
    }
// if (this.after != null) {
// data['after'] = this.after!.toJson();
// }
    return data;
  }
}

class Status {
  String? dAEN5YjpVOXIk1josXgy;

  Status({this.dAEN5YjpVOXIk1josXgy});

  Status.fromJson(Map<String, dynamic> json) {
    dAEN5YjpVOXIk1josXgy = json['DAEN5YjpVOXIk1josXgy'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['DAEN5YjpVOXIk1josXgy'] = this.dAEN5YjpVOXIk1josXgy;
    return data;
  }
}

class At {
  int? iSeconds;
  int? iNanoseconds;

  At({this.iSeconds, this.iNanoseconds});

  At.fromJson(Map<String, dynamic> json) {
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
  dynamic placeTypes;
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
    placeTypes = json['place_types'];
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
  Null duplicates;
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
  String? imageUrl;
  String? userId;
  String? email;
  String? name;
  dynamic role;
  List<Role> roles = []; // ⭐ Added this line

  User({
    this.imageUrl,
    this.userId,
    this.role,
    this.email,
    this.name,
    this.roles = const [],
  });

  User.fromJson(Map<String, dynamic> json) {
    imageUrl = json['image_url'];
    userId = json['user_id'];
    email = json['email'];
    name = json['name'];
    role = json['role'];
// ⭐ parse role list safely
    if (json["role"] != null && json["role"] is List) {
      roles = (json["role"] as List).map((e) => Role.fromJson(e)).toList();
    } else {
      roles = [];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['image_url'] = imageUrl;
    data['user_id'] = userId;
    data['email'] = email;
    data['name'] = name;
    data['role'] = this.role;
// ⭐ convert roles to json list
    data["role"] = roles.map((e) => e.toJson()).toList();

    return data;
  }
}

class Role {
  final String id;
  final String name;
  final String description;
  final bool isApplicableForTrial;
  final bool isSelectable;
  final bool isForIndividual;
  final int trialPeriodDays;
  final bool isMultipleRoleEnabled;
  final bool status;
  final SovOperations sovOperations;

  Role({
    required this.id,
    required this.name,
    required this.description,
    required this.isApplicableForTrial,
    required this.isSelectable,
    required this.isForIndividual,
    required this.trialPeriodDays,
    required this.isMultipleRoleEnabled,
    required this.status,
    required this.sovOperations,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json["id"] ?? "",
      name: json["name"] ?? "",
      description: json["description"] ?? "",
      isApplicableForTrial: json["is_applicable_for_trial"] ?? false,
      isSelectable: json["is_selectable"] ?? false,
      isForIndividual: json["is_for_individual"] ?? false,
      trialPeriodDays: json["trial_period_days"] ?? 0,
      isMultipleRoleEnabled: json["is_multiple_role_enabled"] ?? false,
      status: json["status"] ?? false,
      sovOperations: SovOperations.fromJson(json["sov_operations"] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "description": description,
        "is_applicable_for_trial": isApplicableForTrial,
        "is_selectable": isSelectable,
        "is_for_individual": isForIndividual,
        "trial_period_days": trialPeriodDays,
        "is_multiple_role_enabled": isMultipleRoleEnabled,
        "status": status,
        "sov_operations": sovOperations.toJson(),
      };
}

class SovOperations {
  final bool view;
  final bool edit;
  final bool comment;

  SovOperations({
    required this.view,
    required this.edit,
    required this.comment,
  });

  factory SovOperations.fromJson(Map<String, dynamic> json) {
    return SovOperations(
      view: json["view"] ?? false,
      edit: json["edit"] ?? false,
      comment: json["comment"] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        "view": view,
        "edit": edit,
        "comment": comment,
      };
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
  dynamic locationType;
  var sovId;
  String? locationName;
  String? accountId;
  String? countryIsoCode;
  double? longitude;
  bool? rented;
  String? companyName;

  FinalAddress(
      {this.campusId,
      this.campusKey,
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
      this.rented,
      this.companyName});

  FinalAddress.fromJson(Map<String, dynamic> json) {
    campusId = json['campus_id'];
    campusKey = json['campus_key'];
    country = json['country'];
    locationIdForRef = json['location_id_for_ref'];
    autoCertified = json['auto_certified'];
    city = json['city'];
    ownerId = json['owner_id'];
    latitude = json['latitude'] == null
        ? null
        : double.tryParse(json['latitude'].toString());

    longitude = json['longitude'] == null
        ? null
        : double.tryParse(json['longitude'].toString());

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
    state = json['state'];

    rented = json['rented'];
    companyName = json['company_name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['campus_id'] = campusId;
    data['campus_name'] = campusKey;
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

    data['rented'] = rented;
    data['company_name'] = companyName;
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
  GlobalPerilCounts? globalSovPerilCounts;
  PdValues? pdValues;

  GraphData(
      {this.sovResults,
      this.geocodeCounts,
      this.globalSovPerilCounts,
      this.pdValues});

  GraphData.fromJson(Map<String, dynamic> json) {
    if (json['sov_results'] != null) {
      sovResults = <SovResults>[];
      json['sov_results'].forEach((v) {
        sovResults!.add(SovResults.fromJson(v));
      });
    }

    geocodeCounts = json['geocode_counts'] != null
        ? GeocodeCounts.fromJson(json['geocode_counts'])
        : null;

    globalSovPerilCounts = json['global_peril_counts'] != null
        ? GlobalPerilCounts.fromJson(json['global_peril_counts'])
        : null;
    pdValues =
        json['pd_values'] != null ? PdValues.fromJson(json['pd_values']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (sovResults != null) {
      data['sov_results'] = sovResults!.map((v) => v.toJson()).toList();
    }
    if (geocodeCounts != null) {
      data['geocode_counts'] = geocodeCounts!.toJson();
    }
    if (globalSovPerilCounts != null) {
      data['global_peril_counts'] = globalSovPerilCounts!.toJson();
    }
    if (pdValues != null) {
      data['pd_values'] = pdValues!.toJson();
    }
    return data;
  }
}

class PdValues {
  Map<String, PdScore>? byDataCompletenessScore;
  Map<String, PdScore>? byGeocodeScore;
  Map<String, PdScore>? byOverallScore;

  PdValues({
    this.byDataCompletenessScore,
    this.byGeocodeScore,
    this.byOverallScore,
  });

  factory PdValues.fromJson(Map<String, dynamic> json) {
    return PdValues(
      byDataCompletenessScore: json['by_data_completeness_score'] != null
          ? Map<String, PdScore>.from(
              json['by_data_completeness_score'].map(
                (k, v) => MapEntry(k, PdScore.fromJson(v)),
              ),
            )
          : {},
      byGeocodeScore: json['by_geocode_score'] != null
          ? Map<String, PdScore>.from(
              json['by_geocode_score'].map(
                (k, v) => MapEntry(k, PdScore.fromJson(v)),
              ),
            )
          : {},
      byOverallScore: json['by_overall_score'] != null
          ? Map<String, PdScore>.from(
              json['by_overall_score'].map(
                (k, v) => MapEntry(k, PdScore.fromJson(v)),
              ),
            )
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (byDataCompletenessScore != null) {
      data['by_data_completeness_score'] =
          byDataCompletenessScore!.map((k, v) => MapEntry(k, v.toJson()));
    }
    if (byGeocodeScore != null) {
      data['by_geocode_score'] =
          byGeocodeScore!.map((k, v) => MapEntry(k, v.toJson()));
    }
    if (byOverallScore != null) {
      data['by_overall_score'] =
          byOverallScore!.map((k, v) => MapEntry(k, v.toJson()));
    }

    return data;
  }
}

class PdScore {
  double? avgPdValue;
  int? locationsCount;
  int? overallScore;
  double? pctOfTotal;
  String? sovId;
  double? totalPdValue;

  PdScore({
    this.avgPdValue,
    this.locationsCount,
    this.overallScore,
    this.pctOfTotal,
    this.sovId,
    this.totalPdValue,
  });

  factory PdScore.fromJson(Map<String, dynamic> json) {
    return PdScore(
      avgPdValue: (json['avg_pd_value'] ?? 0).toDouble(),
      locationsCount: json['locations_count'] ?? 0,
      overallScore: json['overall_score'] ?? 0,
      pctOfTotal: (json['pct_of_total'] ?? 0).toDouble(),
      sovId: json['sov_id'] ?? '',
      totalPdValue: (json['total_pd_value'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'avg_pd_value': avgPdValue,
      'locations_count': locationsCount,
      'overall_score': overallScore,
      'pct_of_total': pctOfTotal,
      'sov_id': sovId,
      'total_pd_value': totalPdValue,
    };
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
  Map<String, Hurricane>? globalPerilCounts;

  GlobalPerilCounts({this.globalPerilCounts});

  GlobalPerilCounts.fromJson(Map<String, dynamic> json) {
    globalPerilCounts = {};
    json.forEach((key, value) {
      globalPerilCounts![key] = Hurricane.fromJson(value);
    });
    }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    globalPerilCounts?.forEach((key, value) {
      data[key] = value.toJson();
    });
    return data;
  }
}

class Hurricane {
  int? completedDataLocations;
  var completionRate;
  int? totalLocationsWithPeril;

  Hurricane(
      {this.completedDataLocations,
      this.completionRate,
      this.totalLocationsWithPeril});

  Hurricane.fromJson(Map<String, dynamic> json) {
    completedDataLocations = json['completed_data_locations'];
    completionRate = json['completion_rate'];
    totalLocationsWithPeril = json['total_locations_with_peril'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['completed_data_locations'] = this.completedDataLocations;
    data['completion_rate'] = this.completionRate;
    data['total_locations_with_peril'] = this.totalLocationsWithPeril;
    return data;
  }
}
// class Hurricane {
//   int? total;
//   int? completedData;
//
//   Hurricane({this.total, this.completedData});
//
//   Hurricane.fromJson(Map<String, dynamic> json) {
//     total = json['total'];
//     completedData = json['completed_data'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['total'] = this.total;
//     data['completed_data'] = this.completedData;
//     return data;
//   }
// }

class GlobalValueCounts {
  Map<String, LocationValue>? globalValueCounts;

  GlobalValueCounts({this.globalValueCounts});

  GlobalValueCounts.fromJson(Map<String, dynamic> json) {
    globalValueCounts = {};
    json.forEach((key, value) {
      globalValueCounts![key] = LocationValue.fromJson(value);
    });
    }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    globalValueCounts?.forEach((key, value) {
      data[key] = value.toJson();
    });
    return data;
  }
}

class LocationValue {
  String? pdValue;
  String? name;
  String? address;

  LocationValue({this.pdValue, this.name, this.address});

  factory LocationValue.fromJson(Map<String, dynamic> json) {
    return LocationValue(
      pdValue: json['PD Value']?.toString(),
      name: json['name'],
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'PD Value': pdValue,
      'name': name,
      'address': address,
    };
  }
}

//
// class GlobalValueCounts {
//   Loc01998dc1059b5f213560d3c5174c9a80402c58f3?
//   loc01998dc1059b5f213560d3c5174c9a80402c58f3;
//   Loc01998dc1059b5f213560d3c5174c9a80402c58f3?
//   loc04f1eb0d359d4bb45b2f272caed9b279fd100de3;
//
//   GlobalValueCounts(
//       {this.loc01998dc1059b5f213560d3c5174c9a80402c58f3,
//         this.loc04f1eb0d359d4bb45b2f272caed9b279fd100de3});
//
//   GlobalValueCounts.fromJson(Map<String, dynamic> json) {
//     loc01998dc1059b5f213560d3c5174c9a80402c58f3 =
//     json['loc-01998dc1059b5f213560d3c5174c9a80402c58f3'] != null
//         ? new Loc01998dc1059b5f213560d3c5174c9a80402c58f3.fromJson(
//         json['loc-01998dc1059b5f213560d3c5174c9a80402c58f3'])
//         : null;
//     loc04f1eb0d359d4bb45b2f272caed9b279fd100de3 =
//     json['loc-04f1eb0d359d4bb45b2f272caed9b279fd100de3'] != null
//         ? new Loc01998dc1059b5f213560d3c5174c9a80402c58f3.fromJson(
//         json['loc-04f1eb0d359d4bb45b2f272caed9b279fd100de3'])
//         : null;
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     if (this.loc01998dc1059b5f213560d3c5174c9a80402c58f3 != null) {
//       data['loc-01998dc1059b5f213560d3c5174c9a80402c58f3'] =
//           this.loc01998dc1059b5f213560d3c5174c9a80402c58f3!.toJson();
//     }
//     if (this.loc04f1eb0d359d4bb45b2f272caed9b279fd100de3 != null) {
//       data['loc-04f1eb0d359d4bb45b2f272caed9b279fd100de3'] =
//           this.loc04f1eb0d359d4bb45b2f272caed9b279fd100de3!.toJson();
//     }
//     return data;
//   }
// }

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
  dynamic bIValue;
  dynamic pDValue;

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

class UserManagementResponse {
  final User user;

  UserManagementResponse({
    required this.user,
  });

  factory UserManagementResponse.fromJson(Map<String, dynamic> json) {
    return UserManagementResponse(
      user: User.fromJson(json['user'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        "user": user.toJson(),
      };
}
