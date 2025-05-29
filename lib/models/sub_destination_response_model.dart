class SubDestinationResponse {
  String? message;
  List<SubDestination>? results;

  SubDestinationResponse({this.message, this.results});

  SubDestinationResponse.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    if (json['results'] != null) {
      results = <SubDestination>[];
      json['results'].forEach((v) {
        results!.add(SubDestination.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['message'] = message;
    if (results != null) {
      data['results'] = results!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class SubDestination {
  String? address;
  String? id;
  double? lat;
  double? lng;
  String? name;
  String? placeId;
  List<String>? types;

  SubDestination({this.address, this.id, this.lat, this.lng, this.name, this.placeId, this.types});

  SubDestination.fromJson(Map<String, dynamic> json) {
    address = json['address'];
    id = json['id'];
    lat = json['lat'];
    lng = json['lng'];
    name = json['name'];
    placeId = json['place_id'];
    types = json['types'] != null ? List<String>.from(json['types']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['address'] = address;
    data['id'] = id;
    data['lat'] = lat;
    data['lng'] = lng;
    data['name'] = name;
    data['place_id'] = placeId;
    if (types != null) {
      data['types'] = types;
    }
    return data;
  }
}
