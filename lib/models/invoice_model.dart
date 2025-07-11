class Invoicemodel {
  List<Result>? result;
  String? message;

  Invoicemodel({this.result, this.message});

  Invoicemodel.fromJson(Map<String, dynamic> json) {
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
  String? month;
  Plans? plans;

  Result({this.month, this.plans});

  Result.fromJson(Map<String, dynamic> json) {
    month = json['month'];
    plans = json['plans'] != null ? Plans.fromJson(json['plans']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['month'] = this.month;
    if (plans != null) {
      data['plans'] = plans!.toJson();
    }
    return data;
  }
}

class Plans {
  final Map<String, List<O9L3mwHAJ6RuXPPEepCl>> entries;

  Plans(this.entries);

  factory Plans.fromJson(Map<String, dynamic> json) {
    final map = <String, List<O9L3mwHAJ6RuXPPEepCl>>{};
    json.forEach((key, value) {
      map[key] = List<O9L3mwHAJ6RuXPPEepCl>.from(
        value.map((item) => O9L3mwHAJ6RuXPPEepCl.fromJson(item)),
      );
    });
    return Plans(map);
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    entries.forEach((key, value) {
      data[key] = value.map((v) => v.toJson()).toList();
    });
    return data;
  }
}

class O9L3mwHAJ6RuXPPEepCl {
  String? sessionId;
  String? type;
  String? planType;
  String? docId;
  List<Deductions>? deductions;
  String? planId;
  Plan? plan;
  String? allCredits;
  int? availableCredits;
  String? userName;
  String? userEmail;
  String? userId;
  String? companyId;
  String? companyName;
  String? planName;
  bool? activated;
  DeductionDate? expiresAt;
  dynamic amount;
  String? invoiceId;
  String? invoiceNumber;
  String? invoicePdfUrl;
  String? invoiceUrl;
  DeductionDate? transactionDate;
  DeductionDate? updatedAt;

  O9L3mwHAJ6RuXPPEepCl(
      {this.sessionId,
      this.type,
      this.planType,
      this.docId,
      this.deductions,
      this.planId,
      this.plan,
      this.allCredits,
      this.availableCredits,
      this.userName,
      this.userEmail,
      this.userId,
      this.companyId,
      this.companyName,
      this.planName,
      this.activated,
      this.expiresAt,
      this.amount,
      this.invoiceId,
      this.invoiceNumber,
      this.invoicePdfUrl,
      this.invoiceUrl,
      this.transactionDate,
      this.updatedAt});

  O9L3mwHAJ6RuXPPEepCl.fromJson(Map<String, dynamic> json) {
    sessionId = json['session_id'];
    type = json['type'];
    planType = json['plan_type'];
    docId = json['doc_id'];
    if (json['deductions'] != null) {
      deductions = <Deductions>[];
      json['deductions'].forEach((v) {
        deductions!.add(new Deductions.fromJson(v));
      });
    }
    planId = json['plan_id'];
    plan = json['plan'] != null ? new Plan.fromJson(json['plan']) : null;
    allCredits = json['all_credits'];
    availableCredits = json['available_credits'];
    userName = json['user_name'];
    userEmail = json['user_email'];
    userId = json['user_id'];
    companyId = json['company_id'];
    companyName = json['company_name'];
    planName = json['plan_name'];
    activated = json['activated'];
    expiresAt = json['expires_at'] != null
        ? new DeductionDate.fromJson(json['expires_at'])
        : null;
    amount = json['amount'];
    invoiceId = json['invoice_id'];
    invoiceNumber = json['invoice_number'];
    invoicePdfUrl = json['invoice_pdf_url'];
    invoiceUrl = json['invoice_url'];
    transactionDate = json['transaction_date'] != null
        ? new DeductionDate.fromJson(json['transaction_date'])
        : null;
    updatedAt = json['updated_at'] != null
        ? new DeductionDate.fromJson(json['updated_at'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['session_id'] = this.sessionId;
    data['type'] = this.type;
    data['plan_type'] = this.planType;
    data['doc_id'] = this.docId;
    if (this.deductions != null) {
      data['deductions'] = this.deductions!.map((v) => v.toJson()).toList();
    }
    data['plan_id'] = this.planId;
    if (this.plan != null) {
      data['plan'] = this.plan!.toJson();
    }
    data['all_credits'] = this.allCredits;
    data['available_credits'] = this.availableCredits;
    data['user_name'] = this.userName;
    data['user_email'] = this.userEmail;
    data['user_id'] = this.userId;
    data['company_id'] = this.companyId;
    data['company_name'] = this.companyName;
    data['plan_name'] = this.planName;
    data['activated'] = this.activated;
    if (this.expiresAt != null) {
      data['expires_at'] = this.expiresAt!.toJson();
    }
    data['amount'] = this.amount;
    data['invoice_id'] = this.invoiceId;
    data['invoice_number'] = this.invoiceNumber;
    data['invoice_pdf_url'] = this.invoicePdfUrl;
    data['invoice_url'] = this.invoiceUrl;
    if (this.transactionDate != null) {
      data['transaction_date'] = this.transactionDate!.toJson();
    }
    if (this.updatedAt != null) {
      data['updated_at'] = this.updatedAt!.toJson();
    }
    return data;
  }
}

class Deductions {
  DeductionDate? deductionDate;
  int? counts;
  String? initiatedBy;
  String? initiatedByUserName;
  String? initiatedByUserEmail;
  int? unitCost;
  int? totalCost;

  Deductions({this.deductionDate, this.counts, this.initiatedBy, this.initiatedByUserName, this.initiatedByUserEmail, this.unitCost, this.totalCost});

  Deductions.fromJson(Map<String, dynamic> json) {
    if (json['deduction_date'] != null && json['deduction_date'] is Map<String, dynamic>) {
      deductionDate = DeductionDate.fromJson(json['deduction_date']);
    } else {
      deductionDate = null;
    }

    // deductionDate = json['deduction_date'] != null ? new DeductionDate.fromJson(json['deduction_date']) : null;
    counts = json['counts'];
    initiatedBy = json['initiated_by'];
    initiatedByUserName = json['initiated_by_user_name'];
    initiatedByUserEmail = json['initiated_by_user_email'];
    unitCost = json['unit_cost'];
    totalCost = json['total_cost'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.deductionDate != null) {
      data['deduction_date'] = this.deductionDate!.toJson();
    }
    data['counts'] = this.counts;
    data['initiated_by'] = this.initiatedBy;
    data['initiated_by_user_name'] = this.initiatedByUserName;
    data['initiated_by_user_email'] = this.initiatedByUserEmail;
    data['unit_cost'] = this.unitCost;
    data['total_cost'] = this.totalCost;
    return data;
  }
}

class DeductionDate {
  int? iSeconds;
  int? iNanoseconds;

  DeductionDate({this.iSeconds, this.iNanoseconds});

  DeductionDate.fromJson(Map<String, dynamic> json) {
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

class Plan {
  String? planId;
  String? planType;
  String? planTypeId;
  String? selectedPlan;
  String? planName;
  dynamic price;
  String? productId;
  String? priceId;

  Plan(
      {this.planId,
      this.planType,
      this.planTypeId,
      this.selectedPlan,
      this.planName,
      this.price,
      this.productId,
      this.priceId});

  Plan.fromJson(Map<String, dynamic> json) {
    planId = json['plan_id'];
    planType = json['plan_type'];
    planTypeId = json['plan_type_id'];
    selectedPlan = json['selected_plan'];
    planName = json['plan_name'];
    price = json['price'];
    productId = json['product_id'];
    priceId = json['price_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['plan_id'] = this.planId;
    data['plan_type'] = this.planType;
    data['plan_type_id'] = this.planTypeId;
    data['selected_plan'] = this.selectedPlan;
    data['plan_name'] = this.planName;
    data['price'] = this.price;
    data['product_id'] = this.productId;
    data['price_id'] = this.priceId;
    return data;
  }
}
