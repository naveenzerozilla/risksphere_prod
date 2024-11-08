class SubAccountListModel {
  int? totalHits;
  List<SubAccounts>? results;
  int? totalPages;
  Settings? settings;


  SubAccountListModel({this.totalHits, this.results, this.totalPages, this.settings});

  SubAccountListModel.fromJson(Map<String, dynamic> json) {
    totalHits = json['totalRecords'];
    if (json['results'] != null) {
      results = <SubAccounts>[];
      json['results'].forEach((v) {
        results!.add(SubAccounts.fromJson(v));
      });
    }
    totalPages = json['totalPages'];
    settings = json['settings'] != null ? Settings.fromJson(json['settings']) : null;
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
    return data;
  }
}

class SubAccounts {
  String? path;
  String? name;
  int? sovCount;
  Owner? owner;
  String? accountId;
  String? subAccountId;
  int? lastModified;
  String? objectID;
  bool isChecked = false; // Local variable, not part of JSON serialization
  bool disabled = false;

  SubAccounts({
    this.path,
    this.name,
    this.sovCount,
    this.owner,
    this.accountId,
    this.subAccountId,
    this.lastModified,
    this.objectID,
    this.disabled = false,
  });

  SubAccounts.fromJson(Map<String, dynamic> json) {
    path = json['path'];
    name = json['name'];
    sovCount = json['sov_count'];
    owner = json['owner'] != null ? Owner.fromJson(json['owner']) : null;

    accountId = json['account_id'];
    subAccountId = json['sub_account_id'];

    objectID = json['objectID'];
    disabled = json['is_disabled'] ?? false;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['path'] = path;
    data['name'] = name;
    data['sov_count'] = sovCount;
    if (owner != null) {
      data['owner'] = owner!.toJson();
    }
    data['account_id'] = accountId;
    data['sub_account_id'] = subAccountId;
    data['objectID'] = objectID;
    return data;
  }

  @override
  String toString() {
    return 'SubAccount(subAccountId: $subAccountId, name: $name, isChecked: $isChecked)';
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
  bool? owner;
  bool? sovCount;

  Settings({this.owner, this.sovCount});

  Settings.fromJson(Map<String, dynamic> json) {
    owner = json['owner'];
    sovCount = json['sov_count'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['owner'] = owner;
    data['sov_count'] = sovCount;
    return data;
  }
}
