// // impact_data_card.dart
// import 'package:flutter/material.dart';
//
// import '../design_system/primitives/app_colors.dart';
// import '../screens/listings/widgets/data_tab.dart';
//
// class ImpactDataCard extends StatefulWidget {
//   final String title;
//   final Color titleColor;
//   final List<String> dataElements;
//
//   const ImpactDataCard({
//     Key? key,
//     required this.title,
//     required this.titleColor,
//     required this.dataElements,
//   }) : super(key: key);
//
//   @override
//   _ImpactDataCardState createState() => _ImpactDataCardState();
// }
//
// class _ImpactDataCardState extends State<ImpactDataCard> {
//   String? expandedElement;
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(8),
//         side: BorderSide(color: Colors.grey, width: 0.5),
//       ),
//       elevation: 4,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Title
//           Container(
//             padding: const EdgeInsets.only(left: 16, top: 15, bottom: 10),
//             child: Text(
//               widget.title,
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//                 color: widget.titleColor,
//               ),
//             ),
//           ),
//           // Divider(),
//
//           // Expandable List
//           ...widget.dataElements.asMap().entries.map((entry) {
//             int index = entry.key;
//             String element = entry.value;
//             final isExpanded = expandedElement == element;
//             return Column(
//               children: [
//                 if (index == 0)Divider(height: 1, color: Colors.grey),
//                 Container(
//                   margin: isExpanded ? EdgeInsets.all(8): EdgeInsets.all(0),
//                   // Try adjusting this
//                   decoration: BoxDecoration(
//                       // color: Colors.blueGrey,
//                       color: isExpanded ? AppColors.primaryMain.withOpacity(0.16) : Colors.transparent,
//                       border: Border.all(color: isExpanded ?Colors.blue : Colors.transparent),
//                       borderRadius: BorderRadius.circular(10)),
//
//                   child: Column(
//                     children: [
//                       GestureDetector(
//                         onTap: () {
//                           setState(() {
//                             expandedElement = isExpanded ? null : element;
//                           });
//                         },
//                         child: Container(
//
//
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 10),
//                           decoration: BoxDecoration(
//                             border: Border(
//                               bottom:
//                                   BorderSide(color: Colors.grey, width: 0.5),
//                             ),
//                           ),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.start,
//                             crossAxisAlignment: CrossAxisAlignment.center,
//                             children: [
//                               if (isExpanded) ...[
//                                 Icon(
//                                   Icons.star,
//                                   color: Colors.orangeAccent,
//                                   size: 25,
//                                 ),
//                                 SizedBox(width: 5),
//                               ],
//
//                               Expanded(
//                                 child: Text(
//                                   element,
//                                   style: TextStyle(
//                                     color: isExpanded
//                                         ? Colors.lightBlueAccent
//                                         : widget.titleColor,
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                 ),
//                               ),
//                               if (isExpanded) ...[
//                                 InkWell(
//                                   onTap: () {
//                                     showVersionHistoryBottomSheet(context);
//                                   },
//                                   child: Icon(
//                                     Icons.history,
//                                     color: Colors.white60,
//                                     size: 25,
//                                   ),
//                                 ),
//                                 SizedBox(width: 8),
//                                 Icon(
//                                   Icons.edit_document,
//                                   color: Colors.white60,
//                                   size: 25,
//                                 ),
//                                 SizedBox(width: 10),
//                               ],
//                               Container(
//                                 height: 50,
//                                 width: 1,
//                                 color: Colors.grey, // Vertical line
//                               ),
//                               SizedBox(width: 10),
//                               Icon(
//                                 isExpanded
//                                     ? Icons.remove_circle_outline
//                                     : Icons.add_circle_outline_outlined,
//                                 color: Colors.white60,
//                                 size: 25,
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       if (isExpanded)
//                         Container(
//                           padding: const EdgeInsets.all(16.0),
//                           child: ImageUploadCard(
//                             title: "Number of Floors",
//                             onImagesUpdated: (images) {
//                               print("Uploaded Images Count: ${images.length}");
//                             },
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//               ],
//             );
//           }).toList(),
//         ],
//       ),
//     );
//   }
//   void showVersionHistoryBottomSheet(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       backgroundColor: Colors.black87,
//       builder: (context) {
//         return Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // Header
//               Row(
//                 children: [
//                   CircleAvatar(
//                     backgroundImage: AssetImage('assets/user.jpg'), // Replace with actual image
//                   ),
//                   SizedBox(width: 10),
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text('Robert Jr',
//                           style: TextStyle(color: Colors.white, fontSize: 16)),
//                       Text('Created on 5/23/2024',
//                           style: TextStyle(color: Colors.purpleAccent, fontSize: 12)),
//                     ],
//                   ),
//                   Spacer(),
//                   IconButton(
//                     icon: Icon(Icons.close, color: Colors.white),
//                     onPressed: () => Navigator.pop(context),
//                   )
//                 ],
//               ),
//               Divider(color: Colors.white30),
//
//               // Version Updates
//               Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text('Version Updates',
//                     style: TextStyle(color: Colors.white, fontSize: 14)),
//               ),
//               SizedBox(height: 12),
//
//               // Version List
//               ListView(
//                 shrinkWrap: true,
//                 physics: NeverScrollableScrollPhysics(),
//                 children: [
//                   _versionTile("Version 2.0", "03/03/2025 11:13:22", "Jessica Smith", "R", Colors.blue),
//                   _versionTile("Version 1.2", "03/03/2025 11:13:22", "Jessica Smith", "D", Colors.orange),
//                   _versionTile("Version 1.1", "03/03/2025 11:13:22", "Jessica Smith", "D", Colors.orange),
//                 ],
//               ),
//
//               // View more
//               Align(
//                 alignment: Alignment.centerLeft,
//                 child: TextButton(
//                   onPressed: () {},
//                   child: Text("View more", style: TextStyle(color: Colors.blue)),
//                 ),
//               ),
//               SizedBox(height: 20),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _versionTile(String version, String date, String author, String badge, Color badgeColor) {
//     return ListTile(
//       contentPadding: EdgeInsets.zero,
//       leading: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.circle, color: Colors.blue),
//           Container(
//             width: 2,
//             height: 30,
//             color: Colors.white,
//           )
//         ],
//       ),
//       title: Row(
//         children: [
//           Text(version, style: TextStyle(color: Colors.blueAccent)),
//           SizedBox(width: 8),
//           Text(date, style: TextStyle(color: Colors.white70, fontSize: 12)),
//         ],
//       ),
//       subtitle: Text(author, style: TextStyle(color: Colors.white54)),
//       trailing: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           CircleAvatar(
//             radius: 12,
//             backgroundColor: badgeColor,
//             child: Text(badge, style: TextStyle(fontSize: 12, color: Colors.white)),
//           ),
//           SizedBox(width: 8),
//           Icon(Icons.lock_open_outlined, color: Colors.orange, size: 18),
//         ],
//       ),
//     );
//   }
//
// }
