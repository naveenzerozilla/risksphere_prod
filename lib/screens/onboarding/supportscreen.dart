import 'package:flutter/material.dart';
import '../../design_system/components/custom_drawer.dart';
import '../../utils/global_imports.dart';
import '../terms_privacy.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final TextEditingController fromController = TextEditingController();
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController messageController = TextEditingController();
  bool _isPageLoading = true;

  bool consentChecked = false;
  bool _isExpanded = false;
  bool _showNotificationDot = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getData();
    });
  }

  Future<void> _getData() async {
    setState(() {
      _isPageLoading = true;
    });

    final userProfileProvider = context.read<UserProfileProvider>();

    final value = await userProfileProvider.getAllUserData(context, '', '');

    if (!mounted) return;

    if (value != null) {
      fromController.text = value.email ?? "";
    }

    userProfileProvider.getAvatarUrls(context);
    userProfileProvider.getUserTeamMembers(context);

    setState(() {
      _isPageLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return Scaffold(
            backgroundColor: themeProvider.getTheme.colorScheme.background,
            appBar: CustomAppBar(
              isExpanded: _isExpanded,
              showNotificationDot: _showNotificationDot,
              onExpandPressed: (isExpanded) {
                setState(() => _isExpanded = isExpanded);
              },
              onSearchPressed: () {
                setState(() => _isExpanded = !_isExpanded);
              },
            ),
            drawer: const CustomDrawer(),

            body: _isPageLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF8EC9FF)),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildForm(context),
                  ),

            // Padding(
            //   padding: const EdgeInsets.all(16),
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       _inputField(
            //         label: "From",
            //         hint: "Enter label name",
            //         controller: fromController,
            //       ),
            //       const SizedBox(height: 12),
            //       _inputField(
            //         label: "To",
            //         hint: "help@risksphere.com",
            //         enabled: false,
            //       ),
            //       const SizedBox(height: 12),
            //       _inputField(
            //         label: "Subject",
            //         controller: subjectController,
            //       ),
            //       const SizedBox(height: 12),
            //       _messageBox(),
            //       const SizedBox(height: 10),
            //       Align(
            //         alignment: Alignment.centerRight,
            //         child: Text(
            //           "${messageController.text.length}/1000",
            //           style: const TextStyle(
            //             color: Colors.white54,
            //             fontSize: 12,
            //           ),
            //         ),
            //       ),
            //       const SizedBox(height: 10),
            //       Row(
            //         crossAxisAlignment: CrossAxisAlignment.start,
            //         children: [
            //           Checkbox(
            //             value: consentChecked,
            //             onChanged: (val) {
            //               setState(() => consentChecked = val ?? false);
            //             },
            //             activeColor: const Color(0xFF8EC9FF),
            //             checkColor: Colors.black,
            //             side: const BorderSide(color: Colors.white70),
            //           ),
            //           const Expanded(
            //             child: Text(
            //               "We may email you for more information or updates.",
            //               style: TextStyle(
            //                 color: Colors.white70,
            //                 fontSize: 13,
            //               ),
            //             ),
            //           ),
            //         ],
            //       ),
            //       const SizedBox(height: 6),
            //       const Text(
            //         "By submitting this request, you agree to RiskSphere’s Terms and Privacy Policy.",
            //         style: TextStyle(fontSize: 12, color: Colors.white54),
            //       ),
            //       const Spacer(),
            //       Consumer<AuthNotifier>(
            //         builder: (context, provider, _) {
            //           return SizedBox(
            //             width: double.infinity,
            //             height: 48,
            //             child: ElevatedButton(
            //               style: ElevatedButton.styleFrom(
            //                 backgroundColor: consentChecked
            //                     ? const Color(0xFF8EC9FF)
            //                     : Colors.grey.shade700,
            //                 foregroundColor:
            //                     consentChecked ? Colors.black : Colors.white70,
            //               ),
            //
            //               // ✅ Disable button while loading
            //               onPressed: consentChecked &&
            //                       !provider.isSubmittingSupport
            //                   ? () async {
            //                       if (subjectController.text.trim().isEmpty ||
            //                           messageController.text.trim().isEmpty) {
            //                         ScaffoldMessenger.of(context).showSnackBar(
            //                           const SnackBar(
            //                             content: Text(
            //                                 "Subject and message are required"),
            //                           ),
            //                         );
            //                         return;
            //                       }
            //
            //                       await provider.submitSupportRequest(
            //                         context,
            //                         subjectController.text.trim(),
            //                         messageController.text.trim(),
            //                       );
            //
            //                       // ✅ Clear fields after success
            //                       subjectController.clear();
            //                       messageController.clear();
            //                       setState(() => consentChecked = false);
            //                     }
            //                   : null,
            //
            //               // ✅ Loader inside button
            //               child: provider.isSubmittingSupport
            //                   ? const SizedBox(
            //                       height: 22,
            //                       width: 22,
            //                       child: CircularProgressIndicator(
            //                         strokeWidth: 2.5,
            //                         valueColor: AlwaysStoppedAnimation<Color>(
            //                             Colors.black),
            //                       ),
            //                     )
            //                   : const Text(
            //                       "Submit",
            //                       style: TextStyle(
            //                         fontSize: 16,
            //                         fontWeight: FontWeight.w600,
            //                       ),
            //                     ),
            //             ),
            //           );
            //         },
            //       ),
            //     ],
            //   ),
            // ),
          );
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _inputField(
          label: "From",
          controller: fromController,
          enabled: false, // 🔒 always disabled
        ),
        const SizedBox(height: 12),
        _inputField(
          label: "To",
          hint: "support@risksphere.ai",
          enabled: false,
        ),
        const SizedBox(height: 12),
        _inputField(
          label: "Subject",
          controller: subjectController,
        ),
        const SizedBox(height: 12),
        _messageBox(),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            "${messageController.text.length}/1000",
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Checkbox(
              value: consentChecked,
              onChanged: (val) {
                setState(() => consentChecked = val ?? false);
              },
            ),
            Text("I accept the "),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TermsPage(
                      title: 'Terms & conditions',
                      url:
                          'https://www.risksphere.ai/terms-and-conditions/', // replace with your actual URL
                    ),
                  ),
                );
              },
              child: Text(
                "Terms & conditions",
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
        const Spacer(),
        _submitButton(),
      ],
    );
  }

  Widget _submitButton() {
    return Consumer<AuthNotifier>(
      builder: (context, provider, _) {
        final isDisabled =
            _isPageLoading || !consentChecked || provider.isSubmittingSupport;

        return SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDisabled ? Colors.grey.shade700 : const Color(0xFF8EC9FF),
              foregroundColor: isDisabled ? Colors.white70 : Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: isDisabled
                ? null
                : () async {
                    if (subjectController.text.trim().isEmpty ||
                        messageController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Subject and message are required"),
                        ),
                      );
                      return;
                    }

                    await context.read<AuthNotifier>().submitSupportRequest(
                          context,
                          subjectController.text.trim(),
                          messageController.text.trim(),
                        );

                    subjectController.clear();
                    messageController.clear();
                    setState(() => consentChecked = false);
                  },
            child: provider.isSubmittingSupport
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                : const Text(
                    "Submit",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        );
      },
    );
  }

  /// 🔹 Input field
  Widget _inputField({
    required String label,
    String? hint,
    TextEditingController? controller,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF161616),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white24),
            ),
          ),
        ),
      ],
    );
  }

  /// 🔹 Message box
  Widget _messageBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Message", style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 6),
        TextField(
          controller: messageController,
          maxLines: 6,
          maxLength: 1000,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            counterText: "",
            hintText: "Enter your message",
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF161616),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white24),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  /// ✅ SAME STYLE AS requestAccess
  Future<void> _submitSupport() async {
    if (subjectController.text.trim().isEmpty ||
        messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Subject and message are required"),
        ),
      );
      return;
    }

    await context.read<AuthNotifier>().submitSupportRequest(
          context,
          subjectController.text.trim(),
          messageController.text.trim(),
        );

    subjectController.clear();
    messageController.clear();
    setState(() => consentChecked = false);
  }
}
