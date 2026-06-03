// impact_data_card.dart
import 'dart:convert';
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
import '../service/language_service.dart';

class ImpactDataCard extends StatefulWidget {
  final String? accountId;
  final String? subAccountId;
  final String? locationId;
  final String? sovId;
  final String? campusId;
  final String title;
  final Color titleColor;
  final List<ImpactDataElement> dataElements;
  final String? selectedParameterList;
  final Future<void> Function()? onRefresh;
  final bool? showHeader;
  final String? expandElementName;
  final VoidCallback? onExpanded;

  const ImpactDataCard({
    Key? key,
    this.accountId,
    this.subAccountId,
    this.locationId,
    this.sovId,
    this.campusId,
    required this.title,
    required this.titleColor,
    required this.dataElements,
    required this.selectedParameterList,
    this.onRefresh,
    this.showHeader,
    this.expandElementName,
    this.onExpanded,
  }) : super(key: key);

  @override
  _ImpactDataCardState createState() => _ImpactDataCardState();
}

class _ImpactDataCardState extends State<ImpactDataCard> {
  String? expandedElementName;

  /// 0 = collapsed, 1 = HazardHub sync only, 2 = sync + manual value fields
  final Map<String, int> _hazardHubExpandLevel = {};

  @override
  void didUpdateWidget(covariant ImpactDataCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // case: same element selected again → must force update
    if (widget.expandElementName != null) {
      // reset first so flutter detects change every time
      if (expandedElementName == widget.expandElementName) {
        expandedElementName = null;
      }

      setState(() {
        // expandedElementName = widget.expandElementName!;
        final match = widget.dataElements
            .where((e) => e.name == widget.expandElementName)
            .toList();
        if (match.isNotEmpty) {
          final r = match.first.result;
          final hasTag = r.tags?.contains("hazard_hub") ?? false;
          final hasItems = r.linkVendor?.hazardHub?.items?.isNotEmpty ?? false;
          if (hasTag && hasItems) {
            _hazardHubExpandLevel[widget.expandElementName!] = 1;
            // expandedElementName = widget.expandElementName!;
          }
          // if (hasTag && hasItems) {
          //   _hazardHubExpandLevel[widget.expandElementName!] = 1;
          // }
        }
      });

      // now call scroll after layout
      // if (widget.onExpanded != null) {
      //   WidgetsBinding.instance.addPostFrameCallback((_) {
      //     widget.onExpanded!();
      //   });
      // }
    }
  }

