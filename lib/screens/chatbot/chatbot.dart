import 'package:uuid/uuid.dart';

import '../../utils/global_imports.dart';

class _ChatbotContent extends StatefulWidget {
  final String? locationId;

  const _ChatbotContent({this.locationId});

  @override
  State<_ChatbotContent> createState() => _ChatbotContentState();
}

class _ChatbotContentState extends State<_ChatbotContent> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _sessionId;
  bool _isTyping = false;
  bool _hasText = false;
  List<Map<String, dynamic>> messages = [];

  bool get _showSuggestions =>
      messages.where((m) => m["isBot"] == false).isEmpty;

  @override
  void initState() {
    super.initState();
    _sessionId = const Uuid().v4();
    messages.add({
      "isBot": true,
      "text": "Hi, I'm RiskBuddy your personalized Assistant.",
    });
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _currentTime() {
    final now = DateTime.now();
    final hour = now.hour > 12
        ? now.hour - 12
        : now.hour == 0
            ? 12
            : now.hour;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? "PM" : "AM";
    return "$hour:$minute $period";
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    final userMessage = _controller.text.trim();

    setState(() {
      messages.add({"isBot": false, "text": userMessage});
      _isTyping = true;
    });

    _controller.clear();
    _scrollToBottom();

    final provider =
        Provider.of<MyLocationListProvider>(context, listen: false);

    try {
      final reply = await provider.sendChatDashboardMessage(
        context: context,
        message: userMessage,
        page: "dashboard",
      );
      // final reply = await provider.sendChatMessage(
      //   context: context,
      //   message: userMessage,
      //   locationId: widget.locationId ?? "",
      //   sessionId: _sessionId!,
      //   locationName: provider.selectedLocation?.locationName ?? "",
      //   accountName: provider.selectedLocation?.accountName ?? "",
      // );

      debugPrint("BOT REPLY => $reply");
      setState(() {
        _isTyping = false;
        messages.add({"isBot": true, "text": reply ?? "No response"});
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isTyping = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// ── Header ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryMain,
                child:
                    const Icon(Icons.smart_toy, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "RiskBuddy",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      SvgPicture.asset(
                        "assets/images/ai.svg",
                        color: AppColors.primaryMain,
                        width: 12,
                        height: 12,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        "Smarter decisions, lower risk.",
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  // IconButton(
                  //   icon: const Icon(Icons.open_in_full,
                  //       color: Colors.grey, size: 18),
                  //   onPressed: () {
                  //     // Navigator.pop(context);
                  //     // Navigator.push(
                  //     //   context,
                  //     //   MaterialPageRoute(
                  //     //     builder: (_) =>
                  //     //         ChatbotPage(locationId: widget.locationId),
                  //     //   ),
                  //     // );
                  //   },
                  // ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
        ),

        const Divider(color: Color(0xFF2A2A2A), height: 1),

        /// ── Messages ──
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: messages.length + (_isTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (_isTyping && index == messages.length) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text("...",
                        style: TextStyle(color: Colors.white)),
                  ),
                );
              }

              final message = messages[index];
              final isBot = message["isBot"] as bool;

              return Column(
                crossAxisAlignment:
                    isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isBot
                          ? const Color(0xFF1E1E1E)
                          : const Color(0xFF2D2D2D),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: isBot
                        ? _buildFormattedText(context, message["text"])
                        : Text(
                            message["text"],
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      _currentTime(),
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: Colors.black,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFF3A3A3A), width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: "Ask about risk data, eligibility...",
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                      border: InputBorder.none,
                      isCollapsed: true,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                GestureDetector(
                  onTap: _hasText ? _sendMessage : null,
                  child: Icon(
                    Icons.telegram_sharp,
                    color: _hasText ? AppColors.primaryMain : Colors.grey,
                    size: 38,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 25,
        )
      ],
    );
  }
}

Widget _buildFormattedText(BuildContext context, String rawText) {
  final text = rawText.replaceAll('**', '');
  final lines = text.split('\n');
  final List<Widget> elements = [];

  for (int i = 0; i < lines.length; i++) {
    final trimmed = lines[i].trim();
    if (RegExp(r'^\d+\.$').hasMatch(trimmed)) continue;
    if (trimmed.isEmpty) {
      elements.add(const SizedBox(height: 8));
      continue;
    }

    if (trimmed.endsWith(':') && !trimmed.startsWith('*')) {
      elements.add(Padding(
        padding: EdgeInsets.only(top: i > 0 ? 8.0 : 0, bottom: 4),
        child: Text(
          trimmed,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppColors.primaryMain,
          ),
        ),
      ));
    } else if (trimmed.startsWith('*')) {
      final bulletText = trimmed.substring(1).trim();
      elements.add(Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• ',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
            Expanded(
              child: Text(
                bulletText,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ));
    } else {
      final isHighRisk =
          trimmed.contains('Very High') || trimmed.contains('High');
      elements.add(Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          trimmed,
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: isHighRisk ? Colors.white : Colors.white,
          ),
        ),
      ));
    }
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: elements,
  );
}

class ChatbotBottomSheet extends StatefulWidget {
  late final String? locationId;

  ChatbotBottomSheet({this.locationId});

  @override
  State<ChatbotBottomSheet> createState() => ChatbotBottomSheetState();
}

class ChatbotBottomSheetState extends State<ChatbotBottomSheet> {
  bool _isFullScreen = false;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        height: _isFullScreen ? screenHeight : screenHeight * 0.62,
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => setState(() => _isFullScreen = !_isFullScreen),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade600,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Icon(
                      _isFullScreen
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_up,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _ChatbotContent(locationId: widget.locationId),
            ),
          ],
        ),
      ),
    );
  }
}
