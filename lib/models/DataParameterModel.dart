import 'invoice_model.dart';

class DataParametersModel {
  List<Result>? result;
  HasUpgraded? hasUpgraded;
  Completeness? completeness;
  VendorData? vendorData;

  DataParametersModel(
      {this.result, this.hasUpgraded, this.completeness, this.vendorData});

  DataParametersModel.fromJson(Map<String, dynamic> json) {
    if (json['result'] != null) {
      result = <Result>[];
      json['result'].forEach((v) {
        result!.add(new Result.fromJson(v));
      });
    }
    hasUpgraded = json['has_upgraded'] != null
        ? new HasUpgraded.fromJson(json['has_upgraded'])
        : null;

    completeness = json['completeness'] != null
        ? new Completeness.fromJson(json['completeness'])
        : null;
    vendorData = json['vendor_data'] != null
        ? new VendorData.fromJson(json['vendor_data'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.result != null) {
      data['result'] = this.result!.map((v) => v.toJson()).toList();
    }
    if (this.hasUpgraded != null) {
      data['has_upgraded'] = this.hasUpgraded!.toJson();
    }
    if (this.completeness != null) {
      data['completeness'] = this.completeness!.toJson();
    }
    if (this.vendorData != null) {
      data['vendor_data'] = this.vendorData!.toJson();
    }
    return data;
  }
}

class Result {
  String? id;
  String? hazardName;
  String? name;
  String? parentId;
  ParameterState? parameterState;
  Private? private;
  String? dataCategoryId;
  LinkVendor? linkVendor;
  List<String>? tags;
  ParamConfig? paramConfig;
  HelpDocumantion? helpDocumantion;
  dynamic criticality;
  String? parameterNameA;
  String? parameterNameB;
  ParameterType? parameterType;
  int? selectedParameterType;
  String? unitName;
  String? tooltip;
  bool? status;
  String? ratingStyle;
  String? fileType;
  bool? isList;
  bool? isMultiSelectionList;
  bool? isMultiFiles;
  bool? isDisplayListing;
  bool? isItRangeParameter;
  String? moduleName;
  String? categoryType;
  String? pdElement;
  String? date;
  String? startDate;
  String? endDate;
  String? dataGroupRef;
  Version? version;
  StateManager? stateManager;
  User? user;
  ParameterValue? parameterValue;
  String? currency;
  List<History>? history;

  Result({
    this.id,
    this.hazardName,
    this.name,
    this.parentId,
    this.parameterState,
    this.private,
    this.dataCategoryId,
    this.linkVendor,
    this.tags,
    this.paramConfig,
    this.helpDocumantion,
    this.criticality,
    this.parameterNameA,
    this.parameterNameB,
    this.parameterType,
    this.selectedParameterType,
    this.unitName,
    this.tooltip,
    this.status,
    this.ratingStyle,
    this.fileType,
    this.isList,
    this.isMultiSelectionList,
    this.isMultiFiles,
    this.isDisplayListing,
    this.isItRangeParameter,
    this.moduleName,
    this.categoryType,
    this.pdElement,
    this.date,
    this.startDate,
    this.endDate,
    this.dataGroupRef,
    this.version,
    this.stateManager,
    this.user,
    this.parameterValue,
    this.currency,
    this.history,
  });

  Result.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    hazardName = json['hazard_name'];
    name = json['name'];
    parentId = json['parent_id'];

    parameterState = json['parameter_state'] is Map
        ? ParameterState.fromJson(
            Map<String, dynamic>.from(json['parameter_state']))
        : null;

    private = json['private'] is Map
        ? Private.fromJson(Map<String, dynamic>.from(json['private']))
        : null;

    dataCategoryId = json['data_category_id'];
    linkVendor = json['link_vendor'] is Map
        ? LinkVendor.fromJson(Map<String, dynamic>.from(json['link_vendor']))
        : null;
    tags = json['tags'] != null ? List<String>.from(json['tags']) : [];
    paramConfig = json['param_config'] is Map
        ? ParamConfig.fromJson(Map<String, dynamic>.from(json['param_config']))
        : null;

    helpDocumantion = json['help_documantion'] is Map
        ? HelpDocumantion.fromJson(
            Map<String, dynamic>.from(json['help_documantion']))
        : null;

    var crit = json['criticality'];

