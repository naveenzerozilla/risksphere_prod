class PricingModel {
  List<Result>? result;
  String? message;

  PricingModel({this.result, this.message});

  PricingModel.fromJson(Map<String, dynamic> json) {
    if (json['result'] != null) {
      result = <Result>[];
      json['result'].forEach((v) {
        result!.add(new Result.fromJson(v));
      });
    }
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.result != null) {
      data['result'] = this.result!.map((v) => v.toJson()).toList();
    }
    data['message'] = this.message;
    return data;
  }
}

class Result {
  String? description;
  bool? billingCycleMonthly;
  bool? billingCycleYearly;
  String? unit;
  List<RangeYear>? rangeYear;
  List<RangeYear>? rangeMonth;
  String? type;
  CreatedAt? createdAt;
  String? planId;
  CreatedAt? updatedAt;
  String? planName;

  Result(
      {this.description,
      this.billingCycleMonthly,
      this.billingCycleYearly,
      this.unit,
      this.rangeYear,
      this.rangeMonth,
      this.type,
      this.createdAt,
      this.planId,
      this.updatedAt,
      this.planName});

  Result.fromJson(Map<String, dynamic> json) {
    description = json['description'];
    billingCycleMonthly = json['billing_cycle_monthly'];
    billingCycleYearly = json['billing_cycle_yearly'];
    unit = json['unit'];
    if (json['range_year'] != null) {
      rangeYear = <RangeYear>[];
      json['range_year'].forEach((v) {
        rangeYear!.add(new RangeYear.fromJson(v));
      });
    }
    if (json['range_month'] != null) {
      rangeMonth = <RangeYear>[];
      json['range_month'].forEach((v) {
        rangeMonth!.add(new RangeYear.fromJson(v));
      });
    }
    type = json['type'];
    createdAt = json['created_at'] != null
        ? new CreatedAt.fromJson(json['created_at'])
        : null;
    planId = json['plan_id'];
    updatedAt = json['updated_at'] != null
        ? new CreatedAt.fromJson(json['updated_at'])
        : null;
    planName = json['plan_name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['description'] = this.description;
    data['billing_cycle_monthly'] = this.billingCycleMonthly;
    data['billing_cycle_yearly'] = this.billingCycleYearly;
    data['unit'] = this.unit;
    if (this.rangeYear != null) {
      data['range_year'] = this.rangeYear!.map((v) => v.toJson()).toList();
    }
    if (this.rangeMonth != null) {
      data['range_month'] = this.rangeMonth!.map((v) => v.toJson()).toList();
    }
    data['type'] = this.type;
    if (this.createdAt != null) {
      data['created_at'] = this.createdAt!.toJson();
    }
    data['plan_id'] = this.planId;
    if (this.updatedAt != null) {
      data['updated_at'] = this.updatedAt!.toJson();
    }
    data['plan_name'] = this.planName;
    return data;
  }
}

class RangeYear {
  var startCount;
  var endCount;
  var pricePerUser;
  int? rangePrice;

  RangeYear(
      {this.startCount, this.endCount, this.pricePerUser, this.rangePrice});

  RangeYear.fromJson(Map<String, dynamic> json) {
    startCount = json['start_count'];
    endCount = json['end_count'];
    pricePerUser = json['price_per_user'];
    rangePrice = json['range_price'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['start_count'] = this.startCount;
    data['end_count'] = this.endCount;
    data['price_per_user'] = this.pricePerUser;
    data['range_price'] = this.rangePrice;
    return data;
  }
}

class CreatedAt {
  int? iSeconds;
  int? iNanoseconds;

  CreatedAt({this.iSeconds, this.iNanoseconds});

  CreatedAt.fromJson(Map<String, dynamic> json) {
    iSeconds = json['_seconds'];
    iNanoseconds = json['_nanoseconds'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_seconds'] = this.iSeconds;
    data['_nanoseconds'] = this.iNanoseconds;
    return data;
  }
}
