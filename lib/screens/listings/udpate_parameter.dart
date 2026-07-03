import 'package:RiskSphere/screens/listings/widgets/auto_complete_options.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/global_imports.dart';
import 'package:RiskSphere/models/account_list_model.dart';

class UpdateParameterScreen extends StatefulWidget {
  Data item;

  UpdateParameterScreen({super.key, required this.item});

  @override
  State<UpdateParameterScreen> createState() => _UpdateParameterScreenState();
}

class _UpdateParameterScreenState extends State<UpdateParameterScreen>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  bool _showNotificationDot = true;
  bool hasAnyPlan = false;
  TabController? _tabController;
  Screens _selectedScreen = Screens.accountList;
  TextEditingController _textEditingController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  TextEditingController _messageController = TextEditingController();
  TextEditingController _sovNameController = TextEditingController();
  bool isLoading = false;
  String selectedFilter = "All";
  final TextEditingController _filePathController = TextEditingController();
  final Map<String, TextEditingController> _valueControllers = {};
  String? _uploadedFileName;
  final Map<String, bool> _fieldErrors = {};
  final Map<String, Map<String, dynamic>> _initialValues = {};

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isSubmitting = false;

  bool showCheckbox = false;

  Timer? deBouncer;

  Timer? _debounce;
  String _accountQuery = "";
  bool _accountAlreadyExists = false;
  Accounts? _selectedAccount;
  String _autocompleteText = "";
  bool isPgAdmin = false;
  bool isAdmin = false;
  bool isSuperAdmin = false;
  bool isIndivudual = false;

  ScrollController _scrollController = ScrollController();

  Timer? autoCompleteDeBouncer;

  late File files;

  void debounce(
    VoidCallback callback, {
    Duration duration = const Duration(seconds: 1),
  }) {
    if (deBouncer != null) {
      deBouncer!.cancel();
    }
    deBouncer = Timer(duration, callback);
  }

  void accountsSearchClient(String query) async {
    debounce(() async {
      if (!mounted) return;
      _accountQuery = query;
      print("Query set to: $_accountQuery");
      var provider = Provider.of<AccountListProvider>(context, listen: false);
      provider.page = 1;
      await provider.updateRecommendation(context, widget.item.locationId!);
    });
  }

  void autoCompleteDebounce(
    VoidCallback callback, {
    Duration duration = const Duration(seconds: 1),
  }) {
    if (autoCompleteDeBouncer != null) {
      autoCompleteDeBouncer!.cancel();
    }
    autoCompleteDeBouncer = Timer(duration, callback);
  }

  Future<void> autoCompleteAccountsSearchClient(String query) async {
    if (query.isEmpty) {
      return;
    }
    autoCompleteDebounce(() async {
      if (!mounted) return;
      var provider = Provider.of<AccountListProvider>(context, listen: false);
      await provider.fetchAutoCompleteAccountList(context, query);

      // Force UI update after API call
      if (mounted) {
        setState(() {
          print("setState called after fetchAutoCompleteAccountList");
        });
      }
    });
  }

  bool _showOverlay = false;

  List<Accounts> parameterList = [];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 1, vsync: this);

    _valueControllers.clear();
    _initialValues.clear();
    _fieldErrors.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFreshData();
    });
  }

  Future<void> _loadFreshData() async {
    final provider = context.read<AccountListProvider>();

    _valueControllers.clear();
    _initialValues.clear();
    _fieldErrors.clear();

    provider.parameterList.clear();
    provider.hasLoadedOnce = false;
    provider.isLoading = true;
    provider.notifyListeners();

    await provider.updateRecommendation(
      context,
      widget.item.locationId!,
    );

    if (mounted) {
      setState(() {});
    }
  }

  // Future<void> _loadFreshData() async {
  //   final provider = context.read<AccountListProvider>();
  //
  //   // 🔥 CLEAR STATE BEFORE API
  //   _valueControllers.clear();
  //   _initialValues.clear();
  //   _fieldErrors.clear();
  //
  //   provider.parameterList.clear();
  //   provider.hasLoadedOnce = false;
  //   provider.isLoading = true;
  //   provider.notifyListeners();
  //
  //   await provider.updateRecommendation(
  //     context,
  //     widget.item.locationId!,
  //   );
  // }

  @override
  void dispose() {
    _tabController?.dispose();
    _filePathController.dispose();
    super.dispose();
  }

  Future<void> _getData() async {
    final provider = Provider.of<AccountListProvider>(context, listen: false);

    provider.hasLoadedOnce = false;
    provider.isLoading = true;
    provider.notifyListeners();

    await provider.updateRecommendation(
      context,
      widget.item.locationId!,
    );
  }

  Widget _buildBottomActionBar({
    required VoidCallback onCancel,
    required Future<void> Function()? onSubmit,
    bool isSubmitEnabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        border: Border(
          top: BorderSide(color: Color(0xFF2C2C2C), width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: (!_isSubmitting && isSubmitEnabled)
                  ? () async {
                      setState(() => _isSubmitting = true);

                      try {
                        await onSubmit?.call();
                      } finally {
                        if (mounted) {
                          setState(() => _isSubmitting = false);
                        }
                      }
                    }
                  : null,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : Text(
                      LanguageService.getTranslated(context, "submit"),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primaryMain),
                foregroundColor: AppColors.primaryMain,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: _isSubmitting ? null : onCancel,
              child: Text(
                LanguageService.getTranslated(context, "cancel"),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> buildSubmitPayload() {
    final Map<String, Map<String, dynamic>> grouped = {};

    _valueControllers.forEach((key, controller) {
      final parts = key.split(':');
      if (parts.length != 2) return;

      final paramId = parts[0];
      final field = parts[1];

      final newValue = controller.text.trim();
      final initialValue = _initialValues[paramId]?[field]?.toString() ?? "";

      // ⛔ Skip only if unchanged
      if (newValue == initialValue) return;

      grouped.putIfAbsent(paramId, () => {});
      grouped[paramId]![field] = newValue;
    });

    return {
      "to_update_data_params": grouped.entries.map((entry) {
        final data = entry.value;

        return {
          "data_category_id": entry.key,
          "value": jsonEncode({
            "value": data["value"] ?? "",
            "unit": data["unit"] ?? "",
            "value_a": data["value_a"] ?? "",
            "value_b": data["value_b"] ?? "",
            "currency": data["currency"] ?? "",
            "valuation_date": _formatDateToISO(data["valuation_date"]),
          }),
        };
      }).toList(),
    };
  }

  String _formatDateToISO(String? date) {
    if (date == null || date.isEmpty) return "";

    final parsed = DateTime.tryParse(date);
    if (parsed == null) return "";

    // ✅ Return ONLY date (no time)
    return DateFormat('yyyy-MM-dd').format(parsed);
  }

  // String _formatDateToISO(String? date) {
  //   if (date == null || date.isEmpty) return "";
  //
  //   final parsed = DateTime.tryParse(date);
  //   if (parsed == null) return "";
  //
  //   return parsed.toUtc().toIso8601String();
  // }

  // Map<String, dynamic> buildSubmitPayload() {
  //   final Map<String, Map<String, dynamic>> grouped = {};
  //
  //   _valueControllers.forEach((key, controller) {
  //     final parts = key.split(':');
  //     if (parts.length != 2) return;
  //
  //     final paramId = parts[0];
  //     final field = parts[1];
  //
  //     // 🚫 we only care about "value"
  //     if (field != "value") return;
  //
  //     final newValue = controller.text.trim();
  //     final initialValue =
  //         _initialValues[paramId]?["value"]?.toString() ?? "";
  //
  //     // ⛔ skip ONLY if unchanged
  //     if (newValue == initialValue) return;
  //
  //     grouped.putIfAbsent(paramId, () => {});
  //     grouped[paramId]!["value"] = newValue; // can be empty
  //   });
  //
  //   return {
  //     "to_update_data_params": grouped.entries.map((entry) {
  //       return {
  //         "data_category_id": entry.key,
  //         "value": jsonEncode({
  //           "value": entry.value["value"] ?? "", // ✅ only this corrected
  //         }),
  //       };
  //     }).toList(),
  //   };
  // }

  @override
  Widget build(BuildContext context1) {
    final typography = CustomTypography(context);
    return SafeArea(
      child: Consumer<ThemeProvider>(
          builder: (buildContext, themeProvider, child) {
        return PopScope(
          onPopInvokedWithResult: (canPop, result) {
            Provider.of<DrawerSelectionProvider>(context, listen: false)
                .setSelectedItem("dashboard");
          },
          child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: themeProvider.getTheme.colorScheme.background,
            drawer: CustomDrawer(),
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
            bottomNavigationBar: _buildBottomActionBar(
              onCancel: () => Navigator.pop(context),
              onSubmit: () async {
                final provider =
                    Provider.of<AccountListProvider>(context, listen: false);

                try {
                  await provider.updateRecommendationApi(
                    context,
                    widget.item.locationId!,
                    buildSubmitPayload(), // ✅ payload map
                  );

                  if (mounted) {
                    Navigator.pop(context, true); // optional result
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Failed to update parameters"),
                    ),
                  );
                }
              },

              // onSubmit: () async {
              //   await Provider.of<AccountListProvider>(
              //     context,
              //     listen: false,
              //   ).updateRecommendationApi(
              //     context,
              //     widget.item.locationId!,
              //     buildSubmitPayload(), // ✅ CORRECT
              //   );
              // },
            ),
            body: Consumer<UserProfileProvider>(
                builder: (context, userProfileProvider, child) {
              return PopScope(
                canPop: /*_selectedScreen == Screens.connectionList ||
                          _selectedScreen == Screens.corporateConnectionList,*/
                    true,
                onPopInvoked: (canPop) {
                  print('Can Pop: $canPop, Selected Screen: $_selectedScreen');
                },
                child: Stack(
                  children: [
                    // Background image
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.3,
                        child: Image.asset(
                          'assets/images/mesh.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: CustomSpacing.two),
                                Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                          6), // small radius
                                      child: CachedNetworkImage(
                                        imageUrl:
                                            "https://maps.googleapis.com/maps/api/streetview?size=600x300&location=${widget.item.latitude},${widget.item.longitude}&key=AIzaSyBA8NoBrHa9JwGQT8Mk1s9lXqElfON_NGI",
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                widget.item.locationName ?? "-",
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style:
                                                    typography.Body2.copyWith(
                                                        color: Colors.blue[300],
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontSize: 16),
                                              ),
                                              InkWell(
                                                  onTap: () {
                                                    Navigator.pop(context);
                                                  },
                                                  child: Icon(Icons.close))
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            widget.item.address ?? "",
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: typography.Body2.copyWith(
                                                color: Colors.blue[300],
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            "${widget.item.totalUnfilledParameters} missing fields",
                                            style: typography.Caption.copyWith(
                                              color: Colors.white,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: CustomSpacing.two),
                                Expanded(
                                  child: TabBarView(
                                    controller: _tabController,
                                    children: [
                                      _getAccountUI(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_showOverlay) _buildOverlay(),
                  ],
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7), // dim background/ dim background
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF232323),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(11),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () async {
                    const url = 'https://www.youtube.com/watch?v=7kvdDtowGM0';
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url),
                          mode: LaunchMode.externalApplication);
                    }
                    ;
                  },
                  child: SizedBox(
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SvgPicture.asset(
                        'assets/images/userguide.svg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                const Text(
                  "New Account",
                  style: TextStyle(
                    color: AppColors.primaryMain,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  "Set up a primary account for your client or commercial entity. Add key company info to start building their digital risk data. ",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryMain,
                          side: const BorderSide(color: AppColors.primaryMain),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {},
                        child:
                            const Text("Skip", style: TextStyle(fontSize: 14)),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryMain,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        _showAddAccountDialog(context);
                      }, //_closeOverlay,
                      child: const Text("Add Account",
                          style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<List<TransferAutocompleteModel>> fetchAutocompleteUsers(
      String query) async {
    try {
      ApiService apiService =
          ApiService(AppConstant.TRANSFER_USER_AUTOCOMPLETE);
      String url = '?search=$query';
      var response = await apiService.get(url);

      // The response has 'result' array instead of 'users'
      List<TransferAutocompleteModel> users = (response['result'] as List)
          .map((user) => TransferAutocompleteModel.fromJson(user))
          .toList();

      return users;
    } catch (e) {
      print('Error fetching users: ${e.toString()}');
      return [];
    }
  }

  Future<void> _showAddAccountDialog(BuildContext context) async {
    var typography = CustomTypography(context);
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              clipBehavior: Clip.antiAliasWithSaveLayer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 500,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        LanguageService.getTranslated(
                            context, "account_list_app_add_account_title"),
                        style: typography.H5_Regular,
                      ),
                      SizedBox(height: 16.0),
                      Consumer<AccountListProvider>(
                        builder: (context, accountListProvider, child) {
                          return Column(
                            children: [
                              TextField(
                                controller: _textEditingController,
                                onChanged: (value) {
                                  setState(() {
                                    _accountAlreadyExists = false;
                                    _selectedAccount = null;
                                    accountListProvider.clearAutoCompleteList();
                                  });

                                  _autocompleteText = value;

                                  // Cancel the previous debounce timer
                                  if (_debounce?.isActive ?? false)
                                    _debounce!.cancel();

                                  // Start a new debounce timer
                                  _debounce =
                                      Timer(const Duration(milliseconds: 500),
                                          () async {
                                    await autoCompleteAccountsSearchClient(
                                        _autocompleteText);
                                  });
                                },
                                decoration: InputDecoration(
                                  suffixIcon: _textEditingController
                                          .text.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(Icons.clear),
                                          onPressed: () {
                                            setState(() {
                                              _textEditingController.clear();
                                              _accountAlreadyExists = false;
                                              _selectedAccount = null;
                                              accountListProvider
                                                  .clearAutoCompleteList();
                                            });
                                          },
                                        )
                                      : null,
                                  labelText: LanguageService.getTranslated(
                                      context,
                                      "account_list_app_add_account_title"),
                                  hintText: LanguageService.getTranslated(
                                      context,
                                      "account_list_app_add_account_title"),
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                              if (_textEditingController.text.isNotEmpty &&
                                  !_accountAlreadyExists)
                                AutocompleteOptions(
                                  options: accountListProvider
                                      .autoCompleteAccountList,
                                  onSelected: (Accounts selection) {
                                    setState(() {
                                      _accountAlreadyExists = true;
                                      _selectedAccount = selection;
                                      _textEditingController.text =
                                          selection.accountName!;
                                      // Clear the autocomplete list when an option is selected
                                      accountListProvider
                                          .clearAutoCompleteList();
                                    });
                                  },
                                  isLoading:
                                      accountListProvider.isAutoCompleteLoading,
                                ),
                            ],
                          );
                        },
                      ),
                      SizedBox(height: CustomSpacing.six),
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Consumer<AccountListProvider>(
                                    builder: (context, accountListProvider, _) {
                                  return accountListProvider.isAddAccountLoading
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                                width: 25,
                                                height: 25,
                                                child:
                                                    CircularProgressIndicator()),
                                          ],
                                        )
                                      : CustomButton(
                                          onPressed: () async {
                                            if (_autocompleteText.isEmpty) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                      content: Text(
                                                LanguageService.getTranslated(
                                                    context,
                                                    "account_list_app_add_account_empty_text_error"),
                                                style: typography.Body1,
                                              )));
                                              return;
                                            }

                                            if (!_accountAlreadyExists) {
                                              // Add account
                                              await accountListProvider
                                                  .addAccount(context,
                                                      _autocompleteText);
                                            } else {
                                              // Request access
                                              if (_messageController
                                                  .text.isEmpty) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(SnackBar(
                                                        content: Text(
                                                  LanguageService.getTranslated(
                                                      context,
                                                      "account_list_app_add_account_empty_text_error"),
                                                  style: TextStyle(
                                                      color: Colors.black),
                                                )));
                                                return;
                                              }
                                              await accountListProvider
                                                  .requestAccess(
                                                      context,
                                                      _selectedAccount
                                                              ?.accountId ??
                                                          "",
                                                      _messageController.text);
                                            }
                                            Navigator.pop(context);
                                          },
                                          child: Text(
                                            // _accountAlreadyExists
                                            //     ? LanguageService.getTranslated(
                                            //         context,
                                            //         "account_list_app_request_access_text")
                                            //     :
                                            LanguageService.getTranslated(
                                                context,
                                                "account_list_app_submit_text"),
                                            style: typography.ButtonLargeBlack,
                                          ),
                                          type: ButtonType.elevated,
                                        );
                                }),
                              ),
                            ],
                          ),
                          CustomButton(
                            onPressed: () {
                              // Cancel
                              _uploadedFileName = null;
                              _sovNameController.clear();
                              Navigator.pop(context);
                            },
                            child: Text(
                              LanguageService.getTranslated(
                                  context, "account_list_app_cancel_text"),
                              style: typography.ButtonLarge,
                            ),
                            type: ButtonType.text,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      // Clear the autocomplete list when the dialog is dismissed
      Provider.of<AccountListProvider>(context, listen: false)
          .clearAutoCompleteList();
      _textEditingController.clear();
      _messageController.clear();
      _accountAlreadyExists = false;
    });
  }

  _getComingSoonUI(String title) {
    var typography = CustomTypography(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Column(
              children: [
                Text(
                    title == "shared"
                        ? 'A smarter way to track shared files-Coming Soon! '
                        : 'A smarter way to track access requests – Coming Soon!',
                    textAlign: TextAlign.center,
                    style: typography.H5_Regular),
                SizedBox(height: 10),
                Text(
                    LanguageService.getTranslated(
                        context, 'coming_soon_subtitle'),
                    textAlign: TextAlign.center,
                    style: typography.Body1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getAccountUI() {
    final typography = CustomTypography(context);

    return Consumer<AccountListProvider>(
      builder: (context, provider, _) {
        if (!provider.hasLoadedOnce) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.parameterList.isEmpty) {
          return Center(
            child: Text(
              "No parameters to update",
              style: typography.Body1,
            ),
          );
        }

        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: provider.parameterList.length +
              (provider.isNextPageLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == provider.parameterList.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final param = provider.parameterList[index];
            return _buildParameterCard(param);
          },
        );
      },
    );
  }

  Map<String, dynamic> _extractInitialMap(Accounts param) {
    final raw = param.parameterValue?.value;
    if (raw == null || raw.toString().trim().isEmpty) return {};
    try {
      return jsonDecode(raw);
    } catch (_) {
      return {"value": raw.toString()};
    }
  }

  String _getParamType(Accounts param) {
    return param.parameterType?.name?.toLowerCase() ?? "";
  }

  Widget _buildParameterCard(Accounts param) {
    final typography = CustomTypography(context);
    final String baseKey = param.dataCategoryId!;
    final String type = _getParamType(param);

    /// Parse initial API value
    Map<String, dynamic> initialData = {};
    try {
      if (param.parameterValue?.value != null &&
          param.parameterValue!.value!.isNotEmpty) {
        initialData = jsonDecode(param.parameterValue!.value!);
      }
    } catch (_) {}
    _initialValues.putIfAbsent(
      baseKey,
      () => Map<String, dynamic>.from(initialData),
    );

    TextEditingController _getController(String field) {
      final fullKey = "$baseKey:$field";

      return _valueControllers.putIfAbsent(fullKey, () {
        final c = TextEditingController();

        final value = initialData[field]?.toString() ?? "";
        c.text = value;

        _fieldErrors[fullKey] = value.trim().isEmpty;

        return c;
      });
    }

    // bool _hasError(String field) => _fieldErrors["$baseKey:$field"] ?? false;
    bool _hasError(String field) {
      final key = "$baseKey:$field";

      _fieldErrors.putIfAbsent(
        key,
        () => _getController(field).text.trim().isEmpty,
      );

      return _fieldErrors[key]!;
    }

    void _setError(String field, bool value) {
      _fieldErrors["$baseKey:$field"] = value;
    }

    final existingDate = DateTime.tryParse(
      _getController("valuation_date").text,
    );
    final bool hasCurrency = param.paramConfig?.enableCurrencySelection == true;
    final bool hasValuationDate =
        param.paramConfig?.enableValuationDateSelection == true;
    final currencyController = _getController("currency");

    List<Map<String, String>> currencyJson = [
      {"code": "USD", "name": "US Dollar"},
      {"code": "CAD", "name": "Canadian Dollar"},
      {"code": "EUR", "name": "Euro"},
      {"code": "AED", "name": "United Arab Emirates Dirham"},
      {"code": "AFN", "name": "Afghan Afghani"},
      {"code": "ALL", "name": "Albanian Lek"},
      {"code": "AMD", "name": "Armenian Dram"},
      {"code": "ARS", "name": "Argentine Peso"},
      {"code": "AUD", "name": "Australian Dollar"},
      {"code": "AZN", "name": "Azerbaijani Manat"},
      {"code": "BAM", "name": "Bosnia-Herzegovina Convertible Mark"},
      {"code": "BDT", "name": "Bangladeshi Taka"},
      {"code": "BGN", "name": "Bulgarian Lev"},
      {"code": "BHD", "name": "Bahraini Dinar"},
      {"code": "BIF", "name": "Burundian Franc"},
      {"code": "BND", "name": "Brunei Dollar"},
      {"code": "BOB", "name": "Bolivian Boliviano"},
      {"code": "BRL", "name": "Brazilian Real"},
      {"code": "BWP", "name": "Botswanan Pula"},
      {"code": "BYN", "name": "Belarusian Ruble"},
      {"code": "BZD", "name": "Belize Dollar"},
      {"code": "CDF", "name": "Congolese Franc"},
      {"code": "CHF", "name": "Swiss Franc"},
      {"code": "CLP", "name": "Chilean Peso"},
      {"code": "CNY", "name": "Chinese Yuan"},
      {"code": "COP", "name": "Colombian Peso"},
      {"code": "CRC", "name": "Costa Rican Colón"},
      {"code": "CVE", "name": "Cape Verdean Escudo"},
      {"code": "CZK", "name": "Czech Republic Koruna"},
      {"code": "DJF", "name": "Djiboutian Franc"},
      {"code": "DKK", "name": "Danish Krone"},
      {"code": "DOP", "name": "Dominican Peso"},
      {"code": "DZD", "name": "Algerian Dinar"},
      {"code": "EEK", "name": "Estonian Kroon"},
      {"code": "EGP", "name": "Egyptian Pound"},
      {"code": "ERN", "name": "Eritrean Nakfa"},
      {"code": "ETB", "name": "Ethiopian Birr"},
      {"code": "GBP", "name": "British Pound Sterling"},
      {"code": "GEL", "name": "Georgian Lari"},
      {"code": "GHS", "name": "Ghanaian Cedi"},
      {"code": "GNF", "name": "Guinean Franc"},
      {"code": "GTQ", "name": "Guatemalan Quetzal"},
      {"code": "HKD", "name": "Hong Kong Dollar"},
      {"code": "HNL", "name": "Honduran Lempira"},
      {"code": "HRK", "name": "Croatian Kuna"},
      {"code": "HUF", "name": "Hungarian Forint"},
      {"code": "IDR", "name": "Indonesian Rupiah"},
      {"code": "ILS", "name": "Israeli New Sheqel"},
      {"code": "INR", "name": "Indian Rupee"},
      {"code": "IQD", "name": "Iraqi Dinar"},
      {"code": "IRR", "name": "Iranian Rial"},
      {"code": "ISK", "name": "Icelandic Króna"},
      {"code": "JMD", "name": "Jamaican Dollar"},
      {"code": "JOD", "name": "Jordanian Dinar"},
      {"code": "JPY", "name": "Japanese Yen"},
      {"code": "KES", "name": "Kenyan Shilling"},
      {"code": "KHR", "name": "Cambodian Riel"},
      {"code": "KMF", "name": "Comorian Franc"},
      {"code": "KRW", "name": "South Korean Won"},
      {"code": "KWD", "name": "Kuwaiti Dinar"},
      {"code": "KZT", "name": "Kazakhstani Tenge"},
      {"code": "LBP", "name": "Lebanese Pound"},
      {"code": "LKR", "name": "Sri Lankan Rupee"},
      {"code": "LTL", "name": "Lithuanian Litas"},
      {"code": "LVL", "name": "Latvian Lats"},
      {"code": "LYD", "name": "Libyan Dinar"},
      {"code": "MAD", "name": "Moroccan Dirham"},
      {"code": "MDL", "name": "Moldovan Leu"},
      {"code": "MGA", "name": "Malagasy Ariary"},
      {"code": "MKD", "name": "Macedonian Denar"},
      {"code": "MMK", "name": "Myanma Kyat"},
      {"code": "MOP", "name": "Macanese Pataca"},
      {"code": "MUR", "name": "Mauritian Rupee"},
      {"code": "MXN", "name": "Mexican Peso"},
      {"code": "MYR", "name": "Malaysian Ringgit"},
      {"code": "MZN", "name": "Mozambican Metical"},
      {"code": "NAD", "name": "Namibian Dollar"},
      {"code": "NGN", "name": "Nigerian Naira"},
      {"code": "NIO", "name": "Nicaraguan Córdoba"},
      {"code": "NOK", "name": "Norwegian Krone"},
      {"code": "NPR", "name": "Nepalese Rupee"},
      {"code": "NZD", "name": "New Zealand Dollar"},
      {"code": "OMR", "name": "Omani Rial"},
      {"code": "PAB", "name": "Panamanian Balboa"},
      {"code": "PEN", "name": "Peruvian Nuevo Sol"},
      {"code": "PHP", "name": "Philippine Peso"},
      {"code": "PKR", "name": "Pakistani Rupee"},
      {"code": "PLN", "name": "Polish Zloty"},
      {"code": "PYG", "name": "Paraguayan Guarani"},
      {"code": "QAR", "name": "Qatari Rial"},
      {"code": "RON", "name": "Romanian Leu"},
      {"code": "RSD", "name": "Serbian Dinar"},
      {"code": "RUB", "name": "Russian Ruble"},
      {"code": "RWF", "name": "Rwandan Franc"},
      {"code": "SAR", "name": "Saudi Riyal"},
      {"code": "SDG", "name": "Sudanese Pound"},
      {"code": "SEK", "name": "Swedish Krona"},
      {"code": "SGD", "name": "Singapore Dollar"},
      {"code": "SOS", "name": "Somali Shilling"},
      {"code": "SYP", "name": "Syrian Pound"},
      {"code": "THB", "name": "Thai Baht"},
      {"code": "TND", "name": "Tunisian Dinar"},
      {"code": "TOP", "name": "Tongan Paʻanga"},
      {"code": "TRY", "name": "Turkish Lira"},
      {"code": "TTD", "name": "Trinidad and Tobago Dollar"},
      {"code": "TWD", "name": "New Taiwan Dollar"},
      {"code": "TZS", "name": "Tanzanian Shilling"},
      {"code": "UAH", "name": "Ukrainian Hryvnia"},
      {"code": "UGX", "name": "Ugandan Shilling"},
      {"code": "UYU", "name": "Uruguayan Peso"},
      {"code": "UZS", "name": "Uzbekistan Som"},
      {"code": "VEF", "name": "Venezuelan Bolívar"},
      {"code": "VND", "name": "Vietnamese Dong"},
      {"code": "XAF", "name": "CFA Franc BEAC"},
      {"code": "XOF", "name": "CFA Franc BCEAO"},
      {"code": "YER", "name": "Yemeni Rial"},
      {"code": "ZAR", "name": "South African Rand"},
      {"code": "ZMK", "name": "Zambian Kwacha"},
      {"code": "ZWL", "name": "Zimbabwean Dollar"},
    ];
    final isIntegerField =
        param.parameterType?.name?.toLowerCase() == "integer";
    final String? selectedCurrency = currencyJson.any(
      (c) => c['code'] == currencyController.text,
    )
        ? currencyController.text
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _hasError("value") ? Colors.red : const Color(0xFF2C2C2C),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TITLE
          Row(
            children: [
              Expanded(
                child: Text(
                  param.parameterNameA ?? "",
                  style: typography.Body2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_hasError("value"))
                Text(
                  "Missing",
                  style: typography.Body2.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          /// VALUE
          TextField(
            controller: _getController("value"),
            keyboardType:
                isIntegerField ? TextInputType.number : TextInputType.text,
            inputFormatters:
                isIntegerField ? [FilteringTextInputFormatter.digitsOnly] : [],
            decoration: _buildDecoration(
              _hasError("value"),
              param.parameterNameA ?? "Value",
            ),
            onChanged: (v) {
              _setError("value", v.trim().isEmpty);
              setState(() {});
            },
          ),
          // TextField(
          //   controller: _getController("value"),
          //   decoration: _buildDecoration(
          //     _hasError("value"),
          //     param.parameterNameA ?? "Value",
          //   ),
          //   onChanged: (v) {
          //     _setError("value", v.trim().isEmpty);
          //     setState(() {});
          //   },
          // ),

          const SizedBox(height: 14),
          if (hasCurrency) ...[
            DropdownButtonFormField<String>(
              isExpanded: true,
              // ✅ REQUIRED
              value: selectedCurrency,
              decoration: _buildDecoration(_hasError("currency"), "Currency"),
              items: currencyJson.map((c) {
                return DropdownMenuItem<String>(
                  value: c['code'],
                  child: Text(
                    "${c['name']} (${c['code']})",
                    overflow: TextOverflow.ellipsis, // ✅ prevent overflow
                    maxLines: 1,
                  ),
                );
              }).toList(),
              onChanged: (v) {
                currencyController.text = v ?? "";
                _setError("currency", v == null);
                setState(() {});
              },
            ),
            const SizedBox(height: 14),
          ],

          if (hasValuationDate) ...[
            GestureDetector(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  firstDate: DateTime(1970),
                  lastDate: DateTime(2100),
                  initialDate: existingDate ?? DateTime.now(),
                );
                if (date != null) {
                  _getController("valuation_date").text =
                      DateFormat('yyyy-MM-dd').format(date);
                  _setError("valuation_date", false);
                  setState(() {});
                }
              },
              child: AbsorbPointer(
                child: TextField(
                  controller: _getController("valuation_date"),
                  decoration: _buildDecoration(
                    _hasError("valuation_date"),
                    "Valuation Date",
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _updateValue(String key, String value) {
    _valueControllers[key]!.text = value;
    _fieldErrors[key] = value.trim().isEmpty;
    setState(() {});
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required bool hasError,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      decoration: _buildDecoration(hasError, hint),
      style: const TextStyle(color: Colors.white),
    );
  }

  InputDecoration _buildDecoration(bool hasError, String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      labelText: hint,
      fillColor: const Color(0xFF1E1E1E),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(
          color: Colors.white60,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(
          color: Colors.white,
        ),
      ),
    );
  }
}
