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
    final userProfileProvider = context.read<UserProfileProvider>();

    final value = await userProfileProvider.getAllUserData(context, '', '');

    if (!mounted) return;

    if (value != null) {
      fromController.text = value.email ?? "";
    }

    setState(() {
      _isPageLoading = false;
    });
  }

  @override
  void dispose() {
    fromController.dispose();
    subjectController.dispose();
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        bool shouldExit = await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text('Exit App'),
            content: Text('Are you sure you want to exit this page?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Yes'),
              ),
            ],
          ),
        );

        if (shouldExit) {
          SystemNavigator.pop();
          return false;
        }
        return false;
      },
      child: SafeArea(
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Support",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        SizedBox(height: CustomSpacing.three),
        _inputField(
          label: "From",
          controller: fromController,
          enabled: false,
        ),
        SizedBox(height: CustomSpacing.three),
        _inputField(
          label: "To",
          hint: "support@risksphere.ai",
          enabled: false,
        ),
        SizedBox(height: CustomSpacing.three),
        _inputField(
          label: "Subject",
          controller: subjectController,
        ),
        SizedBox(height: CustomSpacing.three),
        _messageBox(),
        SizedBox(height: CustomSpacing.three),
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
                      url: 'https://www.risksphere.ai/terms-and-conditions/',
                    ),
                  ),
                );
              },
              child: Text(
                "Terms & conditions",
                style: TextStyle(color: AppColors.primaryMain),
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
        ),
      ],
    );
  }
}
