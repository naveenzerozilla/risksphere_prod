class AccountListModel {
  int? totalHits;
  List<Accounts>? results;
  int? totalPages;
  Settings? settings;

  AccountListModel({this.totalHits, this.results, this.totalPages, this.settings});

  AccountListModel.fromJson(Map<String, dynamic> json) {
    totalHits = json['totalHits'];
    if (json['results'] != null) {
      results = <Accounts>[];
      json['results'].forEach((v) {
        results!.add(Accounts.fromJson(v));
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

class Accounts {
  String? accountName;
  Owner? owner;
  String? companyId;
  String? accountId;
  int? overallScore;
  int? sovCount;
  int? subAccountCount;
  bool? isChecked;

  Accounts({
    this.accountName,
    this.owner,
    this.companyId,
    this.accountId,
    this.overallScore,
    this.sovCount,
    this.subAccountCount,
    this.isChecked = false,
  });

  Accounts.fromJson(Map<String, dynamic> json) {
    accountName = json['account_name']??"";
    owner = json['owner'] != null ? Owner.fromJson(json['owner']) : null;
    companyId = json['company_id']??"";
    accountId = json['account_id'];
    overallScore = json['overall_score'];
    sovCount = json['sov_count'];
    subAccountCount = json['sub_account_count'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['account_name'] = accountName;
    if (owner != null) {
      data['owner'] = owner!.toJson();
    }
    data['company_id'] = companyId;
    data['account_id'] = accountId;
    data['overall_score'] = overallScore;
    data['sov_count'] = sovCount;
    data['sub_account_count'] = subAccountCount;
    return data;
  }
}

class Owner {
  String? date;
  String? id;
  String? name;

  Owner({this.date, this.id, this.name});

  Owner.fromJson(Map<String, dynamic> json) {
    date = json['date'];
    id = json['id'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['date'] = date;
    data['id'] = id;
    data['name'] = name;
    return data;
  }
}

class Settings {
  bool? subAccountCount;
  bool? sovCount;
  bool? owner;
  bool? overallScore;

  Settings({this.subAccountCount, this.sovCount, this.owner, this.overallScore});

  Settings.fromJson(Map<String, dynamic> json) {
    subAccountCount = json['sub_account_count'];
    sovCount = json['sov_count'];
    owner = json['owner'];
    overallScore = json['overall_score'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['sub_account_count'] = subAccountCount;
    data['sov_count'] = sovCount;
    data['owner'] = owner;
    data['overall_score'] = overallScore;
    return data;
  }
}
