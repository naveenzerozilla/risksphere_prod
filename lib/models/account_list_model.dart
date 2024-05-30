class AccountListModel {
  String? data;
  Accounts? accounts;
  AccountListModel({this.data, this.accounts});

  AccountListModel.fromJson(Map<String, dynamic> json) {
    data = json['data'];
    accounts = json['accounts'] != null ? new Accounts.fromJson(json['accounts']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['data'] = this.data;
    if (accounts != null) {
      data['accounts'] = accounts!.toJson();
    }
    return data;
  }

}

class Accounts {
  String? name;
  String? displayName;
  String? id;
  int? locationCount;
  String? overAllScore;
  bool? isChecked;

  Accounts({this.name, this.displayName, this.id, this.locationCount, this.overAllScore, this.isChecked=false});

  Accounts.fromJson(Map<String, dynamic> json) {
    name = json['name']??"";
    displayName = json['display_name']??"";
    id = json['id']??"";
    locationCount = json['location_count']??"";
    overAllScore = json['over_all_score']??"";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['display_name'] = displayName;
    data['id'] = id;
    data['location_count'] = locationCount;
    data['over_all_score'] = overAllScore;
    return data;
  }
}