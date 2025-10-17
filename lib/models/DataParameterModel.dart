class DataParametersModel {
  List<Result>? result;
  HasUpgraded? hasUpgraded;
  Completeness? completeness;

  DataParametersModel({this.result, this.hasUpgraded, this.completeness});

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
  ParamConfig? paramConfig;
  HelpDocumantion? helpDocumantion;
  dynamic? criticality;
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

  Result(
      {this.id,
      this.hazardName,
      this.name,
      this.parentId,
      this.parameterState,
      this.private,
      this.dataCategoryId,
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
      this.history});

  Result.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    hazardName = json['hazard_name'];
    name = json['name'];
    parentId = json['parent_id'];
    parameterState = json['parameter_state'] != null
        ? ParameterState.fromJson(json['parameter_state'])
        : null;
    private =
        json['private'] != null ? Private.fromJson(json['private']) : null;
    dataCategoryId = json['data_category_id'];
    paramConfig = json['param_config'] != null
        ? ParamConfig.fromJson(json['param_config'])
        : null;
    helpDocumantion = json['help_documantion'] != null
        ? new HelpDocumantion.fromJson(json['help_documantion'])
        : null;

    // criticality = json['criticality'] != null
    //     ? Criticality.fromJson(json['criticality'])
    //     : null;
    parameterNameA = json['parameter_name_a'];
    parameterNameB = json['parameter_name_b'];
    parameterType = json['parameter_type'] != null
        ? ParameterType.fromJson(json['parameter_type'])
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
    version =
        json['version'] != null ? Version.fromJson(json['version']) : null;
    stateManager = json['state_manager'] != null
        ? StateManager.fromJson(json['state_manager'])
        : null;
    user = json['user'] != null ? User.fromJson(json['user']) : null;

    parameterValue = json['parameter_value'] != null
        ? new ParameterValue.fromJson(json['parameter_value'])
        : null;
    currency = json['currency'];
    if (json['history'] != null) {
      history = <History>[];
      json['history'].forEach((v) {
        history!.add(new History.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = this.id;
    data['hazard_name'] = this.hazardName;
    data['name'] = this.name;
    data['parent_id'] = this.parentId;
    if (this.parameterState != null) {
      data['parameter_state'] = this.parameterState!.toJson();
    }
    if (this.private != null) {
      data['private'] = this.private!.toJson();
    }
    data['data_category_id'] = this.dataCategoryId;
    if (this.paramConfig != null) {
      data['param_config'] = this.paramConfig!.toJson();
    }
    if (this.helpDocumantion != null) {
      data['help_documantion'] = this.helpDocumantion!.toJson();
    }
    // if (this.criticality != null) {
    //   data['criticality'] = this.criticality!.toJson();
    // }
    data['parameter_name_a'] = this.parameterNameA;
    data['parameter_name_b'] = this.parameterNameB;
    if (this.parameterType != null) {
      data['parameter_type'] = this.parameterType!.toJson();
    }
    data['selected_parameter_type'] = this.selectedParameterType;
    data['unit_name'] = this.unitName;
    data['tooltip'] = this.tooltip;
    data['status'] = this.status;
    data['rating_style'] = this.ratingStyle;
    data['file_type'] = this.fileType;
    data['is_list'] = this.isList;
    data['is_multi_selection_list'] = this.isMultiSelectionList;
    data['is_multi_files'] = this.isMultiFiles;
    data['is_display_listing'] = this.isDisplayListing;
    data['is_it_range_parameter'] = this.isItRangeParameter;
    data['module_name'] = this.moduleName;
    data['category_type'] = this.categoryType;
    data['pd_element'] = this.pdElement;
    data['date'] = this.date;
    data['startDate'] = this.startDate;
    data['endDate'] = this.endDate;
    data['data_group_ref'] = this.dataGroupRef;
    if (this.version != null) {
      data['version'] = this.version!.toJson();
    }
    if (this.stateManager != null) {
      data['state_manager'] = this.stateManager!.toJson();
    }
    if (this.user != null) {
      data['user'] = this.user!.toJson();
    }
    if (this.parameterValue != null) {
      data['parameter_value'] = this.parameterValue!.toJson();
    }
    data['currency'] = this.currency;
    if (this.history != null) {
      data['history'] = this.history!.map((v) => v.toJson()).toList();
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
  Null? parameterB;
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

// class Result {
//   // List<Null>? valueList;
//   // List<Null>? parameterTypeFields;
//   String? name;
//   String? parentId;
//   ParameterState? parameterState;
//   Private? private;
//   String? dataCategoryId;
//   ParamConfig? paramConfig;
//
//   // HelpDocumantion? helpDocumantion;
//   Criticality? criticality;
//   String? parameterNameA;
//   String? parameterNameB;
//   ParameterType? parameterType;
//   int? selectedParameterType;
//   String? unitName;
//   String? tooltip;
//   bool? status;
//   String? ratingStyle;
//   String? fileType;
//   bool? isList;
//   bool? isMultiSelectionList;
//   bool? isMultiFiles;
//   bool? isDisplayListing;
//   bool? isItRangeParameter;
//
//   // String? parameterType;
//   String? moduleName;
//   String? categoryType;
//   String? pdElement;
//   String? date;
//   Null? startDate;
//   Null? endDate;
//   String? dataGroupRef;
//   Version? version;
//   StateManager? stateManager;
//   User? user;
//
//   // ParameterValue? parameterValue;
//   String? currency;
//
//   Result(
//       {
//       // this.valueList, this.parameterTypeFields,
//       this.name,
//       this.parentId,
//       this.parameterState,
//       this.private,
//       this.dataCategoryId,
//       this.paramConfig,
//       // this.helpDocumantion,
//       this.criticality,
//       this.parameterNameA,
//       this.parameterNameB,
//       this.parameterType,
//       this.selectedParameterType,
//       this.unitName,
//       this.tooltip,
//       this.status,
//       this.ratingStyle,
//       this.fileType,
//       this.isList,
//       this.isMultiSelectionList,
//       this.isMultiFiles,
//       this.isDisplayListing,
//       this.isItRangeParameter,
//       // this.parameterType,
//       this.moduleName,
//       this.categoryType,
//       this.pdElement,
//       this.date,
//       this.startDate,
//       this.endDate,
//       this.dataGroupRef,
//       this.version,
//       this.stateManager,
//       this.user,
//       // this.parameterValue,
//       this.currency});
//
//   Result.fromJson(Map<String, dynamic> json) {
//     // if (json['value_list'] != null) {
//     //   valueList = <Null>[];
//     //   json['value_list'].forEach((v) { valueList!.add(new Null.fromJson(v)); });
//     // }
//     // if (json['parameter_type_fields'] != null) {
//     //   parameterTypeFields = <Null>[];
//     //   json['parameter_type_fields'].forEach((v) { parameterTypeFields!.add(new Null.fromJson(v)); });
//     // }
//     name = json['name'];
//     parentId = json['parent_id'];
//     parameterState = json['parameter_state'] != null
//         ? new ParameterState.fromJson(json['parameter_state'])
//         : null;
//     private =
//         json['private'] != null ? new Private.fromJson(json['private']) : null;
//     dataCategoryId = json['data_category_id'];
//     paramConfig = json['param_config'] != null
//         ? new ParamConfig.fromJson(json['param_config'])
//         : null;
//     // helpDocumantion = json['help_documantion'] != null ? new HelpDocumantion.fromJson(json['help_documantion']) : null;
//     criticality = json['criticality'] != null
//         ? new Criticality.fromJson(json['criticality'])
//         : null;
//     parameterNameA = json['parameter_name_a'];
//     parameterNameB = json['parameter_name_b'];
//
//     parameterType = json['parameterType'];
//
//     selectedParameterType = json['selected_parameter_type'];
//     unitName = json['unit_name'];
//     tooltip = json['tooltip'];
//     status = json['status'];
//     ratingStyle = json['rating_style'];
//     fileType = json['file_type'];
//     isList = json['is_list'];
//     isMultiSelectionList = json['is_multi_selection_list'];
//     isMultiFiles = json['is_multi_files'];
//     isDisplayListing = json['is_display_listing'];
//     isItRangeParameter = json['is_it_range_parameter'];
//     parameterType = json['parameterType'];
//     moduleName = json['module_name'];
//     categoryType = json['category_type'];
//     pdElement = json['pd_element'];
//     date = json['date'];
//     startDate = json['startDate'];
//     endDate = json['endDate'];
//     dataGroupRef = json['data_group_ref'];
//     version =
//         json['version'] != null ? new Version.fromJson(json['version']) : null;
//     stateManager = json['state_manager'] != null
//         ? new StateManager.fromJson(json['state_manager'])
//         : null;
//     user = json['user'] != null ? new User.fromJson(json['user']) : null;
//     // parameterValue = json['parameter_value'] != null ? new ParameterValue.fromJson(json['parameter_value']) : null;
//     currency = json['currency'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     // if (this.valueList != null) {
//     //   data['value_list'] = this.valueList!.map((v) => v.toJson()).toList();
//     // }
//     // if (this.parameterTypeFields != null) {
//     //   data['parameter_type_fields'] = this.parameterTypeFields!.map((v) => v.toJson()).toList();
//     // }
//     data['name'] = this.name;
//     data['parent_id'] = this.parentId;
//     if (this.parameterState != null) {
//       data['parameter_state'] = this.parameterState!.toJson();
//     }
//     if (this.private != null) {
//       data['private'] = this.private!.toJson();
//     }
//     data['data_category_id'] = this.dataCategoryId;
//     if (this.paramConfig != null) {
//       data['param_config'] = this.paramConfig!.toJson();
//     }
//     // if (this.helpDocumantion != null) {
//     //   data['help_documantion'] = this.helpDocumantion!.toJson();
//     // }
//     if (this.criticality != null) {
//       data['criticality'] = this.criticality!.toJson();
//     }
//     data['parameter_name_a'] = this.parameterNameA;
//     data['parameter_name_b'] = this.parameterNameB;
//     if (this.parameterType != null) {
//       data['parameter_type'] = this.parameterType!.toJson();
//     }
//     data['selected_parameter_type'] = this.selectedParameterType;
//     data['unit_name'] = this.unitName;
//     data['tooltip'] = this.tooltip;
//     data['status'] = this.status;
//     data['rating_style'] = this.ratingStyle;
//     data['file_type'] = this.fileType;
//     data['is_list'] = this.isList;
//     data['is_multi_selection_list'] = this.isMultiSelectionList;
//     data['is_multi_files'] = this.isMultiFiles;
//     data['is_display_listing'] = this.isDisplayListing;
//     data['is_it_range_parameter'] = this.isItRangeParameter;
//     data['parameterType'] = this.parameterType;
//     data['module_name'] = this.moduleName;
//     data['category_type'] = this.categoryType;
//     data['pd_element'] = this.pdElement;
//     data['date'] = this.date;
//     data['startDate'] = this.startDate;
//     data['endDate'] = this.endDate;
//     data['data_group_ref'] = this.dataGroupRef;
//     if (this.version != null) {
//       data['version'] = this.version!.toJson();
//     }
//     if (this.stateManager != null) {
//       data['state_manager'] = this.stateManager!.toJson();
//     }
//     if (this.user != null) {
//       data['user'] = this.user!.toJson();
//     }
//     // if (this.parameterValue != null) {
//     //   data['parameter_value'] = this.parameterValue!.toJson();
//     // }
//     data['currency'] = this.currency;
//     return data;
//   }
// }
class ParameterValue {
  dynamic value;
  String? paramType;
  List<Reference>? reference;
  String? userName;
  UpdatedAt? updatedAt;

  ParameterValue(
      {this.value,
      this.paramType,
      this.reference,
      this.userName,
      this.updatedAt});

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
  String? name;

  Reference({this.url, this.tags, this.name});

  Reference.fromJson(Map<String, dynamic> json) {
    url = json['url'];
    tags = json['tags'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['url'] = this.url;
    data['tags'] = this.tags;
    data['name'] = this.name;
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

// class HelpDocumantion {
//   List<dynamic>? images;
//   List<dynamic>? docs;
//
//   HelpDocumantion({this.images, this.docs});
//
//   HelpDocumantion.fromJson(Map<String, dynamic> json) {
//     if (json['images'] != null) {
//       images = <Null>[];
//       json['images'].forEach((v) { images!.add(new Null.fromJson(v)); });
//     }
//     if (json['docs'] != null) {
//       docs = <Null>[];
//       json['docs'].forEach((v) { docs!.add(new Null.fromJson(v)); });
//     }
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     if (this.images != null) {
//       data['images'] = this.images!.map((v) => v.toJson()).toList();
//     }
//     if (this.docs != null) {
//       data['docs'] = this.docs!.map((v) => v.toJson()).toList();
//     }
//     return data;
//   }
// }

class Criticality {
  String? impactType;
  int? avgPdCriticality;
  int? avgTeCriticality;

  // Advisory? advisory;

  Criticality({
    this.impactType,
    this.avgPdCriticality,
    this.avgTeCriticality,
    // this.advisory
  });

  Criticality.fromJson(Map<String, dynamic> json) {
    impactType = json['impact_type'];
    avgPdCriticality = json['avg_pd_criticality'];
    avgTeCriticality = json['avg_te_criticality'];
    // advisory = json['advisory'] != null ? new Advisory.fromJson(json['advisory']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['impact_type'] = this.impactType;
    data['avg_pd_criticality'] = this.avgPdCriticality;
    data['avg_te_criticality'] = this.avgTeCriticality;
    // if (this.advisory != null) {
    //   data['advisory'] = this.advisory!.toJson();
    // }
    return data;
  }
}

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

// class Advisory {
//   8WiDjXICWSQ9APEgMAn7wWk8NEj2? 88WiDjXICWSQ9APEgMAn7wWk8NEj2;
//
//   Advisory({this.88WiDjXICWSQ9APEgMAn7wWk8NEj2});
//
//   Advisory.fromJson(Map<String, dynamic> json) {
//   88WiDjXICWSQ9APEgMAn7wWk8NEj2 = json['8WiDjXICWSQ9APEgMAn7wWk8NEj2'] != null ? new 8WiDjXICWSQ9APEgMAn7wWk8NEj2.fromJson(json['8WiDjXICWSQ9APEgMAn7wWk8NEj2']) : null;
//   }
//
//   Map<String, dynamic> toJson() {
//   final Map<String, dynamic> data = new Map<String, dynamic>();
//   if (this.88WiDjXICWSQ9APEgMAn7wWk8NEj2 != null) {
//   data['8WiDjXICWSQ9APEgMAn7wWk8NEj2'] = this.88WiDjXICWSQ9APEgMAn7wWk8NEj2!.toJson();
//   }
//   return data;
//   }
// }

// class 8WiDjXICWSQ9APEgMAn7wWk8NEj2 {
// List<Null>? history;
// String? name;
// String? email;
// String? userId;
// String? date;
// int? pdCriticality;
// int? teCriticality;
// bool? isRsAdmin;
// String? comments;
//
// 8WiDjXICWSQ9APEgMAn7wWk8NEj2({this.history, this.name, this.email, this.userId, this.date, this.pdCriticality, this.teCriticality, this.isRsAdmin, this.comments});
//
// 8WiDjXICWSQ9APEgMAn7wWk8NEj2.fromJson(Map<String, dynamic> json) {
// if (json['history'] != null) {
// history = <Null>[];
// json['history'].forEach((v) { history!.add(new Null.fromJson(v)); });
// }
// name = json['name'];
// email = json['email'];
// userId = json['user_id'];
// date = json['date'];
// pdCriticality = json['pd_criticality'];
// teCriticality = json['te_criticality'];
// isRsAdmin = json['is_rs_admin'];
// comments = json['comments'];
// }
//
// Map<String, dynamic> toJson() {
// final Map<String, dynamic> data = new Map<String, dynamic>();
// if (this.history != null) {
// data['history'] = this.history!.map((v) => v.toJson()).toList();
// }
// data['name'] = this.name;
// data['email'] = this.email;
// data['user_id'] = this.userId;
// data['date'] = this.date;
// data['pd_criticality'] = this.pdCriticality;
// data['te_criticality'] = this.teCriticality;
// data['is_rs_admin'] = this.isRsAdmin;
// data['comments'] = this.comments;
// return data;
// }
// }

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
