
import 'package:intl/intl.dart';

import '../../design_system/components/custom_toast.dart';
import '../../providers/data_list_parameters.dart';
import '../../utils/global_imports.dart';

class SyncParametersPage extends StatefulWidget {
  final Map<String, dynamic> response;

  const SyncParametersPage({
    Key? key,
    required this.response,
  }) : super(key: key);

  @override
  State<SyncParametersPage> createState() => _SyncParametersPageState();
}

class _SyncParametersPageState extends State<SyncParametersPage> {
  bool isSyncing = false;

  Widget buildCard({
    required String title,
    required String value,
    required String keyName,
    required String source,
    String? updatedAt,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          rowItem("Value", value),
          const SizedBox(height: 10),
          rowItem("Key", keyName),
          const SizedBox(height: 10),
          if (updatedAt != null) ...[
            rowItem("Updated At", updatedAt),
            const SizedBox(height: 10),
          ],
          rowItem("Source", source),
        ],
      ),
    );
  }

  Widget rowItem(String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  bool _isExpanded = false;
  bool _showNotificationDot = true;
  Map<String, bool> expandedMap = {};

  @override
  Widget build(BuildContext context) {
    final originalData = widget.response["original_data"] ?? {};

    final comparison = widget.response["comparison"] ?? {};

    final vendorResults = widget.response["vendor_results"] as List? ?? [];

    final parameterValue = originalData["parameter_value"] ?? {};

    final parameterName = originalData["name"]?.toString() ?? "Parameter";

    final extractionKey = vendorResults.isNotEmpty
        ? vendorResults.first["extraction_key"]?.toString() ?? "N/A"
        : "N/A";
    final datavalue = vendorResults.isNotEmpty
        ? vendorResults.first["data"]?.toString() ?? "N/A"
        : "N/A";
    final extractedValue =
        vendorResults.first["full_data"]?["risks"]?["address"]?.toString() ??
            "";
    final localUserName = comparison["original"]?["full_parameter_value"]
                ?["user_name"]
            ?.toString() ??
        "N/A";
    final localRawValue = comparison["original"]?["value"]?.toString() ?? "NA";

    String localValue = "N/A";
    final bool isVendorFound =
        vendorResults.isNotEmpty && (vendorResults.first["found"] == true);
    try {
      final decoded = jsonDecode(localRawValue);
      if (decoded is Map) {
        if (decoded["value"] is Map) {
          localValue = decoded["value"]["value"]?.toString() ?? "N/A";
        } else {
          localValue = decoded["value"]?.toString() ?? "N/A";
        }
      } else {
        localValue = localRawValue;
      }
    } catch (e) {
      localValue = localRawValue;
    }

    final updatedAt = comparison["original"]?["updated_at"]?["_seconds"];

    String formattedDate = "N/A";

    if (updatedAt != null) {
      final date = DateTime.fromMillisecondsSinceEpoch(
        updatedAt * 1000,
      );

      formattedDate = DateFormat(
        "MMM dd, yyyy hh:mm a",
      ).format(date);
    }

    return SafeArea(
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return Consumer<MyLocationListProvider>(
            builder: (context, locationProfileProvider, child) {
              return Scaffold(
                backgroundColor: themeProvider.getTheme.colorScheme.surface,
                appBar: CustomAppBar(
                  isExpanded: _isExpanded,
                  showNotificationDot: _showNotificationDot,
                  onExpandPressed: (isExpanded) {
                    setState(() {
                      _isExpanded = isExpanded;
                    });
                  },
                  onSearchPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
                bottomNavigationBar: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  decoration: BoxDecoration(
                    color: themeProvider.getTheme.colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8CC8FF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: isSyncing || !isVendorFound
                                ? null
                                : showConfirmSyncBottomSheet,
                            // onPressed:
                            //     isSyncing ? null : showConfirmSyncBottomSheet,
                            child: isSyncing
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
                                    ),
                                  )
                                : const Text(
                                    "Sync HazardHub → RiskSphere",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.2),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              "Cancel",
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// HEADER
                      // Container(
                      //   padding: const EdgeInsets.all(14),
                      //   decoration: BoxDecoration(
                      //     color: const Color(0xFF151515),
                      //     borderRadius: BorderRadius.circular(14),
                      //     border: Border.all(
                      //       color: Colors.orange.withOpacity(0.25),
                      //     ),
                      //   ),
                      //   child: Row(
                      //     children: [
                      //       Container(
                      //         padding: const EdgeInsets.symmetric(
                      //           horizontal: 10,
                      //           vertical: 5,
                      //         ),
                      //         decoration: BoxDecoration(
                      //           color: Colors.orange.withOpacity(0.15),
                      //           borderRadius: BorderRadius.circular(8),
                      //         ),
                      //         child: const Text(
                      //           "Sync Parameters",
                      //           style: TextStyle(
                      //             color: Colors.orange,
                      //             fontSize: 11,
                      //             fontWeight: FontWeight.w700,
                      //           ),
                      //         ),
                      //       ),
                      //       // const Spacer(),
                      //       // Text(
                      //       //   extractionKey,
                      //       //   style: const TextStyle(
                      //       //     color: Colors.white38,
                      //       //     fontSize: 12,
                      //       //   ),
                      //       // ),
                      //     ],
                      //   ),
                      // ),
                      Container(
                        child: const Text(
                          "Sync Parameters",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),

                      /// TITLE
                      Text(
                        parameterName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 5),

                      /// HAZARD HUB
                      buildCard(
                        title: "HazardHub (${extractionKey})",
                        value: datavalue,
                        keyName: extractionKey,
                        source: "HazardHub API",
                      ),

                      const SizedBox(height: 18),

                      Center(
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFF1A1A1A),
                          child: const Icon(
                            Icons.arrow_circle_down_outlined,
                            color: Colors.white70,
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      buildCard(
                        title: "Risksphere Recommendation",
                        value: localValue,
                        keyName: extractionKey,
                        updatedAt: formattedDate,
                        source: localUserName,
                      ),

                      const SizedBox(height: 30),

                      /// COMPARISON
                      // if (comparison["other_sources"] != null &&
                      //     comparison["other_sources"] is Map)
                      //   Container(
                      //     padding: const EdgeInsets.all(16),
                      //     decoration: BoxDecoration(
                      //       color: const Color(0xFF151515),
                      //       borderRadius: BorderRadius.circular(16),
                      //     ),
                      //     child: Column(
                      //       crossAxisAlignment: CrossAxisAlignment.start,
                      //       children: [
                      //         const Text(
                      //           "Other Sources",
                      //           style: TextStyle(
                      //             color: Colors.white,
                      //             fontSize: 16,
                      //             fontWeight: FontWeight.w700,
                      //           ),
                      //         ),
                      //         const SizedBox(height: 14),
                      //         ...comparison["other_sources"]
                      //             .entries
                      //             .map<Widget>(
                      //               (entry) => Padding(
                      //                 padding:
                      //                     const EdgeInsets.only(bottom: 10),
                      //                 child: Row(
                      //                   children: [
                      //                     Expanded(
                      //                       child: Text(
                      //                         entry.key,
                      //                         style: const TextStyle(
                      //                           color: Colors.white70,
                      //                         ),
                      //                       ),
                      //                     ),
                      //                     Expanded(
                      //                       child: Text(
                      //                         entry.value.toString(),
                      //                         textAlign: TextAlign.right,
                      //                         style: const TextStyle(
                      //                           color: Colors.white,
                      //                           fontWeight: FontWeight.w600,
                      //                         ),
                      //                       ),
                      //                     ),
                      //                   ],
                      //                 ),
                      //               ),
                      //             )
                      //             .toList(),
                      //       ],
                      //     ),
                      //   ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void showConfirmSyncBottomSheet() {
    final originalData = widget.response["original_data"] ?? {};

    final parameterName = originalData["name"]?.toString() ?? "Parameter";

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF0E0E0E),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Confirm Sync",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      "This will overwrite the current Local Data Parameter value for \"$parameterName\" with HazardHub.",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8CC8FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isSyncing
                            ? null
                            : () async {
                                Navigator.pop(context);

                                await syncHazardHubToLocal();
                              },
                        child: isSyncing
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Text(
                                "Confirm",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.2),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> syncHazardHubToLocal() async {
    setState(() {
      isSyncing = true;
    });

    try {
      final locationId = widget.response["location_id"]?.toString() ?? "";

      final dataCategoryId =
          widget.response["data_category_id"]?.toString() ?? "";
      final vendorResults = widget.response["vendor_results"] as List? ?? [];

      final extractionKey = vendorResults.isNotEmpty
          ? vendorResults.first["extraction_key"]?.toString() ?? ""
          : "";

      final response = await Provider.of<SubaccountParameterProvider>(
        context,
        listen: false,
      ).vendorDataComparisonApi(
        context,
        locationId,
        dataCategoryId,
        extractionKey,
      );

      print("SYNC RESPONSE => $response");

      if (response != null && response["message"] != null) {
        CustomToast.success(
          context,
          response["message"],
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      print("SYNC ERROR => $e");

      CustomToast.error(
        context,
        "Sync failed",
      );
    } finally {
      if (mounted) {
        setState(() {
          isSyncing = false;
        });
      }
    }
  }
}
