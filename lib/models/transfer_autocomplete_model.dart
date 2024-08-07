class TransferAutocompleteModel {
  final String id;
  final String displayName;
  final String email;
  final String imageUrl;

  TransferAutocompleteModel({
    required this.id,
    required this.displayName,
    required this.email,
    required this.imageUrl,
  });

  factory TransferAutocompleteModel.fromJson(Map<String, dynamic> json) {
    return TransferAutocompleteModel(
      id: json['id'] ?? '',
      displayName: json['displayName'] ?? '',
      email: json['email'] ?? '',
      imageUrl: json['display_image_url'] ?? '',
    );
  }
}
