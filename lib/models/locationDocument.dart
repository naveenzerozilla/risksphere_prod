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
    return LocationDocument(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      urls: List<String>.from(json['url'] ?? []),
      size: json['size'] ?? 0,
      isLocationMedia: json['is_location_media'] ?? false,
      uploadedBy: json['uploadedBy'],
      createdAt: json['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
        json['created_at']['_seconds'] * 1000,
      )
          : null,
    );
  }
}
