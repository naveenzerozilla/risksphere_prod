class LocationDocument {
  final String id;
  final String name;
  final List<String> urls;
  final int size;
  final bool isLocationMedia;
  final String? uploadedBy;
  final DateTime? createdAt;

  LocationDocument({
    required this.id,
    required this.name,
    required this.urls,
    required this.size,
    required this.isLocationMedia,
    this.uploadedBy,
    this.createdAt,
  });

  factory LocationDocument.fromJson(Map<String, dynamic> json) {
    List<String> parsedUrls = [];

    final rawUrl = json['url'];

    if (rawUrl is List) {
      parsedUrls = rawUrl
          .where((e) => e != null)
          .map((e) => e.toString())
          .toList();
    } else if (rawUrl is String) {
      parsedUrls = [rawUrl];
    }

    return LocationDocument(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      urls: parsedUrls,
      size: json['size'] ?? 0,
      isLocationMedia: json['is_location_media'] ?? false,
      uploadedBy: json['uploadedBy']?.toString(),
      createdAt: json['created_at'] != null &&
          json['created_at']['_seconds'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
        json['created_at']['_seconds'] * 1000,
      )
          : null,
    );
  }
}
