class SubAccountListModel {
  int? totalHits;
  List<SubAccounts>? results;
  int? totalPages;
  Settings? settings;

  SubAccountListModel(
      {this.totalHits, this.results, this.totalPages, this.settings});

  SubAccountListModel.fromJson(Map<String, dynamic> json) {
    totalHits = json['totalRecords'];
    if (json['results'] != null) {
      results = <SubAccounts>[];
      json['results'].forEach((v) {
        results!.add(SubAccounts.fromJson(v));
      });
    }
    totalPages = json['totalPages'];
    settings =
        json['settings'] != null ? Settings.fromJson(json['settings']) : null;
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
  bool? isDefault;
  Owner? owner;
  String? accountId;
  String? subAccountId;
  int? lastModified;
  String? objectID;
  int? locationCount;
  bool isChecked = false; // Local variable, not part of JSON serialization
  bool disabled = false;

  SubAccounts({
    this.path,
    this.name,
    this.sovCount,
    this.isDefault,
    this.owner,
    this.accountId,
    this.subAccountId,
    this.lastModified,
    this.objectID,
    this.locationCount,
    this.disabled = false,
  });

  SubAccounts.fromJson(Map<String, dynamic> json) {
    path = json['path'];
    name = json['name'];
    sovCount = json['sov_count'];
    isDefault = json['is_default'] ?? false;
    owner = json['owner'] != null ? Owner.fromJson(json['owner']) : null;

    accountId = json['account_id'];
    subAccountId = json['sub_account_id'];

    objectID = json['objectID'];
    locationCount = json['location_count'];
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
    data['location_count'] = this.locationCount;
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
  dynamic name;

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
  CompanyGlobalConfiguration? companyGlobalConfiguration;

  Settings({this.owner, this.sovCount, this.companyGlobalConfiguration});

  Settings.fromJson(Map<String, dynamic> json) {
    owner = json['owner'];
    sovCount = json['sov_count'];
    companyGlobalConfiguration = json['company_global_configuration'] != null
        ? new CompanyGlobalConfiguration.fromJson(
            json['company_global_configuration'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['owner'] = owner;
    data['sov_count'] = sovCount;
    if (this.companyGlobalConfiguration != null) {
      data['company_global_configuration'] =
          this.companyGlobalConfiguration!.toJson();
    }
    return data;
  }
}

class CompanyGlobalConfiguration {
  String? accountNames;
  String? accountName;

  CompanyGlobalConfiguration({this.accountNames, this.accountName});

  CompanyGlobalConfiguration.fromJson(Map<String, dynamic> json) {
    accountNames = json['sub_account_names'];
    accountName = json['sub_account_name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['sub_account_names'] = this.accountNames;
    data['sub_account_name'] = this.accountName;
    return data;
  }
}
