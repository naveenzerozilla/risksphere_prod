class GiftModel {
  final int totalRecords;
  final int page;
  final int pageSize;
  final List<GiftResult> results;

  GiftModel({
    required this.totalRecords,
    required this.page,
    required this.pageSize,
    required this.results,
  });

  factory GiftModel.fromJson(Map<String, dynamic> json) {
    return GiftModel(
      totalRecords: json['totalRecords'] ?? 0,
      page: json['page'] ?? 1,
      pageSize: json['pageSize'] ?? 20,
      results: (json['results'] as List? ?? [])
          .map((e) => GiftResult.fromJson(e))
          .toList(),
    );
  }
}

class GiftResult {
  final String giftId;
  final String senderUserId;
  final String senderEmail;
  final String senderUserName;
  final String senderCompanyId;
  final String recipientEmail;
  final String recipientUserId;
  final String recipientUserName;
  final String? recipientCompanyId;
  final String planType;
  final int credits;
  final String status;
  final DateTime? expiresAt;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool notificationSent;
  final String? resultPlanId;
  final String? message;

  GiftResult({
    required this.giftId,
    required this.senderUserId,
    required this.senderEmail,
    required this.senderUserName,
    required this.senderCompanyId,
    required this.recipientEmail,
    required this.recipientUserId,
    required this.recipientUserName,
    this.recipientCompanyId,
    required this.planType,
    required this.credits,
    required this.status,
    this.expiresAt,
    this.acceptedAt,
    this.rejectedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.notificationSent,
    this.resultPlanId,
    this.message,
  });

  factory GiftResult.fromJson(Map<String, dynamic> json) {
    DateTime? parseTimestamp(dynamic val) {
      if (val == null) return null;
      if (val is Map && val['_seconds'] != null) {
        return DateTime.fromMillisecondsSinceEpoch(
            (val['_seconds'] as int) * 1000);
      }
      return null;
    }

    return GiftResult(
      giftId: json['gift_id'] ?? '',
      senderUserId: json['sender_user_id'] ?? '',
      senderEmail: json['sender_email'] ?? '',
      senderUserName: json['sender_user_name'] ?? '',
      senderCompanyId: json['sender_company_id'] ?? '',
      recipientEmail: json['recipient_email'] ?? '',
      recipientUserId: json['recipient_user_id'] ?? '',
      recipientUserName: json['recipient_user_name'] ?? '',
      recipientCompanyId: json['recipient_company_id'],
      planType: json['plan_type'] ?? '',
      credits: json['credits'] ?? 0,
      status: json['status'] ?? '',
      expiresAt: parseTimestamp(json['expires_at']),
      acceptedAt: parseTimestamp(json['accepted_at']),
      rejectedAt: parseTimestamp(json['rejected_at']),
      createdAt: parseTimestamp(json['created_at']) ?? DateTime.now(),
      updatedAt: parseTimestamp(json['updated_at']) ?? DateTime.now(),
      notificationSent: json['notification_sent'] ?? false,
      resultPlanId: json['result_plan_id'],
      message: json['message'],
    );
  }
}
