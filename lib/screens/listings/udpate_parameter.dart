import 'package:RiskSphere/screens/listings/widgets/auto_complete_options.dart';
import 'package:tuple/tuple.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/global_imports.dart';
import 'package:flutter/cupertino.dart';
import 'package:RiskSphere/models/account_list_model.dart';

class UpdateParameterScreen extends StatefulWidget {
  static const String routeName = '/updateparameter';

  const UpdateParameterScreen({
    super.key,
  });

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

  String? _uploadedFileName;

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool showCheckbox = false;

  Timer? deBouncer;

  TextEditingController _accountEditNameController = TextEditingController();

  int _selectedAccountIndex = 0;
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
      await provider.fetchAccountList(context, _accountQuery, provider.page, 5);
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
    print("autoCompleteAccountsSearchClient called with query: $query");
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

  GlobalKey keyFeature1 = GlobalKey();
  GlobalKey keyFeature2 = GlobalKey();
  GlobalKey keyFeature3 = GlobalKey();
  List<TargetFocus> targets = [];
  TutorialCoachMark? tutorialCoachMark;
  bool _showOverlay = false;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
    var userProfileProvider =
        Provider.of<UserProfileProvider>(context, listen: false);
    final trialStatus = userProfileProvider.trialInfo['status'] ?? '';
    int tabCount = (trialStatus.isEmpty) ? 4 : 3;
    _tabController = TabController(length: tabCount, vsync: this);
    Future.microtask(() => _getData());
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _getData();
    // });
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('isFirstTime') ?? true;
    if (isFirstTime) {
      setState(() => _showOverlay = true);
    }
  }

  Future<void> _closeOverlay() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
        'isFirstTime', false); // 👈 save only when user closes it
    setState(() => _showOverlay = false);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _filePathController.dispose();
    super.dispose();
  }

  _getData() async {
    final futures = await Future.wait([
      SharedPreferenceService.getHasAnyPlan(),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.IS_PG_ADMIN),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.IS_ADMIN),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.IS_SUPER_ADMIN),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.Is_Indivudual),
    ]);

    hasAnyPlan = futures[0] ?? false;
    isPgAdmin = futures[1] ?? false;
    isAdmin = futures[2] ?? false;
    isSuperAdmin = futures[3] ?? false;
    isIndivudual = futures[4] ?? false;

    final accountListProvider =
        Provider.of<AccountListProvider>(context, listen: false);

    await accountListProvider.fetchAccountList(context, "", 1, 4);
    setState(() => _selectedScreen = Screens.accountList);
  }

  Widget _buildBottomActionBar({
    required VoidCallback onCancel,
    required VoidCallback? onSubmit,
    bool isSubmitEnabled = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // dark background
        border: Border(
          top: BorderSide(color: const Color(0xFF2C2C2C), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          /// Cancel Button
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(
                color: AppColors.primaryMain,
              ),
              // blue border
              foregroundColor: AppColors.primaryMain,
              // blue text
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onPressed: onCancel,
            child: const Text(
              "Cancel",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(width: 10),

          /// Submit Button (Disabled Style)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isSubmitEnabled
                  ? AppColors.primaryMain
                  : AppColors.primaryMain,
              foregroundColor: isSubmitEnabled
                  ? AppColors.primaryMain
                  : AppColors.primaryMain,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onPressed: onSubmit,
            child: const Text(
              "Submit",
              style: TextStyle(
                fontSize: 14,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context1) {
    var typography = CustomTypography(context);
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
              onSubmit: () {
                // handle submit
              },
              isSubmitEnabled: false, // true to enable
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
                                //
                                SizedBox(height: CustomSpacing.two),

                                Expanded(
                                  child: TabBarView(
                                    controller: _tabController,
                                    children: [
                                      _getAccountUI(),
                                      _getComingSoonUI("shared"),
                                      if (isSuperAdmin || isPgAdmin) ...[
                                        ConfigurationTab(),
                                      ],
                                      _getComingSoonUI("request"),
                                      // Consumer<AccountListProvider>(
                                      //   builder: (context, accountListProvider, _) {
                                      //     final accountId = accountListProvider.accountList.isNotEmpty
                                      //         ? accountListProvider.accountList[0].accountId ?? ""
                                      //         : "";
                                      //     return DataTab(
                                      //       accountName: accountListProvider.accountList[0].accountName ?? "",
                                      //       accountId: accountId,
                                      //       subaccountId: accountId,
                                      //     );
                                      //   },
                                      // ),
                                      // DataTab(
                                      //   accountId:"",
                                      //   // userProfileProvider.accountList.isNotEmpty
                                      //   //     ? userProfileProvider.accountList[0].accountId ?? ""
                                      //   //     : "",
                                      //   subaccountId: null,
                                      // ),
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
                        onPressed: _closeOverlay,
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
                        _closeOverlay();
                        _showAddAccountDialog(context);
                      }, //_closeOverlay,
                      child: const Text("Add Account",
                          style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
                // const SizedBox(height: 16),
                // const Text(
                //   "New Account",
                //   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                // ),
                // const SizedBox(height: 8),
                // const Text(
                //   "Create a primary account to organize your sub accounts and locations.",
                //   // textAlign: TextAlign.center,
                // ),
                // const SizedBox(height: 20),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //   children: [
                //     TextButton(
                //       onPressed: _closeOverlay,
                //       child: const Text("Skip"),
                //     ),
                //     ElevatedButton(
                //       onPressed: _closeOverlay,
                //       child: const Text("Add Account"),
                //     ),
                //   ],
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountCard(int index, AccountListProvider accountListProvider) {
    final account = accountListProvider.accountList[index];
    final typography = CustomTypography(context);
    final isDisabled = account.disabled ?? false;

    // you can make this stateful

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A), // dark background
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2C2C2C), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          /// 🏷️ Field 1: Geocoding Type
          _buildInputField("Geocoding Type", "Enter the field", typography),
        ],
      ),
    );
  }

  /// 🔹 Reusable Filter Tab Widget
  Widget _buildFilterTab(String title, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryMain : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.primaryMain : AppColors.primaryMain,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.black : AppColors.primaryMain,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// 🏷️ Reusable Input Field
  Widget _buildInputField(
      String label, String hint, CustomTypography typography) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: typography.Body2.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 11),
        TextField(
          style: TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: typography.Caption.copyWith(color: Colors.grey[300]),
            filled: true,
            fillColor: const Color(0xFF2A2A2A),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.white60, width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Colors.white60, width: 1),
            ),
          ),
        ),
      ],
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
    var typography = CustomTypography(context);
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'Zerozilla',
                  style: typography.Body1,
                ),
                SizedBox(width: 5),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "10".toString().padLeft(2, '0') ?? '00',
                    style: typography.Caption.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => UpdateParameterScreen()));
              },
              borderRadius: BorderRadius.circular(6),
              child: const Icon(Icons.edit,
                  size: 16, color: AppColors.primaryMain),
            ),
          ],
        ),
        SizedBox(height: CustomSpacing.four),

        /// 🔹 Filter Tabs ("All" and "Missing")
        Row(
          children: [
            _buildFilterTab("All", selectedFilter == "All", () {
              // handle "All" click
            }),
            const SizedBox(width: 8),
            _buildFilterTab("Missing", selectedFilter == "Missing", () {
              // handle "Missing" click
            }),
          ],
        ),
        SizedBox(height: CustomSpacing.four),
        // List of accounts
        Expanded(
          child: Selector<AccountListProvider,
              Tuple4<bool, bool, int, List<Accounts>>>(
            selector: (_, provider) => Tuple4(
              provider.isLoading,
              provider.isNextPageLoading,
              provider.page,
              provider.accountList,
            ),
            builder: (context, data, _) {
              final isLoading = data.item1;
              final isNextPageLoading = data.item2;
              final currentPage = data.item3;
              final accountList = data.item4;

              if (isLoading && accountList.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (accountList.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "Looks like you don't have an account yet. No worries! Just create a new one and start adding your locations.",
                      textAlign: TextAlign.center,
                      style: CustomTypography(context).Body1,
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await Provider.of<AccountListProvider>(context, listen: false)
                      .fetchAccountList(context, _accountQuery, 1, 5);
                },
                child: NotificationListener<ScrollNotification>(
                  onNotification: (scrollInfo) {
                    if (!isNextPageLoading &&
                        scrollInfo.metrics.pixels >=
                            scrollInfo.metrics.maxScrollExtent - 200) {
                      Provider.of<AccountListProvider>(context, listen: false)
                          .fetchAccountList(
                              context, _accountQuery, currentPage + 1, 5);
                    }
                    return false;
                  },
                  child: ListView.builder(
                    key: const PageStorageKey('accountListView'),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: accountList.length + (isNextPageLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= accountList.length) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final account = accountList[index];
                      return _buildAccountCard(
                          index,
                          Provider.of<AccountListProvider>(context,
                              listen: false));

                      // return _buildAccountCard(context, account, index);
                    },
                  ),
                ),
              );
            },
          ),
        )
      ],
    );
  }
}
