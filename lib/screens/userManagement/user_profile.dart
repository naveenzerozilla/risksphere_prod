// import 'package:RiskSphere/models/user_corporate_model.dart';
// import 'package:cached_network_image/cached_network_image.dart';
//
// import '../../models/user_profile_model.dart';
// import '../../utils/global_imports.dart';
// import 'package:RiskSphere/models/networking_model.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:phone_input/phone_input_package.dart';
// import '../../design_system/components/custom_flexible_roles_bottom_sheet.dart';
// import '../../design_system/components/roles_bottom_sheet.dart';
// import '../../design_system/repo/constants.dart';
// import '../../models/initial_data_model.dart';
// import 'package:image/image.dart' as img;
// import '../../utils/utils.dart';
//
// class ProfileScreen extends StatefulWidget {
//   const ProfileScreen({super.key});
//
//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }
//
// class _ProfileScreenState extends State<ProfileScreen>
//     with SingleTickerProviderStateMixin {
//   bool _isExpanded = false;
//   bool _showNotificationDot = true;
//   TabController? _tabController;
//   Screens _selectedScreen = Screens.connectionList;
//   List<Categories> _selectedRoles = [];
//   List<AcceptedRole> _selectedAcceptRole = [];
//
//   TextEditingController _textEditingController = TextEditingController();
//   SignUpOptions? _selectedOption;
//   String _selectedCountryCode = '+1';
//   TextEditingController mobileController = TextEditingController();
//   final TextEditingController phoneController = TextEditingController();
//
//   // PhoneController phoneController =
//   //     PhoneController(PhoneNumber(isoCode: IsoCode.US, nsn: ''));
//
//   GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
//
//   // form key
//   final _formKey = GlobalKey<FormState>();
//
//   bool isEdit = false;
//
//   bool showAssignDeleteManager = true;
//   bool showAddDelegate = true;
//   bool showRevokeDelegate = true;
//   bool showAddReportee = true;
//   bool showEditUser = true;
//   bool showMyTeams = true;
//   bool isPgAdmin = false;
//   bool isAdmin = false;
//   bool isSuperAdmin = false;
//   bool isIndividual = false;
//
//   // General Info
//   String userImageUrl = '';
//   TextEditingController _nameGeneralInfoController = TextEditingController();
//   TextEditingController _displayNameGeneralInfoController =
//       TextEditingController();
//   TextEditingController _emailGeneralInfoController = TextEditingController();
//   TextEditingController _phoneGeneralInfoController = TextEditingController();
//   dynamic nameLabelText = "";
//   String displayNameLabelText = "";
//   String emailLabelText = "";
//   String phoneLabelText = "";
//   String selectedAvatar = "";
//   String selectedCountryCode = "+1";
//
//   // My Team
//   Timer? deBouncer;
//   List<NetworkingUsers> _managerList = [];
//   NetworkingUsers? _selectedManager;
//
//   bool _tabsLoading = true;
//   int _tabLength = 3;
//
//   void debounce(
//     VoidCallback callback, {
//     Duration duration = const Duration(seconds: 1),
//   }) {
//     if (deBouncer != null) {
//       deBouncer!.cancel();
//     }
//     deBouncer = Timer(duration, callback);
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     _setClaims();
//     _getData();
//   }
//
//   _setClaims() async {
//     _selectedScreen = Screens.generalInfo;
//     isPgAdmin = await SharedPreferenceService.getClaimForSubfeature(
//             SharedPreferenceService.IS_PG_ADMIN) ??
//         false;
//     isAdmin = await SharedPreferenceService.getClaimForSubfeature(
//             SharedPreferenceService.IS_ADMIN) ??
//         false;
//     isSuperAdmin = await SharedPreferenceService.getClaimForSubfeature(
//             SharedPreferenceService.IS_SUPER_ADMIN) ??
//         false;
//     isIndividual = await SharedPreferenceService.getClaimForSubfeature(
//             SharedPreferenceService.Is_Indivudual) ??
//         false;
//     // isPgAdmin = false;
//     // isAdmin = true;
//     // isSuperAdmin = true;
//     showAssignDeleteManager =
//         await SharedPreferenceService.getClaimForSubfeature(
//                 SharedPreferenceService.CUMAM) ??
//             false;
//     showAddDelegate = await SharedPreferenceService.getClaimForSubfeature(
//             SharedPreferenceService.CUMDA) ??
//         false;
//     showRevokeDelegate = await SharedPreferenceService.getClaimForSubfeature(
//             SharedPreferenceService.CUMRD) ??
//         false;
//     showAddReportee = await SharedPreferenceService.getClaimForSubfeature(
//             SharedPreferenceService.CUMRE) ??
//         false;
//     //showEditUser = await SharedPreferenceService.getClaimForSubfeature(SharedPreferenceService.CAMVC)??false;
//     print(
//         '1st claim: ${await SharedPreferenceService.getClaimForSubfeature(SharedPreferenceService.NCMEU) ?? false}');
//     print(
//         '2nd claim: ${await SharedPreferenceService.getClaimForSubfeature(SharedPreferenceService.CUMEU) ?? false}');
//     print(
//         '3rd claim: ${await SharedPreferenceService.getClaimForSubfeature(SharedPreferenceService.EMPEU) ?? false}');
//     showEditUser = (await SharedPreferenceService.getClaimForSubfeature(
//                 SharedPreferenceService.NCMEU) ??
//             false) ||
//         ((await SharedPreferenceService.getClaimForSubfeature(
//                     SharedPreferenceService.CUMEU) ??
//                 false) ||
//             (await SharedPreferenceService.getClaimForSubfeature(
//                     SharedPreferenceService.EMPEU) ??
//                 false));
//     bool showNonCorporateMyTeams =
//         await SharedPreferenceService.getClaimForSubfeature(
//                 SharedPreferenceService.NCMMT) ??
//             false;
//     bool showEmployeeMyTeams =
//         await SharedPreferenceService.getClaimForSubfeature(
//                 SharedPreferenceService.EMPMT) ??
//             false;
//     User user = FirebaseAuth.instance.currentUser!;
//     await user.getIdTokenResult().then((value) {
//       if (value.claims != null) {
//         if (value.claims!['isIndividual'] == true) {
//           showMyTeams = showNonCorporateMyTeams;
//           print('isIndividual: $showMyTeams');
//         } else if (value.claims!['internal'] == true) {
//           showMyTeams = showEmployeeMyTeams;
//           print('isInternal: $showMyTeams');
//         } else {
//           showMyTeams = true;
//           print('external: $showMyTeams');
//         }
//       }
//     });
//
//     if (!showMyTeams) {
//       _tabLength = 2;
//     }
//
//     _tabController = TabController(length: _tabLength, vsync: this);
//     _tabController?.addListener(() {
//       if (_tabLength == 3) {
//         if (_tabController?.index == 0) {
//           setState(() {
//             _selectedScreen = Screens.generalInfo;
//           });
//         } else if (_tabController?.index == 1) {
//           setState(() {
//             _selectedScreen = Screens.teamsScreen;
//           });
//         } else if (_tabController?.index == 2) {
//           setState(() {
//             _selectedScreen = Screens.securityScreen;
//           });
//         }
//       } else if (_tabLength == 2) {
//         if (_tabController?.index == 0) {
//           setState(() {
//             _selectedScreen = Screens.generalInfo;
//           });
//         } else if (_tabController?.index == 1) {
//           setState(() {
//             _selectedScreen = Screens.securityScreen;
//           });
//         }
//       }
//       print(
//           'Tab Index: ${_tabController?.index} Selected Screen: $_selectedScreen');
//     });
//     setState(() {
//       _tabsLoading = false;
//     });
//   }
//
//   _getData() {
//     Provider.of<UserProfileProvider>(context, listen: false)
//         .getAllUserData(context, '', '')
//         .then((value) {
//       if (value != null) {
//         setState(() {
//           userImageUrl = value.displayImageUrl ?? "";
//           nameLabelText = value.name.toString();
//           _nameGeneralInfoController.text = value.name.toString();
//           // displayNameLabelText = value.displayName ?? value.name ?? "";
//           _displayNameGeneralInfoController.text =
//               value.displayName.toString();
//           emailLabelText = value.email ?? "";
//           _emailGeneralInfoController.text = value.email ?? "";
//           phoneLabelText = value.phone ?? "";
//           _phoneGeneralInfoController.text = value.phone ?? "";
//           print('Country Code: ${value.countryCode}');
//           // remove '+' from country code
//           _selectedCountryCode = value.countryCode?.replaceAll('+', '') ?? "1";
//           print('Country Code: ${countryCodeToIsoCode[_selectedCountryCode]}');
//           phoneController.text = value.phone ?? "";
//           // Set roles and assign from List<Roles> to List<Categories>
//           _selectedRoles = (value.role ?? [])
//               .map((role) => Categories(
//                     id: role.id ?? "",
//                     name: role.name ?? "",
//                     role: role.role ?? "",
//                     isForIndividual: role.isForIndividual ?? false,
//                     isMultipleRoleEnabled: role.isMultipleRoleEnabled ?? false,
//                     isApplicableForTrial: role.isApplicableForTrial ?? false,
//                   ))
//               .toList();
//           _selectedAcceptRole = value.acceptedRole!;
//           _selectedCountryCode = value.countryCode ?? "+1";
//         });
//       }
//     });
//     Provider.of<UserProfileProvider>(context, listen: false)
//         .getAvatarUrls(context);
//     Provider.of<UserProfileProvider>(context, listen: false)
//         .getUserTeamMembers(context);
//   }
//
//   Future<List<NetworkingUsers>> searchNetworks(String query) async =>
//       Provider.of<UserProfileProvider>(context, listen: false)
//           .getUserSuggestions(context, query);
//
//   @override
//   Widget build(BuildContext context1) {
//     var typography = CustomTypography(context1);
//     return SafeArea(
//       child: Consumer<ThemeProvider>(
//           builder: (buildContext, themeProvider, child) {
//         return Scaffold(
//           key: _scaffoldKey,
//           backgroundColor: themeProvider.getTheme.colorScheme.background,
//           appBar: CustomAppBar(
//             isExpanded: _isExpanded,
//             showNotificationDot: _showNotificationDot,
//             onExpandPressed: (isExpanded) {
//               setState(() {
//                 _isExpanded = isExpanded;
//               });
//             },
//             onSearchPressed: () {
//               setState(() {
//                 _isExpanded = !_isExpanded;
//               });
//             },
//             stopNavigateToProfile: _selectedScreen == Screens.generalInfo,
//           ),
//           drawer: CustomDrawer(),
//           body: _tabsLoading
//               ? Column(
//                   children: [
//                     SizedBox(
//                       height: CustomSpacing.four,
//                     ),
//                     Center(
//                       child: CircularProgressIndicator(),
//                     )
//                   ],
//                 )
//               : PopScope(
//                   canPop: _selectedScreen == Screens.generalInfo,
//                   onPopInvoked: (canPop) {
//                     print(
//                         'Can Pop: $canPop, Selected Screen: $_selectedScreen');
//                     if (_selectedScreen != Screens.generalInfo) {
//                       setState(() {
//                         _selectedScreen = Screens.generalInfo;
//                         _tabController?.animateTo(0);
//                       });
//                     }
//                   },
//                   child: Stack(
//                     children: [
//                       // Background image
//                       Positioned.fill(
//                         child: Image.asset(
//                           'assets/images/mesh.png',
//                           fit: BoxFit.cover,
//                         ),
//                       ),
//                       Column(
//                         children: [
//                           SizedBox(height: CustomSpacing.four),
//                           Expanded(
//                             child: Container(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Padding(
//                                     padding: const EdgeInsets.only(left: 8.0),
//                                     child: Text(
//                                         LanguageService.getTranslated(context,
//                                             "user_profile_user_management_title"),
//                                         style: typography.H5_Regular),
//                                   ),
//                                   // Add 3 tabs
//                                   SizedBox(
//                                     height: CustomSpacing.two,
//                                   ),
//                                   TabBar(
//                                     controller: _tabController,
//                                     labelStyle:
//                                         typography.BottomNavigationActiveLabel,
//                                     tabs: _tabLength == 3
//                                         ? [
//                                             Tab(
//                                               child: InkWell(
//                                                 onTap: () {
//                                                   _tabController?.animateTo(0);
//                                                   _selectedScreen =
//                                                       Screens.connectionList;
//                                                 },
//                                                 child: Tab(
//                                                   text: LanguageService
//                                                       .getTranslated(context,
//                                                           "user_profile_app_user_management_general_info_tab"),
//                                                 ),
//                                               ),
//                                             ),
//                                             !showMyTeams
//                                                 ? SizedBox()
//                                                 : InkWell(
//                                                     onTap: () {
//                                                       _tabController
//                                                           ?.animateTo(1);
//                                                       _selectedScreen =
//                                                           Screens.requestList;
//                                                     },
//                                                     child: Tab(
//                                                       text: LanguageService
//                                                           .getTranslated(
//                                                               context,
//                                                               "user_profile_app_user_management_my_team_tab"),
//                                                     ),
//                                                   ),
//                                             InkWell(
//                                               onTap: () {
//                                                 _tabController?.animateTo(2);
//                                                 _selectedScreen =
//                                                     Screens.chatList;
//                                               },
//                                               child: Tab(
//                                                 text: LanguageService.getTranslated(
//                                                     context,
//                                                     "user_profile_app_user_management_security_tab"),
//                                               ),
//                                             ),
//                                           ]
//                                         : [
//                                             Tab(
//                                               child: InkWell(
//                                                 onTap: () {
//                                                   _tabController?.animateTo(0);
//                                                   _selectedScreen =
//                                                       Screens.connectionList;
//                                                 },
//                                                 child: Tab(
//                                                   text: LanguageService
//                                                       .getTranslated(context,
//                                                           "user_profile_app_user_management_general_info_tab"),
//                                                 ),
//                                               ),
//                                             ),
//                                             InkWell(
//                                               onTap: () {
//                                                 _tabController?.animateTo(1);
//                                                 _selectedScreen =
//                                                     Screens.chatList;
//                                               },
//                                               child: Tab(
//                                                 text: LanguageService.getTranslated(
//                                                     context,
//                                                     "user_profile_app_user_management_security_tab"),
//                                               ),
//                                             ),
//                                           ],
//                                   ),
//
//                                   // Add 3 tab views
//                                   Expanded(
//                                     child: TabBarView(
//                                       controller: _tabController,
//                                       children: _tabLength == 3
//                                           ? [
//                                               // General Info
//                                               _getGeneralInfoUI(),
//                                               // My Team
//                                               !showMyTeams
//                                                   ? SizedBox()
//                                                   : _getMyTeamUI(),
//                                               // Security
//                                               _getSecurityUI(),
//                                             ]
//                                           : [
//                                               // General Info
//                                               _getGeneralInfoUI(),
//                                               // Security
//                                               _getSecurityUI(),
//                                             ],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//           // endDrawer: Material(
//           //   child: Container(
//           //     margin: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
//           //     child: SingleChildScrollView(
//           //       child: Column(
//           //         children: [
//           //           SizedBox(height: CustomSpacing.two),
//           //           // Circular elevated icon for filter
//           //           Center(
//           //               child: Container(
//           //             decoration: BoxDecoration(
//           //               color: Theme.of(context).colorScheme.surface,
//           //               shape: BoxShape.circle,
//           //               boxShadow: [
//           //                 BoxShadow(
//           //                   color: Colors.black.withOpacity(0.1),
//           //                   blurRadius: 8,
//           //                   offset: Offset(0, 4),
//           //                 ),
//           //               ],
//           //             ),
//           //             child: Padding(
//           //               padding: const EdgeInsets.all(16.0),
//           //               child: Icon(
//           //                 Icons.filter_alt_outlined,
//           //                 size: 32,
//           //               ),
//           //             ),
//           //           )),
//           //           SizedBox(height: CustomSpacing.six),
//           //           // name, phone, email, company, role dropdown, status,
//           //           Form(
//           //             child: Column(
//           //               children: [
//           //                 // Name
//           //                 TextFormField(
//           //                   decoration: InputDecoration(
//           //                     labelText: LanguageService.getTranslated(
//           //                         context, "usermanagement_app_filter_name"),
//           //                     labelStyle: typography.Body1,
//           //                     border: OutlineInputBorder(
//           //                       borderRadius: BorderRadius.circular(8),
//           //                     ),
//           //                   ),
//           //                 ),
//           //                 SizedBox(
//           //                   height: CustomSpacing.two,
//           //                 ),
//           //                 // Email
//           //                 TextFormField(
//           //                   decoration: InputDecoration(
//           //                     labelText: LanguageService.getTranslated(
//           //                         context, "usermanagement_app_filter_email"),
//           //                     labelStyle: typography.Body1,
//           //                     border: OutlineInputBorder(
//           //                       borderRadius: BorderRadius.circular(8),
//           //                     ),
//           //                   ),
//           //                 ),
//           //                 SizedBox(
//           //                   height: CustomSpacing.two,
//           //                 ),
//           //                 // Phone
//           //                 Row(
//           //                   children: [
//           //                     Expanded(
//           //                       flex: 4,
//           //                       child: Container(
//           //                         decoration: BoxDecoration(
//           //                           border: Border.all(
//           //                               color: Colors.white.withOpacity(0.5)),
//           //                           borderRadius: BorderRadius.circular(4),
//           //                         ),
//           //                         padding:
//           //                             const EdgeInsets.symmetric(vertical: 2.0),
//           //                         child: Center(
//           //                           child: Container(),
//           //                         ),
//           //                       ),
//           //                     ),
//           //                     SizedBox(width: CustomSpacing.two),
//           //                     // Mobile Number TextFormField
//           //                     Expanded(
//           //                       flex: 7,
//           //                       child: TextFormField(
//           //                         keyboardType: TextInputType.number,
//           //                         maxLength: 10,
//           //                         // Numeric keyboard
//           //                         inputFormatters: <TextInputFormatter>[
//           //                           FilteringTextInputFormatter.digitsOnly
//           //                           // Only allows digits
//           //                         ],
//           //                         decoration: InputDecoration(
//           //                           labelText: LanguageService.getTranslated(
//           //                               context,
//           //                               "usermanagement_app_filter_phone"),
//           //                           hintText: LanguageService.getTranslated(
//           //                               context,
//           //                               "usermanagement_app_filter_phone_hint"),
//           //                           border: const OutlineInputBorder(),
//           //                           counterText: '',
//           //                         ),
//           //                         validator: (value) {
//           //                           if (!RegExp(r'^[0-9]+$').hasMatch(value!)) {
//           //                             return LanguageService.getTranslated(
//           //                                 context,
//           //                                 "usermanagement_app_filter_phone_validation");
//           //                           }
//           //                           return null;
//           //                         },
//           //                         controller: mobileController,
//           //                       ),
//           //                     ),
//           //                     // Dropdown Icon Suffix
//           //                   ],
//           //                 ),
//           //                 SizedBox(height: CustomSpacing.two),
//           //                 // Company
//           //                 TextFormField(
//           //                   decoration: InputDecoration(
//           //                     labelText: LanguageService.getTranslated(
//           //                         context, "usermanagement_app_filter_company"),
//           //                     labelStyle: typography.Body1,
//           //                     border: OutlineInputBorder(
//           //                       borderRadius: BorderRadius.circular(8),
//           //                     ),
//           //                   ),
//           //                 ),
//           //                 SizedBox(height: CustomSpacing.two),
//           //                 // Role Dropdown
//           //                 Stack(
//           //                   children: [
//           //                     TextField(
//           //                       readOnly: true,
//           //                       onTap: () {
//           //                         showBottomSheet(
//           //                           context: context,
//           //                           builder: (BuildContext context) {
//           //                             return RolesBottomSheet(
//           //                               showCorporateSwitch: true,
//           //                               // isUserProfile: true,
//           //                               // options: roles,
//           //                               options:
//           //                                   context.read<AuthNotifier>().roles,
//           //                               selectedRoles: _selectedRoles,
//           //                               addChip: _addChip,
//           //                               removeChip: _removeChip,
//           //                               removeAllChips: _removeAllChips,
//           //                               selectedOption: SignUpOptions.corporate,
//           //                               onOptionChanged:
//           //                                   (SignUpOptions option) {
//           //                                 setState(() {
//           //                                   _selectedOption = option;
//           //                                 });
//           //                               },
//           //                             );
//           //                           },
//           //                         );
//           //                       },
//           //                       controller: _textEditingController,
//           //                       onChanged: (value) {
//           //                         // Handle input changes
//           //                       },
//           //                       decoration: InputDecoration(
//           //                         labelText: LanguageService.getTranslated(
//           //                             context,
//           //                             "usermanagement_app_filter_roles"),
//           //                         hintText: _selectedRoles.isEmpty
//           //                             ? 'Select Roles'
//           //                             : "",
//           //                         border: OutlineInputBorder(),
//           //                         suffixIcon: IconButton(
//           //                           icon: Icon(Icons.arrow_drop_down),
//           //                           onPressed: () {
//           //                             showModalBottomSheet(
//           //                               context: context,
//           //                               useSafeArea: true,
//           //                               isScrollControlled: true,
//           //                               builder: (BuildContext context) {
//           //                                 return RolesBottomSheet(
//           //                                   showCorporateSwitch: false,
//           //                                   // isUserProfile: true,
//           //                                   options: context
//           //                                       .read<AuthNotifier>()
//           //                                       .roles,
//           //                                   // options: roles,
//           //                                   selectedRoles: _selectedRoles,
//           //                                   addChip: _addChip,
//           //                                   removeChip: _removeChip,
//           //                                   removeAllChips: _removeAllChips,
//           //                                   selectedOption:
//           //                                       SignUpOptions.corporate,
//           //                                   onOptionChanged:
//           //                                       (SignUpOptions signUpOptions) {
//           //                                     setState(() {
//           //                                       _selectedOption = signUpOptions;
//           //                                     });
//           //                                   },
//           //                                 );
//           //                               },
//           //                             );
//           //                           },
//           //                         ),
//           //                       ),
//           //                     ),
//           //                     Positioned(
//           //                       top: 10.0,
//           //                       left: 10.0,
//           //                       right: 10.0,
//           //                       child: Container(
//           //                         margin: const EdgeInsets.only(right: 32.0),
//           //                         child: SingleChildScrollView(
//           //                           scrollDirection: Axis.horizontal,
//           //                           child: Row(
//           //                             children: _selectedRoles
//           //                                 .map(
//           //                                   (value) => Padding(
//           //                                     padding: const EdgeInsets.only(
//           //                                         right: 8.0),
//           //                                     child: Chip(
//           //                                       label: Text(value.name!),
//           //                                       deleteIcon: Icon(Icons.cancel),
//           //                                       onDeleted: () =>
//           //                                           _removeChip(value),
//           //                                     ),
//           //                                   ),
//           //                                 )
//           //                                 .toList(),
//           //                           ),
//           //                         ),
//           //                       ),
//           //                     ),
//           //                   ],
//           //                 ),
//           //
//           //                 SizedBox(height: CustomSpacing.two),
//           //                 // Status
//           //                 DropdownButtonFormField<String>(
//           //                   decoration: InputDecoration(
//           //                     labelText: LanguageService.getTranslated(
//           //                         context, "usermanagement_app_filter_status"),
//           //                     border: OutlineInputBorder(
//           //                       borderRadius: BorderRadius.circular(8),
//           //                     ),
//           //                   ),
//           //                   items: ['Active', 'Inactive'].map((String value) {
//           //                     return DropdownMenuItem<String>(
//           //                       value: value,
//           //                       child: Text(value),
//           //                     );
//           //                   }).toList(),
//           //                   onChanged: (String? value) {
//           //                     // Handle status change
//           //                   },
//           //                 ),
//           //                 SizedBox(height: CustomSpacing.two),
//           //                 // Cancel and Submit Buttons
//           //                 Row(
//           //                   children: [
//           //                     Expanded(
//           //                       child: OutlinedButton(
//           //                         onPressed: () {
//           //                           // Handle cancel button
//           //                         },
//           //                         style: ElevatedButton.styleFrom(
//           //                           shape: RoundedRectangleBorder(
//           //                             borderRadius: BorderRadius.circular(8),
//           //                           ),
//           //                           padding: EdgeInsets.symmetric(
//           //                               horizontal: 22, vertical: 8),
//           //                         ),
//           //                         child: Text(
//           //                           LanguageService.getTranslated(context,
//           //                               "usermanagement_app_filter_cancel"),
//           //                           style: typography.ButtonLarge,
//           //                         ),
//           //                       ),
//           //                     ),
//           //                     SizedBox(width: CustomSpacing.two),
//           //                     Expanded(
//           //                       child: CustomButton(
//           //                         onPressed: () {
//           //                           Navigator.pop(context);
//           //                         },
//           //                         type: ButtonType.filled,
//           //                         child: Text(
//           //                           LanguageService.getTranslated(context,
//           //                               "usermanagement_app_filter_submit"),
//           //                           style: typography.ButtonLarge,
//           //                         ),
//           //                       ),
//           //                     ),
//           //                   ],
//           //                 ),
//           //               ],
//           //             ),
//           //           ),
//           //         ],
//           //       ),
//           //     ),
//           //   ),
//           // ),
//         );
//       }),
//     );
//   }
//
//   void _showFiltersBottomSheet(BuildContext context) {
//     // show modal bottom sheet using scaffold key
//     /*showAdaptiveDialog(
//       */ /*shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.only(
//           topLeft: Radius.circular(24),
//           topRight: Radius.circular(24),
//         ),
//       ),*/ /*
//       context: context,
//       builder: (context) {
//         return ;
//       },
//     );*/
//     Scaffold.of(context).openEndDrawer();
//   }
//
//   final ImagePicker _picker = ImagePicker();
//   File? _pickedImage;
//
//   void _showImageOptions() {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.black87,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//       builder: (context) {
//         return SafeArea(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const SizedBox(height: 8),
//               const Text(
//                 "Profile Image",
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 16,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//               const Divider(color: Colors.white24, height: 20),
//               ListTile(
//                 leading: const Icon(Icons.photo_library, color: Colors.white),
//                 title: const Text("Choose from library",
//                     style: TextStyle(color: Colors.white)),
//                 onTap: _pickFromGallery,
//               ),
//               ListTile(
//                 leading: const Icon(Icons.camera_alt, color: Colors.white),
//                 title: const Text("Take a picture",
//                     style: TextStyle(color: Colors.white)),
//                 onTap: _takePicture,
//               ),
//               ListTile(
//                 leading: const Icon(Icons.delete, color: Colors.red),
//                 title: const Text("Delete photo",
//                     style: TextStyle(color: Colors.red)),
//                 onTap: () {
//                   setState(() {
//                     _pickedImage = null;
//                     userImageUrl = '';
//                   });
//                   Navigator.pop(context);
//                 },
//               ),
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text("Cancel",
//                     style: TextStyle(color: Colors.white70)),
//               ),
//               const SizedBox(height: 8),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   Future<void> _pickFromGallery() async {
//     final picked = await _picker.pickImage(source: ImageSource.gallery);
//     if (picked != null) {
//       setState(() => _pickedImage = File(picked.path));
//     }
//     Navigator.pop(context);
//   }
//
//   Future<void> _takePicture() async {
//     final picked = await _picker.pickImage(source: ImageSource.camera);
//     if (picked != null) {
//       setState(() => _pickedImage = File(picked.path));
//     }
//     Navigator.pop(context);
//   }
//
//   _getGeneralInfoUI() {
//     var typography = CustomTypography(context);
//     return Consumer<UserProfileProvider>(
//         builder: (context, userProfileProvider, child) {
//       return !userProfileProvider.isLoading
//           ? SingleChildScrollView(
//               child: Card(
//                 color: Theme.of(context).brightness == Brightness.dark
//                     ? AppColors.paperElavation25
//                     : AppColors.paperElavation25Light,
//                 child: Column(
//                   children: [
//                     // Profile Pic
//                     Center(
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Row(
//                             mainAxisSize: MainAxisSize.max,
//                             children: [
//                               Expanded(
//                                 child: Container(
//                                   padding: EdgeInsets.all(20),
//                                   color: Theme.of(context).brightness ==
//                                           Brightness.dark
//                                       ? AppColors.paperElavation25
//                                       : AppColors.paperElavation25Light,
//                                   child: Column(
//                                     mainAxisAlignment: MainAxisAlignment.start,
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       SizedBox(
//                                         width: CustomSpacing.four,
//                                       ),
//                                       Column(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.start,
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.start,
//                                         children: [
//                                           // Add button
//                                           Column(
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.start,
//                                             children: [
//                                               Row(
//                                                 mainAxisAlignment:
//                                                     MainAxisAlignment
//                                                         .spaceBetween,
//                                                 children: [
//                                                   Row(
//                                                     children: [
//                                                       Consumer<
//                                                           UserProfileProvider>(
//                                                         builder: (_,
//                                                             userProfileProvider,
//                                                             child) {
//                                                           return userProfileProvider
//                                                                   .isImageUploadLoading
//                                                               ? const Center(
//                                                                   child:
//                                                                       CircularProgressIndicator(),
//                                                                 )
//                                                               : GestureDetector(
//                                                                   onTap: !isEdit
//                                                                       ? null
//                                                                       : () {
//                                                                           showModalBottomSheet(
//                                                                             context:
//                                                                                 context,
//                                                                             backgroundColor:
//                                                                                 Colors.black87,
//                                                                             shape:
//                                                                                 const RoundedRectangleBorder(
//                                                                               borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//                                                                             ),
//                                                                             builder:
//                                                                                 (context) {
//                                                                               return SafeArea(
//                                                                                 child: Wrap(
//                                                                                   children: [
//                                                                                     const SizedBox(height: 12),
//                                                                                     Center(
//                                                                                       child: Container(
//                                                                                         height: 4,
//                                                                                         width: 40,
//                                                                                         decoration: BoxDecoration(
//                                                                                           color: Colors.grey[700],
//                                                                                           borderRadius: BorderRadius.circular(2),
//                                                                                         ),
//                                                                                       ),
//                                                                                     ),
//                                                                                     ListTile(
//                                                                                       leading: const Icon(Icons.image, color: Colors.white),
//                                                                                       title: const Text(
//                                                                                         "Upload Image",
//                                                                                         style: TextStyle(color: Colors.white),
//                                                                                       ),
//                                                                                       onTap: () {
//                                                                                         Navigator.pop(context);
//                                                                                         _pickAndUploadImage(context, userProfileProvider);
//                                                                                       },
//                                                                                     ),
//                                                                                     ListTile(
//                                                                                       leading: const Icon(Icons.person, color: Colors.white),
//                                                                                       title: const Text(
//                                                                                         "Choose Avatar",
//                                                                                         style: TextStyle(color: Colors.white),
//                                                                                       ),
//                                                                                       onTap: () {
//                                                                                         Navigator.pop(context);
//                                                                                         _showAvatarBottomSheet(context, userProfileProvider);
//                                                                                       },
//                                                                                     ),
//                                                                                     ListTile(
//                                                                                       leading: const Icon(Icons.delete, color: Colors.red),
//                                                                                       title: const Text(
//                                                                                         "Delete Photo",
//                                                                                         style: TextStyle(color: Colors.red),
//                                                                                       ),
//                                                                                       onTap: () {
//                                                                                         setState(() {
//                                                                                           userImageUrl = '';
//                                                                                         });
//                                                                                         Navigator.pop(context);
//                                                                                       },
//                                                                                     ),
//                                                                                   ],
//                                                                                 ),
//                                                                               );
//                                                                             },
//                                                                           );
//                                                                         },
//                                                                   child: Stack(
//                                                                     alignment:
//                                                                         Alignment
//                                                                             .bottomRight,
//                                                                     children: [
//                                                                       userImageUrl ==
//                                                                               ''
//                                                                           ? CircleAvatar(
//                                                                               foregroundImage: const AssetImage('assets/images/loginImage.png'),
//                                                                               backgroundColor: AppColors.avatarBackground,
//                                                                               radius: 40,
//                                                                             )
//                                                                           : CircleAvatar(
//                                                                               backgroundColor: AppColors.avatarBackground,
//                                                                               radius: 40,
//                                                                               child: ClipOval(
//                                                                                 child: Image.network(
//                                                                                   userImageUrl,
//                                                                                   fit: BoxFit.cover,
//                                                                                   width: 80,
//                                                                                   height: 80,
//                                                                                   loadingBuilder: (context, child, progress) {
//                                                                                     if (progress == null) return child;
//                                                                                     return Center(
//                                                                                       child: CircularProgressIndicator(
//                                                                                         value: progress.expectedTotalBytes != null ? progress.cumulativeBytesLoaded / (progress.expectedTotalBytes ?? 1) : null,
//                                                                                         color: AppColors.primaryMain,
//                                                                                       ),
//                                                                                     );
//                                                                                   },
//                                                                                   errorBuilder: (context, error, stack) => const Icon(
//                                                                                     Icons.error,
//                                                                                     size: 40,
//                                                                                     color: Colors.red,
//                                                                                   ),
//                                                                                 ),
//                                                                               ),
//                                                                             ),
//                                                                       Positioned(
//                                                                         bottom:
//                                                                             4,
//                                                                         right:
//                                                                             4,
//                                                                         child: isEdit
//                                                                             ? Container(
//                                                                                 decoration: const BoxDecoration(
//                                                                                   color: Colors.black54,
//                                                                                   shape: BoxShape.circle,
//                                                                                 ),
//                                                                                 padding: const EdgeInsets.all(5),
//                                                                                 child: const Icon(Icons.edit, color: Colors.white, size: 18),
//                                                                               )
//                                                                             : Container(),
//                                                                       ),
//                                                                     ],
//                                                                   ),
//                                                                 );
//                                                         },
//                                                       ),
//                                                       SizedBox(width: 10),
//                                                       Column(
//                                                         mainAxisAlignment:
//                                                             MainAxisAlignment
//                                                                 .start,
//                                                         crossAxisAlignment:
//                                                             CrossAxisAlignment
//                                                                 .start,
//                                                         children: [
//                                                           SizedBox(
//                                                             height:
//                                                                 CustomSpacing
//                                                                     .two,
//                                                           ),
//                                                           Text(
//                                                             LanguageService
//                                                                 .getTranslated(
//                                                                     context,
//                                                                     "user_profile_user_managemt_uploadimage_text"),
//                                                             style: typography
//                                                                 .Body1,
//                                                             textAlign: TextAlign
//                                                                 .center,
//                                                           ),
//                                                           SizedBox(
//                                                             height:
//                                                                 CustomSpacing
//                                                                     .two,
//                                                           ),
//                                                           Container(
//                                                             width: MediaQuery.of(
//                                                                         context)
//                                                                     .size
//                                                                     .width /
//                                                                 2.2,
//                                                             child: Text(
//                                                               LanguageService
//                                                                   .getTranslated(
//                                                                       context,
//                                                                       "usermanagement_app_image_size"),
//                                                               maxLines: 2,
//                                                               style: typography
//                                                                   .BottomNavigationActiveLabel,
//                                                               textAlign:
//                                                                   TextAlign
//                                                                       .start,
//                                                             ),
//                                                           ),
//                                                           SizedBox(
//                                                             height:
//                                                                 CustomSpacing
//                                                                     .two,
//                                                           ),
//                                                         ],
//                                                       ),
//                                                     ],
//                                                   ),
//                                                   CustomButton(
//                                                     type: ButtonType.text,
//                                                     onPressed: () {
//                                                       switchEdit();
//                                                     },
//                                                     child: Row(
//                                                       mainAxisSize:
//                                                           MainAxisSize.min,
//                                                       children: [
//                                                         Icon(
//                                                           Icons.edit,
//                                                           size: 30,
//                                                         ),
//                                                         // SizedBox(
//                                                         //     width:
//                                                         //     CustomSpacing.two),
//                                                         // Text(
//                                                         //   isEdit
//                                                         //       ? LanguageService
//                                                         //       .getTranslated(
//                                                         //       context,
//                                                         //       "user_profile_app_user_management_profile_save_text")
//                                                         //       : LanguageService
//                                                         //       .getTranslated(
//                                                         //       context,
//                                                         //       "user_profile_app_user_management_edit_profile_text"),
//                                                         //   style: typography
//                                                         //       .ButtonLarge,
//                                                         // ),
//                                                       ],
//                                                     ),
//                                                   ),
//                                                 ],
//                                               ),
//                                             ],
//                                           ),
//
//                                           // If edit is enables user can edit else its disabled fields: Name, Display Name, Roles with bottom sheet selection, Email and phone with country code
//                                           // Edit button
//                                           // !showEditUser?SizedBox():!isEdit
//                                           //     ?
//
//                                           // : SizedBox(),
//                                           // !isEdit
//                                           //     ? SizedBox(
//                                           //         height: CustomSpacing.two,
//                                           //       )
//                                           //     : SizedBox(),
//                                         ],
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                     Form(
//                       key: _formKey,
//                       child: Container(
//                         padding: EdgeInsets.only(right: 20, left: 20),
//                         child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               // Name
//                               TextFormField(
//                                 enabled: isEdit,
//                                 style: typography.Body1,
//                                 controller: _nameGeneralInfoController,
//                                 initialValue: null,
//                                 // Remove initialValue since we'll use controller
//                                 readOnly: !isEdit,
//                                 // Add readOnly instead of disabled for better value visibility
//                                 //controller: nameGeneralInfoController, // Always use the controller
//                                 decoration: InputDecoration(
//                                   floatingLabelBehavior:
//                                       FloatingLabelBehavior.always,
//                                   labelText: LanguageService.getTranslated(
//                                       context,
//                                       "user_profile_user_management_name_filed_label"),
//                                   labelStyle: typography.Body1,
//                                   border: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                   disabledBorder: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(8),
//                                     borderSide: BorderSide(
//                                       color: Theme.of(context)
//                                           .textTheme
//                                           .labelMedium!
//                                           .color!,
//                                     ),
//                                   ),
//                                 ),
//                                 validator: (value) {
//                                   if (value == null || value.isEmpty) {
//                                     return LanguageService.getTranslated(
//                                         context,
//                                         "user_profile_user_management_name_field_error");
//                                   }
//                                   return null;
//                                 },
//                               ),
//
//                               SizedBox(height: CustomSpacing.four),
//                               // Display Name
//                               TextFormField(
//                                 readOnly: !isEdit,
//                                 style: typography.Body1,
//                                 controller: _displayNameGeneralInfoController,
//                                 decoration: InputDecoration(
//                                   floatingLabelBehavior:
//                                       FloatingLabelBehavior.always,
//                                   labelText:
//                                       isEdit ? 'Display Name' : 'Display Name',
//                                   //displayNameLabelText,
//                                   labelStyle: isEdit
//                                       ? typography.Body1
//                                       : typography.Body1.copyWith(
//                                           color: Theme.of(context)
//                                               .textTheme
//                                               .labelMedium
//                                               ?.color),
//                                   disabledBorder: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(8),
//                                     borderSide: BorderSide(
//                                       color: Theme.of(context)
//                                           .textTheme
//                                           .labelMedium!
//                                           .color!,
//                                     ),
//                                   ),
//                                   border: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                 ),
//                                 validator: (value) {
//                                   if (value == null || value.isEmpty) {
//                                     return 'Display Name is required';
//                                   }
//                                   return null;
//                                 },
//                               ),
//                               SizedBox(height: CustomSpacing.four),
//                               // Text(_selectedAcceptRole.length.toString()),
//                               // Role Dropdown
//
//                               Stack(
//                                 children: [
//                                   TextField(
//                                     readOnly: true,
//                                     // enabled: !(userProfileProvider.userData.role![0].name.toString() == "Admin" &&
//                                     //     (isSuperAdmin || isPgAdmin || isAdmin)),
//                                     // enabled: !isEdit &&
//                                     //     !isSuperAdmin &&
//                                     //     !isPgAdmin &&
//                                     //     !isAdmin,
//                                     onTap: !isEdit &&
//                                             !isSuperAdmin &&
//                                             !isPgAdmin &&
//                                             !isAdmin
//                                         ? () {
//                                             showModalBottomSheet(
//                                               context: context,
//                                               useSafeArea: true,
//                                               isScrollControlled: true,
//                                               builder: (BuildContext context) {
//                                                 List<Map<String, dynamic>>
//                                                     acceptedRoles =
//                                                     userProfileProvider.userData
//                                                             .acceptedRole
//                                                             ?.map((role) =>
//                                                                 role.toJson())
//                                                             ?.toList() ??
//                                                         [];
//                                                 print(
//                                                     "Accepted Roles: $acceptedRoles");
//                                                 print(
//                                                     "useCheckboxes: ${(userProfileProvider.userData.isIndividual ?? false) && (userProfileProvider.userData.isExternal ?? false)}");
//
//                                                 return CustomFlexibleRolesBottomSheet(
//                                                   showCorporateSwitch: true,
//                                                   options: _selectedAcceptRole,
//                                                   selectedRoles: _selectedRoles,
//                                                   addChip: _addChip,
//                                                   removeChip: _removeChip,
//                                                   removeAllChips:
//                                                       _removeAllChips,
//                                                   useCheckboxes:
//                                                       (userProfileProvider
//                                                                   .userData
//                                                                   .isIndividual ??
//                                                               false) &&
//                                                           (userProfileProvider
//                                                                   .userData
//                                                                   .isExternal ??
//                                                               false),
//                                                   // Assuming you want to use checkboxes for selection
//                                                 );
//                                               },
//                                             );
//                                           }
//                                         : null,
//                                     controller: _textEditingController,
//                                     onChanged: (value) {
//                                       // Handle input changes
//                                     },
//                                     decoration: InputDecoration(
//                                       labelText: isEdit &&
//                                               !isSuperAdmin &&
//                                               !isPgAdmin &&
//                                               !isAdmin
//                                           ? ''
//                                           : '',
//                                       labelStyle: isEdit &&
//                                               !isSuperAdmin &&
//                                               !isPgAdmin &&
//                                               !isAdmin
//                                           ? typography.Body1
//                                           : typography.Body1.copyWith(
//                                               color: Theme.of(context)
//                                                   .textTheme
//                                                   .labelMedium
//                                                   ?.color),
//                                       hintText: _selectedRoles.isEmpty &&
//                                               _textEditingController
//                                                   .text.isEmpty
//                                           ? 'Select Roles'
//                                           : '',
//                                       border: OutlineInputBorder(),
//                                       disabledBorder: OutlineInputBorder(
//                                         borderRadius: BorderRadius.circular(8),
//                                         borderSide: BorderSide(
//                                           color: Theme.of(context)
//                                               .textTheme
//                                               .labelMedium!
//                                               .color!,
//                                         ),
//                                       ),
//                                       suffixIcon: IconButton(
//                                         icon: Icon(Icons.arrow_drop_down),
//                                         onPressed: isEdit
//                                             ? () {
//                                                 showModalBottomSheet(
//                                                   context: context,
//                                                   useSafeArea: true,
//                                                   isScrollControlled: true,
//                                                   builder:
//                                                       (BuildContext context) {
//                                                     List<Map<String, dynamic>>
//                                                         acceptedRoles =
//                                                         userProfileProvider
//                                                                 .userData
//                                                                 .acceptedRole
//                                                                 ?.map((role) =>
//                                                                     role.toJson())
//                                                                 ?.toList() ??
//                                                             [];
//                                                     return CustomFlexibleRolesBottomSheet(
//                                                       showCorporateSwitch: true,
//                                                       options:
//                                                           _selectedAcceptRole,
//                                                       selectedRoles:
//                                                           _selectedRoles,
//                                                       addChip: _addChip,
//                                                       removeChip: _removeChip,
//                                                       removeAllChips:
//                                                           _removeAllChips,
//                                                       useCheckboxes: (userProfileProvider
//                                                                   .userData
//                                                                   .isIndividual ??
//                                                               false) &&
//                                                           (userProfileProvider
//                                                                   .userData
//                                                                   .isExternal ??
//                                                               false),
//                                                     );
//                                                   },
//                                                 );
//                                               }
//                                             : null,
//                                       ),
//                                     ),
//                                   ),
//
//                                   Positioned(
//                                     top: 4.0,
//                                     left: 10.0,
//                                     right: 10.0,
//                                     child: Container(
//                                       margin:
//                                           const EdgeInsets.only(right: 32.0),
//                                       child: SingleChildScrollView(
//                                         scrollDirection: Axis.horizontal,
//                                         child: Row(
//                                           children: _selectedRoles.map((value) {
//                                             return Padding(
//                                               padding: const EdgeInsets.only(
//                                                   right: 8.0),
//                                               child: Row(
//                                                 children: [
//                                                   Chip(
//                                                     label: Text(value.name!),
//                                                     deleteIcon: (isEdit &&
//                                                                 !isSuperAdmin &&
//                                                                 !isPgAdmin) ||
//                                                             (isEdit &&
//                                                                 bool.parse(userProfileProvider
//                                                                     .userData
//                                                                     .isIndividual
//                                                                     .toString()))
//                                                         ? Icon(Icons.cancel)
//                                                         : null,
//                                                     onDeleted: (isEdit &&
//                                                                 !isSuperAdmin &&
//                                                                 !isPgAdmin) ||
//                                                             (isEdit &&
//                                                                 bool.parse(userProfileProvider
//                                                                     .userData
//                                                                     .isIndividual
//                                                                     .toString()))
//                                                         ? () =>
//                                                             _removeChip(value)
//                                                         : null,
//                                                   ),
//                                                   // Chip(
//                                                   //   label: Text(value.name!),
//                                                   //   deleteIcon: Icon(Icons.cancel),
//                                                   //   onDeleted: () =>
//                                                   //       _removeChip(value),
//                                                   // ),
//                                                   // if (isEdit &&
//                                                   //         !isSuperAdmin &&
//                                                   //         !isPgAdmin ||
//                                                   //     (isEdit &&
//                                                   //         bool.parse(
//                                                   //             userProfileProvider
//                                                   //                 .userData
//                                                   //                 .isIndividual
//                                                   //                 .toString())))
//                                                   //   IconButton(
//                                                   //     icon: Icon(Icons.cancel,
//                                                   //         size: 20,
//                                                   //         color: Colors.red),
//                                                   //     onPressed: () {
//                                                   //       setState(() {
//                                                   //         _selectedRoles
//                                                   //             .remove(value);
//                                                   //       });
//                                                   //     },
//                                                   //   ),
//                                                 ],
//                                               ),
//                                             );
//                                           }).toList(),
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//
//                                   // Positioned(
//                                   //   top: 4.0,
//                                   //   left: 10.0,
//                                   //   right: 10.0,
//                                   //   child: Container(
//                                   //     margin: const EdgeInsets.only(right: 32.0),
//                                   //     child: SingleChildScrollView(
//                                   //       scrollDirection: Axis.horizontal,
//                                   //       child: Row(
//                                   //         children: _selectedRoles
//                                   //             .map(
//                                   //               (value) => Padding(
//                                   //             padding: const EdgeInsets.only(right: 8.0),
//                                   //             child: Chip(
//                                   //               label: Text(value.name!),
//                                   //               deleteIcon: isEdit&&!isSuperAdmin&&!isPgAdmin ? Icon(Icons.cancel) : null,
//                                   //               onDeleted: isEdit&&!isSuperAdmin&&!isPgAdmin ? () => _removeChip(value) : null,
//                                   //             ),
//                                   //           ),
//                                   //         )
//                                   //             .toList(),
//                                   //       ),
//                                   //     ),
//                                   //   ),
//                                   // ),
//                                 ],
//                               ),
//                               SizedBox(height: CustomSpacing.four),
//                               // Email
//                               TextFormField(
//                                 readOnly: true,
//                                 style: typography.Body1,
//                                 controller: _emailGeneralInfoController,
//                                 decoration: InputDecoration(
//                                   floatingLabelBehavior:
//                                       FloatingLabelBehavior.always,
//                                   labelText: isEdit
//                                       ? LanguageService.getTranslated(context,
//                                           "user_profile_user_management_email_field_label")
//                                       //: emailLabelText,
//                                       : LanguageService.getTranslated(context,
//                                           "user_profile_user_management_email_field_label"),
//                                   labelStyle: isEdit
//                                       ? typography.Body1.copyWith(
//                                           color: Theme.of(context)
//                                               .textTheme
//                                               .labelMedium
//                                               ?.color)
//                                       : typography.Body1.copyWith(
//                                           color: Theme.of(context)
//                                               .textTheme
//                                               .labelMedium
//                                               ?.color),
//                                   disabledBorder: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(8),
//                                     borderSide: BorderSide(
//                                       color: Theme.of(context)
//                                           .textTheme
//                                           .labelMedium!
//                                           .color!,
//                                     ),
//                                   ),
//                                   border: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                 ),
//                               ),
//                               SizedBox(height: CustomSpacing.four),
//                               // Phone
//                               FormField<String>(
//                                 validator: (value) {
//                                   if (phoneController.text.isEmpty) {
//                                     print("object");
//                                     return 'Mobile number is required.';
//                                   }
//                                   if (phoneController.text.length < 10) {
//                                     print("object");
//                                     return 'Enter a valid mobile number.';
//                                   }
//                                   return null;
//                                 },
//                                 builder: (FormFieldState<String> fieldState) {
//                                   return TextFormField(
//                                     controller: phoneController,
//                                     enabled: isEdit,
//                                     keyboardType: TextInputType.phone,
//                                     maxLength: 10,
//                                     decoration: InputDecoration(
//                                       counterText: '',
//                                       // Hides the maxLength counter
//                                       floatingLabelBehavior:
//                                           FloatingLabelBehavior.always,
//                                       labelText: LanguageService.getTranslated(
//                                         context,
//                                         "user_profile_user_management_mobile_field",
//                                       ),
//                                       labelStyle: isEdit
//                                           ? typography.Body1
//                                           : typography.Body1.copyWith(
//                                               color: Theme.of(context)
//                                                   .textTheme
//                                                   .labelMedium
//                                                   ?.color,
//                                             ),
//                                       hintText: LanguageService.getTranslated(
//                                         context,
//                                         "user_profile_user_management_mobile_placeholder",
//                                       ),
//                                       border: OutlineInputBorder(
//                                         borderRadius: BorderRadius.circular(8),
//                                         borderSide: BorderSide(
//                                           color: Theme.of(context).dividerColor,
//                                         ),
//                                       ),
//                                       disabledBorder: OutlineInputBorder(
//                                         borderRadius: BorderRadius.circular(8),
//                                         borderSide: BorderSide(
//                                           color: Theme.of(context)
//                                               .textTheme
//                                               .labelMedium!
//                                               .color!,
//                                         ),
//                                       ),
//                                       contentPadding:
//                                           const EdgeInsets.symmetric(
//                                               vertical: 18, horizontal: 12),
//                                       errorText: fieldState.errorText,
//                                     ),
//                                     onChanged: (value) {
//                                       fieldState.didChange(value);
//                                     },
//                                   );
//                                 },
//                               ),
//
//                               SizedBox(height: CustomSpacing.four),
//                             ]),
//                       ),
//                     ),
//
//                     // Cancel and Submit Buttons
//                     isEdit
//                         ? Column(
//                             children: [
//                               Row(
//                                 children: [
//                                   SizedBox(width: CustomSpacing.five),
//                                   Expanded(
//                                     child: CustomButton(
//                                       onPressed: () {
//                                         // validate
//                                         if (!_formKey.currentState!
//                                             .validate()) {
//                                           print("object");
//                                           return;
//                                         }
//                                         // Atleat one selected role:
//                                         if (_selectedRoles.isEmpty) {
//                                           ScaffoldMessenger.of(context)
//                                               .showSnackBar(
//                                             SnackBar(
//                                               content: Text(
//                                                   'Please select at least one role.',
//                                                   style:
//                                                       typography.Body1.copyWith(
//                                                           color: Colors.black)),
//                                             ),
//                                           );
//                                           return;
//                                         }
//                                         // Update Body
//                                         var body = {
//                                           "current_user": true,
//                                           "userdata": {
//                                             "rating": userProfileProvider
//                                                     .userData.rating ??
//                                                 0,
//                                             "email": userProfileProvider
//                                                     .userData.email ??
//                                                 "",
//                                             "request_sent": [],
//                                             "is_external": true,
//                                             "display_image_url": userImageUrl,
//                                             "display_name":
//                                                 _displayNameGeneralInfoController
//                                                     .text,
//                                             "is_verified": false,
//                                             "user_id": userProfileProvider
//                                                     .userData.userId ??
//                                                 "",
//                                             "referral_code": "",
//                                             "status": true,
//                                             "username": "",
//                                             "company_id": userProfileProvider
//                                                     .userData.companyId ??
//                                                 "",
//                                             "isIndividual": (userProfileProvider
//                                                         .userData
//                                                         .isIndividual ??
//                                                     false) &&
//                                                 (userProfileProvider
//                                                         .userData.isExternal ??
//                                                     false),
//                                             "displayName":
//                                                 _displayNameGeneralInfoController
//                                                     .text,
//                                             "phone": phoneController.text ?? "",
//                                             "my_assignee": [""],
//                                             "roles": _selectedRoles
//                                                 .map((role) => role.toJson())
//                                                 .toList(),
//                                             "selectedCountryCode":
//                                                 _selectedCountryCode,
//                                             "country_code":
//                                                 _selectedCountryCode,
//                                             "name":
//                                                 _nameGeneralInfoController.text,
//                                             "accepted_role": userProfileProvider
//                                                     .userData.acceptedRole
//                                                     ?.map(
//                                                         (role) => role.toJson())
//                                                     ?.toList() ??
//                                                 []
//                                           }
//                                         };
//                                         userProfileProvider
//                                             .updateUserData(context, body)
//                                             .then((value) {
//                                           if (value) {
//                                             setState(() {
//                                               nameLabelText =
//                                                   _nameGeneralInfoController
//                                                       .text;
//                                               displayNameLabelText =
//                                                   _displayNameGeneralInfoController
//                                                       .text;
//                                               emailLabelText =
//                                                   _emailGeneralInfoController
//                                                       .text;
//                                               phoneLabelText =
//                                                   phoneController.text ?? "";
//                                               isEdit = false;
//                                             });
//                                           }
//                                         });
//                                       },
//                                       type: ButtonType.filled,
//                                       child: Text(
//                                         LanguageService.getTranslated(context,
//                                             "user_profile_user_management_btn_submit"),
//                                         // style: typography.ButtonLarge,
//                                       ),
//                                     ),
//                                   ),
//                                   SizedBox(width: CustomSpacing.five),
//                                 ],
//                               ),
//                               SizedBox(height: CustomSpacing.two),
//                               Row(
//                                 children: [
//                                   SizedBox(width: CustomSpacing.five),
//                                   Expanded(
//                                     child: OutlinedButton(
//                                       onPressed: () {
//                                         // Handle submit button
//                                         switchEdit();
//                                       },
//                                       style: ElevatedButton.styleFrom(
//                                         shape: RoundedRectangleBorder(
//                                           borderRadius:
//                                               BorderRadius.circular(8),
//                                         ),
//                                         padding: EdgeInsets.symmetric(
//                                             horizontal: 22, vertical: 8),
//                                       ),
//                                       child: Text(
//                                         LanguageService.getTranslated(context,
//                                             "user_profile_user_management_btn_cancel"),
//                                         style: typography.ButtonLarge,
//                                       ),
//                                     ),
//                                   ),
//                                   SizedBox(width: CustomSpacing.five),
//                                 ],
//                               ),
//                             ],
//                           )
//                         : SizedBox(),
//                   ],
//                 ),
//               ),
//             )
//
//           : SizedBox(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.start,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Container(
//                             padding: const EdgeInsets.only(left: 8.0),
//                             child: Text(
//                               "Security",
//                               style: TextStyle(
//                                 fontSize: 20,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             )),
//                         Divider(),
//                         Container(
//                             padding: const EdgeInsets.only(left: 8.0),
//                             child: Text(
//                               "You can update your password below.",
//                               style: TextStyle(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             )),
//                         SizedBox(height: CustomSpacing.three),
//                         Container(
//                           padding: const EdgeInsets.only(left: 8.0),
//                           width: 250,
//                           child: OutlinedButton(
//                             onPressed: () {
//                               final rootContext =
//                                   context;
//
//                               showModalBottomSheet(
//                                 context: context,
//                                 isScrollControlled: true,
//                                 backgroundColor: Colors.transparent,
//                                 builder: (sheetContext) {
//                                   return _changePasswordBottomSheet(
//                                     sheetContext,
//                                     rootContext,
//                                     _emailGeneralInfoController.text,
//                                   );
//                                 },
//                               );
//                             },
//                             style: OutlinedButton.styleFrom(
//
//                               side: BorderSide(
//                                 color: AppColors
//                                     .primaryMain, // border color
//                                 width: 1,
//                               ),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               padding: const EdgeInsets.symmetric(
//                                   horizontal: 22, vertical: 8),
//                             ),
//                             child: Text(
//                               "Change Password",
//                               style: typography.ButtonLarge.copyWith(
//                                 color: AppColors
//                                     .primaryMain, // ensure text color
//                               ),
//                             ),
//                           ),
//                         ),
//                         SizedBox(height: CustomSpacing.three),
//                       ],
//                     ))
//               :
//       Column(
//               mainAxisSize: MainAxisSize.max,
//               children: [
//                 Expanded(
//                   child: Center(
//                       child: Container(
//                     height: 20,
//                     width: 20,
//                     child: CircularProgressIndicator(),
//                   )),
//                 ),
//               ],
//             );
//     });
//   }
//
//   Future<void> _pickAndUploadImage(
//       BuildContext context, UserProfileProvider provider) async {
//     try {
//       final pickedFile =
//           await ImagePicker().pickImage(source: ImageSource.gallery);
//       if (pickedFile == null) return;
//
//       final file = File(pickedFile.path);
//       final img.Image? image = img.decodeImage(file.readAsBytesSync());
//
//       if (image == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//               content: Text('Could not load the image. Please try again.')),
//         );
//         return;
//       }
//
//       final isValidSize = image.width >= 400 && image.height >= 400;
//       final isValidFormat = pickedFile.path.toLowerCase().endsWith('.png') ||
//           pickedFile.path.toLowerCase().endsWith('.jpg') ||
//           pickedFile.path.toLowerCase().endsWith('.jpeg');
//
//       if (!isValidSize || !isValidFormat) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text(
//                 'Image must be at least 400x400 pixels and in PNG or JPEG format.'),
//           ),
//         );
//         return;
//       }
//
//       final imageUrl = await provider.uploadImage(context, file);
//
//       if (imageUrl.isNotEmpty && mounted) {
//         setState(() => userImageUrl = imageUrl);
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Something went wrong: $e')),
//       );
//     }
//   }
//
//   void _showAvatarBottomSheet(
//       BuildContext context, UserProfileProvider provider) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       useSafeArea: true,
//       backgroundColor: Colors.black87,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//       builder: (BuildContext context) {
//         return SafeArea(
//           child: Padding(
//             padding: MediaQuery.of(context).viewInsets,
//             child: SingleChildScrollView(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const SizedBox(height: 16),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       const Padding(
//                         padding: EdgeInsets.symmetric(horizontal: 16),
//                         child: Text(
//                           "Select Avatar",
//                           style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.white),
//                         ),
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.close, color: Colors.white),
//                         onPressed: () => Navigator.pop(context),
//                       ),
//                     ],
//                   ),
//                   GridView.builder(
//                     padding: const EdgeInsets.all(16),
//                     shrinkWrap: true,
//                     itemCount: provider.avatars.length,
//                     physics: const NeverScrollableScrollPhysics(),
//                     gridDelegate:
//                         const SliverGridDelegateWithFixedCrossAxisCount(
//                       crossAxisCount: 5,
//                       crossAxisSpacing: 16,
//                       mainAxisSpacing: 16,
//                     ),
//                     itemBuilder: (context, index) {
//                       final avatarUrl = provider.avatars[index]?.url ?? "";
//                       return GestureDetector(
//                         onTap: () {
//                           setState(() {
//                             userImageUrl = avatarUrl;
//                           });
//                           Navigator.pop(context);
//                         },
//                         child: CircleAvatar(
//                           backgroundImage: NetworkImage(avatarUrl),
//                           backgroundColor: AppColors.avatarBackground,
//                           radius: 25,
//                         ),
//                       );
//                     },
//                   ),
//                   const SizedBox(height: 12),
//                   TextButton(
//                     onPressed: () => Navigator.pop(context),
//                     child: const Text("Cancel",
//                         style: TextStyle(color: Colors.white70)),
//                   ),
//                   const SizedBox(height: 16),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   void switchEdit() {
//     setState(() {
//       isEdit = !isEdit;
//       if (isEdit) {
//         _nameGeneralInfoController.text = nameLabelText;
//         _displayNameGeneralInfoController.text = displayNameLabelText;
//         _emailGeneralInfoController.text = emailLabelText;
//         _phoneGeneralInfoController.text = phoneLabelText;
//       } else {
//         _nameGeneralInfoController.text = nameLabelText;
//         _displayNameGeneralInfoController.text = displayNameLabelText;
//         _emailGeneralInfoController.text = emailLabelText;
//         _phoneGeneralInfoController.text = phoneLabelText;
//       }
//     });
//   }
//
//   _getMyTeamUI() {
//     return SingleChildScrollView(
//       child: Consumer<UserProfileProvider>(
//           builder: (context, userProfileProvider, child) {
//         return userProfileProvider.isUserTeamLoading
//             ? Column(
//                 mainAxisSize: MainAxisSize.max,
//                 children: [
//                   Center(
//                       child: Container(
//                     height: 20,
//                     width: 20,
//                     child: CircularProgressIndicator(),
//                   )),
//                 ],
//               )
//             : Column(
//                 children: [
//                   SizedBox(height: CustomSpacing.two),
//                   Container(
//                     child: _managerCardUI(userProfileProvider),
//                   ),
//                   SizedBox(height: CustomSpacing.two),
//                   Container(
//                     child: _delegateCardUI(userProfileProvider),
//                   ),
//                   SizedBox(height: CustomSpacing.two),
//                   Container(
//                     child: _reporteesCardUI(userProfileProvider),
//                   ),
//                   SizedBox(height: CustomSpacing.two),
//                 ],
//               );
//       }),
//     );
//   }
//
//   _managerCardUI(UserProfileProvider userProfileProvider) {
//     var typography = CustomTypography(context);
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           SizedBox(height: CustomSpacing.two),
//           Container(
//             padding:
//                 const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.only(bottom: 6.0),
//                   child: Text(
//                     LanguageService.getTranslated(context,
//                         "user_profile_user_management_row_name_manager"),
//                     style: typography.Body1,
//                   ),
//                 ),
//                 !showAssignDeleteManager
//                     ? SizedBox()
//                     : Builder(builder: (context) {
//                         return Row(
//                           mainAxisSize: MainAxisSize.min,
//                           mainAxisAlignment: MainAxisAlignment.end,
//                           children: [
//                             userProfileProvider.myManager.isNotEmpty &&
//                                     userProfileProvider.myManager[0] != null
//                                 ? SizedBox(
//                                     height: 48,
//                                   )
//                                 : IconButton(
//                                     onPressed: () {
//                                       showAdaptiveDialog(
//                                         context: context,
//                                         builder: (localContext) {
//                                           return AlertDialog(
//                                             content: _addMemberDialogUI(
//                                                 localContext, "add_manager"),
//                                           );
//                                         },
//                                       );
//                                     },
//                                     icon: Icon(
//                                       Icons.add,
//                                       color: AppColors.primaryMain,
//                                     ),
//                                   ),
//                           ],
//                         );
//                       }),
//               ],
//             ),
//           ),
//           userProfileProvider.myManager.isEmpty ||
//                   userProfileProvider.myManager[0] == null
//               ? SizedBox()
//               : Container(
//                   color: Theme.of(context).colorScheme.background,
//                   child: Column(
//                     children: [
//                       SizedBox(height: CustomSpacing.four),
//                       Container(
//                           child: Row(
//                         children: [
//                           // Manager Image Avatar, Name and email as column, role chip, actions as search and delete
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: CircleAvatar(
//                               radius: 24,
//                               child: userProfileProvider
//                                               .myManager[0]?.displayImageUrl !=
//                                           null &&
//                                       userProfileProvider
//                                               .myManager[0]?.displayImageUrl !=
//                                           ''
//                                   ? ClipOval(
//                                       child: Image.network(
//                                         userProfileProvider
//                                             .myManager[0]!.displayImageUrl!,
//                                         fit: BoxFit.cover,
//                                       ),
//                                     )
//                                   : Text(
//                                       userProfileProvider.myManager[0]?.name
//                                               ?.substring(0, 1)
//                                               .toUpperCase() ??
//                                           "",
//                                     ),
//                             ),
//                           ),
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(userProfileProvider.myManager[0]?.name ?? "",
//                                   style: typography.Body1),
//                               Text(
//                                   userProfileProvider.myManager[0]?.email ?? "",
//                                   style: typography.Body2),
//                             ],
//                           ),
//
//                           Spacer(),
//                           // Actions
//                           !showAssignDeleteManager
//                               ? SizedBox()
//                               : PopupMenuButton<PopupMenuItem<dynamic>>(
//                                   itemBuilder: (BuildContext context) {
//                                     List<PopupMenuEntry<PopupMenuItem<dynamic>>>
//                                         items = [];
//
//                                     /*if (userProfileProvider.myManager.isEmpty || userProfileProvider.myManager[0] == null) {
//                           items.add(
//                             PopupMenuItem(
//                               onTap: () {
//                                 // Handle search
//                                 showDialog(
//                                   context: context,
//                                   builder: (context) => _addMemberDialogUI(context, "add_manager"),
//                                 );
//                               },
//                               child: Row(
//                                 children: [
//                                   Icon(Icons.search),
//                                   SizedBox(width: CustomSpacing.two),
//                                   Text('Search'),
//                                 ],
//                               ),
//                             ),
//                           );
//                         }*/
//
//                                     if (showAssignDeleteManager) {
//                                       items.add(
//                                         PopupMenuItem(
//                                           onTap: () {
//                                             // Show delete dialog and pop off the menu also on ok
//                                             showDialog(
//                                               context: context,
//                                               builder: (context) {
//                                                 return AlertDialog(
//                                                     content: Column(
//                                                   mainAxisSize:
//                                                       MainAxisSize.min,
//                                                   children: [
//                                                     Text(
//                                                         'Are you sure you want to delete this manager?'),
//                                                     SizedBox(
//                                                         height:
//                                                             CustomSpacing.two),
//                                                     Row(
//                                                       mainAxisAlignment:
//                                                           MainAxisAlignment.end,
//                                                       children: [
//                                                         TextButton(
//                                                           onPressed: () {
//                                                             Navigator.pop(
//                                                                 context);
//                                                           },
//                                                           child: Text('Cancel'),
//                                                         ),
//                                                         SizedBox(
//                                                             width: CustomSpacing
//                                                                 .two),
//                                                         TextButton(
//                                                           onPressed: () {
//                                                             // Handle delete
//                                                             userProfileProvider.deleteTeamMember(
//                                                                 context,
//                                                                 userProfileProvider
//                                                                         .myManager[
//                                                                             0]!
//                                                                         .id ??
//                                                                     "",
//                                                                 "add_manager");
//                                                             Navigator.pop(
//                                                                 context);
//                                                           },
//                                                           child: Text('Delete'),
//                                                         ),
//                                                       ],
//                                                     ),
//                                                   ],
//                                                 ));
//                                               },
//                                             );
//                                           },
//                                           child: Row(
//                                             children: [
//                                               Icon(Icons.delete),
//                                               SizedBox(
//                                                   width: CustomSpacing.two),
//                                               Text('Delete'),
//                                             ],
//                                           ),
//                                         ),
//                                       );
//                                     }
//
//                                     return items;
//                                   },
//                                 ),
//                         ],
//                       )),
//                       // Role Chip
//                       userProfileProvider.myManager[0]?.role == null
//                           ? SizedBox()
//                           : Row(
//                               mainAxisAlignment: MainAxisAlignment.end,
//                               children: [
//                                 Padding(
//                                   padding: const EdgeInsets.only(right: 8.0),
//                                   child: Chip(
//                                     label: Text(userProfileProvider
//                                             .myManager[0]?.role ??
//                                         ""),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                       SizedBox(height: CustomSpacing.two),
//                     ],
//                   ),
//                 ),
//         ],
//       ),
//     );
//   }
//
//   _delegateCardUI(UserProfileProvider userProfileProvider) {
//     var typography = CustomTypography(context);
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           SizedBox(height: CustomSpacing.two),
//           Container(
//             padding:
//                 const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.only(bottom: 6.0),
//                   child: Text(
//                     LanguageService.getTranslated(context,
//                         "user_profile_user_management_row_name_Delegate"),
//                     style: typography.Body1,
//                   ),
//                 ),
//                 !showAddDelegate
//                     ? SizedBox()
//                     : userProfileProvider.myReportee.isEmpty
//                         ? SizedBox(
//                             height: 40,
//                           )
//                         : Builder(builder: (context) {
//                             return Row(
//                               mainAxisSize: MainAxisSize.min,
//                               mainAxisAlignment: MainAxisAlignment.end,
//                               children: [
//                                 userProfileProvider.myDeligate.isNotEmpty &&
//                                         userProfileProvider.myDeligate[0] !=
//                                             null
//                                     ? SizedBox(
//                                         height: 48,
//                                       )
//                                     : IconButton(
//                                         onPressed: () {
//                                           // Handle submit button
//                                           showDialog(
//                                             context: context,
//                                             builder: (localContext) {
//                                               return AlertDialog(
//                                                 content: _addMemberDialogUI(
//                                                     localContext,
//                                                     "add_delegate"),
//                                               );
//                                             },
//                                           );
//                                         },
//                                         icon: Icon(
//                                           Icons.add,
//                                           color: AppColors.primaryMain,
//                                         ),
//                                       ),
//                               ],
//                             );
//                           }),
//               ],
//             ),
//           ),
//           userProfileProvider.myDeligate.isEmpty ||
//                   userProfileProvider.myDeligate[0] == null
//               ? SizedBox()
//               : Container(
//                   color: Theme.of(context).colorScheme.background,
//                   child: Column(
//                     children: [
//                       SizedBox(height: CustomSpacing.four),
//                       Container(
//                           child: Row(
//                         children: [
//                           // Manager Image Avatar, Name and email as column, role chip, actions as search and delete
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: CircleAvatar(
//                               radius: 24,
//                               child: userProfileProvider
//                                               .myDeligate[0]?.displayImageUrl !=
//                                           null &&
//                                       userProfileProvider
//                                               .myDeligate[0]?.displayImageUrl !=
//                                           ''
//                                   ? ClipOval(
//                                       child: Image.network(
//                                         userProfileProvider
//                                             .myDeligate[0]!.displayImageUrl!,
//                                         fit: BoxFit.cover,
//                                       ),
//                                     )
//                                   : Text(
//                                       userProfileProvider.myDeligate[0]?.name
//                                               ?.substring(0, 1)
//                                               .toUpperCase() ??
//                                           "",
//                                     ),
//                             ),
//                           ),
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                   userProfileProvider.myDeligate[0]?.name ?? "",
//                                   style: typography.Body1),
//                               Text(
//                                   userProfileProvider.myDeligate[0]?.email ??
//                                       "",
//                                   style: typography.Body2),
//                             ],
//                           ),
//
//                           Spacer(),
//                           // Actions
//                           PopupMenuButton<PopupMenuEntry<dynamic>>(
//                             itemBuilder: (BuildContext context) {
//                               List<PopupMenuEntry<PopupMenuEntry<dynamic>>>
//                                   items = [];
//
//                               /*if (userProfileProvider.myDeligate.isNotEmpty && userProfileProvider.myDeligate[0] != null) {
//                           items.add(
//                             PopupMenuItem(
//                               onTap: () {
//                                 // Handle search
//                                 showDialog(
//                                   context: context,
//                                   builder: (context) => _addMemberDialogUI(context, "add_deligate"),
//                                 );
//                               },
//                               child: Row(
//                                 children: [
//                                   Icon(Icons.search),
//                                   SizedBox(width: CustomSpacing.two),
//                                   Text('Search'),
//                                 ],
//                               ),
//                             ),
//                           );
//                         }*/
//
//                               if (showRevokeDelegate) {
//                                 items.add(
//                                   PopupMenuItem(
//                                     onTap: () {
//                                       // Show delete dialog and pop off the menu also on ok
//                                       showDialog(
//                                         context: context,
//                                         builder: (context) {
//                                           return AlertDialog(
//                                               content: Column(
//                                             mainAxisSize: MainAxisSize.min,
//                                             children: [
//                                               Text(
//                                                   'Are you sure you want to delete this delegate?'),
//                                               SizedBox(
//                                                   height: CustomSpacing.two),
//                                               Row(
//                                                 mainAxisAlignment:
//                                                     MainAxisAlignment.end,
//                                                 children: [
//                                                   TextButton(
//                                                     onPressed: () {
//                                                       Navigator.pop(context);
//                                                     },
//                                                     child: Text('Cancel'),
//                                                   ),
//                                                   SizedBox(
//                                                       width: CustomSpacing.two),
//                                                   TextButton(
//                                                     onPressed: () {
//                                                       // Handle delete
//                                                       userProfileProvider
//                                                           .deleteTeamMember(
//                                                               context,
//                                                               userProfileProvider
//                                                                       .myDeligate[
//                                                                           0]!
//                                                                       .id ??
//                                                                   "",
//                                                               "add_deligate");
//                                                       Navigator.pop(context);
//                                                     },
//                                                     child: Text('Delete'),
//                                                   ),
//                                                 ],
//                                               ),
//                                             ],
//                                           ));
//                                         },
//                                       );
//                                     },
//                                     child: Row(
//                                       children: [
//                                         Icon(Icons.delete),
//                                         SizedBox(width: CustomSpacing.two),
//                                         Text('Delete'),
//                                       ],
//                                     ),
//                                   ),
//                                 );
//                               }
//
//                               return items;
//                             },
//                           ),
//                         ],
//                       )),
//                       // Role Chip
//                       userProfileProvider.myDeligate[0]?.role == null
//                           ? SizedBox()
//                           : Row(
//                               mainAxisAlignment: MainAxisAlignment.end,
//                               children: [
//                                 Padding(
//                                   padding: const EdgeInsets.only(right: 8.0),
//                                   child: Chip(
//                                     label: Text(userProfileProvider
//                                             .myDeligate[0]?.role ??
//                                         ""),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                       SizedBox(height: CustomSpacing.two),
//                     ],
//                   ),
//                 ),
//         ],
//       ),
//     );
//   }
//
//   _reporteesCardUI(UserProfileProvider userProfileProvider) {
//     var typography = CustomTypography(context);
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           SizedBox(height: CustomSpacing.two),
//           Container(
//             padding:
//                 const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.only(bottom: 6.0),
//                   child: Text(
//                     LanguageService.getTranslated(context,
//                         "user_profile_user_management_row_name_reportee"),
//                     style: typography.Body1,
//                   ),
//                 ),
//                 !showAddReportee
//                     ? SizedBox()
//                     : Row(
//                         mainAxisSize: MainAxisSize.min,
//                         mainAxisAlignment: MainAxisAlignment.end,
//                         children: [
//                           IconButton(
//                             onPressed: () {
//                               // Handle submit button
//                               showAdaptiveDialog(
//                                 context: context,
//                                 builder: (localContext) {
//                                   return AlertDialog(
//                                     content: _addMemberDialogUI(
//                                         localContext, "add_reportee"),
//                                   );
//                                 },
//                               );
//                             },
//                             icon: Icon(
//                               Icons.add,
//                               color: AppColors.primaryMain,
//                             ),
//                           ),
//                         ],
//                       ),
//               ],
//             ),
//           ),
//           userProfileProvider.myReportee.isEmpty ||
//                   userProfileProvider.myReportee[0] == null
//               ? SizedBox()
//               : SizedBox(
//                   height: MediaQuery.of(context).size.height * 0.5,
//                   child: ListView.builder(
//                       shrinkWrap: true,
//                       physics: ClampingScrollPhysics(),
//                       itemCount: userProfileProvider.myReportee.length,
//                       itemBuilder: (context, index) {
//                         return _reporteesListCardUI(userProfileProvider, index);
//                       }),
//                 ),
//         ],
//       ),
//     );
//   }
//
//   _reporteesListCardUI(UserProfileProvider userProfileProvider, int index) {
//     var typography = CustomTypography(context);
//     return Container(
//       color: Theme.of(context).colorScheme.background,
//       child: Column(
//         children: [
//           SizedBox(height: CustomSpacing.four),
//           Row(
//             children: [
//               // Manager Image Avatar, Name and email as column, role chip, actions as search and delete
//               Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: CircleAvatar(
//                   radius: 24,
//                   child:
//                       userProfileProvider.myReportee[index]?.displayImageUrl !=
//                                   null &&
//                               userProfileProvider
//                                       .myReportee[index]?.displayImageUrl !=
//                                   ''
//                           ? ClipOval(
//                               child: Image.network(
//                                 userProfileProvider
//                                     .myReportee[index]!.displayImageUrl!,
//                                 fit: BoxFit.cover,
//                               ),
//                             )
//                           : Text(
//                               userProfileProvider.myReportee[index]?.name
//                                       ?.substring(0, 1)
//                                       .toUpperCase() ??
//                                   "",
//                             ),
//                 ),
//               ),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(userProfileProvider.myReportee[index]?.name ?? "",
//                       style: typography.Body1),
//                   Text(userProfileProvider.myReportee[index]?.email ?? "",
//                       style: typography.Body2),
//                 ],
//               ),
//
//               Spacer(),
//               // Actions
//               !showAddReportee
//                   ? SizedBox()
//                   : PopupMenuButton(
//                       itemBuilder: (BuildContext context) {
//                         return [
//                           /*PopupMenuItem(
//                       onTap: () {
//                         // Handle search
//                         showDialog(
//                           context: context,
//                           builder: (context) => _addMemberDialogUI(context, "add_reportee"),
//                         );
//                       },
//                       child: Row(
//                         children: [
//                           Icon(Icons.search),
//                           SizedBox(width: CustomSpacing.two),
//                           Text('Search'),
//                         ],
//                       ),
//                     ),*/
//                           PopupMenuItem(
//                             onTap: () {
//                               // Show delete dialog and pop off the menu also on ok
//                               showDialog(
//                                 context: context,
//                                 builder: (context) {
//                                   return AlertDialog(
//                                       content: Column(
//                                     mainAxisSize: MainAxisSize.min,
//                                     children: [
//                                       Text(
//                                           'Are you sure you want to delete this reportee?'),
//                                       SizedBox(height: CustomSpacing.two),
//                                       Row(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.end,
//                                         children: [
//                                           TextButton(
//                                             onPressed: () {
//                                               Navigator.pop(context);
//                                             },
//                                             child: Text('Cancel'),
//                                           ),
//                                           SizedBox(width: CustomSpacing.two),
//                                           TextButton(
//                                             onPressed: () {
//                                               // Handle delete
//                                               userProfileProvider
//                                                   .deleteTeamMember(
//                                                       context,
//                                                       userProfileProvider
//                                                               .myReportee[
//                                                                   index]!
//                                                               .id ??
//                                                           "",
//                                                       "add_reportee");
//                                               Navigator.pop(context);
//                                             },
//                                             child: Text('Delete'),
//                                           ),
//                                         ],
//                                       ),
//                                     ],
//                                   ));
//                                 },
//                               );
//                             },
//                             child: Row(
//                               children: [
//                                 Icon(Icons.delete),
//                                 SizedBox(width: CustomSpacing.two),
//                                 Text('Delete'),
//                               ],
//                             ),
//                           ),
//                         ];
//                       },
//                     ),
//             ],
//           ),
//           // Role Chip
//           userProfileProvider.myReportee[index]?.role == null
//               ? SizedBox()
//               : Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     Padding(
//                       padding: const EdgeInsets.only(right: 8.0),
//                       child: Chip(
//                         label: Text(
//                             userProfileProvider.myReportee[index]?.role ?? ""),
//                       ),
//                     ),
//                   ],
//                 ),
//           SizedBox(height: CustomSpacing.two),
//         ],
//       ),
//     );
//   }
//
//   _addMemberDialogUI(BuildContext localContext, String type) {
//     var typography = CustomTypography(context);
//     return SingleChildScrollView(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           SizedBox(height: CustomSpacing.two),
//           Text(
//               type == "add_manager"
//                   ? LanguageService.getTranslated(
//                       context, "user_profile_user_management_add_manager_btn")
//                   : type == 'add_delegate'
//                       ? LanguageService.getTranslated(context,
//                           "user_profile_user_management_add_delegate_btn")
//                       : LanguageService.getTranslated(
//                           context, "user_profile_user_management_add_reportee"),
//               style: typography.H5_Regular),
//           SizedBox(height: CustomSpacing.two),
//           // Search Box with Autocomplete
//           Autocomplete<NetworkingUsers>(
//             optionsBuilder: (TextEditingValue textEditingValue) {
//               if (textEditingValue.text == '') {
//                 return const Iterable<NetworkingUsers>.empty();
//               } else {
//                 return Future.delayed(Duration.zero, () async {
//                   _managerList = await searchNetworks(textEditingValue.text);
//                   print("Manager List: $_managerList");
//                   return _managerList;
//                 });
//               }
//             },
//             onSelected: (NetworkingUsers selection) {
//               setState(() {
//                 _selectedManager = selection;
//               });
//             },
//             fieldViewBuilder: (BuildContext context,
//                 TextEditingController textEditingController,
//                 FocusNode focusNode,
//                 VoidCallback onFieldSubmitted) {
//               return SizedBox(
//                 height: 50,
//                 child: TextField(
//                   controller: textEditingController,
//                   focusNode: focusNode,
//                   decoration: InputDecoration(
//                     hintText: 'Search by name or email',
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     suffixIcon: IconButton(
//                       onPressed: onFieldSubmitted,
//                       icon: Icon(Icons.search),
//                     ),
//                   ),
//                 ),
//               );
//             },
//             displayStringForOption: (NetworkingUsers option) {
//               // Assuming _searchResults is a list of User objects
//               NetworkingUsers user =
//                   _managerList.firstWhere((user) => user.id == option.id);
//               return '${user.name} (${user.email})';
//             },
//             optionsViewBuilder: (BuildContext context,
//                 AutocompleteOnSelected<NetworkingUsers> onSelected,
//                 Iterable<NetworkingUsers> options) {
//               return Align(
//                 alignment: Alignment.topLeft,
//                 child: Material(
//                   child: ListView.builder(
//                     padding: EdgeInsets.all(10),
//                     itemCount: options.length,
//                     itemBuilder: (BuildContext context, int index) {
//                       NetworkingUsers option = options.elementAt(index);
//                       NetworkingUsers user = _managerList
//                           .firstWhere((user) => user.id == option.id);
//                       return GestureDetector(
//                         onTap: () {
//                           onSelected(option);
//                         },
//                         child: ListTile(
//                           leading: CircleAvatar(
//                             child: user.displayImageUrl != null &&
//                                     user.displayImageUrl != ''
//                                 ? ClipOval(
//                                     child: CachedNetworkImage(
//                                       imageUrl: user.displayImageUrl!,
//                                       fit: BoxFit.cover,
//                                     ),
//                                   )
//                                 : Text(
//                                     user.name?.substring(0, 1).toUpperCase() ??
//                                         "",
//                                   ),
//                           ),
//                           title: Text(user.name ?? "",
//                               style: typography.Body1.copyWith(
//                                   color: Theme.of(context)
//                                       .textTheme
//                                       .labelMedium
//                                       ?.color)),
//                           subtitle: Text(user.email ?? "",
//                               style: typography.Subtitle1.copyWith(
//                                   color: Theme.of(context)
//                                       .textTheme
//                                       .labelMedium
//                                       ?.color)),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               );
//             },
//           ),
//           SizedBox(height: CustomSpacing.two),
//           // Cancel and Submit Buttons
//           Row(
//             children: [
//               Expanded(
//                 child: OutlinedButton(
//                   onPressed: () {
//                     Navigator.of(localContext).pop();
//                   },
//                   style: ElevatedButton.styleFrom(
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     padding: EdgeInsets.symmetric(horizontal: 22, vertical: 8),
//                   ),
//                   child: Text(
//                     LanguageService.getTranslated(
//                         context, "user_profile_user_management_btn_cancel"),
//                     style: typography.ButtonLarge,
//                   ),
//                 ),
//               ),
//               SizedBox(width: CustomSpacing.two),
//               Expanded(
//                 child: CustomButton(
//                   onPressed: () {
//                     // Handle submit button
//                     switch (type) {
//                       case 'add_manager':
//                         Provider.of<UserProfileProvider>(localContext,
//                                 listen: false)
//                             .addTeamMember(context, _selectedManager?.id ?? "",
//                                 "add_manager")
//                             .then((value) {
//                           Navigator.pop(localContext);
//                           if (value) {
//                             Future.delayed(Duration(seconds: 1), () {
//                               Provider.of<UserProfileProvider>(context,
//                                       listen: false)
//                                   .getUserTeamMembers(context);
//                             });
//                           }
//                         });
//                         break;
//                       case 'add_delegate':
//                         Provider.of<UserProfileProvider>(localContext,
//                                 listen: false)
//                             .addTeamMember(context, _selectedManager?.id ?? "",
//                                 "add_delegate")
//                             .then((value) {
//                           Navigator.pop(localContext);
//                           if (value) {
//                             Future.delayed(Duration(seconds: 1), () {
//                               Provider.of<UserProfileProvider>(context,
//                                       listen: false)
//                                   .getUserTeamMembers(context);
//                             });
//                           }
//                         });
//                         break;
//                       case 'add_reportee':
//                         Provider.of<UserProfileProvider>(localContext,
//                                 listen: false)
//                             .addTeamMember(context, _selectedManager?.id ?? "",
//                                 "add_reportee")
//                             .then((value) {
//                           Navigator.pop(localContext);
//                           if (value) {
//                             Future.delayed(Duration(seconds: 1), () {
//                               Provider.of<UserProfileProvider>(context,
//                                       listen: false)
//                                   .getUserTeamMembers(context);
//                             });
//                           }
//                         });
//                     }
//                   },
//                   type: ButtonType.filled,
//                   child: Text(
//                     LanguageService.getTranslated(
//                         context, "user_profile_user_management_btn_submit"),
//                     style: typography.ButtonLarge,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   _getSecurityUI() {
//     var typography = CustomTypography(context);
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Center(
//         // Directly center the entire column
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             Text(
//               LanguageService.getTranslated(context, 'coming_soon_title'),
//               style: typography.H4,
//               textAlign: TextAlign.center, // Ensure the text is centered
//             ),
//             SizedBox(
//               height: CustomSpacing.two,
//             ),
//             Text(
//               LanguageService.getTranslated(context, 'coming_soon_subtitle'),
//               style: typography.Body1,
//               textAlign: TextAlign.center, // Ensure the text is centered
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _addChip(Categories value) {
//     setState(() {
//       _selectedRoles.add(value);
//       _textEditingController.clear();
//     });
//   }
//
//   void _removeChip(Categories value) {
//     print('Removing chip: ${value.name}');
//     setState(() {
//       _selectedRoles.removeWhere((element) => element.name == value.name);
//     });
//     print(
//         'Selected roles: ${_selectedRoles.map((role) => role.name).toList()}');
//   }
//
//   void _removeAllChips() {
//     setState(() {
//       _selectedRoles.clear();
//     });
//   }
// }

import 'package:cached_network_image/cached_network_image.dart';

import '../../models/user_profile_model.dart';
import '../../utils/global_imports.dart';
import 'package:RiskSphere/models/networking_model.dart';
import 'package:image_picker/image_picker.dart';
import '../../design_system/components/custom_flexible_roles_bottom_sheet.dart';
import '../../design_system/repo/constants.dart';
import '../../models/initial_data_model.dart';
import 'package:image/image.dart' as img;
import '../../utils/utils.dart';
import 'package:http/http.dart' as http;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  bool _showNotificationDot = true;
  TabController? _tabController;
  Screens _selectedScreen = Screens.connectionList;
  List<Categories> _selectedRoles = [];
  List<AcceptedRole> _selectedAcceptRole = [];

  TextEditingController _textEditingController = TextEditingController();
  SignUpOptions? _selectedOption;
  String _selectedCountryCode = '+1';
  TextEditingController mobileController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  // PhoneController phoneController =
  //     PhoneController(PhoneNumber(isoCode: IsoCode.US, nsn: ''));

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // form key
  final _formKey = GlobalKey<FormState>();

  bool isEdit = false;

  bool showAssignDeleteManager = true;
  bool showAddDelegate = true;
  bool showRevokeDelegate = true;
  bool showAddReportee = true;
  bool showEditUser = true;
  bool showMyTeams = true;
  bool isPgAdmin = false;
  bool isAdmin = false;
  bool isSuperAdmin = false;
  bool isIndividual = false;

  // General Info
  String userImageUrl = '';
  TextEditingController _nameGeneralInfoController = TextEditingController();
  TextEditingController _displayNameGeneralInfoController =
      TextEditingController();
  TextEditingController _emailGeneralInfoController = TextEditingController();
  TextEditingController _phoneGeneralInfoController = TextEditingController();
  String nameLabelText = "";
  String displayNameLabelText = "";
  String emailLabelText = "";
  String phoneLabelText = "";
  String selectedAvatar = "";
  String selectedCountryCode = "+1";

  // My Team
  Timer? deBouncer;
  List<NetworkingUsers> _managerList = [];
  NetworkingUsers? _selectedManager;

  bool _tabsLoading = true;
  int _tabLength = 3;

  void debounce(
    VoidCallback callback, {
    Duration duration = const Duration(seconds: 1),
  }) {
    if (deBouncer != null) {
      deBouncer!.cancel();
    }
    deBouncer = Timer(duration, callback);
  }

  @override
  void initState() {
    super.initState();
    _setClaims();
    _getData();
  }

  _setClaims() async {
    _selectedScreen = Screens.generalInfo;
    isPgAdmin = await SharedPreferenceService.getClaimForSubfeature(
            SharedPreferenceService.IS_PG_ADMIN) ??
        false;
    isAdmin = await SharedPreferenceService.getClaimForSubfeature(
            SharedPreferenceService.IS_ADMIN) ??
        false;
    isSuperAdmin = await SharedPreferenceService.getClaimForSubfeature(
            SharedPreferenceService.IS_SUPER_ADMIN) ??
        false;
    isIndividual = await SharedPreferenceService.getClaimForSubfeature(
            SharedPreferenceService.Is_Indivudual) ??
        false;
    // isPgAdmin = false;
    // isAdmin = true;
    // isSuperAdmin = true;
    showAssignDeleteManager =
        await SharedPreferenceService.getClaimForSubfeature(
                SharedPreferenceService.CUMAM) ??
            false;
    showAddDelegate = await SharedPreferenceService.getClaimForSubfeature(
            SharedPreferenceService.CUMDA) ??
        false;
    showRevokeDelegate = await SharedPreferenceService.getClaimForSubfeature(
            SharedPreferenceService.CUMRD) ??
        false;
    showAddReportee = await SharedPreferenceService.getClaimForSubfeature(
            SharedPreferenceService.CUMRE) ??
        false;
    //showEditUser = await SharedPreferenceService.getClaimForSubfeature(SharedPreferenceService.CAMVC)??false;
    print(
        '1st claim: ${await SharedPreferenceService.getClaimForSubfeature(SharedPreferenceService.NCMEU) ?? false}');
    print(
        '2nd claim: ${await SharedPreferenceService.getClaimForSubfeature(SharedPreferenceService.CUMEU) ?? false}');
    print(
        '3rd claim: ${await SharedPreferenceService.getClaimForSubfeature(SharedPreferenceService.EMPEU) ?? false}');
    showEditUser = (await SharedPreferenceService.getClaimForSubfeature(
                SharedPreferenceService.NCMEU) ??
            false) ||
        ((await SharedPreferenceService.getClaimForSubfeature(
                    SharedPreferenceService.CUMEU) ??
                false) ||
            (await SharedPreferenceService.getClaimForSubfeature(
                    SharedPreferenceService.EMPEU) ??
                false));
    bool showNonCorporateMyTeams =
        await SharedPreferenceService.getClaimForSubfeature(
                SharedPreferenceService.NCMMT) ??
            false;
    bool showEmployeeMyTeams =
        await SharedPreferenceService.getClaimForSubfeature(
                SharedPreferenceService.EMPMT) ??
            false;
    User user = FirebaseAuth.instance.currentUser!;
    await user.getIdTokenResult().then((value) {
      if (value.claims != null) {
        if (value.claims!['isIndividual'] == true) {
          showMyTeams = showNonCorporateMyTeams;
          print('isIndividual: $showMyTeams');
        } else if (value.claims!['internal'] == true) {
          showMyTeams = showEmployeeMyTeams;
          print('isInternal: $showMyTeams');
        } else {
          showMyTeams = true;
          print('external: $showMyTeams');
        }
      }
    });

    if (!showMyTeams) {
      _tabLength = 2;
    }

    _tabController = TabController(length: _tabLength, vsync: this);
    _tabController?.addListener(() {
      if (_tabLength == 3) {
        if (_tabController?.index == 0) {
          setState(() {
            _selectedScreen = Screens.generalInfo;
          });
        } else if (_tabController?.index == 1) {
          setState(() {
            _selectedScreen = Screens.teamsScreen;
          });
        } else if (_tabController?.index == 2) {
          setState(() {
            _selectedScreen = Screens.securityScreen;
          });
        }
      } else if (_tabLength == 2) {
        if (_tabController?.index == 0) {
          setState(() {
            _selectedScreen = Screens.generalInfo;
          });
        } else if (_tabController?.index == 1) {
          setState(() {
            _selectedScreen = Screens.securityScreen;
          });
        }
      }
      print(
          'Tab Index: ${_tabController?.index} Selected Screen: $_selectedScreen');
    });
    setState(() {
      _tabsLoading = false;
    });
  }

  _getData() {
    Provider.of<UserProfileProvider>(context, listen: false)
        .getAllUserData(context, '', '')
        .then((value) {
      if (value != null) {
        setState(() {
          userImageUrl = value.displayImageUrl ?? "";
          nameLabelText = value.name ?? "";
          _nameGeneralInfoController.text = value.name ?? "";
          displayNameLabelText = value.displayName ?? value.name ?? "";
          _displayNameGeneralInfoController.text =
              value.displayName ?? value.name ?? "";
          emailLabelText = value.email ?? "";
          _emailGeneralInfoController.text = value.email ?? "";
          phoneLabelText = value.phone ?? "";
          _phoneGeneralInfoController.text = value.phone ?? "";
          print('Country Code: ${value.countryCode}');
          // remove '+' from country code
          _selectedCountryCode = value.countryCode?.replaceAll('+', '') ?? "1";
          print('Country Code: ${countryCodeToIsoCode[_selectedCountryCode]}');
          phoneController.text = value.phone ?? "";
          // Set roles and assign from List<Roles> to List<Categories>
          _selectedRoles = (value.role ?? [])
              .map((role) => Categories(
                    id: role.id ?? "",
                    name: role.name ?? "",
                    role: role.role ?? "",
                    isForIndividual: role.isForIndividual ?? false,
                    isMultipleRoleEnabled: role.isMultipleRoleEnabled ?? false,
                    isApplicableForTrial: role.isApplicableForTrial ?? false,
                  ))
              .toList();
          _selectedAcceptRole = value.acceptedRole!;
          _selectedCountryCode = value.countryCode ?? "+1";
        });
      }
    });
    Provider.of<UserProfileProvider>(context, listen: false)
        .getAvatarUrls(context);
    Provider.of<UserProfileProvider>(context, listen: false)
        .getUserTeamMembers(context);
  }

  Future<List<NetworkingUsers>> searchNetworks(String query) async =>
      Provider.of<UserProfileProvider>(context, listen: false)
          .getUserSuggestions(context, query);

  @override
  Widget build(BuildContext context1) {
    var typography = CustomTypography(context1);
    return SafeArea(
      child: Consumer<ThemeProvider>(
          builder: (buildContext, themeProvider, child) {
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: themeProvider.getTheme.colorScheme.background,
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
            stopNavigateToProfile: _selectedScreen == Screens.generalInfo,
          ),
          drawer: CustomDrawer(),
          body: _tabsLoading
              ? Column(
                  children: [
                    SizedBox(
                      height: CustomSpacing.four,
                    ),
                    Center(
                      child: CircularProgressIndicator(),
                    )
                  ],
                )
              : PopScope(
                  canPop: _selectedScreen == Screens.generalInfo,
                  onPopInvoked: (canPop) {
                    print(
                        'Can Pop: $canPop, Selected Screen: $_selectedScreen');
                    if (_selectedScreen != Screens.generalInfo) {
                      setState(() {
                        _selectedScreen = Screens.generalInfo;
                        _tabController?.animateTo(0);
                      });
                    }
                  },
                  child: Stack(
                    children: [
                      // Background image
                      Positioned.fill(
                        child: Image.asset(
                          'assets/images/mesh.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                      Column(
                        children: [
                          SizedBox(height: CustomSpacing.four),
                          Expanded(
                            child: Container(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text(
                                        LanguageService.getTranslated(context,
                                            "user_profile_user_management_title"),
                                        style: typography.H5_Regular),
                                  ),
                                  // Add 3 tabs
                                  SizedBox(
                                    height: CustomSpacing.two,
                                  ),
                                  TabBar(
                                    controller: _tabController,
                                    labelStyle:
                                        typography.BottomNavigationActiveLabel,
                                    tabs: _tabLength == 3
                                        ? [
                                            Tab(
                                              child: InkWell(
                                                onTap: () {
                                                  _tabController?.animateTo(0);
                                                  _selectedScreen =
                                                      Screens.connectionList;
                                                },
                                                child: Tab(
                                                  text: LanguageService
                                                      .getTranslated(context,
                                                          "user_profile_app_user_management_general_info_tab"),
                                                ),
                                              ),
                                            ),
                                            !showMyTeams
                                                ? SizedBox()
                                                : InkWell(
                                                    onTap: () {
                                                      _tabController
                                                          ?.animateTo(1);
                                                      _selectedScreen =
                                                          Screens.requestList;
                                                    },
                                                    child: Tab(
                                                      text: LanguageService
                                                          .getTranslated(
                                                              context,
                                                              "user_profile_app_user_management_my_team_tab"),
                                                    ),
                                                  ),
                                            InkWell(
                                              onTap: () {
                                                _tabController?.animateTo(2);
                                                _selectedScreen =
                                                    Screens.chatList;
                                              },
                                              child: Tab(
                                                text: LanguageService.getTranslated(
                                                    context,
                                                    "user_profile_app_user_management_security_tab"),
                                              ),
                                            ),
                                          ]
                                        : [
                                            Tab(
                                              child: InkWell(
                                                onTap: () {
                                                  _tabController?.animateTo(0);
                                                  _selectedScreen =
                                                      Screens.connectionList;
                                                },
                                                child: Tab(
                                                  text: LanguageService
                                                      .getTranslated(context,
                                                          "user_profile_app_user_management_general_info_tab"),
                                                ),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                _tabController?.animateTo(1);
                                                _selectedScreen =
                                                    Screens.chatList;
                                              },
                                              child: Tab(
                                                text: LanguageService.getTranslated(
                                                    context,
                                                    "user_profile_app_user_management_security_tab"),
                                              ),
                                            ),
                                          ],
                                  ),

                                  // Add 3 tab views
                                  Expanded(
                                    child: TabBarView(
                                      controller: _tabController,
                                      children: _tabLength == 3
                                          ? [
                                              // General Info
                                              _getGeneralInfoUI(),
                                              // My Team
                                              !showMyTeams
                                                  ? SizedBox()
                                                  : _getMyTeamUI(),
                                              // Security
                                              _getSecurityUI(),
                                            ]
                                          : [
                                              // General Info
                                              _getGeneralInfoUI(),
                                              // Security
                                              _getSecurityUI(),
                                            ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
          // endDrawer: Material(
          //   child: Container(
          //     margin: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          //     child: SingleChildScrollView(
          //       child: Column(
          //         children: [
          //           SizedBox(height: CustomSpacing.two),
          //           // Circular elevated icon for filter
          //           Center(
          //               child: Container(
          //             decoration: BoxDecoration(
          //               color: Theme.of(context).colorScheme.surface,
          //               shape: BoxShape.circle,
          //               boxShadow: [
          //                 BoxShadow(
          //                   color: Colors.black.withOpacity(0.1),
          //                   blurRadius: 8,
          //                   offset: Offset(0, 4),
          //                 ),
          //               ],
          //             ),
          //             child: Padding(
          //               padding: const EdgeInsets.all(16.0),
          //               child: Icon(
          //                 Icons.filter_alt_outlined,
          //                 size: 32,
          //               ),
          //             ),
          //           )),
          //           SizedBox(height: CustomSpacing.six),
          //           // name, phone, email, company, role dropdown, status,
          //           Form(
          //             child: Column(
          //               children: [
          //                 // Name
          //                 TextFormField(
          //                   decoration: InputDecoration(
          //                     labelText: LanguageService.getTranslated(
          //                         context, "usermanagement_app_filter_name"),
          //                     labelStyle: typography.Body1,
          //                     border: OutlineInputBorder(
          //                       borderRadius: BorderRadius.circular(8),
          //                     ),
          //                   ),
          //                 ),
          //                 SizedBox(
          //                   height: CustomSpacing.two,
          //                 ),
          //                 // Email
          //                 TextFormField(
          //                   decoration: InputDecoration(
          //                     labelText: LanguageService.getTranslated(
          //                         context, "usermanagement_app_filter_email"),
          //                     labelStyle: typography.Body1,
          //                     border: OutlineInputBorder(
          //                       borderRadius: BorderRadius.circular(8),
          //                     ),
          //                   ),
          //                 ),
          //                 SizedBox(
          //                   height: CustomSpacing.two,
          //                 ),
          //                 // Phone
          //                 Row(
          //                   children: [
          //                     Expanded(
          //                       flex: 4,
          //                       child: Container(
          //                         decoration: BoxDecoration(
          //                           border: Border.all(
          //                               color: Colors.white.withOpacity(0.5)),
          //                           borderRadius: BorderRadius.circular(4),
          //                         ),
          //                         padding:
          //                             const EdgeInsets.symmetric(vertical: 2.0),
          //                         child: Center(
          //                           child: Container(),
          //                         ),
          //                       ),
          //                     ),
          //                     SizedBox(width: CustomSpacing.two),
          //                     // Mobile Number TextFormField
          //                     Expanded(
          //                       flex: 7,
          //                       child: TextFormField(
          //                         keyboardType: TextInputType.number,
          //                         maxLength: 10,
          //                         // Numeric keyboard
          //                         inputFormatters: <TextInputFormatter>[
          //                           FilteringTextInputFormatter.digitsOnly
          //                           // Only allows digits
          //                         ],
          //                         decoration: InputDecoration(
          //                           labelText: LanguageService.getTranslated(
          //                               context,
          //                               "usermanagement_app_filter_phone"),
          //                           hintText: LanguageService.getTranslated(
          //                               context,
          //                               "usermanagement_app_filter_phone_hint"),
          //                           border: const OutlineInputBorder(),
          //                           counterText: '',
          //                         ),
          //                         validator: (value) {
          //                           if (!RegExp(r'^[0-9]+$').hasMatch(value!)) {
          //                             return LanguageService.getTranslated(
          //                                 context,
          //                                 "usermanagement_app_filter_phone_validation");
          //                           }
          //                           return null;
          //                         },
          //                         controller: mobileController,
          //                       ),
          //                     ),
          //                     // Dropdown Icon Suffix
          //                   ],
          //                 ),
          //                 SizedBox(height: CustomSpacing.two),
          //                 // Company
          //                 TextFormField(
          //                   decoration: InputDecoration(
          //                     labelText: LanguageService.getTranslated(
          //                         context, "usermanagement_app_filter_company"),
          //                     labelStyle: typography.Body1,
          //                     border: OutlineInputBorder(
          //                       borderRadius: BorderRadius.circular(8),
          //                     ),
          //                   ),
          //                 ),
          //                 SizedBox(height: CustomSpacing.two),
          //                 // Role Dropdown
          //                 Stack(
          //                   children: [
          //                     TextField(
          //                       readOnly: true,
          //                       onTap: () {
          //                         showBottomSheet(
          //                           context: context,
          //                           builder: (BuildContext context) {
          //                             return RolesBottomSheet(
          //                               showCorporateSwitch: true,
          //                               // isUserProfile: true,
          //                               // options: roles,
          //                               options:
          //                                   context.read<AuthNotifier>().roles,
          //                               selectedRoles: _selectedRoles,
          //                               addChip: _addChip,
          //                               removeChip: _removeChip,
          //                               removeAllChips: _removeAllChips,
          //                               selectedOption: SignUpOptions.corporate,
          //                               onOptionChanged:
          //                                   (SignUpOptions option) {
          //                                 setState(() {
          //                                   _selectedOption = option;
          //                                 });
          //                               },
          //                             );
          //                           },
          //                         );
          //                       },
          //                       controller: _textEditingController,
          //                       onChanged: (value) {
          //                         // Handle input changes
          //                       },
          //                       decoration: InputDecoration(
          //                         labelText: LanguageService.getTranslated(
          //                             context,
          //                             "usermanagement_app_filter_roles"),
          //                         hintText: _selectedRoles.isEmpty
          //                             ? 'Select Roles'
          //                             : "",
          //                         border: OutlineInputBorder(),
          //                         suffixIcon: IconButton(
          //                           icon: Icon(Icons.arrow_drop_down),
          //                           onPressed: () {
          //                             showModalBottomSheet(
          //                               context: context,
          //                               useSafeArea: true,
          //                               isScrollControlled: true,
          //                               builder: (BuildContext context) {
          //                                 return RolesBottomSheet(
          //                                   showCorporateSwitch: false,
          //                                   // isUserProfile: true,
          //                                   options: context
          //                                       .read<AuthNotifier>()
          //                                       .roles,
          //                                   // options: roles,
          //                                   selectedRoles: _selectedRoles,
          //                                   addChip: _addChip,
          //                                   removeChip: _removeChip,
          //                                   removeAllChips: _removeAllChips,
          //                                   selectedOption:
          //                                       SignUpOptions.corporate,
          //                                   onOptionChanged:
          //                                       (SignUpOptions signUpOptions) {
          //                                     setState(() {
          //                                       _selectedOption = signUpOptions;
          //                                     });
          //                                   },
          //                                 );
          //                               },
          //                             );
          //                           },
          //                         ),
          //                       ),
          //                     ),
          //                     Positioned(
          //                       top: 10.0,
          //                       left: 10.0,
          //                       right: 10.0,
          //                       child: Container(
          //                         margin: const EdgeInsets.only(right: 32.0),
          //                         child: SingleChildScrollView(
          //                           scrollDirection: Axis.horizontal,
          //                           child: Row(
          //                             children: _selectedRoles
          //                                 .map(
          //                                   (value) => Padding(
          //                                     padding: const EdgeInsets.only(
          //                                         right: 8.0),
          //                                     child: Chip(
          //                                       label: Text(value.name!),
          //                                       deleteIcon: Icon(Icons.cancel),
          //                                       onDeleted: () =>
          //                                           _removeChip(value),
          //                                     ),
          //                                   ),
          //                                 )
          //                                 .toList(),
          //                           ),
          //                         ),
          //                       ),
          //                     ),
          //                   ],
          //                 ),
          //
          //                 SizedBox(height: CustomSpacing.two),
          //                 // Status
          //                 DropdownButtonFormField<String>(
          //                   decoration: InputDecoration(
          //                     labelText: LanguageService.getTranslated(
          //                         context, "usermanagement_app_filter_status"),
          //                     border: OutlineInputBorder(
          //                       borderRadius: BorderRadius.circular(8),
          //                     ),
          //                   ),
          //                   items: ['Active', 'Inactive'].map((String value) {
          //                     return DropdownMenuItem<String>(
          //                       value: value,
          //                       child: Text(value),
          //                     );
          //                   }).toList(),
          //                   onChanged: (String? value) {
          //                     // Handle status change
          //                   },
          //                 ),
          //                 SizedBox(height: CustomSpacing.two),
          //                 // Cancel and Submit Buttons
          //                 Row(
          //                   children: [
          //                     Expanded(
          //                       child: OutlinedButton(
          //                         onPressed: () {
          //                           // Handle cancel button
          //                         },
          //                         style: ElevatedButton.styleFrom(
          //                           shape: RoundedRectangleBorder(
          //                             borderRadius: BorderRadius.circular(8),
          //                           ),
          //                           padding: EdgeInsets.symmetric(
          //                               horizontal: 22, vertical: 8),
          //                         ),
          //                         child: Text(
          //                           LanguageService.getTranslated(context,
          //                               "usermanagement_app_filter_cancel"),
          //                           style: typography.ButtonLarge,
          //                         ),
          //                       ),
          //                     ),
          //                     SizedBox(width: CustomSpacing.two),
          //                     Expanded(
          //                       child: CustomButton(
          //                         onPressed: () {
          //                           Navigator.pop(context);
          //                         },
          //                         type: ButtonType.filled,
          //                         child: Text(
          //                           LanguageService.getTranslated(context,
          //                               "usermanagement_app_filter_submit"),
          //                           style: typography.ButtonLarge,
          //                         ),
          //                       ),
          //                     ),
          //                   ],
          //                 ),
          //               ],
          //             ),
          //           ),
          //         ],
          //       ),
          //     ),
          //   ),
          // ),
        );
      }),
    );
  }

  void _showFiltersBottomSheet(BuildContext context) {
    // show modal bottom sheet using scaffold key
    /*showAdaptiveDialog(
      */ /*shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),*/ /*
      context: context,
      builder: (context) {
        return ;
      },
    );*/
    Scaffold.of(context).openEndDrawer();
  }

  final ImagePicker _picker = ImagePicker();
  File? _pickedImage;

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const Text(
                "Profile Image",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Divider(color: Colors.white24, height: 20),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: const Text("Choose from library",
                    style: TextStyle(color: Colors.white)),
                onTap: _pickFromGallery,
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: const Text("Take a picture",
                    style: TextStyle(color: Colors.white)),
                onTap: _takePicture,
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("Delete photo",
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  setState(() {
                    _pickedImage = null;
                    userImageUrl = '';
                  });
                  Navigator.pop(context);
                },
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel",
                    style: TextStyle(color: Colors.white70)),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickFromGallery() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
    Navigator.pop(context);
  }

  Future<void> _takePicture() async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
    Navigator.pop(context);
  }

  _getGeneralInfoUI() {
    var typography = CustomTypography(context);
    return Consumer<UserProfileProvider>(
        builder: (context, userProfileProvider, child) {
      return !userProfileProvider.isLoading
          ? SingleChildScrollView(
              child: Card(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.paperElavation25
                    : AppColors.paperElavation25Light,
                child: Column(
                  children: [
                    // Profile Pic
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.all(20),
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.paperElavation25
                                      : AppColors.paperElavation25Light,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: CustomSpacing.four,
                                      ),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Add button
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Consumer<
                                                          UserProfileProvider>(
                                                        builder: (_,
                                                            userProfileProvider,
                                                            child) {
                                                          return userProfileProvider
                                                                  .isImageUploadLoading
                                                              ? const Center(
                                                                  child:
                                                                      CircularProgressIndicator(),
                                                                )
                                                              : GestureDetector(
                                                                  onTap: !isEdit
                                                                      ? null
                                                                      : () {
                                                                          showModalBottomSheet(
                                                                            context:
                                                                                context,
                                                                            backgroundColor:
                                                                                Colors.black87,
                                                                            shape:
                                                                                const RoundedRectangleBorder(
                                                                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                                                            ),
                                                                            builder:
                                                                                (context) {
                                                                              return SafeArea(
                                                                                child: Wrap(
                                                                                  children: [
                                                                                    const SizedBox(height: 12),
                                                                                    Center(
                                                                                      child: Container(
                                                                                        height: 4,
                                                                                        width: 40,
                                                                                        decoration: BoxDecoration(
                                                                                          color: Colors.grey[700],
                                                                                          borderRadius: BorderRadius.circular(2),
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                    ListTile(
                                                                                      leading: const Icon(Icons.image, color: Colors.white),
                                                                                      title: const Text(
                                                                                        "Upload Image",
                                                                                        style: TextStyle(color: Colors.white),
                                                                                      ),
                                                                                      onTap: () {
                                                                                        Navigator.pop(context);
                                                                                        _pickAndUploadImage(context, userProfileProvider);
                                                                                      },
                                                                                    ),
                                                                                    ListTile(
                                                                                      leading: const Icon(Icons.person, color: Colors.white),
                                                                                      title: const Text(
                                                                                        "Choose Avatar",
                                                                                        style: TextStyle(color: Colors.white),
                                                                                      ),
                                                                                      onTap: () {
                                                                                        Navigator.pop(context);
                                                                                        _showAvatarBottomSheet(context, userProfileProvider);
                                                                                      },
                                                                                    ),
                                                                                    ListTile(
                                                                                      leading: const Icon(Icons.delete, color: Colors.red),
                                                                                      title: const Text(
                                                                                        "Delete Photo",
                                                                                        style: TextStyle(color: Colors.red),
                                                                                      ),
                                                                                      onTap: () {
                                                                                        setState(() {
                                                                                          userImageUrl = '';
                                                                                        });
                                                                                        Navigator.pop(context);
                                                                                      },
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              );
                                                                            },
                                                                          );
                                                                        },
                                                                  child: Stack(
                                                                    alignment:
                                                                        Alignment
                                                                            .bottomRight,
                                                                    children: [
                                                                      userImageUrl ==
                                                                              ''
                                                                          ? CircleAvatar(
                                                                              foregroundImage: const AssetImage('assets/images/loginImage.png'),
                                                                              backgroundColor: AppColors.avatarBackground,
                                                                              radius: 40,
                                                                            )
                                                                          : CircleAvatar(
                                                                              backgroundColor: AppColors.avatarBackground,
                                                                              radius: 40,
                                                                              child: ClipOval(
                                                                                child: Image.network(
                                                                                  userImageUrl,
                                                                                  fit: BoxFit.cover,
                                                                                  width: 80,
                                                                                  height: 80,
                                                                                  loadingBuilder: (context, child, progress) {
                                                                                    if (progress == null) return child;
                                                                                    return Center(
                                                                                      child: CircularProgressIndicator(
                                                                                        value: progress.expectedTotalBytes != null ? progress.cumulativeBytesLoaded / (progress.expectedTotalBytes ?? 1) : null,
                                                                                        color: AppColors.primaryMain,
                                                                                      ),
                                                                                    );
                                                                                  },
                                                                                  errorBuilder: (context, error, stack) => const Icon(
                                                                                    Icons.error,
                                                                                    size: 40,
                                                                                    color: Colors.red,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                      Positioned(
                                                                        bottom:
                                                                            4,
                                                                        right:
                                                                            4,
                                                                        child: isEdit
                                                                            ? Container(
                                                                                decoration: const BoxDecoration(
                                                                                  color: Colors.black54,
                                                                                  shape: BoxShape.circle,
                                                                                ),
                                                                                padding: const EdgeInsets.all(5),
                                                                                child: const Icon(Icons.edit, color: Colors.white, size: 18),
                                                                              )
                                                                            : Container(),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                );
                                                        },
                                                      ),
                                                      SizedBox(width: 10),
                                                      Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .start,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          SizedBox(
                                                            height:
                                                                CustomSpacing
                                                                    .two,
                                                          ),
                                                          Text(
                                                            LanguageService
                                                                .getTranslated(
                                                                    context,
                                                                    "user_profile_user_managemt_uploadimage_text"),
                                                            style: typography
                                                                .Body1,
                                                            textAlign: TextAlign
                                                                .center,
                                                          ),
                                                          SizedBox(
                                                            height:
                                                                CustomSpacing
                                                                    .two,
                                                          ),
                                                          Container(
                                                            width: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width /
                                                                2.2,
                                                            child: Text(
                                                              LanguageService
                                                                  .getTranslated(
                                                                      context,
                                                                      "usermanagement_app_image_size"),
                                                              maxLines: 2,
                                                              style: typography
                                                                  .BottomNavigationActiveLabel,
                                                              textAlign:
                                                                  TextAlign
                                                                      .start,
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            height:
                                                                CustomSpacing
                                                                    .two,
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                  CustomButton(
                                                    type: ButtonType.text,
                                                    onPressed: () {
                                                      switchEdit();
                                                    },
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.edit,
                                                          size: 30,
                                                        ),
                                                        // SizedBox(
                                                        //     width:
                                                        //     CustomSpacing.two),
                                                        // Text(
                                                        //   isEdit
                                                        //       ? LanguageService
                                                        //       .getTranslated(
                                                        //       context,
                                                        //       "user_profile_app_user_management_profile_save_text")
                                                        //       : LanguageService
                                                        //       .getTranslated(
                                                        //       context,
                                                        //       "user_profile_app_user_management_edit_profile_text"),
                                                        //   style: typography
                                                        //       .ButtonLarge,
                                                        // ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),

                                          // If edit is enables user can edit else its disabled fields: Name, Display Name, Roles with bottom sheet selection, Email and phone with country code
                                          // Edit button
                                          // !showEditUser?SizedBox():!isEdit
                                          //     ?

                                          // : SizedBox(),
                                          // !isEdit
                                          //     ? SizedBox(
                                          //         height: CustomSpacing.two,
                                          //       )
                                          //     : SizedBox(),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Form(
                      key: _formKey,
                      child: Container(
                        padding: EdgeInsets.only(right: 20, left: 20),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name
                              TextFormField(
                                enabled: isEdit,
                                style: typography.Body1,
                                controller: _nameGeneralInfoController,
                                initialValue: null,
                                // Remove initialValue since we'll use controller
                                readOnly: !isEdit,
                                // Add readOnly instead of disabled for better value visibility
                                //controller: nameGeneralInfoController, // Always use the controller
                                decoration: InputDecoration(
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.always,
                                  labelText: LanguageService.getTranslated(
                                      context,
                                      "user_profile_user_management_name_filed_label"),
                                  labelStyle: typography.Body1,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  disabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Theme.of(context)
                                          .textTheme
                                          .labelMedium!
                                          .color!,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return LanguageService.getTranslated(
                                        context,
                                        "user_profile_user_management_name_field_error");
                                  }
                                  return null;
                                },
                              ),

                              SizedBox(height: CustomSpacing.four),
                              // Display Name
                              TextFormField(
                                readOnly: !isEdit,
                                style: typography.Body1,
                                controller: _displayNameGeneralInfoController,
                                decoration: InputDecoration(
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.always,
                                  labelText:
                                      isEdit ? 'Display Name' : 'Display Name',
                                  //displayNameLabelText,
                                  labelStyle: isEdit
                                      ? typography.Body1
                                      : typography.Body1.copyWith(
                                          color: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.color),
                                  disabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Theme.of(context)
                                          .textTheme
                                          .labelMedium!
                                          .color!,
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Display Name is required';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: CustomSpacing.four),
                              // Text(_selectedAcceptRole.length.toString()),
                              // Role Dropdown

                              Stack(
                                children: [
                                  TextField(
                                    readOnly: true,
                                    enabled: !(userProfileProvider
                                                .userData.role![0].name
                                                .toString() ==
                                            "Admin" &&
                                        (isSuperAdmin || isPgAdmin || isAdmin)),
                                    // enabled: !isEdit &&
                                    //     !isSuperAdmin &&
                                    //     !isPgAdmin &&
                                    //     !isAdmin,
                                    onTap: !isEdit &&
                                            !isSuperAdmin &&
                                            !isPgAdmin &&
                                            !isAdmin
                                        ? () {
                                            showModalBottomSheet(
                                              context: context,
                                              useSafeArea: true,
                                              isScrollControlled: true,
                                              builder: (BuildContext context) {
                                                List<Map<String, dynamic>>
                                                    acceptedRoles =
                                                    userProfileProvider.userData
                                                            .acceptedRole
                                                            ?.map((role) =>
                                                                role.toJson())
                                                            .toList() ??
                                                        [];
                                                print(
                                                    "Accepted Roles: $acceptedRoles");
                                                print(
                                                    "useCheckboxes: ${(userProfileProvider.userData.isIndividual ?? false) && (userProfileProvider.userData.isExternal ?? false)}");

                                                return CustomFlexibleRolesBottomSheet(
                                                  showCorporateSwitch: true,
                                                  options: _selectedAcceptRole,
                                                  selectedRoles: _selectedRoles,
                                                  addChip: _addChip,
                                                  removeChip: _removeChip,
                                                  removeAllChips:
                                                      _removeAllChips,
                                                  useCheckboxes:
                                                      (userProfileProvider
                                                                  .userData
                                                                  .isIndividual ??
                                                              false) &&
                                                          (userProfileProvider
                                                                  .userData
                                                                  .isExternal ??
                                                              false),
                                                  // Assuming you want to use checkboxes for selection
                                                );
                                              },
                                            );
                                          }
                                        : null,
                                    controller: _textEditingController,
                                    onChanged: (value) {
                                      // Handle input changes
                                    },
                                    decoration: InputDecoration(
                                      labelText: isEdit &&
                                              !isSuperAdmin &&
                                              !isPgAdmin &&
                                              !isAdmin
                                          ? ''
                                          : '',
                                      labelStyle: isEdit &&
                                              !isSuperAdmin &&
                                              !isPgAdmin &&
                                              !isAdmin
                                          ? typography.Body1
                                          : typography.Body1.copyWith(
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .labelMedium
                                                  ?.color),
                                      hintText: _selectedRoles.isEmpty &&
                                              _textEditingController
                                                  .text.isEmpty
                                          ? 'Select Roles'
                                          : '',
                                      border: OutlineInputBorder(),
                                      disabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: Theme.of(context)
                                              .textTheme
                                              .labelMedium!
                                              .color!,
                                        ),
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(Icons.arrow_drop_down),
                                        onPressed: isEdit
                                            ? () {
                                                showModalBottomSheet(
                                                  context: context,
                                                  useSafeArea: true,
                                                  isScrollControlled: true,
                                                  builder:
                                                      (BuildContext context) {
                                                    List<Map<String, dynamic>>
                                                        acceptedRoles =
                                                        userProfileProvider
                                                                .userData
                                                                .acceptedRole
                                                                ?.map((role) =>
                                                                    role.toJson())
                                                                .toList() ??
                                                            [];
                                                    return CustomFlexibleRolesBottomSheet(
                                                      showCorporateSwitch: true,
                                                      options:
                                                          _selectedAcceptRole,
                                                      selectedRoles:
                                                          _selectedRoles,
                                                      addChip: _addChip,
                                                      removeChip: _removeChip,
                                                      removeAllChips:
                                                          _removeAllChips,
                                                      useCheckboxes: (userProfileProvider
                                                                  .userData
                                                                  .isIndividual ??
                                                              false) &&
                                                          (userProfileProvider
                                                                  .userData
                                                                  .isExternal ??
                                                              false),
                                                    );
                                                  },
                                                );
                                              }
                                            : null,
                                      ),
                                    ),
                                  ),

                                  Positioned(
                                    top: 4.0,
                                    left: 10.0,
                                    right: 10.0,
                                    child: Container(
                                      margin:
                                          const EdgeInsets.only(right: 32.0),
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: _selectedRoles.map((value) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 8.0),
                                              child: Row(
                                                children: [
                                                  Chip(
                                                    label: Text(value.name!),
                                                    deleteIcon: (isEdit &&
                                                                !isSuperAdmin &&
                                                                !isPgAdmin) ||
                                                            (isEdit &&
                                                                bool.parse(userProfileProvider
                                                                    .userData
                                                                    .isIndividual
                                                                    .toString()))
                                                        ? Icon(Icons.cancel)
                                                        : null,
                                                    onDeleted: (isEdit &&
                                                                !isSuperAdmin &&
                                                                !isPgAdmin) ||
                                                            (isEdit &&
                                                                bool.parse(userProfileProvider
                                                                    .userData
                                                                    .isIndividual
                                                                    .toString()))
                                                        ? () =>
                                                            _removeChip(value)
                                                        : null,
                                                  ),
                                                  // Chip(
                                                  //   label: Text(value.name!),
                                                  //   deleteIcon: Icon(Icons.cancel),
                                                  //   onDeleted: () =>
                                                  //       _removeChip(value),
                                                  // ),
                                                  // if (isEdit &&
                                                  //         !isSuperAdmin &&
                                                  //         !isPgAdmin ||
                                                  //     (isEdit &&
                                                  //         bool.parse(
                                                  //             userProfileProvider
                                                  //                 .userData
                                                  //                 .isIndividual
                                                  //                 .toString())))
                                                  //   IconButton(
                                                  //     icon: Icon(Icons.cancel,
                                                  //         size: 20,
                                                  //         color: Colors.red),
                                                  //     onPressed: () {
                                                  //       setState(() {
                                                  //         _selectedRoles
                                                  //             .remove(value);
                                                  //       });
                                                  //     },
                                                  //   ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Positioned(
                                  //   top: 4.0,
                                  //   left: 10.0,
                                  //   right: 10.0,
                                  //   child: Container(
                                  //     margin: const EdgeInsets.only(right: 32.0),
                                  //     child: SingleChildScrollView(
                                  //       scrollDirection: Axis.horizontal,
                                  //       child: Row(
                                  //         children: _selectedRoles
                                  //             .map(
                                  //               (value) => Padding(
                                  //             padding: const EdgeInsets.only(right: 8.0),
                                  //             child: Chip(
                                  //               label: Text(value.name!),
                                  //               deleteIcon: isEdit&&!isSuperAdmin&&!isPgAdmin ? Icon(Icons.cancel) : null,
                                  //               onDeleted: isEdit&&!isSuperAdmin&&!isPgAdmin ? () => _removeChip(value) : null,
                                  //             ),
                                  //           ),
                                  //         )
                                  //             .toList(),
                                  //       ),
                                  //     ),
                                  //   ),
                                  // ),
                                ],
                              ),
                              SizedBox(height: CustomSpacing.four),
                              // Email
                              TextFormField(
                                readOnly: true,
                                style: typography.Body1,
                                controller: _emailGeneralInfoController,
                                decoration: InputDecoration(
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.always,
                                  labelText: isEdit
                                      ? LanguageService.getTranslated(context,
                                          "user_profile_user_management_email_field_label")
                                      //: emailLabelText,
                                      : LanguageService.getTranslated(context,
                                          "user_profile_user_management_email_field_label"),
                                  labelStyle: isEdit
                                      ? typography.Body1.copyWith(
                                          color: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.color)
                                      : typography.Body1.copyWith(
                                          color: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.color),
                                  disabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Theme.of(context)
                                          .textTheme
                                          .labelMedium!
                                          .color!,
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              SizedBox(height: CustomSpacing.four),
                              // Phone
                              FormField<String>(
                                validator: (value) {
                                  if (phoneController.text.isEmpty) {
                                    print("object");
                                    return 'Mobile number is required.';
                                  }
                                  if (phoneController.text.length < 10) {
                                    print("object");
                                    return 'Enter a valid mobile number.';
                                  }
                                  return null;
                                },
                                builder: (FormFieldState<String> fieldState) {
                                  return TextFormField(
                                    controller: phoneController,
                                    enabled: isEdit,
                                    keyboardType: TextInputType.phone,
                                    maxLength: 10,
                                    decoration: InputDecoration(
                                      counterText: '',
                                      // Hides the maxLength counter
                                      floatingLabelBehavior:
                                          FloatingLabelBehavior.always,
                                      labelText: LanguageService.getTranslated(
                                        context,
                                        "user_profile_user_management_mobile_field",
                                      ),
                                      labelStyle: isEdit
                                          ? typography.Body1
                                          : typography.Body1.copyWith(
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .labelMedium
                                                  ?.color,
                                            ),
                                      hintText: LanguageService.getTranslated(
                                        context,
                                        "user_profile_user_management_mobile_placeholder",
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: Theme.of(context).dividerColor,
                                        ),
                                      ),
                                      disabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: Theme.of(context)
                                              .textTheme
                                              .labelMedium!
                                              .color!,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 18, horizontal: 12),
                                      errorText: fieldState.errorText,
                                    ),
                                    onChanged: (value) {
                                      fieldState.didChange(value);
                                    },
                                  );
                                },
                              ),

                              SizedBox(height: CustomSpacing.four),
                            ]),
                      ),
                    ),

                    // Cancel and Submit Buttons
                    isEdit
                        ? Column(
                            children: [
                              Row(
                                children: [
                                  SizedBox(width: CustomSpacing.five),
                                  Expanded(
                                    child: CustomButton(
                                      onPressed: () {
                                        // validate
                                        if (!_formKey.currentState!
                                            .validate()) {
                                          print("object");
                                          return;
                                        }
                                        // Atleat one selected role:
                                        if (_selectedRoles.isEmpty) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Please select at least one role.',
                                                  style:
                                                      typography.Body1.copyWith(
                                                          color: Colors.black)),
                                            ),
                                          );
                                          return;
                                        }
                                        // Update Body
                                        var body = {
                                          "current_user": true,
                                          "userdata": {
                                            "rating": userProfileProvider
                                                    .userData.rating ??
                                                0,
                                            "email": userProfileProvider
                                                    .userData.email ??
                                                "",
                                            "request_sent": [],
                                            "is_external": true,
                                            "display_image_url": userImageUrl,
                                            "display_name":
                                                _displayNameGeneralInfoController
                                                    .text,
                                            "is_verified": false,
                                            "user_id": userProfileProvider
                                                    .userData.userId ??
                                                "",
                                            "referral_code": "",
                                            "status": true,
                                            "username": "",
                                            "company_id": userProfileProvider
                                                    .userData.companyId ??
                                                "",
                                            "isIndividual": (userProfileProvider
                                                        .userData
                                                        .isIndividual ??
                                                    false) &&
                                                (userProfileProvider
                                                        .userData.isExternal ??
                                                    false),
                                            "displayName":
                                                _displayNameGeneralInfoController
                                                    .text,
                                            "phone": phoneController.text ?? "",
                                            "my_assignee": [""],
                                            "roles": _selectedRoles
                                                .map((role) => role.toJson())
                                                .toList(),
                                            "selectedCountryCode":
                                                _selectedCountryCode,
                                            "country_code":
                                                _selectedCountryCode,
                                            "name":
                                                _nameGeneralInfoController.text,
                                            "accepted_role": userProfileProvider
                                                    .userData.acceptedRole
                                                    ?.map(
                                                        (role) => role.toJson())
                                                    .toList() ??
                                                []
                                          }
                                        };
                                        userProfileProvider
                                            .updateUserData(context, body)
                                            .then((value) {
                                          if (value) {
                                            setState(() {
                                              nameLabelText =
                                                  _nameGeneralInfoController
                                                      .text;
                                              displayNameLabelText =
                                                  _displayNameGeneralInfoController
                                                      .text;
                                              emailLabelText =
                                                  _emailGeneralInfoController
                                                      .text;
                                              phoneLabelText =
                                                  phoneController.text ?? "";
                                              isEdit = false;
                                            });
                                          }
                                        });
                                      },
                                      type: ButtonType.filled,
                                      child: Text(
                                        LanguageService.getTranslated(context,
                                            "user_profile_user_management_btn_submit"),
                                        // style: typography.ButtonLarge,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: CustomSpacing.five),
                                ],
                              ),
                              SizedBox(height: CustomSpacing.two),
                              Row(
                                children: [
                                  SizedBox(width: CustomSpacing.five),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        // Handle submit button
                                        switchEdit();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 22, vertical: 8),
                                      ),
                                      child: Text(
                                        LanguageService.getTranslated(context,
                                            "user_profile_user_management_btn_cancel"),
                                        style: typography.ButtonLarge,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: CustomSpacing.five),
                                ],
                              ),
                            ],
                          )
                        : SizedBox(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      "Security",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    )),
                                Divider(),
                                Container(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      "You can update your password below.",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    )),
                                SizedBox(height: CustomSpacing.three),
                                Container(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  width: 250,
                                  child: OutlinedButton(
                                    onPressed: () {
                                      final rootContext = context;

                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (sheetContext) {
                                          return _changePasswordBottomSheet(
                                            sheetContext,
                                            rootContext,
                                            _emailGeneralInfoController.text,
                                          );
                                        },
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: AppColors
                                            .primaryMain, // border color
                                        width: 1,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 22, vertical: 8),
                                    ),
                                    child: Text(
                                      "Change Password",
                                      style: typography.ButtonLarge.copyWith(
                                        color: AppColors
                                            .primaryMain, // ensure text color
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: CustomSpacing.three),
                              ],
                            ),
                          ),
                  ],
                ),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: Center(
                      child: Container(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(),
                  )),
                ),
              ],
            );
    });
  }

  Future<void> _pickAndUploadImage(
      BuildContext context, UserProfileProvider provider) async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      final file = File(pickedFile.path);
      final img.Image? image = img.decodeImage(file.readAsBytesSync());

      if (image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not load the image. Please try again.')),
        );
        return;
      }

      final isValidSize = image.width >= 400 && image.height >= 400;
      final isValidFormat = pickedFile.path.toLowerCase().endsWith('.png') ||
          pickedFile.path.toLowerCase().endsWith('.jpg') ||
          pickedFile.path.toLowerCase().endsWith('.jpeg');

      if (!isValidSize || !isValidFormat) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Image must be at least 400x400 pixels and in PNG or JPEG format.'),
          ),
        );
        return;
      }

      final imageUrl = await provider.uploadImage(context, file);

      if (imageUrl.isNotEmpty && mounted) {
        setState(() => userImageUrl = imageUrl);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Something went wrong: $e')),
      );
    }
  }

  void _showAvatarBottomSheet(
      BuildContext context, UserProfileProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "Select Avatar",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  GridView.builder(
                    padding: const EdgeInsets.all(16),
                    shrinkWrap: true,
                    itemCount: provider.avatars.length,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemBuilder: (context, index) {
                      final avatarUrl = provider.avatars[index]?.url ?? "";
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            userImageUrl = avatarUrl;
                          });
                          Navigator.pop(context);
                        },
                        child: CircleAvatar(
                          backgroundImage: NetworkImage(avatarUrl),
                          backgroundColor: AppColors.avatarBackground,
                          radius: 25,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel",
                        style: TextStyle(color: Colors.white70)),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void switchEdit() {
    setState(() {
      isEdit = !isEdit;
      if (isEdit) {
        _nameGeneralInfoController.text = nameLabelText;
        _displayNameGeneralInfoController.text = displayNameLabelText;
        _emailGeneralInfoController.text = emailLabelText;
        _phoneGeneralInfoController.text = phoneLabelText;
      } else {
        _nameGeneralInfoController.text = nameLabelText;
        _displayNameGeneralInfoController.text = displayNameLabelText;
        _emailGeneralInfoController.text = emailLabelText;
        _phoneGeneralInfoController.text = phoneLabelText;
      }
    });
  }

  _getMyTeamUI() {
    return SingleChildScrollView(
      child: Consumer<UserProfileProvider>(
          builder: (context, userProfileProvider, child) {
        return userProfileProvider.isUserTeamLoading
            ? Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Center(
                      child: Container(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(),
                  )),
                ],
              )
            : Column(
                children: [
                  SizedBox(height: CustomSpacing.two),
                  Container(
                    child: _managerCardUI(userProfileProvider),
                  ),
                  SizedBox(height: CustomSpacing.two),
                  Container(
                    child: _delegateCardUI(userProfileProvider),
                  ),
                  SizedBox(height: CustomSpacing.two),
                  Container(
                    child: _reporteesCardUI(userProfileProvider),
                  ),
                  SizedBox(height: CustomSpacing.two),
                ],
              );
      }),
    );
  }

  _managerCardUI(UserProfileProvider userProfileProvider) {
    var typography = CustomTypography(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: CustomSpacing.two),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Text(
                    LanguageService.getTranslated(context,
                        "user_profile_user_management_row_name_manager"),
                    style: typography.Body1,
                  ),
                ),
                !showAssignDeleteManager
                    ? SizedBox()
                    : Builder(builder: (context) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            userProfileProvider.myManager.isNotEmpty &&
                                    userProfileProvider.myManager[0] != null
                                ? SizedBox(
                                    height: 48,
                                  )
                                : IconButton(
                                    onPressed: () {
                                      showAdaptiveDialog(
                                        context: context,
                                        builder: (localContext) {
                                          return AlertDialog(
                                            content: _addMemberDialogUI(
                                                localContext, "add_manager"),
                                          );
                                        },
                                      );
                                    },
                                    icon: Icon(
                                      Icons.add,
                                      color: AppColors.primaryMain,
                                    ),
                                  ),
                          ],
                        );
                      }),
              ],
            ),
          ),
          userProfileProvider.myManager.isEmpty ||
                  userProfileProvider.myManager[0] == null
              ? SizedBox()
              : Container(
                  color: Theme.of(context).colorScheme.background,
                  child: Column(
                    children: [
                      SizedBox(height: CustomSpacing.four),
                      Container(
                          child: Row(
                        children: [
                          // Manager Image Avatar, Name and email as column, role chip, actions as search and delete
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CircleAvatar(
                              radius: 24,
                              child: userProfileProvider
                                              .myManager[0]?.displayImageUrl !=
                                          null &&
                                      userProfileProvider
                                              .myManager[0]?.displayImageUrl !=
                                          ''
                                  ? ClipOval(
                                      child: Image.network(
                                        userProfileProvider
                                            .myManager[0]!.displayImageUrl!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Text(
                                      userProfileProvider.myManager[0]?.name
                                              ?.substring(0, 1)
                                              .toUpperCase() ??
                                          "",
                                    ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(userProfileProvider.myManager[0]?.name ?? "",
                                  style: typography.Body1),
                              Text(
                                  userProfileProvider.myManager[0]?.email ?? "",
                                  style: typography.Body2),
                            ],
                          ),

                          Spacer(),
                          // Actions
                          !showAssignDeleteManager
                              ? SizedBox()
                              : PopupMenuButton<PopupMenuItem<dynamic>>(
                                  itemBuilder: (BuildContext context) {
                                    List<PopupMenuEntry<PopupMenuItem<dynamic>>>
                                        items = [];

                                    /*if (userProfileProvider.myManager.isEmpty || userProfileProvider.myManager[0] == null) {
                          items.add(
                            PopupMenuItem(
                              onTap: () {
                                // Handle search
                                showDialog(
                                  context: context,
                                  builder: (context) => _addMemberDialogUI(context, "add_manager"),
                                );
                              },
                              child: Row(
                                children: [
                                  Icon(Icons.search),
                                  SizedBox(width: CustomSpacing.two),
                                  Text('Search'),
                                ],
                              ),
                            ),
                          );
                        }*/

                                    if (showAssignDeleteManager) {
                                      items.add(
                                        PopupMenuItem(
                                          onTap: () {
                                            // Show delete dialog and pop off the menu also on ok
                                            showDialog(
                                              context: context,
                                              builder: (context) {
                                                return AlertDialog(
                                                    content: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                        'Are you sure you want to delete this manager?'),
                                                    SizedBox(
                                                        height:
                                                            CustomSpacing.two),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.end,
                                                      children: [
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.pop(
                                                                context);
                                                          },
                                                          child: Text('Cancel'),
                                                        ),
                                                        SizedBox(
                                                            width: CustomSpacing
                                                                .two),
                                                        TextButton(
                                                          onPressed: () {
                                                            // Handle delete
                                                            userProfileProvider.deleteTeamMember(
                                                                context,
                                                                userProfileProvider
                                                                        .myManager[
                                                                            0]!
                                                                        .id ??
                                                                    "",
                                                                "add_manager");
                                                            Navigator.pop(
                                                                context);
                                                          },
                                                          child: Text('Delete'),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ));
                                              },
                                            );
                                          },
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete),
                                              SizedBox(
                                                  width: CustomSpacing.two),
                                              Text('Delete'),
                                            ],
                                          ),
                                        ),
                                      );
                                    }

                                    return items;
                                  },
                                ),
                        ],
                      )),
                      // Role Chip
                      userProfileProvider.myManager[0]?.role == null
                          ? SizedBox()
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Chip(
                                    label: Text(userProfileProvider
                                            .myManager[0]?.role ??
                                        ""),
                                  ),
                                ),
                              ],
                            ),
                      SizedBox(height: CustomSpacing.two),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  _delegateCardUI(UserProfileProvider userProfileProvider) {
    var typography = CustomTypography(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: CustomSpacing.two),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Text(
                    LanguageService.getTranslated(context,
                        "user_profile_user_management_row_name_Delegate"),
                    style: typography.Body1,
                  ),
                ),
                !showAddDelegate
                    ? SizedBox()
                    : userProfileProvider.myReportee.isEmpty
                        ? SizedBox(
                            height: 40,
                          )
                        : Builder(builder: (context) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                userProfileProvider.myDeligate.isNotEmpty &&
                                        userProfileProvider.myDeligate[0] !=
                                            null
                                    ? SizedBox(
                                        height: 48,
                                      )
                                    : IconButton(
                                        onPressed: () {
                                          // Handle submit button
                                          showDialog(
                                            context: context,
                                            builder: (localContext) {
                                              return AlertDialog(
                                                content: _addMemberDialogUI(
                                                    localContext,
                                                    "add_delegate"),
                                              );
                                            },
                                          );
                                        },
                                        icon: Icon(
                                          Icons.add,
                                          color: AppColors.primaryMain,
                                        ),
                                      ),
                              ],
                            );
                          }),
              ],
            ),
          ),
          userProfileProvider.myDeligate.isEmpty ||
                  userProfileProvider.myDeligate[0] == null
              ? SizedBox()
              : Container(
                  color: Theme.of(context).colorScheme.background,
                  child: Column(
                    children: [
                      SizedBox(height: CustomSpacing.four),
                      Container(
                          child: Row(
                        children: [
                          // Manager Image Avatar, Name and email as column, role chip, actions as search and delete
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CircleAvatar(
                              radius: 24,
                              child: userProfileProvider
                                              .myDeligate[0]?.displayImageUrl !=
                                          null &&
                                      userProfileProvider
                                              .myDeligate[0]?.displayImageUrl !=
                                          ''
                                  ? ClipOval(
                                      child: Image.network(
                                        userProfileProvider
                                            .myDeligate[0]!.displayImageUrl!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Text(
                                      userProfileProvider.myDeligate[0]?.name
                                              ?.substring(0, 1)
                                              .toUpperCase() ??
                                          "",
                                    ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  userProfileProvider.myDeligate[0]?.name ?? "",
                                  style: typography.Body1),
                              Text(
                                  userProfileProvider.myDeligate[0]?.email ??
                                      "",
                                  style: typography.Body2),
                            ],
                          ),

                          Spacer(),
                          // Actions
                          PopupMenuButton<PopupMenuEntry<dynamic>>(
                            itemBuilder: (BuildContext context) {
                              List<PopupMenuEntry<PopupMenuEntry<dynamic>>>
                                  items = [];

                              /*if (userProfileProvider.myDeligate.isNotEmpty && userProfileProvider.myDeligate[0] != null) {
                          items.add(
                            PopupMenuItem(
                              onTap: () {
                                // Handle search
                                showDialog(
                                  context: context,
                                  builder: (context) => _addMemberDialogUI(context, "add_deligate"),
                                );
                              },
                              child: Row(
                                children: [
                                  Icon(Icons.search),
                                  SizedBox(width: CustomSpacing.two),
                                  Text('Search'),
                                ],
                              ),
                            ),
                          );
                        }*/

                              if (showRevokeDelegate) {
                                items.add(
                                  PopupMenuItem(
                                    onTap: () {
                                      // Show delete dialog and pop off the menu also on ok
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                              content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                  'Are you sure you want to delete this delegate?'),
                                              SizedBox(
                                                  height: CustomSpacing.two),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                    },
                                                    child: Text('Cancel'),
                                                  ),
                                                  SizedBox(
                                                      width: CustomSpacing.two),
                                                  TextButton(
                                                    onPressed: () {
                                                      // Handle delete
                                                      userProfileProvider
                                                          .deleteTeamMember(
                                                              context,
                                                              userProfileProvider
                                                                      .myDeligate[
                                                                          0]!
                                                                      .id ??
                                                                  "",
                                                              "add_deligate");
                                                      Navigator.pop(context);
                                                    },
                                                    child: Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ));
                                        },
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete),
                                        SizedBox(width: CustomSpacing.two),
                                        Text('Delete'),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              return items;
                            },
                          ),
                        ],
                      )),
                      // Role Chip
                      userProfileProvider.myDeligate[0]?.role == null
                          ? SizedBox()
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Chip(
                                    label: Text(userProfileProvider
                                            .myDeligate[0]?.role ??
                                        ""),
                                  ),
                                ),
                              ],
                            ),
                      SizedBox(height: CustomSpacing.two),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  _reporteesCardUI(UserProfileProvider userProfileProvider) {
    var typography = CustomTypography(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: CustomSpacing.two),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Text(
                    LanguageService.getTranslated(context,
                        "user_profile_user_management_row_name_reportee"),
                    style: typography.Body1,
                  ),
                ),
                !showAddReportee
                    ? SizedBox()
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: () {
                              // Handle submit button
                              showAdaptiveDialog(
                                context: context,
                                builder: (localContext) {
                                  return AlertDialog(
                                    content: _addMemberDialogUI(
                                        localContext, "add_reportee"),
                                  );
                                },
                              );
                            },
                            icon: Icon(
                              Icons.add,
                              color: AppColors.primaryMain,
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
          userProfileProvider.myReportee.isEmpty ||
                  userProfileProvider.myReportee[0] == null
              ? SizedBox()
              : SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: ListView.builder(
                      shrinkWrap: true,
                      physics: ClampingScrollPhysics(),
                      itemCount: userProfileProvider.myReportee.length,
                      itemBuilder: (context, index) {
                        return _reporteesListCardUI(userProfileProvider, index);
                      }),
                ),
        ],
      ),
    );
  }

  _reporteesListCardUI(UserProfileProvider userProfileProvider, int index) {
    var typography = CustomTypography(context);
    return Container(
      color: Theme.of(context).colorScheme.background,
      child: Column(
        children: [
          SizedBox(height: CustomSpacing.four),
          Row(
            children: [
              // Manager Image Avatar, Name and email as column, role chip, actions as search and delete
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  radius: 24,
                  child:
                      userProfileProvider.myReportee[index]?.displayImageUrl !=
                                  null &&
                              userProfileProvider
                                      .myReportee[index]?.displayImageUrl !=
                                  ''
                          ? ClipOval(
                              child: Image.network(
                                userProfileProvider
                                    .myReportee[index]!.displayImageUrl!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Text(
                              userProfileProvider.myReportee[index]?.name
                                      ?.substring(0, 1)
                                      .toUpperCase() ??
                                  "",
                            ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(userProfileProvider.myReportee[index]?.name ?? "",
                      style: typography.Body1),
                  Text(userProfileProvider.myReportee[index]?.email ?? "",
                      style: typography.Body2),
                ],
              ),

              Spacer(),
              // Actions
              !showAddReportee
                  ? SizedBox()
                  : PopupMenuButton(
                      itemBuilder: (BuildContext context) {
                        return [
                          /*PopupMenuItem(
                      onTap: () {
                        // Handle search
                        showDialog(
                          context: context,
                          builder: (context) => _addMemberDialogUI(context, "add_reportee"),
                        );
                      },
                      child: Row(
                        children: [
                          Icon(Icons.search),
                          SizedBox(width: CustomSpacing.two),
                          Text('Search'),
                        ],
                      ),
                    ),*/
                          PopupMenuItem(
                            onTap: () {
                              // Show delete dialog and pop off the menu also on ok
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                      content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                          'Are you sure you want to delete this reportee?'),
                                      SizedBox(height: CustomSpacing.two),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: Text('Cancel'),
                                          ),
                                          SizedBox(width: CustomSpacing.two),
                                          TextButton(
                                            onPressed: () {
                                              // Handle delete
                                              userProfileProvider
                                                  .deleteTeamMember(
                                                      context,
                                                      userProfileProvider
                                                              .myReportee[
                                                                  index]!
                                                              .id ??
                                                          "",
                                                      "add_reportee");
                                              Navigator.pop(context);
                                            },
                                            child: Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ));
                                },
                              );
                            },
                            child: Row(
                              children: [
                                Icon(Icons.delete),
                                SizedBox(width: CustomSpacing.two),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        ];
                      },
                    ),
            ],
          ),
          // Role Chip
          userProfileProvider.myReportee[index]?.role == null
              ? SizedBox()
              : Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Chip(
                        label: Text(
                            userProfileProvider.myReportee[index]?.role ?? ""),
                      ),
                    ),
                  ],
                ),
          SizedBox(height: CustomSpacing.two),
        ],
      ),
    );
  }

  _addMemberDialogUI(BuildContext localContext, String type) {
    var typography = CustomTypography(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: CustomSpacing.two),
          Text(
              type == "add_manager"
                  ? LanguageService.getTranslated(
                      context, "user_profile_user_management_add_manager_btn")
                  : type == 'add_delegate'
                      ? LanguageService.getTranslated(context,
                          "user_profile_user_management_add_delegate_btn")
                      : LanguageService.getTranslated(
                          context, "user_profile_user_management_add_reportee"),
              style: typography.H5_Regular),
          SizedBox(height: CustomSpacing.two),
          // Search Box with Autocomplete
          Autocomplete<NetworkingUsers>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text == '') {
                return const Iterable<NetworkingUsers>.empty();
              } else {
                return Future.delayed(Duration.zero, () async {
                  _managerList = await searchNetworks(textEditingValue.text);
                  print("Manager List: $_managerList");
                  return _managerList;
                });
              }
            },
            onSelected: (NetworkingUsers selection) {
              setState(() {
                _selectedManager = selection;
              });
            },
            fieldViewBuilder: (BuildContext context,
                TextEditingController textEditingController,
                FocusNode focusNode,
                VoidCallback onFieldSubmitted) {
              return SizedBox(
                height: 50,
                child: TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: 'Search by name or email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      onPressed: onFieldSubmitted,
                      icon: Icon(Icons.search),
                    ),
                  ),
                ),
              );
            },
            displayStringForOption: (NetworkingUsers option) {
              // Assuming _searchResults is a list of User objects
              NetworkingUsers user =
                  _managerList.firstWhere((user) => user.id == option.id);
              return '${user.name} (${user.email})';
            },
            optionsViewBuilder: (BuildContext context,
                AutocompleteOnSelected<NetworkingUsers> onSelected,
                Iterable<NetworkingUsers> options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  child: ListView.builder(
                    padding: EdgeInsets.all(10),
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      NetworkingUsers option = options.elementAt(index);
                      NetworkingUsers user = _managerList
                          .firstWhere((user) => user.id == option.id);
                      return GestureDetector(
                        onTap: () {
                          onSelected(option);
                        },
                        child: ListTile(
                          leading: CircleAvatar(
                            child: user.displayImageUrl != null &&
                                    user.displayImageUrl != ''
                                ? ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: user.displayImageUrl!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Text(
                                    user.name?.substring(0, 1).toUpperCase() ??
                                        "",
                                  ),
                          ),
                          title: Text(user.name ?? "",
                              style: typography.Body1.copyWith(
                                  color: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.color)),
                          subtitle: Text(user.email ?? "",
                              style: typography.Subtitle1.copyWith(
                                  color: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.color)),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          SizedBox(height: CustomSpacing.two),
          // Cancel and Submit Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(localContext).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                  ),
                  child: Text(
                    LanguageService.getTranslated(
                        context, "user_profile_user_management_btn_cancel"),
                    style: typography.ButtonLarge,
                  ),
                ),
              ),
              SizedBox(width: CustomSpacing.two),
              Expanded(
                child: CustomButton(
                  onPressed: () {
                    // Handle submit button
                    switch (type) {
                      case 'add_manager':
                        Provider.of<UserProfileProvider>(localContext,
                                listen: false)
                            .addTeamMember(context, _selectedManager?.id ?? "",
                                "add_manager")
                            .then((value) {
                          Navigator.pop(localContext);
                          if (value) {
                            Future.delayed(Duration(seconds: 1), () {
                              Provider.of<UserProfileProvider>(context,
                                      listen: false)
                                  .getUserTeamMembers(context);
                            });
                          }
                        });
                        break;
                      case 'add_delegate':
                        Provider.of<UserProfileProvider>(localContext,
                                listen: false)
                            .addTeamMember(context, _selectedManager?.id ?? "",
                                "add_delegate")
                            .then((value) {
                          Navigator.pop(localContext);
                          if (value) {
                            Future.delayed(Duration(seconds: 1), () {
                              Provider.of<UserProfileProvider>(context,
                                      listen: false)
                                  .getUserTeamMembers(context);
                            });
                          }
                        });
                        break;
                      case 'add_reportee':
                        Provider.of<UserProfileProvider>(localContext,
                                listen: false)
                            .addTeamMember(context, _selectedManager?.id ?? "",
                                "add_reportee")
                            .then((value) {
                          Navigator.pop(localContext);
                          if (value) {
                            Future.delayed(Duration(seconds: 1), () {
                              Provider.of<UserProfileProvider>(context,
                                      listen: false)
                                  .getUserTeamMembers(context);
                            });
                          }
                        });
                    }
                  },
                  type: ButtonType.filled,
                  child: Text(
                    LanguageService.getTranslated(
                        context, "user_profile_user_management_btn_submit"),
                    style: typography.ButtonLarge,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _getSecurityUI() {
    var typography = CustomTypography(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        // Directly center the entire column
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              LanguageService.getTranslated(context, 'coming_soon_title'),
              style: typography.H4,
              textAlign: TextAlign.center, // Ensure the text is centered
            ),
            SizedBox(
              height: CustomSpacing.two,
            ),
            Text(
              LanguageService.getTranslated(context, 'coming_soon_subtitle'),
              style: typography.Body1,
              textAlign: TextAlign.center, // Ensure the text is centered
            ),
          ],
        ),
      ),
    );
  }

  void _addChip(Categories value) {
    setState(() {
      _selectedRoles.add(value);
      _textEditingController.clear();
    });
  }

  void _removeChip(Categories value) {
    print('Removing chip: ${value.name}');
    setState(() {
      _selectedRoles.removeWhere((element) => element.name == value.name);
    });
    print(
        'Selected roles: ${_selectedRoles.map((role) => role.name).toList()}');
  }

  void _removeAllChips() {
    setState(() {
      _selectedRoles.clear();
    });
  }
}

