// impact_data_card.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:url_launcher/url_launcher.dart';
import '../design_system/primitives/app_colors.dart';
import '../models/DataParameterModel.dart';
import '../screens/listings/widgets/data_tab.dart';

class ImpactDataCard extends StatefulWidget {
  final String? subAccountId;
  final String title;
  final Color titleColor;
  final List<ImpactDataElement> dataElements;

  const ImpactDataCard({
    Key? key,
    this.subAccountId,
    required this.title,
    required this.titleColor,
    required this.dataElements,
  }) : super(key: key);

  @override
  _ImpactDataCardState createState() => _ImpactDataCardState();
}

class _ImpactDataCardState extends State<ImpactDataCard> {
  String? expandedElementName;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey, width: 0.5),
      ),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(left: 16, top: 15, bottom: 10),
            child: Text(
              widget.title == "high"
                  ? "High Impact Data Elements"
                  : widget.title == "medium"
                      ? "Medium Impact Data Element"
                      : widget.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),

          // Expandable List
          ...widget.dataElements.asMap().entries.map((entry) {
            int index = entry.key;
            ImpactDataElement element = entry.value;
            final isExpanded = expandedElementName == element.name;

            return Column(
              children: [
                if (index == 0) Divider(height: 1, color: Colors.grey),
                Container(
                  margin: isExpanded ? EdgeInsets.all(8) : EdgeInsets.all(0),
                  decoration: BoxDecoration(
                    color: isExpanded
                        ? AppColors.primaryMain.withOpacity(0.16)
                        : Colors.transparent,
                    border: Border.all(
                        color: isExpanded ? Colors.blue : Colors.transparent),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            expandedElementName =
                                isExpanded ? null : element.name;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom:
                                  BorderSide(color: Colors.grey, width: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (isExpanded) ...[
                                Icon(
                                  Icons.star,
                                  color: Colors.orangeAccent,
                                  size: 25,
                                ),
                                SizedBox(width: 5),
                              ],
                              Expanded(
                                child: Text(
                                  element.name,
                                  style: TextStyle(
                                    color: isExpanded
                                        ? Colors.lightBlueAccent
                                        : widget.titleColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (isExpanded) ...[
                                InkWell(
                                  onTap: () {
                                    showVersionHistoryBottomSheet(
                                        context,
                                        element.result,
                                        element.user,
                                        element.result.version!);
                                  },
                                  child: Icon(
                                    Icons.history,
                                    color: Colors.white60,
                                    size: 25,
                                  ),
                                ),
                                SizedBox(width: 8),
                                element.result.helpDocumantion!.images!
                                            .isEmpty ||
                                        element.result.helpDocumantion!.docs!
                                            .isEmpty
                                    ? Container()
                                    : InkWell(
                                        onTap: () async {
                                          final images = element.result
                                                  .helpDocumantion?.images ??
                                              [];
                                          final docs = element.result
                                                  .helpDocumantion?.docs ??
                                              [];

                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title:
                                                    Text('Help Documentation'),
                                                content: SingleChildScrollView(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      if (images
                                                          .isNotEmpty) ...[
                                                        Text("Images",
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold)),
                                                        SizedBox(height: 8),
                                                        for (var image
                                                            in images)
                                                          FileRow(
                                                              fileUrl: image,
                                                              isImage: true),
                                                        Divider(),
                                                      ],
                                                      if (docs.isNotEmpty) ...[
                                                        Text("Documents",
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold)),
                                                        SizedBox(height: 8),
                                                        for (var doc in docs)
                                                          FileRow(
                                                              fileUrl: doc,
                                                              isImage: false),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    child: Text("Close"),
                                                    onPressed: () =>
                                                        Navigator.of(context)
                                                            .pop(),
                                                  )
                                                ],
                                              );
                                            },
                                          );
                                        },
                                        child: Icon(
                                          Icons.edit_document,
                                          color: Colors.white60,
                                          size: 25,
                                        ),
                                      ),
                                SizedBox(width: 10),
                              ],
                              Container(
                                height: 50,
                                width: 1,
                                color: Colors.grey,
                              ),
                              SizedBox(width: 10),
                              Icon(
                                isExpanded
                                    ? Icons.remove_circle_outline
                                    : Icons.add_circle_outline_outlined,
                                color: Colors.white60,
                                size: 25,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isExpanded)
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          child: ImageUploadCard(
                            subAccountId: widget.subAccountId!,
                            title: element.name,
                            user: element.user,
                            result: element.result,
                            parametertype: element.parameterType,
                            onImagesUpdated: (images) {
                              print("Uploaded Images Count: ${images.length}");
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
    );
  }

  void showVersionHistoryBottomSheet(
      BuildContext context, Result result, User user, Version version) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.black87,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text("History",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),

              SizedBox(height: 5),
              Row(
                children: [
                  Text(result.name.toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Color.fromRGBO(144, 202, 249, 1),
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: AssetImage('assets/user.jpg'),
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(user.name.toString(),
                              style: TextStyle(
                                  color: Colors.purpleAccent, fontSize: 16)),
                          Text(' Created on ${"03/03/2025"}',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 14)),
                        ],
                      ),
                      Text('Last updated on 03/10/2025',
                          style: TextStyle(
                              color: Color.fromRGBO(102, 187, 106, 1),
                              fontSize: 14)),
                    ],
                  ),
                ],
              ),
              // Divider(color: Colors.white30),
              Divider(),
              SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Version Updates',
                    style: TextStyle(color: Colors.white, fontSize: 14)),
              ),
              SizedBox(height: 12),

              Container(
                height: MediaQuery.of(context).size.height / 2.5,
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: ScrollPhysics(),
                  itemCount: result.history?.length ?? 0,
                  itemBuilder: (context, index) {
                    final item = result.history![index];
                    String formattedDate = '--';
                    if (item.updatedAt?.iSeconds != null) {
                      final dateTime = DateTime.fromMillisecondsSinceEpoch(
                          item.updatedAt!.iSeconds! * 1000);
                      formattedDate =
                          DateFormat('dd/MM/yyyy HH:mm:ss').format(dateTime);
                    }

                    return TimelineTile(
                      alignment: TimelineAlign.manual,
                      lineXY: 0.1,
                      isFirst: index == 0,
                      isLast: index == result.history!.length - 1,
                      // ✅ FIXED HERE
                      indicatorStyle: IndicatorStyle(
                        width: 14,
                        color: Colors.blue,
                        indicatorXY: 0.2,
                        padding: EdgeInsets.all(6),
                      ),
                      beforeLineStyle: LineStyle(
                        color: Colors.grey,
                        thickness: 0.3,
                      ),
                      afterLineStyle: LineStyle(
                        color: Colors.grey,
                        thickness: 0.3,
                      ),
                      endChild: Container(
                        margin: EdgeInsets.only(left: 16, bottom: 16),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formattedDate,
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                            SizedBox(height: 6),
                            if (item.value != null)
                              Text("Added value: " + item.value!,
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 14)),
                            if (item.paramType != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  "Value Type: " + item.paramType!,
                                  style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 13),
                                ),
                              ),
                            SizedBox(height: 4),
                            Divider(),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.blueGrey,
                                  backgroundImage: (item.reference != null &&
                                          item.reference!.isNotEmpty &&
                                          item.reference![0].url.isNotEmpty &&
                                          item.reference![0].url[0].isNotEmpty)
                                      ? NetworkImage(item.reference![0].url[0])
                                      : null,
                                  child: (item.reference == null ||
                                          item.reference!.isEmpty ||
                                          item.reference![0].url.isEmpty ||
                                          item.reference![0].url[0].isEmpty)
                                      ? Text(
                                          (item.userName?.isNotEmpty ?? false)
                                              ? item.userName![0].toUpperCase()
                                              : "?",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12),
                                        )
                                      : null,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  item.userName ?? "Unknown",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 13),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _versionTile(String version, String date, String author, String badge,
      Color badgeColor) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.circle, color: Colors.blue),
          // Container(
          //   width: 2,
          //   height: 30,
          //   color: Colors.white,
          // )
        ],
      ),
      title: Row(
        children: [
          Text(version, style: TextStyle(color: Colors.blueAccent)),
          SizedBox(width: 8),
          Text(date, style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
      subtitle: Text(author, style: TextStyle(color: Colors.white54)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: badgeColor,
            child: Text(badge,
                style: TextStyle(fontSize: 12, color: Colors.white)),
          ),
          SizedBox(width: 8),
          Icon(Icons.lock_open_outlined, color: Colors.orange, size: 18),
        ],
      ),
    );
  }
}

