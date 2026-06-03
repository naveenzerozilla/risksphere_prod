import 'package:RiskSphere/utils/global_imports.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../design_system/components/custom_toast.dart';

class ExistingParameterLinksPage extends StatefulWidget {
  const ExistingParameterLinksPage({
    super.key,
  });

  @override
  State<ExistingParameterLinksPage> createState() =>
      _ExistingParameterLinksPageState();
}

class _ExistingParameterLinksPageState
    extends State<ExistingParameterLinksPage> {
  bool _isExpanded = false;
  bool _showNotificationDot = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<InvoiceProvider>();

      provider.fetchHazardHubParameter(
        context,
        '',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<ThemeProvider>(
          builder: (buildContext, themeProvider, child) {
        return Scaffold(
          backgroundColor: Colors.black,
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
          drawer: CustomDrawer(),
          body: Consumer<InvoiceProvider>(
            builder: (context, provider, _) {
              if (provider.isHazardLoading && provider.hazardHubList.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final list = provider.hazardHubList
                  .where(
                    (e) =>
                        e.linkedDataParameters != null &&
                        e.linkedDataParameters!.isNotEmpty,
                  )
                  .toList();

              if (list.isEmpty) {
                return const Center(
                  child: Text(
                    "No Existing Parameters Found",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final item = list[index];

                  return _buildParameterLinkCard(
                    hazardHubParam: item.name ?? '',
                    localParam: item.linkedDataParameters
                            ?.map(
                              (e) => e.dataCategoryName ?? '',
                            )
                            .where(
                              (e) => e.isNotEmpty,
                            )
                            .join(", ") ??
                        '',
                    createdDate: item.linkedDataParameters != null &&
                            item.linkedDataParameters!.isNotEmpty &&
                            item.linkedDataParameters!.first.createdAt != null
                        ? DateFormat('MMM dd, yyyy').format(
                            DateTime.fromMillisecondsSinceEpoch(
                              (item.linkedDataParameters!.first.createdAt!
                                          .iSeconds! ??
                                      0) *
                                  1000,
                            ),
                          )
                        : 'N/A',
                    updatedDate: item.updatedAt != null
                        ? DateFormat('MMM dd, yyyy').format(
                            DateTime.fromMillisecondsSinceEpoch(
                              (item.updatedAt!.iSeconds ?? 0) * 1000,
                            ),
                          )
                        : 'N/A',
                    path: item.path ?? '',
                    dataCategoryId: item.linkedDataParameters != null &&
                            item.linkedDataParameters!.isNotEmpty
                        ? item.linkedDataParameters!.first.dataCategoryId ?? ""
                        : "",
                  );
                },
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildParameterLinkCard({
    required String hazardHubParam,
    required String localParam,
    required String createdDate,
    required String updatedDate,
    required String path,
    required String dataCategoryId,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'HazardHub Parameters : ',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF24323A),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              hazardHubParam,
                              style: const TextStyle(
                                color: Color(0xFF8FBCE6),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Risksphere parameter : ',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: localParam
                                .split(", ")
                                .map(
                                  (e) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2A2A2A),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      e,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (context) {
                        bool isLoading = false;

                        return StatefulBuilder(
                          builder: (context, setStateBottom) {
                            return Container(
                              padding: const EdgeInsets.all(20),
                              decoration: const BoxDecoration(
                                color: Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                              ),
                              child: SafeArea(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      "Unlink Parameter",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      "Are you sure you want to unlink \"$hazardHubParam\" ?",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 52,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        onPressed: isLoading
                                            ? null
                                            : () async {
                                                setStateBottom(() {
                                                  isLoading = true;
                                                });

                                                try {
                                                  ApiService apiService =
                                                      ApiService(
                                                    AppConstant
                                                        .UNLINK_PARAMETER,
                                                  );

                                                  final payload = {
                                                    "vendor_response_key":
                                                        "hazard_hub",
                                                    "key_id": 0,
                                                    "data_paramters": [
                                                      {
                                                        "vendor_key":
                                                            "hazard_hub",
                                                        "data_category_id":
                                                            dataCategoryId,
                                                      }
                                                    ]
                                                  };

                                                  print(
                                                    "UNLINK PAYLOAD => $payload",
                                                  );

                                                  final response =
                                                      await apiService.delete(
                                                    payload,
                                                  );

                                                  print(
                                                    "UNLINK RESPONSE => $response",
                                                  );

                                                  if (response["message"] !=
                                                      null) {
                                                    CustomToast.success(
                                                      context,
                                                      response["message"],
                                                    );
                                                  }

                                                  Navigator.pop(context);

                                                  context
                                                      .read<InvoiceProvider>()
                                                      .fetchHazardHubParameter(
                                                        context,
                                                        '',
                                                      );
                                                } catch (e) {
                                                  print(
                                                    "UNLINK ERROR => $e",
                                                  );

                                                  CustomToast.error(
                                                    context,
                                                    "Failed to unlink",
                                                  );
                                                } finally {
                                                  setStateBottom(() {
                                                    isLoading = false;
                                                  });
                                                }
                                              },
                                        child: isLoading
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Text(
                                                "Unlink",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
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
                                            color:
                                                Colors.white.withOpacity(0.2),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
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
                },
                icon: const Icon(
                  Icons.link_off,
                  color: Colors.red,
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            color: Colors.white.withOpacity(0.08),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Created :',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    createdDate,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Updated :',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    updatedDate,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
