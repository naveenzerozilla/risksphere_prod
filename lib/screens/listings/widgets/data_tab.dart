import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:green/design_system/repo/color_pallets_screen.dart';
import 'package:provider/provider.dart';
import '../../../design_system/primitives/custom_typography.dart';
import '../../../design_system/primitives/utilities/custom_spacing.dart';
import '../../../design_system/primitives/app_colors.dart';
import '../../../providers/configuration_provider.dart';

class DataTab extends StatefulWidget {
  final String? accountId;
  final String? subaccountId;

  const DataTab({
    Key? key,
    this.accountId,
    this.subaccountId,
  }) : super(key: key);

  @override
  _DataTabState createState() => _DataTabState();
}

class _DataTabState extends State<DataTab> {
  List<String> selectedServices = [];
  List<int> selectedStars = [];
  List<dynamic> vendorList = [];
  List<dynamic> dataElements = [
    'Occupancy Type',
    'Construction Type',
    'Number of Lifts',
    'Year Built',
  ];
  String? expandedElement;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);
    return Consumer<ConfigurationProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        return Container(
          padding: const EdgeInsets.only(right: 15.0, left: 15.0, top: 10),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  margin: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                        color: Colors.grey,
                        width: 0.5), // White border for the card
                  ),
                  elevation: 4,
                  child: Container(
                    padding: const EdgeInsets.all(0.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title with bottom border
                        SizedBox(height: 5),
                        Container(
                          padding:
                              EdgeInsets.only(left: 15, top: 15, right: 15),
                          // decoration: BoxDecoration(
                          //   border: Border(
                          //     bottom: BorderSide(
                          //         color: Colors.white,
                          //         width: 1), // White border below title
                          //   ),
                          // ),
                          child: Text(
                            'Critical Impact Data Elements',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade200,
                            ),
                          ),
                        ),
                        Divider(),

                        // Dynamic List with Expandable Container
                        ...dataElements.map((element) {
                          return Column(
                            children: [
                              // Each ListTile with white border
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    // Toggle expansion for the clicked element
                                    expandedElement =
                                        (expandedElement == element)
                                            ? null
                                            : element;
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 2, horizontal: 20),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                          color: Colors.grey,
                                          width:
                                              0.5), // White border for each list item
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Title with border
                                      Expanded(
                                        child: Container(
                                          child: Text(
                                            element,
                                            style: TextStyle(
                                                color: Colors.redAccent,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Divider(
                                        color: Colors.white,
                                      ),

                                      // Icon with border
                                      expandedElement != element
                                          ? Container(
                                              padding: EdgeInsets.all(8),
                                              child: Icon(
                                                Icons
                                                    .add_circle_outline_outlined,
                                                color: Colors.white60,
                                                size: 35,
                                              ),
                                            )
                                          : Container(
                                              padding: EdgeInsets.all(8),
                                              child: Icon(
                                                Icons.arrow_circle_down_rounded,
                                                color: Colors.white60,
                                                size: 35,
                                              ),
                                            ),
                                    ],
                                  ),
                                ),
                              ),
                              // Expandable content
                              if (expandedElement == element)
                                Container(
                                  padding: EdgeInsets.all(10),
                                  // color: Colors.grey.shade200, // Background color for the expanded section
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: ImageUploadCard(
                                          title: "Number of Floors",
                                          onImagesUpdated: (images) {
                                            print(
                                                "Uploaded Images Count: ${images.length}");
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Card(
                  margin: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                        color: Colors.grey,
                        width: 0.5), // White border for the card
                  ),
                  elevation: 4,
                  child: Container(
                    padding: const EdgeInsets.all(0.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title with bottom border
                        Container(
                          padding:
                              EdgeInsets.only(left: 20, top: 15, bottom: 10),
                          // padding: EdgeInsets.symmetric(vertical: 8),
                          // decoration: BoxDecoration(
                          //   border: Border(
                          //     bottom: BorderSide(
                          //         color: Colors.white,
                          //         width: 1), // White border below title
                          //   ),
                          // ),
                          child: Text(
                            'Medium Impact Data Elements',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade200,
                            ),
                          ),
                        ),
                        Divider(),

                        // Dynamic List with Expandable Container
                        ...dataElements.map((element) {
                          return Column(
                            children: [
                              // Each ListTile with white border
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    // Toggle expansion for the clicked element
                                    expandedElement =
                                        (expandedElement == element)
                                            ? null
                                            : element;
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 5, horizontal: 20),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                          color: Colors.grey,
                                          width:
                                              0.5), // White border for each list item
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Title with border
                                      Expanded(
                                        child: Container(
                                          child: Text(
                                            element,
                                            style: TextStyle(
                                                color: Colors.purple,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Divider(
                                        color: Colors.white,
                                      ),

                                      // Icon with border
                                      expandedElement != element
                                          ? Container(
                                              padding: EdgeInsets.all(8),
                                              child: Icon(
                                                Icons
                                                    .add_circle_outline_outlined,
                                                color: Colors.white60,
                                                size: 35,
                                              ),
                                            )
                                          : Container(
                                              padding: EdgeInsets.all(8),
                                              child: Icon(
                                                Icons.arrow_circle_down_rounded,
                                                color: Colors.white60,
                                                size: 35,
                                              ),
                                            ),
                                    ],
                                  ),
                                ),
                              ),
                              // Expandable content
                              if (expandedElement == element)
                                Container(
                                  padding: EdgeInsets.all(10),
                                  // color: Colors.grey.shade200, // Background color for the expanded section
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: ImageUploadCard(
                                          title: "Number of Floors",
                                          onImagesUpdated: (images) {
                                            print(
                                                "Uploaded Images Count: ${images.length}");
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Card(
                  margin: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                        color: Colors.grey,
                        width: 0.5), // White border for the card
                  ),
                  elevation: 4,
                  child: Container(
                    padding: const EdgeInsets.all(0.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title with bottom border
                        Container(
                          padding:
                              EdgeInsets.only(left: 20, top: 15, bottom: 10),
                          // decoration: BoxDecoration(
                          //   border: Border(
                          //     bottom: BorderSide(
                          //         color: Colors.grey,
                          //         width: 0), // White border below title
                          //   ),
                          // ),
                          child: Text(
                            'Low Impact Data Elements',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade200,
                            ),
                          ),
                        ),
                        Divider(),

                        // Dynamic List with Expandable Container
                        ...dataElements.map((element) {
                          return Column(
                            children: [
                              // Each ListTile with white border
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    // Toggle expansion for the clicked element
                                    expandedElement =
                                        (expandedElement == element)
                                            ? null
                                            : element;
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 5, horizontal: 20),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                          color: Colors.grey,
                                          width:
                                              0.5), // White border for each list item
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Title with border
                                      Expanded(
                                        child: Container(
                                          child: Text(
                                            element,
                                            style: TextStyle(
                                                color: Colors.purple,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Divider(
                                        color: Colors.white,
                                      ),

                                      // Icon with border
                                      expandedElement != element
                                          ? Container(
                                              padding: EdgeInsets.all(8),
                                              child: Icon(
                                                Icons
                                                    .add_circle_outline_outlined,
                                                color: Colors.white60,
                                                size: 35,
                                              ),
                                            )
                                          : Container(
                                              padding: EdgeInsets.all(8),
                                              child: Icon(
                                                Icons.arrow_circle_down_rounded,
                                                color: Colors.white60,
                                                size: 35,
                                              ),
                                            ),
                                    ],
                                  ),
                                ),
                              ),
                              // Expandable content
                              if (expandedElement == element)
                                Container(
                                  padding: EdgeInsets.all(10),
                                  // color: Colors.grey.shade200, // Background color for the expanded section
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: ImageUploadCard(
                                          title: "Number of Floors",
                                          onImagesUpdated: (images) {
                                            print(
                                                "Uploaded Images Count: ${images.length}");
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ImageUploadCard extends StatefulWidget {
  final String title;
  final Function(List<ImageProvider>) onImagesUpdated;

  const ImageUploadCard({
    Key? key,
    required this.title,
    required this.onImagesUpdated,
  }) : super(key: key);

  @override
  _ImageUploadCardState createState() => _ImageUploadCardState();
}

class _ImageUploadCardState extends State<ImageUploadCard> {
  List<ImageProvider> uploadedImages = [];

  void addImage() {
    // Example: Add a placeholder image (Replace with actual image picker logic)
    setState(() {
      uploadedImages.add(AssetImage('assets/placeholder_image.png'));
      widget.onImagesUpdated(uploadedImages); // Notify parent of changes
    });
  }

  void deleteImage(int index) {
    setState(() {
      uploadedImages.removeAt(index);
      widget.onImagesUpdated(uploadedImages); // Notify parent of changes
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // Help icon action
                  },
                  icon: Icon(Icons.help_outline, color: Colors.blue),
                ),
              ],
            ),
            SizedBox(height: 8),

            // Input Field
            TextField(
              decoration: InputDecoration(
                labelText: "Enter number of floors",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 16),

            // Image Grid
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: uploadedImages.length + 1,
              // Extra for the add button
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                if (index < uploadedImages.length) {
                  return Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: uploadedImages[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton(
                          onPressed: () => deleteImage(index),
                          icon: Icon(Icons.close, color: Colors.red),
                          iconSize: 20,
                          constraints: BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  );
                } else {
                  // Add Button
                  return GestureDetector(
                    onTap: addImage,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade200,
                      ),
                      child: Icon(Icons.add, size: 40, color: Colors.blue),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