  bool isNullOrEmpty(dynamic value) {
    if (value == null) return true;
    if (value is String && value.trim().isEmpty) return true;
    if (value is List && value.isEmpty) return true;
    if (value is Map && value.isEmpty) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(4),
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        side: BorderSide(color: Colors.grey, width: 0.5),
      ),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...widget.dataElements.asMap().entries.map((entry) {
            int index = entry.key;
            ImpactDataElement element = entry.value;
            final hasHazardHubTag =
                element.result.tags?.contains("hazard_hub") ?? false;
            final hasHazardHubItems =
                element.result.linkVendor?.hazardHub?.items?.isNotEmpty ??
                    false;
            // Two-step expand when synced from HazardHub (tag present).
            final hazardHubExpandFlow = hasHazardHubItems;
            final expandLevel = _hazardHubExpandLevel[element.name] ?? 1;
            final isExpanded = hazardHubExpandFlow
                ? expandLevel == 2
                : expandedElementName == element.name;
            // final isExpanded = hazardHubExpandFlow
            //     ? true
            //     : expandedElementName == element.name;

            final showManualValueFields =
                hazardHubExpandFlow && expandLevel == 2;
            // final isExpanded = hazardHubExpandFlow
            //     ? expandLevel >= 1
            //     : expandedElementName == element.name;
            //
            // final showManualValueFields =
            //     hazardHubExpandFlow && expandLevel == 2;
            // final isExpanded = hazardHubExpandFlow
            //     ? expandLevel > 0
            //     : expandedElementName == element.name;
            // final showManualValueFields =
            //     hazardHubExpandFlow && expandLevel >= 2;
            final references = element.parameterValue?.reference;
            final rawValue = element.parameterValue?.value;

            return Column(
              children: [
                if (index == 0) Divider(height: 0, color: Colors.grey),
                Container(
                  margin: isExpanded ? EdgeInsets.all(8) : EdgeInsets.all(0),
                  decoration: BoxDecoration(
                    // color: isExpanded
                    //     ? AppColors.primaryMain.withOpacity(0.16)
                    //     : Colors.transparent,
                    border: Border.all(
                        color: isExpanded ? Colors.blue : Colors.transparent),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (hazardHubExpandFlow) {
                              final level =
                                  _hazardHubExpandLevel[element.name] ?? 1;

                              if (level == 1) {
                                // Show value fields
                                _hazardHubExpandLevel[element.name] = 2;
                              } else {
                                // Hide value fields
                                _hazardHubExpandLevel[element.name] = 1;
                              }
                            } else {
                              expandedElementName =
                                  isExpanded ? null : element.name;

                              _hazardHubExpandLevel.remove(element.name);
                            }
                          });

                          if (!isExpanded && widget.onExpanded != null) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              widget.onExpanded!();
                            });
                          }
                        },
                        // onTap: () {
                        //   setState(() {
                        //     if (hazardHubExpandFlow) {
                        //       // Default state = sync card visible
                        //       final level =
                        //           _hazardHubExpandLevel[element.name] ?? 1;
                        //
                        //       if (level == 1) {
                        //         // Show value fields
                        //         _hazardHubExpandLevel[element.name] = 2;
                        //         expandedElementName = element.name;
                        //       } else {
                        //         // Back to sync-only card
                        //         _hazardHubExpandLevel[element.name] = 1;
                        //         expandedElementName = element.name;
                        //       }
                        //     } else {
                        //       // Normal expand/collapse
                        //       expandedElementName =
                        //           isExpanded ? null : element.name;
                        //
                        //       _hazardHubExpandLevel.remove(element.name);
                        //     }
                        //   });
                        //
                        //   if (!isExpanded && widget.onExpanded != null) {
                        //     WidgetsBinding.instance.addPostFrameCallback((_) {
                        //       widget.onExpanded!();
                        //     });
                        //   }
                        // },
                        // onTap: () {
                        //   setState(() {
                        //     if (hazardHubExpandFlow) {
                        //       final level =
                        //           _hazardHubExpandLevel[element.name] ?? 0;
                        //       if (level == 0) {
                        //         _hazardHubExpandLevel[element.name] = 1;
                        //         expandedElementName = element.name;
                        //       } else if (level == 1) {
                        //         _hazardHubExpandLevel[element.name] = 2;
                        //       } else {
                        //         _hazardHubExpandLevel[element.name] = 0;
                        //         expandedElementName = null;
                        //       }
                        //     } else {
                        //       expandedElementName =
                        //           isExpanded ? null : element.name;
                        //       _hazardHubExpandLevel.remove(element.name);
                        //     }
                        //   });
                        //
                        //   if (!isExpanded && widget.onExpanded != null) {
                        //     WidgetsBinding.instance.addPostFrameCallback((_) {
                        //       widget.onExpanded!();
                        //     });
                        //   }
                        // },

                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 3),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom:
                                  BorderSide(color: Colors.grey, width: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            // crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  element.name,
                                  style: TextStyle(
                                    color: isParameterEmpty(rawValue)
                                        ? Colors.red
                                        : const Color(0xFF66BB6A),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),

                              (isParameterEmpty(element.parameterValue?.value))
                                  ? Row(
                                      children: [
                                        if (!isExpanded) ...[
                                          ConstrainedBox(
                                            constraints: const BoxConstraints(
                                                maxWidth: 100, maxHeight: 40),
                                            child: Builder(
                                              builder: (context) {
                                                final references = element
                                                        .parameterValue
                                                        ?.reference ??
                                                    [];

                                                final int fileCount = references
                                                    .expand(
                                                        (ref) => ref.url ?? [])
                                                    .where((u) =>
                                                        u != null &&
                                                        u
                                                            .toString()
                                                            .trim()
                                                            .isNotEmpty)
                                                    .length;

                                                final bool hasFiles =
                                                    fileCount > 0;

                                                return TextFormField(
                                                  textAlign: TextAlign.center,
                                                  readOnly: true,
                                                  initialValue:
                                                      hasFiles ? "" : "---",
                                                  onTap: () {
                                                    setState(() {
                                                      expandedElementName =
                                                          isExpanded
                                                              ? null
                                                              : element.name;
                                                    });
                                                  },
                                                  decoration: InputDecoration(
                                                    filled: true,
                                                    fillColor:
                                                        const Color(0xFF2B0000),
                                                    isDense: true,
                                                    prefixIcon: hasFiles
                                                        ? Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        6),
                                                            child: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                const Icon(
                                                                  Icons
                                                                      .description,
                                                                  size: 18,
                                                                  color: Color(
                                                                      0xFFFF6666),
                                                                ),
                                                                const SizedBox(
                                                                    width: 4),
                                                                Text(
                                                                  "($fileCount)",
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize:
                                                                        13,
                                                                    color: Color(
                                                                        0xFFFF6666),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          )
                                                        : null,
                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      borderSide:
                                                          const BorderSide(
                                                        color:
                                                            Color(0xFFB00000),
                                                        width: 0.6,
                                                      ),
                                                    ),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                      borderSide:
                                                          const BorderSide(
                                                        color:
                                                            Color(0xFFFF3333),
                                                        width: 0.6,
                                                      ),
                                                    ),
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Color(0xFFFF9999),
                                                    letterSpacing: 1.0,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                        PopupMenuButton<String>(
                                          icon: Icon(
                                            Icons.more_vert_outlined,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          onSelected: (value) {
                                            if (value == 'history') {
                                              showVersionHistoryBottomSheet(
                                                context,
                                                element.result,
                                                element.user,
                                                element.result.version!,
                                              );
                                            } else if (value == 'help') {
                                              _showHelpDialog(context, element);
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            PopupMenuItem(
                                              value: 'history',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.history, size: 20),
                                                  SizedBox(width: 10),
                                                  Text(
                                                    LanguageService
                                                        .getTranslated(
                                                            context, "history"),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'help',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit_document,
                                                      size: 20),
                                                  SizedBox(width: 10),
                                                  Text(
                                                    LanguageService
                                                        .getTranslated(context,
                                                            "supporting_docs"),
                                                  )
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        if (!isExpanded) ...[
                                          ConstrainedBox(
                                            constraints: BoxConstraints(
                                                maxWidth: 100, maxHeight: 40),
                                            child: TextFormField(
                                              initialValue: '',
                                              // (element
                                              //                 .parameterValue
                                              //                 ?.reference ==
                                              //             null ||
                                              //         element.parameterValue!
                                              //             .reference!.isEmpty)
                                              //     ? element
                                              //         .parameterValue.paramType
                                              //     : '',
                                              readOnly: true,
                                              onTap: () {
                                                setState(() {
                                                  expandedElementName =
                                                      isExpanded
                                                          ? null
                                                          : element.name;
                                                });
                                              },
                                              decoration: InputDecoration(
                                                isDense: true,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                  vertical: 8,
                                                  horizontal: 10,
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                ),
                                                prefixIcon: Builder(
                                                  builder: (context) {
                                                    final rawValue = element
                                                        .parameterValue?.value;

                                                    String? displayValue;

                                                    try {
                                                      if (rawValue != null &&
                                                          rawValue
                                                              .toString()
                                                              .trim()
                                                              .isNotEmpty) {
                                                        dynamic decoded =
                                                            rawValue;

                                                        // Decode if JSON string
                                                        if (decoded is String &&
                                                            decoded
                                                                .trim()
                                                                .startsWith(
                                                                    "{") &&
                                                            decoded
                                                                .trim()
                                                                .endsWith(
                                                                    "}")) {
                                                          decoded = jsonDecode(
                                                              decoded);
                                                        }

                                                        // Handle nested {"value":"{...}"}
                                                        if (decoded is Map &&
                                                            decoded["value"]
                                                                is String &&
                                                            decoded["value"]
                                                                .toString()
                                                                .trim()
                                                                .startsWith(
                                                                    "{")) {
                                                          decoded["value"] =
                                                              jsonDecode(
                                                                  decoded[
                                                                      "value"]);
                                                        }

                                                        // Handle {"value":{...}}
                                                        if (decoded is Map &&
                                                            decoded["value"]
                                                                is Map) {
                                                          displayValue =
                                                              decoded["value"]
                                                                      ["value"]
                                                                  ?.toString();
                                                        }
                                                        // Handle {"value":12,...}
                                                        else if (decoded
                                                                is Map &&
                                                            decoded.containsKey(
                                                                "value")) {
                                                          displayValue =
                                                              decoded["value"]
                                                                  ?.toString();
                                                        }
                                                      }
                                                    } catch (e) {
                                                      displayValue =
                                                          rawValue?.toString();
                                                    }

// 🔥 Show only actual numeric value
                                                    if (displayValue != null &&
                                                        displayValue
                                                            .trim()
                                                            .isNotEmpty &&
                                                        displayValue.trim() !=
                                                            "null") {
                                                      return Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(6),
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        child: Text(
                                                          displayValue,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      );
                                                    }
                                                    final references = element
                                                        .parameterValue
                                                        ?.reference;

                                                    if (references != null &&
                                                        references.isNotEmpty) {
                                                      final int fileCount =
                                                          references
                                                              .expand((ref) =>
                                                                  ref.url ?? [])
                                                              .where((u) =>
                                                                  u != null &&
                                                                  u
                                                                      .toString()
                                                                      .trim()
                                                                      .isNotEmpty)
                                                              .length;

                                                      if (fileCount > 0) {
                                                        return Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      6),
                                                          alignment: Alignment
                                                              .centerLeft,
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              const Icon(
                                                                Icons
                                                                    .description,
                                                                size: 18,
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                              const SizedBox(
                                                                  width: 4),
                                                              Text(
                                                                "($fileCount)",
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize: 13,
                                                                  color: Colors
                                                                      .grey,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      }
                                                    }

                                                    return const SizedBox();
                                                  },
                                                ),
                                              ),
                                              style: TextStyle(fontSize: 14),
                                            ),
                                          )
                                        ],
                                        PopupMenuButton<String>(
                                          icon: Icon(
                                            Icons.more_vert_outlined,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          onSelected: (value) {
                                            if (value == 'history') {
                                              showVersionHistoryBottomSheet(
                                                context,
                                                element.result,
                                                element.user,
                                                element.result.version!,
                                              );
                                            } else if (value == 'help') {
                                              _showHelpDialog(context, element);
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            PopupMenuItem(
                                              value: 'history',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.history, size: 20),
                                                  SizedBox(width: 10),
                                                  Text("History"),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'help',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit_document,
                                                      size: 20),
                                                  SizedBox(width: 10),
                                                  Text("Helping Docs"),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                              Container(
                                height: 50,
                                width: 1,
                                color: Colors.transparent,
                              ),
                              // SizedBox(width: 10),
                            ],
                          ),
                        ),
                      ),
                      // Text(element.result.linkVendor!.hazardHub!.items!.keys!.toString()),
                      // if (isExpanded)
                      if (isExpanded || hazardHubExpandFlow)
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          child: ImageUploadCard(
                            accountId: widget.accountId!,
                            subAccountId: widget.subAccountId!,
                            locationId: widget.locationId ?? '',
                            sovId: widget.sovId ?? '',
                            campusId: widget.campusId ?? '',
                            title: element.name,
                            user: element.user,
                            result: element.result,
                            parametertype: element.parameterType,
                            parameterValue: element.parameterValue?.value,
                            linkVendor: element.result.linkVendor,
                            onImagesUpdated: (images) {
                              print("Uploaded Images Count: ${images.length}");
                            },
                            selectedParameterList:
                                widget.selectedParameterList!,
                            onRefresh: widget.onRefresh,
                            showManualValueFields: showManualValueFields,
                            // showManualValueFields: (element.result.linkVendor
                            //                 ?.hazardHub?.items?.length ??
                            //             0) ==
                            //         1
                            //     ? true
                            //     : showManualValueFields,
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

  bool isParameterEmpty(dynamic rawValue) {
    if (rawValue == null) return true;

    try {
      dynamic decoded = rawValue;

      // Case 1: If value is JSON string
      if (decoded is String &&
          decoded.trim().startsWith("{") &&
          decoded.trim().endsWith("}")) {
        decoded = jsonDecode(decoded);
      }

      // Case 2: {"value":{...}}
      if (decoded is Map && decoded["value"] is Map) {
        final inner = decoded["value"]["value"];
        return inner == null || inner.toString().trim().isEmpty;
      }

      // Case 3: {"value":396}
      if (decoded is Map && decoded.containsKey("value")) {
        final inner = decoded["value"];
        return inner == null || inner.toString().trim().isEmpty;
      }

      // Case 4: direct value
      return decoded.toString().trim().isEmpty;
    } catch (e) {
      return true;
    }
  }

  void _showHelpDialog(BuildContext context, element) {
    final images = element.result.helpDocumantion?.images ?? [];
    final docs = element.result.helpDocumantion?.docs ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Help Documentation'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Documents", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              if (docs.isNotEmpty)
                ...docs.map((doc) => FileRow(fileUrl: doc, isImage: false))
              else
                Text("No documents available."),
              SizedBox(height: 16),
              Text("Images", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              if (images.isNotEmpty)
                ...images.map((img) => FileRow(fileUrl: img, isImage: true))
              else
                Text("No images available."),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          )
        ],
      ),
    );
  }

  String _extractCleanValue(dynamic rv) {
    if (rv == null) return "";

    try {
      dynamic current = rv;

      if (current is String &&
          current.trim().startsWith("{") &&
          current.contains(":")) {
        current = jsonDecode(current);
      }

      if (current is Map && current.containsKey("value")) {
        current = current["value"];
      }

      if (current is Map &&
          current.containsKey("_seconds") &&
          current.containsKey("_nanoseconds")) {
        int seconds = current["_seconds"];
        DateTime dt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
        return DateFormat("dd/MM/yyyy hh:mm a").format(dt);
      }
      if (current is Map) {
        return jsonEncode(current);
      }
      return current.toString();
    } catch (e) {
      return rv.toString();
    }
  }

  String formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    return DateFormat('dd/MM/yyyy').format(date);
  }

  void showVersionHistoryBottomSheet(
      BuildContext context, Result result, User user, Version version) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black87,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.7, // ← Bottom sheet max height (adjustable)
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ---------- HEADER ----------
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
                    Expanded(
                      child: Text(
                        result.name.toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Color.fromRGBO(144, 202, 249, 1),
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 8),

                // ---------- USER INFO ----------
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(user.name.toString(),
                                style: TextStyle(
                                    color: Colors.purpleAccent, fontSize: 16)),
                            SizedBox(width: 8),
                            Text(
                              'Created on ${formatDate(version.versionHistory![0].date.toString())}',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 14),
                            )
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          (result.history != null &&
                                  result.history!.isNotEmpty &&
                                  result.history![0].updatedAt?.iSeconds !=
                                      null)
                              ? 'Last updated on ${DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(result.history![0].updatedAt!.iSeconds! * 1000))}'
                              : 'Last updated on --',
                          style: TextStyle(
                            color: Color.fromRGBO(102, 187, 106, 1),
                            fontSize: 14,
                          ),
                        )
                      ],
                    ),
                  ],
                ),

                Divider(),

                SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Version Updates',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),

                SizedBox(height: 12),

                // ----------- DYNAMIC HEIGHT LIST ----------
                Expanded(
                  child: ListView.builder(
                    itemCount: result.history?.length ?? 0,
                    itemBuilder: (context, index) {
                      final item = result.history![index];

                      if (item.value == null) return SizedBox();

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
                        indicatorStyle: IndicatorStyle(
                          width: 14,
                          color: Colors.blue,
                          indicatorXY: 0.2,
                        ),
                        beforeLineStyle:
                            LineStyle(color: Colors.grey, thickness: 0.3),
                        afterLineStyle:
                            LineStyle(color: Colors.grey, thickness: 0.3),
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
                              Text(formattedDate,
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                              SizedBox(height: 6),
                              buildValueWidget(item.value),
                              if (item.paramType != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    "Value Type: ${item.paramType!}",
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 13,
                                    ),
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
                                            item.reference![0].url[0]
                                                .isNotEmpty)
                                        ? NetworkImage(
                                            item.reference![0].url[0])
                                        : null,
                                    child: (item.reference == null ||
                                            item.reference!.isEmpty ||
                                            item.reference![0].url.isEmpty ||
                                            item.reference![0].url[0].isEmpty)
                                        ? Text(
                                            (item.userName?.isNotEmpty ?? false)
                                                ? item.userName![0]
                                                    .toUpperCase()
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
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildValueWidget(dynamic value) {
    try {
      // Handle if value is a String
      if (value is String) {
        // Check if it's an ISO date
        if (RegExp(r'\d{4}-\d{2}-\d{2}T').hasMatch(value)) {
          final date = DateTime.tryParse(value);
          if (date != null) {
            return Text(
              "Added Value : " + DateFormat('dd/MM/yyyy HH:mm:ss').format(date),
              style: TextStyle(color: Colors.white),
            );
          }
        }

        // Try decoding as JSON
        final decoded = jsonDecode(value);

        // Handle List
        if (decoded is List) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: decoded
                .map((e) => Text("Added Value : ${e.toString()}",
                    style: TextStyle(color: Colors.white)))
                .toList(),
          );
        }

        // Handle Map from string
        if (decoded is Map) {
          return _renderFromMap(decoded);
        }

        // Otherwise, return plain string
        return Text("Added Value : " + value,
            style: TextStyle(color: Colors.white));
      }

      // Handle if value is already a Map
      if (value is Map) {
        return _renderFromMap(value);
      }

      // Fallback
      return Text("Added value -" + value.toString(),
          style: TextStyle(color: Colors.white));
    } catch (e) {
      return Text("Added value -" + value.toString(),
          style: TextStyle(color: Colors.white));
    }
  }

// Helper function to render Map<String, dynamic>
  Widget _renderFromMap(Map map) {
    // Priority: Show "value" key if exists and not empty
    if (map.containsKey("value") &&
        (map["value"]?.toString().isNotEmpty ?? false)) {
      return Text("Added Value : " + map["value"].toString(),
          style: TextStyle(color: Colors.white));
    }

    // Otherwise, show the first non-empty key-value
    for (var entry in map.entries) {
      final val = entry.value?.toString() ?? "";
      if (val.trim().isNotEmpty) {
        return Text("Added Value : " + val,
            style: TextStyle(color: Colors.white));
      }
    }

    // If all are empty
    return Text("--", style: TextStyle(color: Colors.white));
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
      print(" Download Error: $e");
      print(" StackTrace: $stackTrace");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Download failed: $e")),
      );
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
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
