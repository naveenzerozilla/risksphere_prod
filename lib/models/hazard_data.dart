import 'package:RiskSphere/models/vendor_data.dart';

class HazardData {
  final String id;
  final String name;
  final bool active;
  final List<VendorData> vendors;

  HazardData({
    required this.id,
    required this.name,
    required this.active,
    required this.vendors,
  });

  factory HazardData.fromJson(Map<String, dynamic> json) {
    return HazardData(
      id: json['id'],
      name: json['name'],
      active: json['active'],
      vendors: (json['vendors'] as List)
          .map((v) => VendorData.fromJson(v))
          .toList(),
    );
  }
}