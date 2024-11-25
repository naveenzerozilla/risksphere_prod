class TransferAutocompleteModel {
  final String id;
  final String displayName;
  final String email;
  final String imageUrl;
  final String phone;
  final String role;
  final bool isEnabled;

  TransferAutocompleteModel({
    required this.id,
    required this.displayName,
    required this.email,
    required this.imageUrl,
    required this.phone,
    required this.role,
    required this.isEnabled,
  });

  factory TransferAutocompleteModel.fromJson(Map<String, dynamic> json) {
    return TransferAutocompleteModel(
      id: json['id'] ?? '',
      displayName: json['displayName'] ?? '',
      email: json['email'] ?? '',
      imageUrl: json['display_image_url'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? '',
      isEnabled: json['is_enabled'] ?? false,
    );
  }
}