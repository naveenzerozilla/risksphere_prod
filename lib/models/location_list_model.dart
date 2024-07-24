class LocationListModel {
  int? totalHits;
  List<Location>? results;
  int? totalPages;
  List<String>? summaryList = [];

  LocationListModel({this.totalHits, this.results, this.totalPages, this.summaryList});

  LocationListModel.fromJson(Map<String, dynamic> json) {
    totalHits = json['totalHits'];
    if (json['results'] != null) {
      results = <Location>[];
      json['results'].forEach((v) {
        results!.add(Location.fromJson(v));
      });
    }
    totalPages = json['totalPages'];
    summaryList = json['summary'] != null ? List<String>.from(json['summary']) : [];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['totalHits'] = totalHits;
    if (results != null) {
      data['results'] = results!.map((v) => v.toJson()).toList();
    }
    data['totalPages'] = totalPages;
    data['summary'] = summaryList;
    return data;
  }
}

class Location {
  String? path;
  String? accountId;
  String? address;
  bool? autoCertified;
  String? city;
  dynamic country;
  String? description;
  List<String>? images;
  String? locationId;
  String? locationIdForRef;
  String? locationName;
  List<String>? locationType;
  Owner? owner;
  String? ownerEmail;
  String? ownerId;
  String? ownerName;
  List<String>? placeTypes;
  int? score;
  String? sovId;
  String? state;
  String? subAccountId;
  String? zip;
  String? objectID;
  bool isChecked = false; // Local variable, not part of JSON serialization
  String? percent;
  String? campusId;

  Location({
    this.path,
    this.accountId,
    this.address,
    this.autoCertified,
    this.city,
    this.country,
    this.description,
    this.images,
    this.locationId,
    this.locationIdForRef,
    this.locationName,
    this.locationType,
    this.owner,
    this.ownerEmail,
    this.ownerId,
    this.ownerName,
    this.placeTypes,
    this.score,
    this.sovId,
    this.state,
    this.subAccountId,
    this.zip,
    this.objectID,
    this.percent,
    this.isChecked = false,
    this.campusId,
  });

  Location.fromJson(Map<String, dynamic> json) {
    path = json['path'];
    accountId = json['account_id'];
    address = json['address'];
    autoCertified = json['auto_certified'];
    city = json['city'];
    country = json['country'];
    description = json['description'];
    images = json['images'] != null ? List<String>.from(json['images']) : null;
    locationId = json['location_id'];
    locationIdForRef = json['location_id_for_ref'];
    locationName = json['location_name'];
    locationType = json['location_type'] is List
        ? List<String>.from(json['location_type'])
        : [json['location_type']];
    owner = json['owner'] != null ? Owner.fromJson(json['owner']) : null;
    ownerEmail = json['owner_email'];
    ownerId = json['owner_id'];
    ownerName = json['owner_name'];
    placeTypes = json['place_types'] != null ? List<String>.from(json['place_types']) : null;
    score = json['score'];
    sovId = json['sov_id'];
    state = json['state'];
    subAccountId = json['sub_account_id'];
    zip = json['zip'];
    objectID = json['objectID'];
    percent = json['percent'];
    campusId = json['campus_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['path'] = path;
    data['account_id'] = accountId;
    data['address'] = address;
    data['auto_certified'] = autoCertified;
    data['city'] = city;
    data['country'] = country;
    data['description'] = description;
    if (images != null) {
      data['images'] = images;
    }
    data['location_id'] = locationId;
    data['location_id_for_ref'] = locationIdForRef;
    data['location_name'] = locationName;
    data['location_type'] = locationType;
    if (owner != null) {
      data['owner'] = owner!.toJson();
    }
    data['owner_email'] = ownerEmail;
    data['owner_id'] = ownerId;
    data['owner_name'] = ownerName;
    if (placeTypes != null) {
      data['place_types'] = placeTypes;
    }
    data['score'] = score;
    data['sov_id'] = sovId;
    data['state'] = state;
    data['sub_account_id'] = subAccountId;
    data['zip'] = zip;
    data['objectID'] = objectID;
    data['percent'] = percent;
    data['campus_id'] = campusId;
    return data;
  }

  @override
  String toString() {
    return 'Location(locationId: $locationId, locationName: $locationName, isChecked: $isChecked)';
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
