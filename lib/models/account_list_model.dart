import 'DataParameterModel.dart';

class AccountListModel {
  int? totalHits;
  List<Accounts>? results; // 👈 single list
  int? totalPages;
  Settings? settings;
  int? totalRecords;
  String? sovId;
  bool? fromCache;
  List<Data>? data;
  UpdatedAt? updatedAt;

  AccountListModel({
    this.totalHits,
    this.results,
    this.totalPages,
    this.settings,
    this.totalRecords,
    this.sovId,
    this.fromCache,
    this.data,
    this.updatedAt,
  });

  AccountListModel.fromJson(Map<String, dynamic> json) {
    totalHits = json['totalHits'];
    totalRecords = json['totalRecords'];
    totalPages = json['totalPages'];
    sovId = json['sov_id'];
    fromCache = json['from_cache'];

    /// ✅ HANDLE BOTH `results` AND `result`
    final list = json['results'] ?? json['result'];
    if (list != null && list is List) {
      results = list.map((v) => Accounts.fromJson(v)).toList();
    } else {
      results = [];
    }

    settings =
        json['settings'] != null ? Settings.fromJson(json['settings']) : null;

    if (json['data'] != null) {
      data = (json['data'] as List).map((v) => Data.fromJson(v)).toList();
    }

    updatedAt = json['updated_at'] != null
        ? UpdatedAt.fromJson(json['updated_at'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    json['totalHits'] = totalHits;
    json['totalRecords'] = totalRecords;
    json['totalPages'] = totalPages;
    json['sov_id'] = sovId;
    json['from_cache'] = fromCache;

    if (results != null) {
      json['results'] = results!.map((v) => v.toJson()).toList();
    }

    if (settings != null) {
      json['settings'] = settings!.toJson();
    }

    if (data != null) {
      json['data'] = data!.map((v) => v.toJson()).toList();
    }

    if (updatedAt != null) {
      json['updated_at'] = updatedAt!.toJson();
    }

    return json;
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
  bool disabled = false;
  String? id;
  String? hazardName;
  String? name;
  String? parentId;
  ParameterState? parameterState;
  Private? private;
  String? dataCategoryId;
  ParamConfig? paramConfig;
  HelpDocumantion? helpDocumantion;
  dynamic criticality;
  String? parameterNameA;
  String? parameterNameB;
  dynamic parameterType;
  int? selectedParameterType;
  String? unitName;
  bool? isMultiSelectionList;
  bool? isDisplayListing;
  ParameterValue? parameterValue;
  bool? isList;
  String? belongsToCompany;
  Null? date;
  String? tooltip;

  // List<String>? parents;
  bool? isCustom;
  String? pdElement;
  User? user;
  List<Null>? valueList;

  // List<String>? tags;
  Null? endDate;
  Null? startDate;
  bool? isMultiFiles;
  String? dataGroupRef;
  String? categoryType;
  String? ratingStyle;
  String? fileType;
  String? masterParentId;
  Version? version;
  bool? status;
  StateManager? stateManager;
  List<Null>? parameterTypeFields;
  String? moduleName;
  bool? isItRangeParameter;
  List<Null>? history;
  UpdatedAt? updatedAt;

  Accounts(
      {this.accountName,
      this.owner,
      this.companyId,
      this.accountId,
      this.overallScore,
      this.sovCount,
      this.subAccountCount,
      this.isChecked = false,
      this.disabled = false,
      this.unitName,
      this.isMultiSelectionList,
      this.isDisplayListing,
      this.parameterValue,
      this.selectedParameterType,
      this.isList,
      this.belongsToCompany,
      this.dataCategoryId,
      this.date,
      this.tooltip,
      // this.parents,
      this.isCustom,
      this.parentId,
      this.pdElement,
      this.user,
      this.private,
      this.parameterType,
      this.valueList,
      this.helpDocumantion,
      // this.tags,
      this.endDate,
      this.startDate,
      this.isMultiFiles,
      this.paramConfig,
      this.criticality,
      this.parameterNameB,
      this.dataGroupRef,
      this.categoryType,
      this.ratingStyle,
      this.fileType,
      this.masterParentId,
      this.version,
      this.name,
      this.status,
      this.stateManager,
      this.parameterTypeFields,
      this.parameterState,
      this.moduleName,
      this.parameterNameA,
      this.isItRangeParameter,
      this.history,
      this.updatedAt});

  Accounts.fromJson(Map<String, dynamic> json) {
    accountName = json['account_name'] ?? "";
    owner = json['owner'] != null ? Owner.fromJson(json['owner']) : null;
    companyId = json['company_id'] ?? "";
    accountId = json['account_id'];
    overallScore = json['overall_score'];
    sovCount = json['sov_count'];
    subAccountCount = json['sub_account_count'];
    disabled = json['disabled'] ?? false;
    unitName = json['unit_name'];
    isMultiSelectionList = json['is_multi_selection_list'];
    isDisplayListing = json['is_display_listing'];
    parameterValue = json['parameter_value'] != null
        ? new ParameterValue.fromJson(json['parameter_value'])
        : null;
    selectedParameterType = json['selected_parameter_type'];
    isList = json['is_list'];
    belongsToCompany = json['belongs_to_company'];
    dataCategoryId = json['data_category_id'];
    date = json['date'];
    tooltip = json['tooltip'];
    // parents = json['parents'].cast<String>();
    isCustom = json['is_custom'];
    parentId = json['parent_id'];
    pdElement = json['pd_element'];
    user = json['user'] != null ? new User.fromJson(json['user']) : null;
    private =
        json['private'] != null ? new Private.fromJson(json['private']) : null;
    parameterType = json['parameterType'];

    helpDocumantion = json['help_documantion'] != null
        ? new HelpDocumantion.fromJson(json['help_documantion'])
        : null;
    // tags = json['tags'].cast<String>();
    endDate = json['endDate'];
    startDate = json['startDate'];
    isMultiFiles = json['is_multi_files'];
    paramConfig = json['param_config'] != null
        ? new ParamConfig.fromJson(json['param_config'])
        : null;
    parameterType = json['parameter_type'] != null
        ? new ParameterType.fromJson(json['parameter_type'])
        : null;
    if (json['criticality'] != null) {
      criticality = <Criticality>[];
      json['criticality'].forEach((v) {
        criticality!.add(new Criticality.fromJson(v));
      });
    }
    parameterNameB = json['parameter_name_b'];
    dataGroupRef = json['data_group_ref'];
    categoryType = json['category_type'];
    ratingStyle = json['rating_style'];
    fileType = json['file_type'];
    masterParentId = json['master_parent_id'];
    version =
        json['version'] != null ? new Version.fromJson(json['version']) : null;
    name = json['name'];
    status = json['status'];
    stateManager = json['state_manager'] != null
        ? new StateManager.fromJson(json['state_manager'])
        : null;

    parameterState = json['parameter_state'] != null
        ? new ParameterState.fromJson(json['parameter_state'])
        : null;
    moduleName = json['module_name'];
    parameterNameA = json['parameter_name_a'];
    isItRangeParameter = json['is_it_range_parameter'];

    updatedAt = json['updated_at'] != null
        ? new UpdatedAt.fromJson(json['updated_at'])
        : null;
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
    data['disabled'] = disabled;
    data['unit_name'] = this.unitName;
    data['is_multi_selection_list'] = this.isMultiSelectionList;
    data['is_display_listing'] = this.isDisplayListing;
    if (this.parameterValue != null) {
      data['parameter_value'] = this.parameterValue!.toJson();
    }
    data['selected_parameter_type'] = this.selectedParameterType;
    data['is_list'] = this.isList;
    data['belongs_to_company'] = this.belongsToCompany;
    data['data_category_id'] = this.dataCategoryId;
    data['date'] = this.date;
    data['tooltip'] = this.tooltip;
    // data['parents'] = this.parents;
    data['is_custom'] = this.isCustom;
    data['parent_id'] = this.parentId;
    data['pd_element'] = this.pdElement;
    if (this.user != null) {
      data['user'] = this.user!.toJson();
    }
    if (this.private != null) {
      data['private'] = this.private!.toJson();
    }
    data['parameterType'] = this.parameterType;

    if (this.helpDocumantion != null) {
      data['help_documantion'] = this.helpDocumantion!.toJson();
    }
    // data['tags'] = this.tags;
    data['endDate'] = this.endDate;
    data['startDate'] = this.startDate;
    data['is_multi_files'] = this.isMultiFiles;
    if (this.paramConfig != null) {
      data['param_config'] = this.paramConfig!.toJson();
    }

    if (this.criticality != null) {
      data['criticality'] = this.criticality!.map((v) => v.toJson()).toList();
    }
    data['parameter_name_b'] = this.parameterNameB;
    data['data_group_ref'] = this.dataGroupRef;
    data['category_type'] = this.categoryType;
    data['rating_style'] = this.ratingStyle;
    data['file_type'] = this.fileType;
    data['master_parent_id'] = this.masterParentId;
    if (this.version != null) {
      data['version'] = this.version!.toJson();
    }
    data['name'] = this.name;
    data['status'] = this.status;
    if (this.stateManager != null) {
      data['state_manager'] = this.stateManager!.toJson();
    }

    if (this.parameterState != null) {
      data['parameter_state'] = this.parameterState!.toJson();
    }
    data['module_name'] = this.moduleName;
    data['parameter_name_a'] = this.parameterNameA;
    data['is_it_range_parameter'] = this.isItRangeParameter;

    if (this.updatedAt != null) {
      data['updated_at'] = this.updatedAt!.toJson();
    }
    return data;
  }

  @override
  String toString() {
    return 'Accounts(accountId: $accountId, accountName: $accountName, disabled: $disabled)';
  }
}

class Owner {
  String? date;
  String? id;
  String? name;

  Owner({this.date, this.id, this.name});

  Owner.fromJson(Map<String, dynamic> json) {
    //date = json['date'];
    id = json['id'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    //data['date'] = date;
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
  CompanyGlobalConfiguration? companyGlobalConfiguration;

  Settings(
      {this.subAccountCount,
      this.sovCount,
      this.owner,
      this.overallScore,
      this.companyGlobalConfiguration});

  Settings.fromJson(Map<String, dynamic> json) {
    subAccountCount = json['sub_account_count'];
    sovCount = json['sov_count'];
    owner = json['owner'];
    overallScore = json['overall_score'];
    companyGlobalConfiguration = json['company_global_configuration'] != null
        ? new CompanyGlobalConfiguration.fromJson(
            json['company_global_configuration'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['sub_account_count'] = subAccountCount;
    data['sov_count'] = sovCount;
    data['owner'] = owner;
    data['overall_score'] = overallScore;
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
  String? subAccountName;

  CompanyGlobalConfiguration(
      {this.accountNames, this.accountName, this.subAccountName});

  CompanyGlobalConfiguration.fromJson(Map<String, dynamic> json) {
    accountNames = json['account_names'];
    accountName = json['account_name'];
    subAccountName = json['sub_account_name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['account_names'] = this.accountNames;
    data['account_name'] = this.accountName;
    data['sub_account_name'] = this.subAccountName;
    return data;
  }
}


class Data {
  String? sovId;
  String? locationId;
  String? locationName;
  String? placeId;
  bool? usFlag;
  double? latitude;
  double? longitude;
  String? address;
  int? totalParameters;
  int? totalUnfilledParameters;
  int? highRiskParameters;
  int? highRiskUnfilledParameters;
  List<String>? highRiskParameterNames;
  List<String>? highRiskUnfilledParameterNames;

  Data(
      {this.sovId,
      this.locationId,
      this.locationName,
      this.placeId,
      this.usFlag,
      this.latitude,
      this.longitude,
      this.address,
      this.totalParameters,
      this.totalUnfilledParameters,
      this.highRiskParameters,
      this.highRiskUnfilledParameters,
      this.highRiskParameterNames,
      this.highRiskUnfilledParameterNames});

  Data.fromJson(Map<String, dynamic> json) {
    sovId = json['sov_id'];
    locationId = json['location_id'];
    locationName = json['location_name'];
    placeId = json['place_id'];
    usFlag = json['us_flag'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    address = json['address'];
    totalParameters = json['total_parameters'];
    totalUnfilledParameters = json['total_unfilled_parameters'];
    highRiskParameters = json['high_risk_parameters'];
    highRiskUnfilledParameters = json['high_risk_unfilled_parameters'];
    highRiskParameterNames = json['high_risk_parameter_names'].cast<String>();
    highRiskUnfilledParameterNames =
        json['high_risk_unfilled_parameter_names'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['sov_id'] = this.sovId;
    data['location_id'] = this.locationId;
    data['location_name'] = this.locationName;
    data['place_id'] = this.placeId;
    data['us_flag'] = this.usFlag;
    data['latitude'] = this.latitude;
    data['longitude'] = this.longitude;
    data['address'] = this.address;
    data['total_parameters'] = this.totalParameters;
    data['total_unfilled_parameters'] = this.totalUnfilledParameters;
    data['high_risk_parameters'] = this.highRiskParameters;
    data['high_risk_unfilled_parameters'] = this.highRiskUnfilledParameters;
    data['high_risk_parameter_names'] = this.highRiskParameterNames;
    data['high_risk_unfilled_parameter_names'] =
        this.highRiskUnfilledParameterNames;
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