    if (crit == null) {
      criticality = [];
    } else if (crit is List) {
      criticality = crit
          .where((e) => e is Map)
          .map((e) => Criticality.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } else if (crit is Map) {
      if (crit.isEmpty) {
        criticality = [];
      } else {
        criticality = [Criticality.fromJson(Map<String, dynamic>.from(crit))];
      }
    } else {
      criticality = [];
    }

    parameterNameA = json['parameter_name_a'];
    parameterNameB = json['parameter_name_b'];

    parameterType = json['parameter_type'] is Map
        ? ParameterType.fromJson(
            Map<String, dynamic>.from(json['parameter_type']))
        : null;

    selectedParameterType = json['selected_parameter_type'];
    unitName = json['unit_name'];
    tooltip = json['tooltip'];
    status = json['status'];
    ratingStyle = json['rating_style'];
    fileType = json['file_type'];
    isList = json['is_list'];
    isMultiSelectionList = json['is_multi_selection_list'];
    isMultiFiles = json['is_multi_files'];
    isDisplayListing = json['is_display_listing'];
    isItRangeParameter = json['is_it_range_parameter'];
    moduleName = json['module_name'];
    categoryType = json['category_type'];
    pdElement = json['pd_element'];
    date = json['date'];
    startDate = json['startDate'];
    endDate = json['endDate'];
    dataGroupRef = json['data_group_ref'];

    version = json['version'] is Map
        ? Version.fromJson(Map<String, dynamic>.from(json['version']))
        : null;

    stateManager = json['state_manager'] is Map
        ? StateManager.fromJson(
            Map<String, dynamic>.from(json['state_manager']))
        : null;

    user = json['user'] is Map
        ? User.fromJson(Map<String, dynamic>.from(json['user']))
        : null;

    parameterValue = json['parameter_value'] is Map
        ? ParameterValue.fromJson(
            Map<String, dynamic>.from(json['parameter_value']))
        : null;

    currency = json['currency'];

    // ------------------------------------------------------------------
    // 🔥 SAFE HISTORY
    // ------------------------------------------------------------------
    history = [];
    if (json['history'] is List) {
      for (var h in json['history']) {
        if (h is Map) {
          history!.add(History.fromJson(Map<String, dynamic>.from(h)));
        }
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    data['id'] = id;
    data['hazard_name'] = hazardName;
    data['name'] = name;
    data['parent_id'] = parentId;

    if (parameterState != null)
      data['parameter_state'] = parameterState!.toJson();
    if (private != null) data['private'] = private!.toJson();
    data['data_category_id'] = dataCategoryId;
    data['link_vendor'] = linkVendor != null ? linkVendor!.toJson() : null;
    data['tags'] = tags;
    if (paramConfig != null) data['param_config'] = paramConfig!.toJson();
    if (helpDocumantion != null)
      data['help_documantion'] = helpDocumantion!.toJson();

    if (criticality != null) {
      data['criticality'] = criticality!.map((e) => e.toJson()).toList();
    }

    data['parameter_name_a'] = parameterNameA;
    data['parameter_name_b'] = parameterNameB;

    if (parameterType != null) data['parameter_type'] = parameterType!.toJson();

    data['selected_parameter_type'] = selectedParameterType;
    data['unit_name'] = unitName;
    data['tooltip'] = tooltip;
    data['status'] = status;
    data['rating_style'] = ratingStyle;
    data['file_type'] = fileType;
    data['is_list'] = isList;
    data['is_multi_selection_list'] = isMultiSelectionList;
    data['is_multi_files'] = isMultiFiles;
    data['is_display_listing'] = isDisplayListing;
    data['is_it_range_parameter'] = isItRangeParameter;
    data['module_name'] = moduleName;
    data['category_type'] = categoryType;
    data['pd_element'] = pdElement;
    data['date'] = date;
    data['startDate'] = startDate;
    data['endDate'] = endDate;
    data['data_group_ref'] = dataGroupRef;

    if (version != null) data['version'] = version!.toJson();
    if (stateManager != null) data['state_manager'] = stateManager!.toJson();
    if (user != null) data['user'] = user!.toJson();
    if (parameterValue != null)
      data['parameter_value'] = parameterValue!.toJson();

    data['currency'] = currency;

    if (history != null) {
      data['history'] = history!.map((h) => h.toJson()).toList();
    }

    return data;
  }
}

class LinkVendor {
  HazardHub? hazardHub;

  LinkVendor({this.hazardHub});

  LinkVendor.fromJson(Map<String, dynamic> json) {
    hazardHub = json['hazard_hub'] != null
        ? new HazardHub.fromJson(json['hazard_hub'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.hazardHub != null) {
      data['hazard_hub'] = this.hazardHub!.toJson();
    }
    return data;
  }
}

class History {
  dynamic? value;
  String? paramType;
  List<Reference>? reference;
  String? userName;
  UpdatedAt? updatedAt;

  History(
      {this.value,
      this.paramType,
      this.reference,
      this.userName,
      this.updatedAt});

  History.fromJson(Map<String, dynamic> json) {
    value = json['value'];
    paramType = json['param_type'];
    if (json['reference'] != null) {
      reference = <Reference>[];
      json['reference'].forEach((v) {
        reference!.add(new Reference.fromJson(v));
      });
    }
    userName = json['user_name'];
    updatedAt = json['updated_at'] != null
        ? new UpdatedAt.fromJson(json['updated_at'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();

    data['value'] = this.value;
    data['param_type'] = this.paramType;
    if (this.reference != null) {
      data['reference'] = this.reference!.map((v) => v.toJson()).toList();
    }
    data['user_name'] = this.userName;
    if (this.updatedAt != null) {
      data['updated_at'] = this.updatedAt!.toJson();
    }
    return data;
  }
}

class Value {
  String? parameterA;
  String? parameterB;
  String? unit;

  Value({this.parameterA, this.parameterB, this.unit});

  Value.fromJson(Map<String, dynamic> json) {
    parameterA = json['parameterA'];
    parameterB = json['parameterB'];
    unit = json['unit'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['parameterA'] = this.parameterA;
    data['parameterB'] = this.parameterB;
    data['unit'] = this.unit;
    return data;
  }
}

class HelpDocumantion {
  List<String>? images;
  List<String>? docs;

  HelpDocumantion({this.images, this.docs});

  HelpDocumantion.fromJson(Map<String, dynamic> json) {
    images = json['images'].cast<String>();
    docs = json['docs'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['images'] = this.images;
    data['docs'] = this.docs;
    return data;
  }
}

class ParameterValue {
  dynamic value;
  String? paramType;
  List<Reference>? reference;
  String? userName;
  UpdatedAt? updatedAt;
  Map<String, dynamic>? otherSources;
  ParameterValue(
      {this.value,
      this.paramType,
      this.reference,
      this.userName,
      this.updatedAt,
      this.otherSources
      });

  ParameterValue.fromJson(Map<String, dynamic> json) {
    value = json['value'];
    paramType = json['param_type'];
    if (json['reference'] != null) {
      reference = <Reference>[];
      json['reference'].forEach((v) {
        reference!.add(new Reference.fromJson(v));
      });
    }
    userName = json['user_name'];
    updatedAt = json['updated_at'] != null
        ? new UpdatedAt.fromJson(json['updated_at'])
        : null;
    otherSources = json['other_sources'] != null
        ? Map<String, dynamic>.from(json['other_sources'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['value'] = this.value;
    data['param_type'] = this.paramType;
    if (this.reference != null) {
      data['reference'] = this.reference!.map((v) => v.toJson()).toList();
    }
    data['user_name'] = this.userName;
    if (this.updatedAt != null) {
      data['updated_at'] = this.updatedAt!.toJson();
    }
    if (this.otherSources != null) {
      data['other_sources'] = this.otherSources;
    }
    return data;
  }
}

class UpdatedAt {
  int? iSeconds;
  int? iNanoseconds;

  UpdatedAt({this.iSeconds, this.iNanoseconds});

  UpdatedAt.fromJson(Map<String, dynamic> json) {
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

class Data {
  dynamic value;
  String? paramType;
  List<Reference>? reference;

  Data({this.value, this.paramType, this.reference});

  Data.fromJson(Map<String, dynamic> json) {
    value = json['value'];
    paramType = json['param_type'];
    if (json['reference'] != null && json['reference'] is List) {
      reference = <Reference>[];
      json['reference'].forEach((v) {
        reference!.add(Reference.fromJson(v));
      });
    } else {
      reference = []; // fallback if it's a string or null
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['value'] = this.value;
    data['param_type'] = this.paramType;
    if (this.reference != null) {
      data['reference'] = this.reference!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Reference {
  dynamic url;
  dynamic tags;
  dynamic size;
  String? name;
  String? uploadedBy;

  Reference({this.url, this.tags, this.size, this.name, this.uploadedBy});

  Reference.fromJson(Map<String, dynamic> json) {
    url = json['url'];
    tags = json['tags'];
    size = json['size'];
    name = json['name'];
    uploadedBy = json['uploaded_by'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['url'] = this.url;
    data['tags'] = this.tags;
    data['size'] = this.size;
    data['name'] = this.name;
    data['uploaded_by'] = this.uploadedBy;
    return data;
  }
}

class ParameterState {
  bool? isLocked;
  bool? isEnabled;
  String? module;
  bool? isDataGroup;
  String? mode;

  ParameterState(
      {this.isLocked,
      this.isEnabled,
      this.module,
      this.isDataGroup,
      this.mode});

  ParameterState.fromJson(Map<String, dynamic> json) {
    isLocked = json['is_locked'];
    isEnabled = json['is_enabled'];
    module = json['module'];
    isDataGroup = json['is_dataGroup'];
    mode = json['mode'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['is_locked'] = this.isLocked;
    data['is_enabled'] = this.isEnabled;
    data['module'] = this.module;
    data['is_dataGroup'] = this.isDataGroup;
    data['mode'] = this.mode;
    return data;
  }
}

class Private {
  bool? isPrivate;
  String? accountId;

  Private({this.isPrivate, this.accountId});

  Private.fromJson(Map<String, dynamic> json) {
    isPrivate = json['is_private'];
    accountId = json['account_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['is_private'] = this.isPrivate;
    data['account_id'] = this.accountId;
    return data;
  }
}

class ParamConfig {
  // List<Null>? listConfiguration;
  bool? isRangeParameter;
  bool? isList;
  bool? isMultiSelectionList;
  bool? includeInDataCompleteness;
  bool? enableValuationDateSelection;
  bool? enableCurrencySelection;
  bool? enableDataAggregation;
  bool? enableValueSelectionType;
  bool? isPdElement;

  ParamConfig(
      {
      // this.listConfiguration,
      this.isRangeParameter,
      this.isList,
      this.isMultiSelectionList,
      this.includeInDataCompleteness,
      this.enableValuationDateSelection,
      this.enableCurrencySelection,
      this.enableDataAggregation,
      this.enableValueSelectionType,
      this.isPdElement});

  ParamConfig.fromJson(Map<String, dynamic> json) {
    // if (json['list_configuration'] != null) {
    //   listConfiguration = <Null>[];
    //   json['list_configuration'].forEach((v) { listConfiguration!.add(new Null.fromJson(v)); });
    // }
    isRangeParameter = json['is_range_parameter'];
    isList = json['is_list'];
    isMultiSelectionList = json['is_multi_selection_list'];
    includeInDataCompleteness = json['include_in_data_completeness'];
    enableValuationDateSelection = json['enable_valuation_date_selection'];
    enableCurrencySelection = json['enable_currency_selection'];
    enableDataAggregation = json['enable_data_aggregation'];
    enableValueSelectionType = json['enable_value_selection_type'];
    isPdElement = json['is_pd_element'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    // if (this.listConfiguration != null) {
    //   data['list_configuration'] = this.listConfiguration!.map((v) => v.toJson()).toList();
    // }
    data['is_range_parameter'] = this.isRangeParameter;
    data['is_list'] = this.isList;
    data['is_multi_selection_list'] = this.isMultiSelectionList;
    data['include_in_data_completeness'] = this.includeInDataCompleteness;
    data['enable_valuation_date_selection'] = this.enableValuationDateSelection;
    data['enable_currency_selection'] = this.enableCurrencySelection;
    data['enable_data_aggregation'] = this.enableDataAggregation;
    data['enable_value_selection_type'] = this.enableValueSelectionType;
    data['is_pd_element'] = this.isPdElement;
    return data;
  }
}

class Criticality {
  // String? perils;
  int? avgPdCriticality;
  int? avgTeCriticality;
  String? impactType;
  String? comments;
  dynamic vendors; // can be null
  List<Advisory>? advisory; // always list

  Criticality({
    // this.perils,
    this.avgPdCriticality,
    this.avgTeCriticality,
    this.comments,
    this.impactType,
    this.vendors,
    this.advisory,
  });

  Criticality.fromJson(Map<String, dynamic> json) {
    // perils = json['perils'];
    avgPdCriticality = json['avg_pd_criticality'];
    avgTeCriticality = json['avg_te_criticality'];
    comments = json['comments'];
    impactType = json['impact_type'];
    vendors = json['vendors'];

    // 🔥 handle advisory safely
    if (json['advisory'] == null) {
      advisory = []; // no advisory
    } else if (json['advisory'] is List) {
      advisory =
          (json['advisory'] as List).map((e) => Advisory.fromJson(e)).toList();
    } else if (json['advisory'] is Map) {
      // sometimes advisory comes as {}
      if ((json['advisory'] as Map).isEmpty) {
        advisory = [];
      } else {
        advisory = [Advisory.fromJson(json['advisory'])];
      }
    } else {
      advisory = [];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    // data['perils'] = perils;
    data['avg_pd_criticality'] = avgPdCriticality;
    data['avg_te_criticality'] = avgTeCriticality;
    data['comments'] = comments;
    data['impact_type'] = impactType;
    data['vendors'] = vendors;

    // always output list
    data['advisory'] = advisory?.map((e) => e.toJson()).toList() ?? [];

    return data;
  }
}

class Advisory {
  String? name;
  String? email;
  String? userId;
  String? date;
  int? pdCriticality;
  int? teCriticality;
  bool? isRsAdmin;
  String? comments;

  // List<Null>? history;

  Advisory(
      {this.name,
      this.email,
      this.userId,
      this.date,
      this.pdCriticality,
      this.teCriticality,
      this.isRsAdmin,
      this.comments});

  Advisory.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    email = json['email'];
    userId = json['user_id'];
    date = json['date'];
    pdCriticality = json['pd_criticality'];
    teCriticality = json['te_criticality'];
    isRsAdmin = json['is_rs_admin'];
    comments = json['comments'];
    // if (json['history'] != null) {
    //   history = <Null>[];
    //   json['history'].forEach((v) { history!.add(new Null.fromJson(v)); });
    // }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['email'] = this.email;
    data['user_id'] = this.userId;
    data['date'] = this.date;
    data['pd_criticality'] = this.pdCriticality;
    data['te_criticality'] = this.teCriticality;
    data['is_rs_admin'] = this.isRsAdmin;
    data['comments'] = this.comments;
    // if (this.history != null) {
    //   data['history'] = this.history!.map((v) => v.toJson()).toList();
    // }
    return data;
  }
}

// class Criticality {
//   String? impactType;
//   String? perils;
//   List<Advisory>? advisory;
//   int? avgPdCriticality;
//   String? comments;
//   Null? vendors;
//   int? avgTeCriticality;
//
//   Criticality(
//       {this.impactType,
//       this.perils,
//       this.advisory,
//       this.avgPdCriticality,
//       this.comments,
//       this.vendors,
//       this.avgTeCriticality});
//
//   Criticality.fromJson(Map<String, dynamic> json) {
//     impactType = json['impact_type'];
//     perils = json['perils'];
//     if (json['advisory'] != null) {
//       advisory = <Advisory>[];
//       json['advisory'].forEach((v) {
//         advisory!.add(new Advisory.fromJson(v));
//       });
//     }
//     avgPdCriticality = json['avg_pd_criticality'];
//     comments = json['comments'];
//     vendors = json['vendors'];
//     avgTeCriticality = json['avg_te_criticality'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['impact_type'] = this.impactType;
//     data['perils'] = this.perils;
//     if (this.advisory != null) {
//       data['advisory'] = this.advisory!.map((v) => v.toJson()).toList();
//     }
//     data['avg_pd_criticality'] = this.avgPdCriticality;
//     data['comments'] = this.comments;
//     data['vendors'] = this.vendors;
//     data['avg_te_criticality'] = this.avgTeCriticality;
//     return data;
//   }
// }

// class Advisory {
//   // List<dynamic>? history;
//   int? pdCriticality;
//   int? teCriticality;
//   String? name;
//   String? date;
//   String? email;
//   bool? isRsAdmin;
//   String? comments;
//   String? userId;
//
//   Advisory(
//       {
//       // this.history,
//       this.pdCriticality,
//       this.teCriticality,
//       this.name,
//       this.date,
//       this.email,
//       this.isRsAdmin,
//       this.comments,
//       this.userId});
//
//   Advisory.fromJson(Map<String, dynamic> json) {
//     // if (json['history'] != null) {
//     //   history = <Null>[];
//     //   json['history'].forEach((v) {
//     //     history!.add(new Null!.fromJson(v));
//     //   });
//     // }
//     pdCriticality = json['pd_criticality'];
//     teCriticality = json['te_criticality'];
//     name = json['name'];
//     date = json['date'];
//     email = json['email'];
//     isRsAdmin = json['is_rs_admin'];
//     comments = json['comments'];
//     userId = json['user_id'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     // if (this.history != null) {
//     //   data['history'] = this.history!.map((v) => v.toJson()).toList();
//     // }
//     data['pd_criticality'] = this.pdCriticality;
//     data['te_criticality'] = this.teCriticality;
//     data['name'] = this.name;
//     data['date'] = this.date;
//     data['email'] = this.email;
//     data['is_rs_admin'] = this.isRsAdmin;
//     data['comments'] = this.comments;
//     data['user_id'] = this.userId;
//     return data;
//   }
// }

class HasUpgraded {
  bool? dI1o77IZ5M62Ke5wOLui;

  HasUpgraded({this.dI1o77IZ5M62Ke5wOLui});

  HasUpgraded.fromJson(Map<String, dynamic> json) {
    dI1o77IZ5M62Ke5wOLui = json['DI1o77IZ5M62Ke5wOLui'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['DI1o77IZ5M62Ke5wOLui'] = this.dI1o77IZ5M62Ke5wOLui;
    return data;
  }
}

class Completeness {
  int? high;
  int? low;

  Completeness({this.high, this.low});

  Completeness.fromJson(Map<String, dynamic> json) {
    high = json['high'];
    low = json['low'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['high'] = this.high;
    data['low'] = this.low;
    return data;
  }
}

class ParameterType {
  String? name;
  String? id;

  ParameterType({this.name, this.id});

  ParameterType.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['id'] = this.id;
    return data;
  }
}

class Version {
  int? versionNumber;
  dynamic change;
  List<VersionHistory>? versionHistory;

  Version({this.versionNumber, this.change, this.versionHistory});

  Version.fromJson(Map<String, dynamic> json) {
    versionNumber = json['version_number'];
    change = json['change'];
    if (json['version_history'] != null) {
      versionHistory = <VersionHistory>[];
      json['version_history'].forEach((v) {
        versionHistory!.add(new VersionHistory.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['version_number'] = this.versionNumber;
    data['change'] = this.change;
    if (this.versionHistory != null) {
      data['version_history'] =
          this.versionHistory!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class VersionHistory {
  bool? isLocked;
  String? date;
  String? mode;
  dynamic version;
  String? userName;
  Null? image;
  String? docId;

  VersionHistory(
      {this.isLocked,
      this.date,
      this.mode,
      this.version,
      this.userName,
      this.image,
      this.docId});

  VersionHistory.fromJson(Map<String, dynamic> json) {
    isLocked = json['is_locked'];
    date = json['date'];
    mode = json['mode'];
    version = json['version'];
    userName = json['user_name'];
    image = json['image'];
    docId = json['doc_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['is_locked'] = this.isLocked;
    data['date'] = this.date;
    data['mode'] = this.mode;
    data['version'] = this.version;
    data['user_name'] = this.userName;
    data['image'] = this.image;
    data['doc_id'] = this.docId;
    return data;
  }
}

class StateManager {
  bool? lastPublished;
  bool? isLatest;

  StateManager({this.lastPublished, this.isLatest});

  StateManager.fromJson(Map<String, dynamic> json) {
    lastPublished = json['last_published'];
    isLatest = json['is_latest'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['last_published'] = this.lastPublished;
    data['is_latest'] = this.isLatest;
    return data;
  }
}

class User {
  String? name;
  String? email;
  String? userId;
  Null? imageUrl;

  User({this.name, this.email, this.userId, this.imageUrl});

  User.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    email = json['email'];
    userId = json['user_id'];
    imageUrl = json['image_url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['email'] = this.email;
    data['user_id'] = this.userId;
    data['image_url'] = this.imageUrl;
    return data;
  }
}

class VendorData {
  HazardHub? hazardHub;

  VendorData({this.hazardHub});

  VendorData.fromJson(Map<String, dynamic> json) {
    hazardHub = json['hazard_hub'] != null
        ? new HazardHub.fromJson(json['hazard_hub'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.hazardHub != null) {
      data['hazard_hub'] = this.hazardHub!.toJson();
    }
    return data;
  }
}

class HazardHub {
  List<DataCategories>? dataCategories;
  Map<String, HazardHubItem>? items;

  HazardHub({
    this.dataCategories,
    this.items,
  });

  HazardHub.fromJson(Map<String, dynamic> json) {
    if (json['data_categories'] != null) {
      dataCategories = <DataCategories>[];
      json['data_categories'].forEach((v) {
        dataCategories!.add(new DataCategories.fromJson(v));
      });
    }

    items = {};

    json.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        items![key] = HazardHubItem.fromJson(
          value,
        );
      }
    });

    if (items!.isEmpty) {
      items = null;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (this.dataCategories != null) {
      data['data_categories'] =
          this.dataCategories!.map((v) => v.toJson()).toList();
    }
    if (items != null) {
      items!.forEach(
        (key, value) {
          data[key] = value.toJson();
        },
      );
    }

    return data;
  }
}
// class HazardHub {
//   List<DataCategories>? dataCategories;
//   Map<String, HazardHubItem>? items;
//
//   HazardHub({this.items, this.dataCategories});
//
//   HazardHub.fromJson(Map<String, dynamic> json) {
//     if (json['data_categories'] != null) {
//       dataCategories = <DataCategories>[];
//       json['data_categories'].forEach((v) {
//         dataCategories!.add(new DataCategories.fromJson(v));
//       });
//     }
//     items = {};
//
//     json.forEach((key, value) {
//       if (value is Map<String, dynamic>) {
//         items![key] = HazardHubItem.fromJson(
//           value,
//         );
//       }
//     });
//
//     if (items!.isEmpty) {
//       items = null;
//     }
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = {};
//     if (this.dataCategories != null) {
//       data['data_categories'] =
//           this.dataCategories!.map((v) => v.toJson()).toList();
//     }
//     if (items != null) {
//       items!.forEach(
//         (key, value) {
//           data[key] = value.toJson();
//         },
//       );
//     }
//
//     return data;
//   }
// }

class HazardHubItem {
  String? name;
  String? path;

  UpdatedAt? updatedAt;

  List<LinkedDataParameter>? linkedDataParameters;

  HazardHubItem({
    this.name,
    this.path,
    this.updatedAt,
    this.linkedDataParameters,
  });

  HazardHubItem.fromJson(Map<String, dynamic> json) {
    name = json['name'];

    path = json['path'];

    updatedAt = json['updated_at'] != null
        ? UpdatedAt.fromJson(
            json['updated_at'],
          )
        : null;

    if (json['linked_data_parameters'] != null) {
      linkedDataParameters = <LinkedDataParameter>[];

      (json['linked_data_parameters'] as List).forEach((v) {
        linkedDataParameters!.add(
          LinkedDataParameter.fromJson(v),
        );
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    data['name'] = name;

    data['path'] = path;

    if (updatedAt != null) {
      data['updated_at'] = updatedAt!.toJson();
    }

    if (linkedDataParameters != null) {
      data['linked_data_parameters'] = linkedDataParameters!
          .map(
            (v) => v.toJson(),
          )
          .toList();
    }

    return data;
  }
}

class DataCategories {
  String? parameterId;
  List<String>? accessibleTo;
  double? lng;
  List<String>? accessibleToCompany;
  double? lat;
  String? vendorKey;
  ParameterData? parameterData;
  VendorData? vendorData;
  String? locationId;
  UpdatedAt? timestamp;

  DataCategories(
      {this.parameterId,
      this.accessibleTo,
      this.lng,
      this.accessibleToCompany,
      this.lat,
      this.vendorKey,
      this.parameterData,
      this.vendorData,
      this.locationId,
      this.timestamp});

  DataCategories.fromJson(Map<String, dynamic> json) {
    parameterId = json['parameter_id'];
    accessibleTo = json['accessible_to'].cast<String>();
    lng = json['lng'];
    accessibleToCompany = json['accessible_to_company'].cast<String>();
    lat = json['lat'];
    vendorKey = json['vendor_key'];
    parameterData = json['parameter_data'] != null
        ? new ParameterData.fromJson(json['parameter_data'])
        : null;
    vendorData = json['vendor_data'] != null
        ? new VendorData.fromJson(json['vendor_data'])
        : null;
    locationId = json['location_id'];
    timestamp = json['timestamp'] != null
        ? new UpdatedAt.fromJson(json['timestamp'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['parameter_id'] = this.parameterId;
    data['accessible_to'] = this.accessibleTo;
    data['lng'] = this.lng;
    data['accessible_to_company'] = this.accessibleToCompany;
    data['lat'] = this.lat;
    data['vendor_key'] = this.vendorKey;
    if (this.parameterData != null) {
      data['parameter_data'] = this.parameterData!.toJson();
    }
    if (this.vendorData != null) {
      data['vendor_data'] = this.vendorData!.toJson();
    }
    data['location_id'] = this.locationId;
    if (this.timestamp != null) {
      data['timestamp'] = this.timestamp!.toJson();
    }
    return data;
  }
}

class ParameterData {
  String? unitName;
  bool? isMultiSelectionList;
  bool? isDisplayListing;
  ParameterValue? parameterValue;
  int? selectedParameterType;
  bool? isList;
  String? dataCategoryId;
  Null? date;
  String? tooltip;

  // List<String>? parents;
  bool? isCustom;
  String? pdElement;
  String? parentId;
  User? user;
  Private? private;
  String? parameterType;
  List<Null>? valueList;
  Null? startDate;
  List<String>? tags;
  Null? endDate;

  // ParameterType? parameterType;
  HelpDocumantion? helpDocumantion;
  ParamConfig? paramConfig;
  bool? isMultiFiles;
  List<Null>? criticality;
  String? parameterNameB;
  String? dataGroupRef;
  String? categoryType;
  String? ratingStyle;
  String? fileType;
  Version? version;
  String? masterParentId;
  String? name;
  bool? status;
  StateManager? stateManager;
  List<Null>? parameterTypeFields;
  ParameterState? parameterState;
  String? moduleName;
  String? parameterNameA;
  bool? isItRangeParameter;

  // String? path;

  ParameterData({
    this.unitName,
    this.isMultiSelectionList,
    this.isDisplayListing,
    this.parameterValue,
    this.selectedParameterType,
    this.isList,
    this.dataCategoryId,
    this.date,
    this.tooltip,
    // this.parents,
    this.isCustom,
    this.pdElement,
    this.parentId,
    this.user,
    this.private,
    this.parameterType,
    this.valueList,
    this.startDate,
    this.tags,
    this.endDate,
    this.helpDocumantion,
    this.paramConfig,
    this.isMultiFiles,
    this.criticality,
    this.parameterNameB,
    this.dataGroupRef,
    this.categoryType,
    this.ratingStyle,
    this.fileType,
    this.version,
    this.masterParentId,
    this.name,
    this.status,
    this.stateManager,
    this.parameterTypeFields,
    this.parameterState,
    this.moduleName,
    this.parameterNameA,
    this.isItRangeParameter,
    // this.path
  });

  ParameterData.fromJson(Map<String, dynamic> json) {
    unitName = json['unit_name'];
    isMultiSelectionList = json['is_multi_selection_list'];
    isDisplayListing = json['is_display_listing'];
    parameterValue = json['parameter_value'] != null
        ? new ParameterValue.fromJson(json['parameter_value'])
        : null;
    selectedParameterType = json['selected_parameter_type'];
    isList = json['is_list'];
    dataCategoryId = json['data_category_id'];
    date = json['date'];
    tooltip = json['tooltip'];
    // parents = json['parents'].cast<String>();
    isCustom = json['is_custom'];
    pdElement = json['pd_element'];
    parentId = json['parent_id'];
    user = json['user'] != null ? new User.fromJson(json['user']) : null;
    private =
        json['private'] != null ? new Private.fromJson(json['private']) : null;
    parameterType = json['parameterType'];
    // if (json['value_list'] != null) {
    //   valueList = <Null>[];
    //   json['value_list'].forEach((v) { valueList!.add(new Null.fromJson(v)); });
    // }
    startDate = json['startDate'];
    tags = json['tags'].cast<String>();
    endDate = json['endDate'];
    // parameterType = json['parameter_type'] != null ? new ParameterType.fromJson(json['parameter_type']) : null;
    helpDocumantion = json['help_documantion'] != null
        ? new HelpDocumantion.fromJson(json['help_documantion'])
        : null;
    paramConfig = json['param_config'] != null
        ? new ParamConfig.fromJson(json['param_config'])
        : null;
    isMultiFiles = json['is_multi_files'];
    // if (json['criticality'] != null) {
    //   criticality = <Null>[];
    //   json['criticality'].forEach((v) { criticality!.add(new Null.fromJson(v)); });
    // }
    parameterNameB = json['parameter_name_b'];
    dataGroupRef = json['data_group_ref'];
    categoryType = json['category_type'];
    ratingStyle = json['rating_style'];
    fileType = json['file_type'];
    version =
        json['version'] != null ? new Version.fromJson(json['version']) : null;
    masterParentId = json['master_parent_id'];
    name = json['name'];
    status = json['status'];
    stateManager = json['state_manager'] != null
        ? new StateManager.fromJson(json['state_manager'])
        : null;
    // if (json['parameter_type_fields'] != null) {
    //   parameterTypeFields = <Null>[];
    //   json['parameter_type_fields'].forEach((v) { parameterTypeFields!.add(new Null.fromJson(v)); });
    // }
    parameterState = json['parameter_state'] != null
        ? new ParameterState.fromJson(json['parameter_state'])
        : null;
    moduleName = json['module_name'];
    parameterNameA = json['parameter_name_a'];
    isItRangeParameter = json['is_it_range_parameter'];
    // path = json['path'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['unit_name'] = this.unitName;
    data['is_multi_selection_list'] = this.isMultiSelectionList;
    data['is_display_listing'] = this.isDisplayListing;
    if (this.parameterValue != null) {
      data['parameter_value'] = this.parameterValue!.toJson();
    }
    data['selected_parameter_type'] = this.selectedParameterType;
    data['is_list'] = this.isList;
    data['data_category_id'] = this.dataCategoryId;
    data['date'] = this.date;
    data['tooltip'] = this.tooltip;
    // data['parents'] = this.parents;
    data['is_custom'] = this.isCustom;
    data['pd_element'] = this.pdElement;
    data['parent_id'] = this.parentId;
    if (this.user != null) {
      data['user'] = this.user!.toJson();
    }
    if (this.private != null) {
      data['private'] = this.private!.toJson();
    }
    data['parameterType'] = this.parameterType;
    // if (this.valueList != null) {
    //   data['value_list'] = this.valueList!.map((v) => v.toJson()).toList();
    // }
    data['startDate'] = this.startDate;
    data['tags'] = this.tags;
    data['endDate'] = this.endDate;
    // if (this.parameterType != null) {
    //   data['parameter_type'] = this.parameterType!.toJson();
    // }
    if (this.helpDocumantion != null) {
      data['help_documantion'] = this.helpDocumantion!.toJson();
    }
    if (this.paramConfig != null) {
      data['param_config'] = this.paramConfig!.toJson();
    }
    data['is_multi_files'] = this.isMultiFiles;
    // if (this.criticality != null) {
    //   data['criticality'] = this.criticality!.map((v) => v.toJson()).toList();
    // }
    data['parameter_name_b'] = this.parameterNameB;
    data['data_group_ref'] = this.dataGroupRef;
    data['category_type'] = this.categoryType;
    data['rating_style'] = this.ratingStyle;
    data['file_type'] = this.fileType;
    if (this.version != null) {
      data['version'] = this.version!.toJson();
    }
    data['master_parent_id'] = this.masterParentId;
    data['name'] = this.name;
    data['status'] = this.status;
    if (this.stateManager != null) {
      data['state_manager'] = this.stateManager!.toJson();
    }
    // if (this.parameterTypeFields != null) {
    //   data['parameter_type_fields'] = this.parameterTypeFields!.map((v) => v.toJson()).toList();
    // }
    if (this.parameterState != null) {
      data['parameter_state'] = this.parameterState!.toJson();
    }
    data['module_name'] = this.moduleName;
    data['parameter_name_a'] = this.parameterNameA;
    data['is_it_range_parameter'] = this.isItRangeParameter;
    // data['path'] = this.path;
    return data;
  }
}
