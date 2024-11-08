/*
class LocationProfileModel {
  String? locationIdForRef;
  String? country;
  bool? autoCertified;
  String? city;
  String? ownerId;
  double? latitude;
  String? description;
  String? subAccountId;
  String? percent;
  String? locationId;
  int? score;
  List<String>? placeTypes;
  String? state;
  String? placeId;
  double? longitude;
  Owner? owner;
  String? zip;
  String? ownerEmail;
  String? address;
  String? ownerName;
  bool? isSubdestination;
  String? campusId;
  dynamic locationType; // This can be either a String or a List<String>
  String? sovId;
  String? locationName;
  String? accountId;
  List<Subdestination>? subdestinations;
  List<Screenshots>? screenShots;

  LocationProfileModel({
    this.locationIdForRef,
    this.country,
    this.autoCertified,
    this.city,
    this.ownerId,
    this.latitude,
    this.description,
    this.subAccountId,
    this.percent,
    this.locationId,
    this.score,
    this.placeTypes,
    this.state,
    this.placeId,
    this.longitude,
    this.owner,
    this.zip,
    this.ownerEmail,
    this.address,
    this.ownerName,
    this.isSubdestination,
    this.campusId,
    this.locationType,
    this.sovId,
    this.locationName,
    this.accountId,
    this.subdestinations,
    this.screenShots,
  });

  LocationProfileModel.fromJson(Map<String, dynamic> json) {
    locationIdForRef = json['location_id_for_ref'];
    country = json['country'];
    autoCertified = json['auto_certified'];
    city = json['city'];
    ownerId = json['owner_id'];
    latitude = json['latitude']?.toDouble();
    description = json['description'];
    subAccountId = json['sub_account_id'];
    percent = json['percent'];
    locationId = json['location_id'];
    score = json['score'];
    placeTypes = json['place_types'] is String
        ? [json['place_types']]
        : (json['place_types'] as List?)?.map((item) => item as String).toList();
    state = json['state'];
    placeId = json['place_id'];
    print('locationIdForRef: $locationIdForRef, placeId: $placeId');
    longitude = json['longitude']?.toDouble();
    owner = json['owner'] != null ? Owner.fromJson(json['owner']) : null;
    zip = json['zip'];
    ownerEmail = json['owner_email'];
    address = json['address'];
    ownerName = json['owner_name'];
    isSubdestination = json['is_subdestination'];
    campusId = json['campus_id'];
    locationType = json['location_type'] is String
        ? json['location_type']
        : (json['location_type'] as List?)?.map((item) => item as String).toList();
    sovId = json['sov_id'];
    locationName = json['location_name'];
    accountId = json['account_id'];
    subdestinations = (json['subdestinations'] as List?)?.map((item) => Subdestination.fromJson(item)).toList();
    screenShots = (json['screen_shots'] as List?)?.map((item) => Screenshots.fromJson(item)).toList();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['location_id_for_ref'] = locationIdForRef;
    data['country'] = country;
    data['auto_certified'] = autoCertified;
    data['city'] = city;
    data['owner_id'] = ownerId;
    data['latitude'] = latitude;
    data['description'] = description;
    data['sub_account_id'] = subAccountId;
    data['percent'] = percent;
    data['location_id'] = locationId;
    data['score'] = score;
    data['place_types'] = placeTypes;
    data['state'] = state;
    data['place_id'] = placeId;
    data['longitude'] = longitude;
    if (owner != null) {
      data['owner'] = owner!.toJson();
    }
    data['zip'] = zip;
    data['owner_email'] = ownerEmail;
    data['address'] = address;
    data['owner_name'] = ownerName;
    data['is_subdestination'] = isSubdestination;
    data['campus_id'] = campusId;
    if (locationType is String) {
      data['location_type'] = locationType;
    } else if (locationType is List) {
      data['location_type'] = (locationType as List).join(',');
    }
    data['sov_id'] = sovId;
    data['location_name'] = locationName;
    data['account_id'] = accountId;
    if (subdestinations != null) {
      data['subdestinations'] = subdestinations!.map((v) => v.toJson()).toList();
    }
    if (screenShots != null) {
      data['screen_shots'] = screenShots!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class FinalAddress {
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
    score = json['score'];
    sovName = json['sov_name'];
    accountName = json['account_name'];
    placeTypes = json['place_types'] != null ? List<String>.from(json['place_types']) : null;
    placeId = json['place_id'];
    ownerEmail = json['owner_email'];
    zip = json['zip'];
    owner = json['owner'] != null ? Owner.fromJson(json['owner']) : null;
    address = json['address'];
    ownerName = json['owner_name'];
    subAccountName = json['sub_account_name'];
    companyId = json['company_id'];
    lineNo = json['line_no'];
    locationType = json['location_type'];
    sovId = json['sov_id'];
    locationName = json['location_name'];
    accountId = json['account_id'];
    countryIsoCode = json['country_iso_code'];
    longitude = json['longitude']?.toDouble();
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
    return data;
  }
}
*/

