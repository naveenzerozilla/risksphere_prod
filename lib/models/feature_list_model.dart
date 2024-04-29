class FeatureListModel {
  List<Features>? features;

  FeatureListModel({this.features});

  FeatureListModel.fromJson(Map<String, dynamic> json) {
    if (json['features'] != null) {
      features = <Features>[];
      json['features'].forEach((v) {
        features!.add(new Features.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.features != null) {
      data['features'] = this.features!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Features {
  String? name;
  String? id;
  bool? status;
  List<SubFeatures>? subFeatures;

  Features({this.name, this.id, this.status, this.subFeatures});

  Features.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    id = json['id'];
    status = json['status'];
    if (json['subFeatures'] != null) {
      subFeatures = <SubFeatures>[];
      json['subFeatures'].forEach((v) {
        subFeatures!.add(new SubFeatures.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['id'] = this.id;
    data['status'] = this.status;
    if (this.subFeatures != null) {
      data['subFeatures'] = this.subFeatures!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class SubFeatures {
  String? name;
  String? tag;

  SubFeatures({this.name, this.tag});

  SubFeatures.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    tag = json['tag'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['tag'] = this.tag;
    return data;
  }
}
