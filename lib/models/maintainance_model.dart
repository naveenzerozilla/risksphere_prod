class MaintainanceModel {
  String? id;
  DateTime? startTime;
  DateTime? endTime;
  String? message;
  String? status;
  bool? isActive;
  DateTime? updatedOn;

  MaintainanceModel({
    this.id,
    this.startTime,
    this.endTime,
    this.message,
    this.status,
    this.isActive,
    this.updatedOn,
  });

  // Factory method to parse from JSON
  factory MaintainanceModel.fromJson(Map<String, dynamic> json) {
    return MaintainanceModel(
      id: json['id'] as String?,
      startTime: json['start_time'] != null ? DateTime.parse(json['start_time']) : null,
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      message: json['message'] as String?,
      status: json['status'] as String?,
      isActive: json['is_active'] as bool?,
      updatedOn: json['updated_on'] != null ? DateTime.parse(json['updated_on']) : null,
    );
  }

  // Method to convert object back to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'message': message,
      'status': status,
      'is_active': isActive,
      'updated_on': updatedOn?.toIso8601String(),
    };
  }
}

class MaintainanceResponse {
  List<MaintainanceModel>? results;

  MaintainanceResponse({this.results});

  // Factory method to parse from JSON
  factory MaintainanceResponse.fromJson(Map<String, dynamic> json) {
    return MaintainanceResponse(
      results: (json['results'] as List<dynamic>?)
          ?.map((item) => MaintainanceModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  // Method to convert object back to JSON
  Map<String, dynamic> toJson() {
    return {
      'results': results?.map((result) => result.toJson()).toList(),
    };
  }
}
