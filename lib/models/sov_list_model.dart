class SovListModel {
  int? totalHits;
  List<SovAccount>? results;
  int? totalPages;
  Settings? settings;
  int? totalRecords;

  SovListModel({this.totalHits, this.results, this.totalPages, this.settings});

  SovListModel.fromJson(Map<String, dynamic> json) {
    totalHits = json['totalHits'];
    if (json['results'] != null) {
      results = <SovAccount>[];
      json['results'].forEach((v) {
        results!.add(SovAccount.fromJson(v));
      });
    }
    totalPages = json['totalPages'];
    settings = json['settings'] != null ? Settings.fromJson(json['settings']) : null;
    totalRecords = json['totalRecords'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['totalHits'] = totalHits;
    if (results != null) {
      data['results'] = results!.map((v) => v.toJson()).toList();
    }
    data['totalPages'] = totalPages;
    if (settings != null) {
      data['settings'] = settings!.toJson();
    }
    data['totalRecords'] = totalRecords;
    return data;
  }
}

class SovAccount {
  String? id;
  String? path;
  String? name;
  Owner? owner;
  int? createdAt;
  String? accountId;
  String? subAccountId;
  String? objectID;
  double? overAllScore;
  int? locationCount;
  bool isChecked = false; // Local variable, not part of JSON serialization
  bool disabled = false;

  SovAccount({
    this.id,
    this.path,
    this.name,
    this.owner,
    this.createdAt,
    this.accountId,
    this.subAccountId,
    this.objectID,
    this.overAllScore,
    this.locationCount,
    this.isChecked = false,
    this.disabled = false,
  });

  SovAccount.fromJson(Map<String, dynamic> json) {
    id = json['sov_id'];
    path = json['path'];
    name = json['name'];
    owner = json['owner'] != null ? Owner.fromJson(json['owner']) : null;
    //createdAt = json['created_at'];
    accountId = json['account_id'];
    subAccountId = json['sub_account_id'];
    objectID = json['objectID'];
    if(json['over_all_score'].runtimeType == int) {
      overAllScore = json['over_all_score'].toDouble();
    } else {
      overAllScore = json['over_all_score'];
    }
    locationCount = json['location_count'];
    disabled = json['is_disabled'] ?? false;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['path'] = path;
    data['name'] = name;
    if (owner != null) {
      data['owner'] = owner!.toJson();
    }
    //data['created_at'] = createdAt;
    data['account_id'] = accountId;
    data['sub_account_id'] = subAccountId;
    data['objectID'] = objectID;
    data['overAllScore'] = overAllScore;
    data['locationCount'] = locationCount;
    data['sov_id'] = id;
    data['is_disabled'] = disabled;
    return data;
  }

  @override
  String toString() {
    return 'SovAccount(subAccountId: $subAccountId, name: $name, isChecked: $isChecked, path: $path, owner: $owner, createdAt: $createdAt, accountId: $accountId, objectID: $objectID, overAllScore: $overAllScore, locationCount: $locationCount, disabled: $disabled)';
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

class Settings {
  bool? locationCount;
  bool? overAllScore;

  Settings({this.locationCount, this.overAllScore});

  Settings.fromJson(Map<String, dynamic> json) {
    locationCount = json['location_count'];
    overAllScore = json['over_all_score'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['location_count'] = locationCount;
    data['over_all_score'] = overAllScore;
    return data;
  }
}
