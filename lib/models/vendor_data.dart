class VendorData {
  final String name;
  final String url;

  VendorData({required this.name, required this.url});

  factory VendorData.fromJson(Map<String, dynamic> json) {
    return VendorData(
      name: json['name'],
      url: json['url'],
    );
  }
}