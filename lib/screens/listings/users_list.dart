import '../../models/my_location_list_model.dart';
import '../../utils/global_imports.dart';
import '../../models/sov_list_model.dart';
import 'package:RiskSphere/models/role_model.dart' as roleModel;

import '../userManagement/user_management.dart';

class UsersList extends StatefulWidget {
  final String? status;
  final String? accountID;
  final String? subAccountID;
  final String accountName;
  final String subAccountName;
  final String? initialProcessId;
  final String? initialSubProcessId;

  const UsersList({
    super.key,
    this.status,
    this.accountID,
    this.subAccountID,
    this.accountName = '',
    this.subAccountName = '',
    this.initialProcessId,
    this.initialSubProcessId,
  });

  @override
  State<UsersList> createState() => _VendorListState();
}

class _VendorListState extends State<UsersList> with TickerProviderStateMixin {
  Timer? _refreshTimer;
  static bool _hasActiveTimer = false;
  bool _isExpanded = false;
  bool sovDeleteStatus = false;
  bool _showNotificationDot = true;
  TabController? _masterTabController;
  late TabController _tabController;
  String selectedProcessId = "";
  bool isSelectionMode = false;
  List<bool> selectedList = [];
  String isMaintenance = "";
  String selectedVendor = '';
  List<Results> _dedupedVendors = [];
  String? trialMap;
  bool isFilterApplied = false; // 🔥 controls filter icon highlight
  List<Result> allVendorList = [];
  List<Result> filteredAutoCompleteList1 = [];

  String locationQuery = '';
  String dateView = 'yearly';
  String corporateSort = 'asc'; // asc | desc
  String userSort = 'asc';
  bool isHasAnyPlan = false;
  List<String> UsersList = [];
  Screens _selectedScreen = Screens.locationList;
  TextEditingController _sovNameEditNameController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  String selectedDropdown = 'TPV';
  int? touchedIndex; // For showing overlay info
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showOverlay_mylocation = false;
  int requestActionIndex = 0;
  bool _isLoading = false;
  List<roleModel.Roles> filterRoleList = [];
  List<roleModel.Roles> filterRoles = [];
  List<String> filterNames = [];
  List<String> filterEmails = [];
  List<String> filterPhones = [];
  List<String> filterCompanies = [];
  List<String> filterStatus = [];
  roleModel.Roles? selectedRoleForFilter;
  String selectedStatus = '';
  bool showSelectAll = false;
  bool isAllSelected = false;
  Timer? deBouncer;
  List<MyLocation> selectedLocations = [];
  File? files;
  TabController? _mainTabController;
  int selectedMainTab = 0;
  int selectedTab = 0;
  int selectedMasterTab = 0;
  Set<String> selectedSovIds = {};

  String _sovQuery = "";
  bool showCheckbox = false;
  bool showNonCorporateManagementTab = true;
  bool showCorporateManagementTab = true;
  bool showEmployeeManagementTab = true;
  bool showCorporateList = true;
  bool showCorporateUserListDropdown = true;
  bool showCorporateVerificationTab = true;
  bool showCorporateProfile = true;
  bool addToSOVCheck = false;
  bool isLoading = false;
  var conflictLocations;
  bool hasAnyPlan = false;
  String? hasLicenseStatus = "1";
  String? hasGeocodingStatus = "1";
  String? hasHazardLicenseStatus = "1";
  List<TargetFocus> targets = [];

  String selectedSovId = "";
  TextEditingController sovController = TextEditingController();
  TextEditingController tagController = TextEditingController();

  bool isUploadInProgress = false;

  void debounce(VoidCallback callback,
      {Duration duration = const Duration(seconds: 1)}) {
    if (deBouncer != null) {
      deBouncer!.cancel();
    }
    deBouncer = Timer(duration, callback);
  }

  final ScrollController _scrollController = ScrollController();
  bool isProcessing = false;

