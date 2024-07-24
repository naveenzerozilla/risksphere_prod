class SovUploadModel {
  List<String>? headers;
  String? url;
  DateTime? createdAt;
  List<Result>? result;
  SovDetails? sovDetails;
  String? id;

  SovUploadModel({
    this.headers,
    this.url,
    this.createdAt,
    this.result,
    this.sovDetails,
    this.id,
  });

  SovUploadModel.fromJson(Map<String, dynamic> json) {
    headers = json['headers'] != null ? List<String>.from(json['headers']) : null;
    url = json['url'];
    createdAt = json['created_at'] != null ? DateTime.fromMillisecondsSinceEpoch(json['created_at']['_seconds'] * 1000 + json['created_at']['_nanoseconds'] ~/ 1000000) : null;
    if (json['result'] != null) {
      result = <Result>[];
      json['result'].forEach((v) {
        result!.add(Result.fromJson(v));
      });
    }
    sovDetails = json['sov_details'] != null ? SovDetails.fromJson(json['sov_details']) : null;
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (headers != null) {
      data['headers'] = headers;
    }
    data['url'] = url;
    if (createdAt != null) {
      data['created_at'] = {'_seconds': createdAt!.millisecondsSinceEpoch ~/ 1000, '_nanoseconds': (createdAt!.millisecondsSinceEpoch % 1000) * 1000000};
    }
    if (result != null) {
      data['result'] = result!.map((v) => v.toJson()).toList();
    }
    if (sovDetails != null) {
      data['sov_details'] = sovDetails!.toJson();
    }
    data['id'] = id;
    return data;
  }

  @override
  String toString() {
    return 'SovUploadModel(headers: $headers, url: $url, createdAt: $createdAt, result: $result, sovDetails: $sovDetails, id: $id)';
  }
}

class Result {
  MappingStatus? mappingStatus;
  String? targetField;
  String? id;
  List<Match>? matches;
  Match? matchedField;

  // Local use variables
  bool isChecked;
  bool isUserEdited;

  Result({
    this.mappingStatus,
    this.targetField,
    this.id,
    this.matches,
    this.matchedField,
    this.isChecked = false,
    this.isUserEdited = false,
  });

  Result.fromJson(Map<String, dynamic> json)
      : isChecked = false,
        isUserEdited = false {
    mappingStatus = json['mappingStatus'] != null ? MappingStatus.fromJson(json['mappingStatus']) : null;
    targetField = json['targetField'];
    id = json['id'];
    if (json['matches'] != null) {
      matches = <Match>[];
      json['matches'].forEach((v) {
        matches!.add(Match.fromJson(v));
      });
    }
    matchedField = json['matchedField'] != null ? Match.fromJson(json['matchedField']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (mappingStatus != null) {
      data['mappingStatus'] = mappingStatus!.toJson();
    }
    data['targetField'] = targetField;
    data['id'] = id;
    if (matches != null) {
      data['matches'] = matches!.map((v) => v.toJson()).toList();
    }
    if (matchedField != null) {
      data['matchedField'] = matchedField!.toJson();
    }
    data['isChecked'] = isChecked;
    data['isUserEdited'] = isUserEdited;
    return data;
  }

  @override
  String toString() {
    return 'Result(mappingStatus: $mappingStatus, targetField: $targetField, id: $id, matches: $matches, matchedField: $matchedField, isChecked: $isChecked, isUserEdited: $isUserEdited)';
  }
}

class MappingStatus {
  String? label;
  String? value;

  MappingStatus({this.label, this.value});

  MappingStatus.fromJson(Map<String, dynamic> json) {
    label = json['label'];
    value = json['value'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['label'] = label;
    data['value'] = value;
    return data;
  }

  @override
  String toString() {
    return 'MappingStatus(label: $label, value: $value)';
  }
}

class Match {
  int? percentage;
  String? name;
  String? id;

  Match({this.percentage, this.name, this.id});

  Match.fromJson(Map<String, dynamic> json) {
    percentage = json['percentage'];
    name = json['name'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['percentage'] = percentage;
    data['name'] = name;
    data['id'] = id;
    return data;
  }

  @override
  String toString() {
    return 'Match(percentage: $percentage, name: $name, id: $id)';
  }
}

class SovDetails {
  String? accountId;
  String? name;
  String? device;

  SovDetails({this.accountId, this.name, this.device});

  SovDetails.fromJson(Map<String, dynamic> json) {
    accountId = json['account_id'];
    name = json['name'];
    device = json['device'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['account_id'] = accountId;
    data['name'] = name;
    data['device'] = device;
    return data;
  }

  @override
  String toString() {
    return 'SovDetails(accountId: $accountId, name: $name, device: $device)';
  }
}