class FileRow extends StatefulWidget {
  final String fileUrl;
  final bool isImage;

  const FileRow({super.key, required this.fileUrl, this.isImage = false});

  @override
  State<FileRow> createState() => _FileRowState();
}

class _FileRowState extends State<FileRow> {
  double _downloadProgress = 0;
  bool _isDownloading = false;
  bool _isDownloaded = false;
  String? _downloadedPath;

  /// Extracts file name from URL, removes query params
  String get _fileName {
    final uri = Uri.parse(widget.fileUrl);
    return uri.pathSegments.last; // Removes query parameters
  }

  String get _fileExtension => _fileName.split('.').last.toUpperCase();

  bool get _isPDF => _fileExtension == 'PDF';

  bool get _isImage =>
      widget.isImage ||
      _fileExtension == 'PNG' ||
      _fileExtension == 'JPG' ||
      _fileExtension == 'JPEG';

  Future<void> _downloadFile() async {
    final permission = await Permission.storage.request();
    if (!permission.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Storage permission required")),
      );
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
    });

    try {
      // Use the documents directory for permanent storage
      final appDir = await getApplicationDocumentsDirectory();
      final savePath = '${appDir.path}/downloads/$_fileName';

      final file = File(savePath);

      if (await file.exists()) {
        await file.delete(); // 🔥 Delete if already exists
      }

      // Download the file
      await Dio().download(
        widget.fileUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() => _downloadProgress = received / total);
          }
        },
      );

      setState(() {
        _downloadedPath = savePath;
        _isDownloaded = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Downloaded to $savePath")),
      );
    } catch (e, stackTrace) {
      print("❌ Download Error: $e");
      print("📌 StackTrace: $stackTrace");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Download failed: $e")),
      );
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isImage
                    ? Icons.image
                    : _isPDF
                        ? Icons.picture_as_pdf
                        : Icons.insert_drive_file,
                color: Colors.blue,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _fileName,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              if (_isDownloading)
                Text(
                  "${(_downloadProgress * 100).toStringAsFixed(0)}%",
                  style: TextStyle(fontWeight: FontWeight.bold),
                )
              else if (_isDownloaded)
                Icon(Icons.check_circle, color: Colors.green)
              else
                IconButton(
                  icon: Icon(Icons.download),
                  onPressed: _downloadFile,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