  int? selectedVendorIndex; // null = All
  @override
  void initState() {
    super.initState();

    final provider = context.read<SOVListProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.page = 1;

      provider.fetchUserList(
        context,
        "",
        1,
        10,
        widget.status,
      );
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        final provider = context.read<SOVListProvider>();

        // ✅ Prevent multiple calls
        if (!provider.isNextPageLoading && !provider.isLoading) {
          provider.fetchUserList(
            context,
            "",
            provider.page + 1, // 👉 next page
            10,
            widget.status,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context1) {
    var typography = CustomTypography(context);
    return SafeArea(
      child: Consumer<SOVListProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            appBar: CustomAppBar(
              hasAnyPlan: hasAnyPlan,
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
            body: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.only(left: 10),
                      child: Text("User Management",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          )),
                    ),
                  ],
                ),

                /// 🔥 FILTERS
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              label: "User Type",
                              value: provider.selectedUserType,
                              items: provider.userTypes,
                              onChanged: (val) {
                                provider.selectedUserType = val!;
                                provider.applyFilters(); // ✅ Apply immediately
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildDropdown(
                              label: "Status",
                              value: provider.selectedStatus,
                              items: provider.statusList,
                              onChanged: (val) {
                                provider.selectedStatus = val!;
                                provider.applyFilters(); // ✅ Apply immediately
                              },
                            ),
                          ),
                          // Expanded(
                          //   child: _buildDropdown(
                          //     label: "Role",
                          //     value: provider.selectedRole,
                          //     items: provider.roles,
                          //     onChanged: (val) {
                          //       provider.selectedRole = val!;
                          //       provider.applyFilters(); // ✅ Apply immediately
                          //     },
                          //   ),
                          // ),
                        ],
                      ),
                      // const SizedBox(height: 10),
                    ],
                  ),
                ),

                Expanded(
                  child: Consumer<SOVListProvider>(
                    builder: (context, provider, _) {
                      // ✅ Show loading
                      if (provider.isLoading) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      // ✅ Show empty state
                      if (provider.filteredUserList.isEmpty) {
                        return const Center(
                          child: Text(
                            "No Users Found",
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        // ✅ IMPORTANT
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: provider.filteredUserList.length +
                            (provider.isNextPageLoading ? 1 : 0),
                        // ✅ loader item
                        itemBuilder: (context, index) {
                          // ✅ Show loader at bottom
                          if (index == provider.filteredUserList.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final user = provider.filteredUserList[index];
                          return _buildUserCard(index, user);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            bottomNavigationBar: Container(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5DADE2),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: () {
                  Provider.of<DrawerSelectionProvider>(context, listen: false)
                      .setSelectedItem('user_management');

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => UserManagementScreen(
                        initialIndex: 0,
                        subIndex: 0,
                        initialScreen: Screens.corporateEmployeeAdd,
                      ),
                    ),
                  );
                },
                // onPressed: () {
                //   _showAddUserBottomSheet(context);
                // },
                icon: const Icon(Icons.person_add, color: Colors.white),
                label: const Text(
                  "Add User",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

// ✅ Updated _buildUserCard to accept UserResult
  Widget _buildUserCard(int index, UserResult user) {
    final bool isVerified = user.isVerified ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isVerified
                      ? Colors.green.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isVerified ? "Verified" : "Pending",
                  style: TextStyle(
                    color: isVerified ? Colors.green : Colors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  final provider = context.read<SOVListProvider>();

                  provider.companyCredits = null;

                  _showCreditsOverviewBottomSheet(context, user);

                  provider.fetchCompanyCredits(
                    context,
                    user.companyId ?? "",
                  );
                },
                child: const Icon(Icons.more_vert, color: Colors.white70),
              )
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey.shade800,
                child: Text(
                  (user.name != null && user.name!.isNotEmpty)
                      ? user.name!.substring(0, 2).toUpperCase()
                      : "U",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name ?? "No Name",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email ?? "",
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 10),
          _infoRow("User Type", user.userType ?? "NA"),
          const SizedBox(height: 6),
          if (user.roles != null && user.roles!.isNotEmpty)
            Wrap(
              spacing: 6,
              children: user.roles!.map((role) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    role,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 10),
          Text(
            "Last Active: ${user.lastLogin ?? "NA"}",
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    String? hintText, // ✅ NEW: Optional hint text
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// LABEL (Above the dropdown)
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),

        /// DROPDOWN WITH HINT INSIDE BORDER
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white24),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E1E1E),

              /// 🔥 HINT TEXT - Shows when no value selected
              hint: Text(
                hintText ?? label, // Use custom hint or label as fallback
                style: const TextStyle(
                  color: Colors.white54, // Slightly faded color
                  fontSize: 14,
                ),
              ),

              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white70,
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              items: items.map((e) {
                return DropdownMenuItem(
                  value: e,
                  child: Text(e),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: "$label : ",
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreditsOverviewBottomSheet(
    BuildContext context,
    UserResult user,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Consumer<SOVListProvider>(
          builder: (context, provider, _) {
            if (provider.isCreditsLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final credits = provider.companyCredits;

            // if (credits == null) {
            //   return const Center(
            //
            //     child: Text("No Data", style: TextStyle(color: Colors.white)),
            //   );
            // }

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// TITLE
                  const Text(
                    "Credits Overview",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  Text(user.name ?? "",
                      style: const TextStyle(color: Colors.white70)),
                  Text(user.email ?? "",
                      style: const TextStyle(color: Colors.white54)),

                  const SizedBox(height: 20),

                  /// LOCATION
                  _creditSection("Location Count", ""),

                  const SizedBox(height: 20),

                  /// IMPROVEMENT
                  _creditSection("Improvement Credits", 1),

                  const SizedBox(height: 20),

                  /// USER
                  _creditSection("User Credits", ""),

                  const SizedBox(height: 20),

                  /// CLOSE BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close"),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _creditSection(String title, dynamic item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildCreditCard("Total Credits", "00".toString()),
            _buildCreditCard("Used", "00".toString()),
            _buildCreditCard("Remaining", "00".toString()),
          ],
        ),
      ],
    );
  }

  Widget _buildCreditCard(String title, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A), // dark card bg
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// TITLE
            Text(
              title,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),

            const SizedBox(height: 8),

            /// VALUE
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildCreditCard({
  required String title,
  required String value,
}) {
  return Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: Colors.white12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    ),
  );
}

Widget _buildFormDropdown({
  required String label,
  required String value,
  required List<String> items,
  required Function(String?) onChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        value: value,
        style: const TextStyle(color: Colors.white),
        dropdownColor: const Color(0xFF1E1E1E),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ],
  );
}

Widget _buildTextFormField({
  required TextEditingController controller,
  required String label,
  required String hintText,
  required IconData prefixIcon,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.white54),
          prefixIcon: Icon(prefixIcon, color: Colors.white54),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ],
  );
}
