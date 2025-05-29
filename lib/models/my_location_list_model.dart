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
    if (json['filter_by_location_result'] != null) {
      filterByLocationResult = <MyLocation>[];
      json['filter_by_location_result'].forEach((v) {
        filterByLocationResult!.add(MyLocation.fromJson(v));
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
    if (filterByLocationResult != null) {
      data['filter_by_location_result'] =
          filterByLocationResult!.map((v) => v.toJson()).toList();
    }
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
  int? geocodingScore;
  bool? isSelected;
  bool? isConflict;
  List<Conflicts>? conflicts;
  int? defaultConflictindex;
  List<String>? tags;
  int? overallScore;
  Map<String, HazardDetails>? hazard; // Updated to hold vendor-specific data
  String? geocodedAddress;
  List<Subdestination>? subdestinations;
  List<Screenshots>? screenshots;
  bool? isHazardProcess;

  MyLocation(
      {this.id,
      this.finalAddress,
      this.geocodingScore,
      this.isSelected = false,
        this.isConflict,
        this.conflicts,
        this.defaultConflictindex,
      this.tags,
      this.overallScore,
      this.hazard,
      this.geocodedAddress,
      this.subdestinations,
      this.screenshots,
      this.isHazardProcess});

  MyLocation.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    finalAddress = json['final_address'] != null
        ? FinalAddress.fromJson(json['final_address'])
        : null;
    geocodingScore = json['geocoding_score'] is int
        ? json['geocoding_score']
        : int.tryParse(json['geocoding_score']?.toString() ?? '');
    isConflict = json['is_conflict'];
    if (json['conflicts'] != null) {
      conflicts = <Conflicts>[];
      json['conflicts'].forEach((v) { conflicts!.add(new Conflicts.fromJson(v)); });
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
    if (json['overall_score'] is int) {
      overallScore = json['overall_score'];
    } else {
      overallScore = int.tryParse(json['overallScore']?.toString() ?? '');
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
    isHazardProcess = json['is_hazard_processed'] ?? '';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    if (finalAddress != null) {
      data['final_address'] = finalAddress!.toJson();
    }
    data['geocoding_score'] = geocodingScore;
    data['is_conflict'] = this.isConflict;
    if (this.conflicts != null) {
      data['conflicts'] = this.conflicts!.map((v) => v.toJson()).toList();
    }
    data['default_conflict_index'] = defaultConflictindex;
    data['tags'] = tags;
    data['overall_score'] = overallScore;
    data['geocoded_address'] = geocodedAddress;
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


class Conflicts {
  List<UserAccounts>? userAccounts;
  EmbeddedAddress? embeddedAddress;
  FinalAddress? finalAddress;
  String? processId;
  List<String>? accountIndex;
  List<String>? subAccountIndex;
  // EnabledHazards? enabledHazards;
  List<Null>? dataParameters;
  String? geocodedAddress;
  bool? isHazardProcessed;
  String? mappedAddress;
  // List<History>? history;
  String? subProcessId;
  String? originalAddress;
  // EnabledHazards? dataParamIndex;
  String? locationId;

  Conflicts({this.userAccounts, this.embeddedAddress, this.finalAddress, this.processId, this.accountIndex, this.subAccountIndex,  this.dataParameters, this.geocodedAddress, this.isHazardProcessed, this.mappedAddress,  this.subProcessId, this.originalAddress, this.locationId});

  Conflicts.fromJson(Map<String, dynamic> json) {
    if (json['userAccounts'] != null) {
      userAccounts = <UserAccounts>[];
      json['userAccounts'].forEach((v) { userAccounts!.add(new UserAccounts.fromJson(v)); });
    }
    embeddedAddress = json['embedded_address'] != null ? new EmbeddedAddress.fromJson(json['embedded_address']) : null;
    finalAddress = json['final_address'] != null ? new FinalAddress.fromJson(json['final_address']) : null;
    processId = json['process_id'];
    accountIndex = json['account_index'].cast<String>();
    subAccountIndex = json['sub_account_index'].cast<String>();
    // enabledHazards = json['enabled_hazards'] != null ? new EnabledHazards.fromJson(json['enabled_hazards']) : null;
    // if (json['data_parameters'] != null) {
    //   dataParameters = <Null>[];
    //   json['data_parameters'].forEach((v) { dataParameters!.add(new Null.fromJson(v)); });
    // }
    geocodedAddress = json['geocoded_address'];
    isHazardProcessed = json['is_hazard_processed'];
    mappedAddress = json['mapped_address'];
    // if (json['history'] != null) {
    //   history = <History>[];
    //   json['history'].forEach((v) { history!.add(new History.fromJson(v)); });
    // }
    subProcessId = json['sub_process_id'];
    originalAddress = json['original_address'];
    // dataParamIndex = json['data_param_index'] != null ? new EnabledHazards.fromJson(json['data_param_index']) : null;
    locationId = json['location_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.userAccounts != null) {
      data['userAccounts'] = this.userAccounts!.map((v) => v.toJson()).toList();
    }
    if (this.embeddedAddress != null) {
      data['embedded_address'] = this.embeddedAddress!.toJson();
    }
    if (this.finalAddress != null) {
      data['final_address'] = this.finalAddress!.toJson();
    }
    data['process_id'] = this.processId;
    data['account_index'] = this.accountIndex;
    data['sub_account_index'] = this.subAccountIndex;
    // if (this.enabledHazards != null) {
    //   data['enabled_hazards'] = this.enabledHazards!.toJson();
    // }
    // if (this.dataParameters != null) {
    //   data['data_parameters'] = this.dataParameters!.map((v) => v.toJson()).toList();
    // }
    data['geocoded_address'] = this.geocodedAddress;
    data['is_hazard_processed'] = this.isHazardProcessed;
    data['mapped_address'] = this.mappedAddress;
    // if (this.history != null) {
    //   data['history'] = this.history!.map((v) => v.toJson()).toList();
    // }
    data['sub_process_id'] = this.subProcessId;
    data['original_address'] = this.originalAddress;
    // if (this.dataParamIndex != null) {
    //   data['data_param_index'] = this.dataParamIndex!.toJson();
    // }
    data['location_id'] = this.locationId;
    return data;
  }
}
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
  int? rating; // Hazard rating
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
