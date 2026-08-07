import '../../utils/global_imports.dart';
import '../../models/invoice_model.dart';
import 'exisitingparameter.dart';

class LinkParameterPage extends StatefulWidget {
  final int? initialTabIndex;

  LinkParameterPage({super.key, this.initialTabIndex});

  @override
  State<LinkParameterPage> createState() => _LinkParameterPageState();
}

class _LinkParameterPageState extends State<LinkParameterPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? _tabIndex;
  String filterItem = "";
  bool isHasAnyPlan = false;

  // Selected parameters for linking
  String? selectedHazardHubParameter;
  String? selectedLocalParameter;
  List<ParameterItem> selectedHazardHubParameters = [];
  List<ParameterItem> selectedLocalParameters = [];

  PaymentProvider get paymentProvider =>
      Provider.of<PaymentProvider>(context, listen: false);

  InvoiceProvider get invoiceProvider =>
      Provider.of<InvoiceProvider>(context, listen: false);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex ?? 0,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getData();
      _setClaims();
    });

    // _tabController.addListener(() {
    //   if (!_tabController.indexIsChanging) {
    //     _tabIndex = _tabController.index;
    //     if (_tabIndex == 0) {
    //       invoiceProvider.fetchHazardHubParameter(context, '');
    //     } else if (_tabIndex == 1) {
    //       invoiceProvider.fetchRiskParameter(context, '');
    //     }
    //   }
    // });
  }

  Future<void> _setClaims() async {
    isHasAnyPlan = await SharedPreferenceService.getHasAnyPlan();
  }

  Future<void> _getData() async {
    final invoiceProvider =
        Provider.of<InvoiceProvider>(context, listen: false);

    await Future.wait([
      invoiceProvider.fetchHazardHubParameter(context, ''),
      invoiceProvider.fetchRiskParameter(context, ''),
    ]);
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
  }

  void _showLinkParameterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// 🔹 Drag Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const Text(
                      'Confirm Parameter Linking',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    SizedBox(height: CustomSpacing.four),

                    // TextField(
                    //   decoration: InputDecoration(
                    //     hintText: 'Search',
                    //     hintStyle: const TextStyle(color: Colors.grey),
                    //     filled: true,
                    //     fillColor: const Color(0xFF2A2A2A),
                    //     border: OutlineInputBorder(
                    //       borderRadius: BorderRadius.circular(10),
                    //     ),
                    //   ),
                    //   style: const TextStyle(color: Colors.white),
                    // ),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSelectedList(
                            title: "Selected RiskSphere Parameter",
                            items: selectedLocalParameters
                                .map((e) => e.name ?? '')
                                .toList(),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            margin: const EdgeInsets.only(top: 60),
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey),
                            ),
                            child: const Icon(Icons.arrow_forward,
                                color: Colors.grey),
                          ),
                          const SizedBox(width: 12),
                          _buildSelectedList(
                            title: "Selected HazardHub",
                            items: selectedHazardHubParameters
                                .map((e) => e.name ?? '')
                                .toList(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      '${selectedHazardHubParameters.length} HazardHub parameters will be linked to ${selectedLocalParameters.length} Local parameter.',
                      style: const TextStyle(color: Colors.grey),
                    ),

                    const SizedBox(height: 20),

                    Consumer<InvoiceProvider>(
                      builder: (context, provider, _) {
                        return SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (selectedHazardHubParameters.isEmpty ||
                                  selectedLocalParameters.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please select parameters'),
                                  ),
                                );
                                return;
                              }

                              final hazardProvider =
                                  Provider.of<InvoiceProvider>(
                                context,
                                listen: false,
                              );
                              final keyIndex =
                                  hazardProvider.localList.indexWhere(
                                (e) =>
                                    e.id ==
                                    selectedHazardHubParameters.first.id,
                              );
                              final success = await provider.linkParameter(
                                context,
                                keyIndex: keyIndex,
                                hazards: selectedHazardHubParameters,
                                locals: selectedLocalParameters,
                              );
                              if (success && mounted) {
                                Navigator.pop(context);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Parameter linked successfully',
                                    ),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8FBCE6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: provider.isLinkParameterLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
                                    ),
                                  )
                                : const Text(
                                    'Confirm Link',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF8FBCE6)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Color(0xFF8FBCE6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSelectedList({
    required String title,
    required List<String> items,
  }) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 10),
          ...items.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8FBCE6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child:
                        const Icon(Icons.check, size: 12, color: Colors.black),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool _isExpanded = false;
    bool _showNotificationDot = true;
    return DefaultTabController(
      length: 2,
      child: SafeArea(
        child: Scaffold(
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
          bottomNavigationBar: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.08), // top divider line
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 48,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8FBCE6), // light blue
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextButton.icon(
                    onPressed: () {
                      _showLinkParameterBottomSheet();
                    },
                    icon: const Icon(Icons.link, color: Colors.black, size: 18),
                    label: const Text(
                      "Link Parameter",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 48,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF8FBCE6), // blue border
                    ),
                  ),
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ExistingParameterLinksPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.settings_backup_restore,
                        color: Color(0xFF8FBCE6), size: 18),
                    label: const Text(
                      "Manage",
                      style: TextStyle(
                        color: Color(0xFF8FBCE6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          body: Consumer<UserProfileProvider>(
            builder: (context, userProfile, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding:
                        const EdgeInsets.only(top: 16, left: 20, right: 20),
                    child: const Text(
                      "Parameter Linking Management",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // TabBar
                  TabBar(
                    controller: _tabController,
                    isScrollable: false,
                    labelColor: Colors.lightBlueAccent,
                    unselectedLabelColor: Colors.grey,
                    labelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    indicatorColor: Colors.lightBlueAccent,
                    indicatorWeight: 2,
                    tabs: const [
                      Tab(text: "RiskSphere Parameter data"),
                      Tab(text: "HazardHub Parameters"),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildRisksphereParameterTab(),
                        _buildHazardHubParameterTab(),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHazardHubParameterTab() {
    final provider = Provider.of<InvoiceProvider>(context);
    if (provider.isHazardLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final hazardHubParameters = provider.hazardHubList;

    return Container(
      margin: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.lightBlueAccent,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'HazardHub Parameters',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Source',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${selectedHazardHubParameters.length} / ${hazardHubParameters.length} selected',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: hazardHubParameters.length,
              itemBuilder: (context, index) {
                final param = hazardHubParameters[index];
                final isSelected =
                selectedHazardHubParameters.any(
                      (e) => e.name == param.name,
                );
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selectedHazardHubParameters.removeWhere(
                              (e) => e.name == param.name,
                        );
                      } else {
                        selectedHazardHubParameters.add(param);
                      }
                    });

                    print(
                      "SELECTED COUNT: "
                      "${selectedHazardHubParameters.length}",
                    );
                  },
                  // onTap: () {
                  //   setState(() {
                  //     if (isSelected) {
                  //       selectedHazardHubParameters.remove(param);
                  //     } else {
                  //       selectedHazardHubParameters.add(param);
                  //     }
                  //   });
                  // },
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF2C3E50)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.lightBlueAccent
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.lightBlueAccent
                                  : Colors.grey,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  size: 14, color: Colors.black)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            param.name.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRisksphereParameterTab() {
    final provider = Provider.of<InvoiceProvider>(context);

    if (provider.isLocalLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final localParameters = provider.localList;

    return Container(
      margin: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'RiskSphere Parameter data',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Target',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${selectedLocalParameters.length} / ${localParameters.length} selected',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: localParameters.length,
              itemBuilder: (context, index) {
                final param = localParameters[index];
                final isSelected = selectedLocalParameters.any(
                  (e) => e.id == param.id,
                );

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedLocalParameters.clear();
                      selectedLocalParameters.add(param);
                    });
                  },
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF2C3E50)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.lightBlueAccent
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.lightBlueAccent
                                  : Colors.grey,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  size: 14, color: Colors.black)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            param.name.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