Widget _changePasswordBottomSheet(
  BuildContext sheetContext,
  BuildContext rootContext,
  String email,
) {
  return Container(
    padding: EdgeInsets.only(
      left: 16,
      right: 16,
      top: 20,
      bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 80,
    ),
    decoration: const BoxDecoration(
      color: Colors.black,
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(16),
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Update Password",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "A password reset email will be sent to:",
          style: TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),

        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            email, // dynamic email here
            style: const TextStyle(color: Colors.white),
          ),
        ),

        const SizedBox(height: 20),

        // Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.blue),
                ),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  if (email.trim().isEmpty) {
                    ScaffoldMessenger.of(rootContext).showSnackBar(
                      const SnackBar(content: Text("Email is empty")),
                    );
                    return;
                  }

                  try {
                    await sendPasswordResetViaRest(email);

                    Navigator.pop(sheetContext); // close bottom sheet

                    ScaffoldMessenger.of(rootContext).showSnackBar(
                      const SnackBar(
                        content: Text(
                            "Password reset email sent successfully. Please check your email."),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(rootContext).showSnackBar(
                      SnackBar(content: Text("Error: $e")),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlueAccent,
                ),
                child: const Text(
                  "Send Reset Email",
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// Future<List<String>> getSignInMethodsForEmail(String email) async {
//   final cleanEmail = email.trim().toLowerCase();
//
//   final methods =
//   await FirebaseAuth.instance.fetchSignInMethodsForEmail(cleanEmail);
//
//   return methods; // e.g. ["password"], ["google.com"], []
// }

String _providerLabel(String providerId) {
  switch (providerId) {
    case "google.com":
      return "Google";
    case "apple.com":
      return "Apple";
    case "facebook.com":
      return "Facebook";
    case "phone":
      return "Phone";
    default:
      return providerId;
  }
}

Future<void> sendPasswordResetViaRest(String email) async {
  // const apiKey = "AIzaSyCYkVSSfxlq0G0URowvvyfq7Pn1Af_f2YA";
  const apiKey = "AIzaSyCWLlgn4SYw-8aHdPLfeylQ78AsUqyCvv4";

  final url = Uri.parse(
    "https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=$apiKey",
  );
  https: //identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=AIzaSyCWLlgn4SYw-8aHdPLfeylQ78AsUqyCvv4
  final response = await http.post(
    url,
    headers: {
      "Content-Type": "application/json",
    },
    body: jsonEncode({
      "requestType": "PASSWORD_RESET",
      "email": email.trim(),
      "clientType": "CLIENT_TYPE_WEB",
    }),
  );

  if (response.statusCode != 200) {
    final error = jsonDecode(response.body);
    throw Exception(error["error"]["message"] ?? "Reset failed");
  }
}
