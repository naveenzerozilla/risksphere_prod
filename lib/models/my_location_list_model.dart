import 'package:google_maps_cluster_manager_2/google_maps_cluster_manager_2.dart';
import 'package:google_maps_flutter_platform_interface/src/types/location.dart';

import 'location_profile_model.dart';

class MyLocationModel {
  int? totalRecords;
  int? totalCertified;
  int? page;
  int? pageSize;
  List<MyLocation>? results;

  MyLocationModel({
    this.totalRecords,
    this.totalCertified,
    this.page,
    this.pageSize,
    this.results,
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

  @override
  String toString() {
    return 'MyLocationModel(totalRecords: $totalRecords, totalCertified: $totalCertified, page: $page, pageSize: $pageSize, results: $results)';
  }
}

class MyLocation with ClusterItem{
  String? id;
  FinalAddress? finalAddress;
  int? geocodingScore;
  bool? isSelected;
  List<String>? tags;
  int? overallScore;
  Map<String, Hazard>? hazard;
  String? geocodedAddress;
  List<Subdestination>? subdestinations;
  List<Screenshots>? screenshots;


  MyLocation({
    this.id,
    this.finalAddress,
    this.geocodingScore,
    this.isSelected = false,
    this.tags,
    this.overallScore,
    this.hazard,
    this.geocodedAddress,
    this.subdestinations,
    this.screenshots,
  });

  MyLocation.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    finalAddress = json['final_address'] != null
        ? FinalAddress.fromJson(json['final_address'])
        : null;
    geocodingScore = json['geocoding_score'] is int
        ? json['geocoding_score']
        : int.tryParse(json['geocoding_score']?.toString() ?? '');
    tags = json['tags'] != null ? List<String>.from(json['tags']) : null;
    if (json['overall_score'] is int) {
      overallScore = json['overall_score'];
    } else {
      overallScore = int.tryParse(json['overallScore']?.toString() ?? '');
    }
    geocodedAddress = json['geocoded_address']??'';
    if (json['hazard'] != null) {
      hazard = {};
      json['hazard'].forEach((key, value) {
        hazard![key] = Hazard.fromJson(value);
      });
    }
    if (json['subdestinations'] != null) {
      subdestinations = <Subdestination>[];
      json['subdestinations'].forEach((v) {
        subdestinations!.add(Subdestination.fromJson(v));
      });
    }

    if (json['screen_shots'] != null) { // Corrected condition here
      screenshots = <Screenshots>[];
      json['screen_shots'].forEach((v) {
        screenshots!.add(Screenshots.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    if (finalAddress != null) {
      data['final_address'] = finalAddress!.toJson();
    }
    data['geocoding_score'] = geocodingScore;
    data['tags'] = tags;
    data['overall_score'] = overallScore;
    data['geocoded_address'] = geocodedAddress;
    if (hazard != null) {
      data['hazard'] = hazard!.map((key, value) => MapEntry(key, value.toJson()));
    }
    if (subdestinations != null) {
      data['subdestinations'] = subdestinations!.map((v) => v.toJson()).toList();
    }
    if (screenshots != null) {
      data['screen_shots'] = screenshots!.map((v) => v.toJson()).toList();
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

class Hazard {
  int? priority;
  String? vendorName;
  dynamic value; // Can be a String, double, or "No Rating" etc.
  int? rating;
  //Date? date;

  Hazard({
    this.priority,
    this.vendorName,
    this.value,
    this.rating,
   // this.date,
  });

  Hazard.fromJson(Map<String, dynamic> json) {
    priority = json['priority'] is int
        ? json['priority']
        : int.tryParse(json['priority']?.toString() ?? '');
    vendorName = json['vendor_name'];
    value = json['value'];
    rating = json['rating'];
   // date = json['date'] != null ? Date.fromJson(json['date']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['priority'] = priority;
    data['vendor_name'] = vendorName;
    data['value'] = value;
    data['rating'] = rating;
  /*  if (date != null) {
      data['date'] = date!.toJson();
    }*/
    return data;
  }

  @override
  String toString() {
    return 'Hazard(priority: $priority, vendorName: $vendorName, value: $value, rating: $rating)';
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
    return data;
  }

  @override
  String toString() {
    return 'FinalAddress(country: $country, locationIdForRef: $locationIdForRef, autoCertified: $autoCertified, city: $city, ownerId: $ownerId, latitude: $latitude, description: $description, percent: $percent, subAccountId: $subAccountId, locationId: $locationId, score: $score, sovName: $sovName, accountName: $accountName, placeTypes: $placeTypes, placeId: $placeId, ownerEmail: $ownerEmail, zip: $zip, owner: $owner, address: $address, ownerName: $ownerName, subAccountName: $subAccountName, companyId: $companyId, lineNo: $lineNo, locationType: $locationType, sovId: $sovId, locationName: $locationName, accountId: $accountId, countryIsoCode: $countryIsoCode, longitude: $longitude, state: $state, campusId: $campusId, campusKey: $campusKey)';
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