class LocationProfileModel {
  int? totalRecords;
  int? totalCertified;
  int? page;
  int? pageSize;
  List<LocationResult>? results;

  LocationProfileModel({
    this.totalRecords,
    this.totalCertified,
    this.page,
    this.pageSize,
    this.results,
  });

  LocationProfileModel.fromJson(Map<String, dynamic> json) {
    totalRecords = json['totalRecords'];
    totalCertified = json['totalCertified'];
    page = json['page'];
    pageSize = json['pageSize'];
    if (json['result'] != null) {
      results = <LocationResult>[];
      json['result'].forEach((v) {
        results!.add(LocationResult.fromJson(v));
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
    return data;
  }
}

class LocationResult {
  String? id;
  FinalAddress? finalAddress;
  int? geocodingScore;
  List<String>? tags;
  String? geocodedAddress;
  List<Screenshots>? screenShots;
  List<Subdestination>? subdestinations;

  LocationResult({
    this.id,
    this.finalAddress,
    this.geocodingScore,
    this.tags,
    this.geocodedAddress,
    this.screenShots,
    this.subdestinations,
  });

  LocationResult.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    finalAddress = json['final_address'] != null
        ? FinalAddress.fromJson(json['final_address'])
        : null;
    geocodingScore = json['geocoding_score'];
    tags = json['tags'] != null ? List<String>.from(json['tags']) : null;
    geocodedAddress = json['geocoded_address'];
    screenShots = (json['screen_shots'] as List?)?.map((item) => Screenshots.fromJson(item)).toList();
    subdestinations = (json['subdestinations'] as List?)?.map((item) => Subdestination.fromJson(item)).toList();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    if (finalAddress != null) {
      data['final_address'] = finalAddress!.toJson();
    }
    data['geocoding_score'] = geocodingScore;
    data['tags'] = tags;
    data['geocoded_address'] = geocodedAddress;
    if (screenShots != null) {
      data['screen_shots'] = screenShots!.map((v) => v.toJson()).toList();
    }
    if (subdestinations != null) {
      data['subdestinations'] = subdestinations!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class FinalAddress {
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
    score = json['score'];
    sovName = json['sov_name'];
    accountName = json['account_name'];
    placeTypes = json['place_types'] != null ? List<String>.from(json['place_types']) : null;
    placeId = json['place_id'];
    ownerEmail = json['owner_email'];
    zip = json['zip'];
    owner = json['owner'] != null ? Owner.fromJson(json['owner']) : null;
    address = json['address'];
    ownerName = json['owner_name'];
    subAccountName = json['sub_account_name'];
    companyId = json['company_id'];
    lineNo = json['line_no'];
    locationType = json['location_type'];
    sovId = json['sov_id'];
    locationName = json['location_name'];
    accountId = json['account_id'];
    countryIsoCode = json['country_iso_code'];
    longitude = json['longitude']?.toDouble();
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
    return data;
  }
}

// Owner, Subdestination, and Screenshots classes can remain the same.

class Owner {
  String? date;
  String? email;
  String? id;
  String? name;

  Owner({this.date, this.email, this.id, this.name});

  Owner.fromJson(Map<String, dynamic> json) {
    date = json['date'];
    email = json['email'];
    id = json['id'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['date'] = date;
    data['email'] = email;
    data['id'] = id;
    data['name'] = name;
    return data;
  }
}

class Subdestination {
  List<String>? types;
  String? address;
  double? lng;
  String? name;
  String? id;
  double? lat;
  String? placeId;
  String? status;
  String? campusId;
  bool isChecked = false;

  Subdestination({
    this.types,
    this.address,
    this.lng,
    this.name,
    this.id,
    this.lat,
    this.placeId,
    this.status,
    this.campusId,
  });

  Subdestination.fromJson(Map<String, dynamic> json) {
    types = (json['types'] as List?)?.map((item) => item as String).toList();
    address = json['address'];
    lng = json['lng']?.toDouble();
    name = json['name'];
    id = json['id'];
    lat = json['lat']?.toDouble();
    placeId = json['place_id'];
    status = json['status'];
    campusId = json['campus_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['types'] = types;
    data['address'] = address;
    data['lng'] = lng;
    data['name'] = name;
    data['id'] = id;
    data['lat'] = lat;
    data['place_id'] = placeId;
    data['status'] = status;
    data['campus_id'] = campusId;
    return data;
  }
}

class Screenshots {
  String? id;
  String? name;
  String? role;
  String? companyName;
  String? date;
  String? time;
  String? imageUrl;

  Screenshots({
    this.id,
    this.name,
    this.role,
    this.companyName,
    this.date,
    this.time,
    this.imageUrl,
  });

  Screenshots.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    role = json['role'];
    companyName = json['company_name'];
    date = json['date'];
    time = json['time'];
    imageUrl = json['image_url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['role'] = role;
    data['company_name'] = companyName;
    data['date'] = date;
    data['time'] = time;
    data['image_url'] = imageUrl;

    return data;
  }
}

