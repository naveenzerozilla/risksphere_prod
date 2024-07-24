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

