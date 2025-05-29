// class Company {
//   final String companyId;
//   final String companyName;
//   final String companyType;
//   final String country;
//
//   Company({
//     required this.companyId,
//     required this.companyName,
//     required this.companyType,
//     required this.country,
//   });
//
//   factory Company.fromJson(Map<String, dynamic> json) {
//     return Company(
//       companyId: json['company_id'] ?? '',
//       companyName: json['company_name'] ?? '', // ✅ Ensure correct field mapping
//       companyType: json['company_type'] ?? '',
//       country: json['country'] ?? '',
//     );
//   }
// }
