// import 'dart:ui' as BorderType;
//
// import 'package:dotted_border/dotted_border.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:RiskSphare/design_system/repo/color_pallets_screen.dart';
// import 'package:provider/provider.dart';
// import '../../../constants/enums.dart';
// import '../../../design_system/components/custom_button.dart';
// import '../../../design_system/primitives/custom_typography.dart';
// import '../../../design_system/primitives/utilities/custom_spacing.dart';
// import '../../../design_system/primitives/app_colors.dart';
// import '../../../providers/configuration_provider.dart';
// import '../../../service/language_service.dart';
// import '../../../utils/ImpactDataCard.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';
//
// class DataTab extends StatefulWidget {
//   final String? accountName;
//   final String? accountId;
//   final String? subaccountId;
//
//   const DataTab({
//     Key? key,
//     this.accountName,
//     this.accountId,
//     this.subaccountId,
//   }) : super(key: key);
//
//   @override
//   _DataTabState createState() => _DataTabState();
// }
//
// class _DataTabState extends State<DataTab> {
//   TextEditingController _userSearchController = TextEditingController();
//   List<String> selectedServices = [];
//   List<int> selectedStars = [];
//   List<String> vendorList = [];
//   List<String> dataElements = [
//     'MinMaxThreshold',
//     'Construction Type',
//     'Number of Lifts',
//     'Year Built',
//   ];
//   List<String> criticalDataElements = [
//     'Number of Floors',
//     'Foundation Type',
//     'Structural Integrity',
//   ];
//
//   List<String> mediumDataElements = [
//     'Roof Type',
//     'Wall Material',
//   ];
//
//   List<String> lowDataElements = [
//     'Paint Type',
//     'Interior Design',
//   ];
//
//   String? expandedElement;
//
//   @override
//   void initState() {
//     super.initState();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Consumer<ConfigurationProvider>(
//       builder: (context, provider, child) {
//         if (provider.isLoading) {
//           return Center(child: CircularProgressIndicator());
//         }
//
//         return Container(
//           padding: const EdgeInsets.only(right: 10.0, left: 10.0, top: 10),
//           child: SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     SizedBox(height: 5),
//                     Text(
//                       'Configure Sub Account "${widget.accountName}" Data Parameters',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w400,
//                         color: AppColors.white,
//                       ),
//                     ),
//                     // SizedBox(height: 5),
//                     // Padding(
//                     //   padding: EdgeInsets.symmetric(horizontal: 6),
//                     //   child: TextField(
//                     //     controller: _userSearchController,
//                     //     onChanged: (query) {
//                     //       setState(() {});
//                     //       // Call search change handler with local setState
//                     //       // _onSearchChanged(query, setState);
//                     //     },
//                     //     decoration: InputDecoration(
//                     //       isDense: true,
//                     //       hintText: 'Search',
//                     //       border: OutlineInputBorder(),
//                     //       // suffixIcon:
//                     //       // _isSearching
//                     //       //     ?
//                     //       // Container(
//                     //       //     margin: EdgeInsets.fromLTRB(0, 8, 16, 8),
//                     //       //     width: 20,
//                     //       //     height: 20,
//                     //       //     child: CircularProgressIndicator())
//                     //       // : null,
//                     //     ),
//                     //   ),
//                     // ),
//                     SizedBox(height: 10),
//                     ImpactDataCard(
//                       title: 'My Parameters',
//                       titleColor: Colors.white,
//                       dataElements: dataElements,
//                     ),
//                     SizedBox(height: 10),
//                     // ImpactDataCard(
//                     //   title: 'Critical Impact Data Elements',
//                     //   titleColor: Colors.redAccent,
//                     //   dataElements: dataElements,
//                     // ),
//                     // SizedBox(height: 10),
//                     ImpactDataCard(
//                       title: 'Medium Impact Data Elements',
//                       titleColor: Colors.purple,
//                       dataElements: dataElements,
//                     ),
//                     SizedBox(height: 10),
//                     ImpactDataCard(
//                       title: 'Low Impact Data Elements',
//                       titleColor: Colors.green,
//                       dataElements: dataElements,
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
//
// class ImageUploadCard extends StatefulWidget {
//   final String title;
//   final Function(List<ImageProvider>) onImagesUpdated;
//
//   const ImageUploadCard({
//     Key? key,
//     required this.title,
//     required this.onImagesUpdated,
//   }) : super(key: key);
//
//   @override
//   _ImageUploadCardState createState() => _ImageUploadCardState();
// }
//
// class _ImageUploadCardState extends State<ImageUploadCard> {
//   List<ImageProvider> uploadedImages = [];
//   TextEditingController monthlyRentedController = TextEditingController();
//   TextEditingController valueTypeController = TextEditingController();
//   TextEditingController currencyController = TextEditingController();
//   TextEditingController dateController = TextEditingController();
//   DateTime? _startDate;
//   DateTime? _endDate;
//   final ImagePicker _picker = ImagePicker();
//   List<String> items = ['( 0 - 10)', '( 11 -20 )', '( 21 -100 )'];
//   List<Color> itemColors = [Colors.green, Colors.orange, Colors.red];
//   List<IconData> itemIcons = [
//     Icons.stacked_line_chart_outlined,
//     Icons.sports_tennis_outlined,
//     Icons.sports_motorsports_rounded
//   ];
//   String? selectedValue;
//
//   // void addImage() {
//   //   // Example: Add a placeholder image (Replace with actual image picker logic)
//   //   setState(() {
//   //     uploadedImages.add(AssetImage('assets/placeholder_image.png'));
//   //     widget.onImagesUpdated(uploadedImages); // Notify parent of changes
//   //   });
//   // }
//   void addImage() {
//     File? selectedImage;
//     List<String> selectedTags = [];
//     final List<String> tagOptions = ['Chip 1', 'Chip 2', 'Chip 3', 'Chip 4'];
//
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) => Padding(
//         padding: MediaQuery.of(context).viewInsets,
//         child: StatefulBuilder(
//           builder: (context, setModalState) {
//             return Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text("Upload",
//                       style:
//                           TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//                   const SizedBox(height: 16),
//
//                   // Upload Box or Filename Preview
//                   DottedBorder(
//                     radius: Radius.circular(12),
//                     dashPattern: [6, 3],
//                     color: Colors.grey,
//                     child: InkWell(
//                       onTap: () async {
//                         final XFile? image = await _picker.pickImage(
//                             source: ImageSource.gallery);
//                         if (image != null) {
//                           setModalState(() {
//                             selectedImage = File(image.path);
//                           });
//                         }
//                       },
//                       child: Container(
//                         width: double.infinity,
//                         height: 150,
//                         padding: EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: selectedImage != null
//                             ? Column(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Text(
//                                     'Selected File:',
//                                     style: TextStyle(fontSize: 16),
//                                     textAlign: TextAlign.center,
//                                   ),
//                                   const SizedBox(height: 8),
//                                   Row(
//                                     children: [
//                                       Container(
//                                         width: 250,
//                                         child: Text(
//                                           selectedImage!.path.split('/').last,
//                                           maxLines: 2,
//                                           style: TextStyle(fontSize: 16),
//                                           textAlign: TextAlign.center,
//                                         ),
//                                       ),
//                                       const SizedBox(height: 8),
//                                       TextButton.icon(
//                                         onPressed: () {
//                                           setModalState(() {
//                                             selectedImage = null;
//                                           });
//                                         },
//                                         icon: Icon(Icons.clear,
//                                             color: Colors.red),
//                                         label: Text("",
//                                             style:
//                                                 TextStyle(color: Colors.red)),
//                                       ),
//                                     ],
//                                   ),
//                                 ],
//                               )
//                             : Column(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Icon(Icons.cloud_upload,
//                                       size: 40, color: Colors.grey),
//                                   const SizedBox(height: 8),
//                                   Text("Click to upload or drag and drop"),
//                                   const SizedBox(height: 4),
//                                   Text(
//                                     "Select from the Gallery",
//                                     style: TextStyle(
//                                         color: Colors.blue,
//                                         decoration: TextDecoration.underline),
//                                   ),
//                                   const SizedBox(height: 4),
//                                   Text("Max file size is 200 MB",
//                                       style: TextStyle(
//                                           fontSize: 12, color: Colors.grey)),
//                                 ],
//                               ),
//                       ),
//                     ),
//                   ),
//
//                   const SizedBox(height: 16),
//
//                   Align(
//                     alignment: Alignment.centerLeft,
//                     child: Text("Select Tag:",
//                         style: TextStyle(fontWeight: FontWeight.bold)),
//                   ),
//                   const SizedBox(height: 8),
//
//                   DropdownButtonFormField<String>(
//                     value: null,
//                     items: tagOptions
//                         .map((tag) => DropdownMenuItem(
//                               value: tag,
//                               child: Text(tag),
//                             ))
//                         .toList(),
//                     onChanged: (value) {
//                       if (value != null && !selectedTags.contains(value)) {
//                         setModalState(() {
//                           selectedTags.add(value);
//                         });
//                       }
//                     },
//                     decoration: InputDecoration(
//                       border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12)),
//                       hintText: "Choose a tag",
//                     ),
//                   ),
//
//                   const SizedBox(height: 8),
//
//                   // Selected Tags
//                   Align(
//                     alignment: Alignment.centerLeft,
//                     child: Wrap(
//                       spacing: 8,
//                       children: selectedTags.map((tag) {
//                         return Chip(
//                           label: Text(tag),
//                           onDeleted: () {
//                             setModalState(() {
//                               selectedTags.remove(tag);
//                             });
//                           },
//                         );
//                       }).toList(),
//                     ),
//                   ),
//
//                   const SizedBox(height: 16),
//
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.end,
//                     children: [
//                       TextButton(
//                         onPressed: () => Navigator.pop(context),
//                         child: Text("Cancel"),
//                       ),
//                       ElevatedButton(
//                         onPressed: () {
//                           // Use selectedImage & selectedTags
//                           Navigator.pop(context);
//                         },
//                         child: Text("Submit"),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
//
//   // void addImage() {
//   //   showModalBottomSheet(
//   //     context: context,
//   //     isScrollControlled: true,
//   //     shape: RoundedRectangleBorder(
//   //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//   //     ),
//   //     builder: (context) => Padding(
//   //       padding: MediaQuery.of(context).viewInsets,
//   //       child: StatefulBuilder(builder: (context, setModalState) {
//   //         List<String> selectedTags = ['Chip', 'Chip', 'Chip', 'Chip'];
//   //         File? selectedImage;
//   //
//   //         return Padding(
//   //           padding: const EdgeInsets.all(16.0),
//   //           child: Column(
//   //             mainAxisSize: MainAxisSize.min,
//   //             children: [
//   //               Text("Upload", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//   //               const SizedBox(height: 16),
//   //
//   //               // Upload Box or Image Preview
//   //               DottedBorder(
//   //                 radius: Radius.circular(12),
//   //                 dashPattern: [6, 3],
//   //                 color: Colors.grey,
//   //                 child: InkWell(
//   //                   onTap: () async {
//   //                     final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
//   //                     if (image != null) {
//   //                       setModalState(() {
//   //                         selectedImage = File(image.path);
//   //                       });
//   //                     }
//   //                   },
//   //                   child: Container(
//   //                     width: double.infinity,
//   //                     height: 150,
//   //                     decoration: BoxDecoration(
//   //                       borderRadius: BorderRadius.circular(12),
//   //                     ),
//   //                     child: selectedImage != null
//   //                         ? ClipRRect(
//   //                       borderRadius: BorderRadius.circular(12),
//   //                       child: Image.file(
//   //                         selectedImage!,
//   //                         fit: BoxFit.cover,
//   //                         width: double.infinity,
//   //                       ),
//   //                     )
//   //                         : Column(
//   //                       mainAxisAlignment: MainAxisAlignment.center,
//   //                       children: [
//   //                         Icon(Icons.cloud_upload, size: 40, color: Colors.grey),
//   //                         const SizedBox(height: 8),
//   //                         Text("Click to upload or drag and drop"),
//   //                         const SizedBox(height: 4),
//   //                         Text(
//   //                           "Select from the Gallery",
//   //                           style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
//   //                         ),
//   //                         const SizedBox(height: 4),
//   //                         Text("Max file size is 200 MB", style: TextStyle(fontSize: 12, color: Colors.grey)),
//   //                       ],
//   //                     ),
//   //                   ),
//   //                 ),
//   //               ),
//   //
//   //               const SizedBox(height: 16),
//   //
//   //               Align(
//   //                 alignment: Alignment.centerLeft,
//   //                 child: Text("Add Tags:", style: TextStyle(fontWeight: FontWeight.bold)),
//   //               ),
//   //               const SizedBox(height: 8),
//   //
//   //               Wrap(
//   //                 spacing: 8,
//   //                 children: selectedTags.map((tag) {
//   //                   return Chip(
//   //                     label: Text(tag),
//   //                     onDeleted: () {
//   //                       setModalState(() {
//   //                         selectedTags.remove(tag);
//   //                       });
//   //                     },
//   //                   );
//   //                 }).toList(),
//   //               ),
//   //
//   //               const SizedBox(height: 16),
//   //
//   //               Row(
//   //                 mainAxisAlignment: MainAxisAlignment.end,
//   //                 children: [
//   //                   TextButton(
//   //                     onPressed: () => Navigator.pop(context),
//   //                     child: Text("Cancel"),
//   //                   ),
//   //                   ElevatedButton(
//   //                     onPressed: () {
//   //                       // Submit logic using `selectedImage`
//   //                       Navigator.pop(context);
//   //                     },
//   //                     child: Text("Submit"),
//   //                   ),
//   //                 ],
//   //               ),
//   //             ],
//   //           ),
//   //         );
//   //       }),
//   //     ),
//   //   );
//   // }
//
//   void deleteImage(int index) {
//     setState(() {
//       uploadedImages.removeAt(index);
//       widget.onImagesUpdated(uploadedImages); // Notify parent of changes
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     var typography = CustomTypography(context);
//     return Container(
//       // color: AppColors.primaryMain.withOpacity(0.16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           TextFormField(
//             decoration: InputDecoration(
//               isDense: true,
//               label: RichText(
//                 text: TextSpan(
//                   children: [
//                     TextSpan(
//                       text:
//                           "Monthly Rental Loss", // Label text, // Black color for "Name"
//                     ),
//                   ],
//                 ),
//               ),
//               hintText: LanguageService.getTranslated(
//                   context, "user_profile_user_management_name_placeholder"),
//               hintStyle: typography.Body2,
//               labelStyle: typography.Body2,
//               border: const OutlineInputBorder(),
//             ),
//             validator: (value) {
//               if (value == null ||
//                   value.isEmpty ||
//                   value.contains(RegExp(r'[0-9]'))) {
//                 return 'Name is required';
//               }
//               // You can add more specific email validation here if needed
//               return null;
//             },
//             controller: monthlyRentedController,
//           ),
//
//           SizedBox(height: 8),
//           // Input Field
//           TextFormField(
//             controller: valueTypeController,
//             decoration: InputDecoration(
//               isDense: true,
//               labelText: "Value type",
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//           ),
//           SizedBox(height: 8),
//           TextFormField(
//             controller: currencyController,
//             decoration: InputDecoration(
//               isDense: true,
//               label: RichText(
//                 text: TextSpan(
//                   children: [
//                     TextSpan(
//                       text: 'Currency', // Label text, // Black color for "Name"
//                     ),
//                   ],
//                 ),
//               ),
//               hintText: 'Currency',
//               hintStyle: typography.Body1,
//               labelStyle: typography.Body1,
//               border: const OutlineInputBorder(),
//             ),
//             validator: (value) {
//               if (value == null ||
//                   value.isEmpty ||
//                   value.contains(RegExp(r'[0-9]'))) {
//                 return 'currency is required';
//               }
//               // You can add more specific email validation here if needed
//               return null;
//             },
//           ),
//           SizedBox(height: 8),
//           // Input Field
//           _buildDateTimeField(
//             label: 'Select Start date',
//             hint: _startDate != null
//                 ? _formatDate(_startDate!)
//                 : 'DD/MM/YYYY HH:MM',
//             onIconPressed: () => _selectStartDate(context),
//           ),
//           const SizedBox(height: 16),
//           _buildDateTimeField(
//             label: 'Select End date',
//             hint:
//                 _endDate != null ? _formatDate(_endDate!) : 'DD/MM/YYYY HH:MM',
//             onIconPressed: () => _selectEndDate(context),
//           ),
//           const SizedBox(height: 16),
//           // Each item's color
//
//           DropdownButtonFormField<String>(
//             decoration: InputDecoration(
//               labelText: 'MinMaxThreshold',
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             value: selectedValue,
//             items: items.asMap().entries.map((entry) {
//               int index = entry.key;
//               String value = entry.value;
//
//               return DropdownMenuItem<String>(
//                 value: value,
//                 child: Row(
//                   children: [
//                     Icon(itemIcons[index], color: itemColors[index], size: 18),
//                     // Icon before text
//                     SizedBox(width: 8),
//                     Text(
//                       value,
//                       style: TextStyle(
//                           color: itemColors[index]), // Apply color to text too
//                     ),
//                     Divider(
//                       color: Colors.white,
//                     ),
//                   ],
//                 ),
//               );
//             }).toList(),
//             onChanged: (String? value) {
//               setState(() {
//                 selectedValue = value!;
//               });
//             },
//           ),
//
//           SizedBox(height: 10),
//
//           Row(
//             children: [
//               CustomButton(
//                 onPressed: () async {
//                   // if (_accountEditNameController.text.isEmpty) {
//                   //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//                   //       content: Text(
//                   //         LanguageService.getTranslated(context, "account_list_app_rename_account_empty_text_error"),
//                   //         style: typography.Body1,
//                   //       )));
//                   //   return;
//                   // }
//                   // // Update account details
//                   // await accountListProvider.renameAccount(
//                   //     context,
//                   //     accountListProvider.accountList[index].accountId!,
//                   //     _accountEditNameController.text);
//                   // Navigator.pop(context);
//                 },
//                 child: Text(
//                   'Submit',
//                   style: typography.Body1.copyWith(color: AppColors.black),
//                 ),
//                 type: ButtonType.elevated,
//               ),
//               SizedBox(width: 8),
//               Column(
//                 mainAxisAlignment: MainAxisAlignment.start,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text("Edited by: John Doe"),
//                   Text("03/03/2025 11:13:22")
//                 ],
//               )
//             ],
//           ),
//
//           SizedBox(height: 16),
//           // Image Grid
//           GridView.builder(
//             shrinkWrap: true,
//             physics: NeverScrollableScrollPhysics(),
//             itemCount: uploadedImages.length + 1,
//             // Extra for the add button
//             gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 3,
//               crossAxisSpacing: 8,
//               mainAxisSpacing: 8,
//             ),
//             itemBuilder: (context, index) {
//               if (index < uploadedImages.length) {
//                 return Stack(
//                   children: [
//                     Container(
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(8),
//                         image: DecorationImage(
//                           image: uploadedImages[index],
//                           fit: BoxFit.cover,
//                         ),
//                       ),
//                     ),
//                     Positioned(
//                       top: 4,
//                       right: 4,
//                       child: IconButton(
//                         onPressed: () => deleteImage(index),
//                         icon: Icon(Icons.close, color: Colors.red),
//                         iconSize: 20,
//                         constraints: BoxConstraints(),
//                         padding: EdgeInsets.zero,
//                       ),
//                     ),
//                   ],
//                 );
//               } else {
//                 // Add Button
//                 return GestureDetector(
//                   onTap: addImage,
//                   child: Container(
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(8),
//                       color: Colors.grey.shade200,
//                     ),
//                     child: Icon(Icons.add, size: 40, color: Colors.blue),
//                   ),
//                 );
//               }
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildDateTimeField({
//     required String label,
//     required String hint,
//     required VoidCallback onIconPressed,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         TextFormField(
//           readOnly: true,
//           decoration: InputDecoration(
//             hintText: hint,
//             suffixIcon: IconButton(
//               icon: const Icon(Icons.calendar_today, color: Colors.grey),
//               onPressed: onIconPressed,
//             ),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   String _formatDate(DateTime date) {
//     final format = DateFormat('dd/MM/yyyy hh:mm a');
//     return format.format(date);
//   }
//
//   Future<void> _selectStartDate(BuildContext context) async {
//     DateTime? selectedDate = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime.now(),
//       lastDate: DateTime(2100),
//     );
//
//     if (selectedDate != null) {
//       TimeOfDay? selectedTime = await showTimePicker(
//         context: context,
//         initialTime: TimeOfDay.now(),
//       );
//
//       if (selectedTime != null) {
//         DateTime selectedDateTime = DateTime(
//           selectedDate.year,
//           selectedDate.month,
//           selectedDate.day,
//           selectedTime.hour,
//           selectedTime.minute,
//         );
//         setState(() {
//           _startDate = selectedDateTime;
//         });
//       }
//     }
//   }
//
//   Future<void> _selectEndDate(BuildContext context) async {
//     if (_startDate == null) return;
//
//     DateTime? selectedDate = await showDatePicker(
//       context: context,
//       initialDate: _startDate!,
//       firstDate: _startDate!,
//       lastDate: DateTime(2100),
//     );
//
//     if (selectedDate != null) {
//       TimeOfDay? selectedTime = await showTimePicker(
//         context: context,
//         initialTime: TimeOfDay.now(),
//       );
//
//       if (selectedTime != null) {
//         DateTime selectedDateTime = DateTime(
//           selectedDate.year,
//           selectedDate.month,
//           selectedDate.day,
//           selectedTime.hour,
//           selectedTime.minute,
//         );
//         setState(() {
//           _endDate = selectedDateTime;
//         });
//       }
//     }
//   }
// }
