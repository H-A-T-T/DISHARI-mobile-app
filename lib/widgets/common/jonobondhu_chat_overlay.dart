import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../config/env.dart';
import '../../providers/language_provider.dart';
import '../../services/agent_service.dart';

class ChatMessage {
  final String id;
  final bool isUser;
  final String text;
  final String time;

  ChatMessage({
    required this.id,
    required this.isUser,
    required this.text,
    required this.time,
  });
}

class JonobondhuChatOverlay extends StatefulWidget {
  final Widget child;

  const JonobondhuChatOverlay({
    super.key,
    required this.child,
  });

  @override
  State<JonobondhuChatOverlay> createState() => _JonobondhuChatOverlayState();
}

class _JonobondhuChatOverlayState extends State<JonobondhuChatOverlay> {
  // Floating bubble position
  double _x = 0;
  double _y = 0;
  bool _initialized = false;

  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  bool _isTyping = false;
  StateSetter? _modalSetState;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final size = MediaQuery.of(context).size;
      // Position bottom-right by default matching web
      _x = size.width - 76;
      _y = size.height - 180;
      _initialized = true;

      _addWelcomeMessage();
    }
  }

  void _addWelcomeMessage() {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isBn = langProvider.isBn;

    _messages.clear();
    _messages.add(
      ChatMessage(
        id: 'welcome',
        isUser: false,
        text: isBn
            ? 'আসসালামু আলাইকুম ও স্বাগতম! আমি দিশারীর ‘জনবন্ধু AI’। সরকারি সেবা, প্রয়োজনীয় কাগজপত্র, ফি কিংবা আবেদন প্রক্রিয়া সম্পর্কে আমাকে যেকোনো প্রশ্ন করতে পারেন।'
            : 'Welcome! I am Dishari\'s "Jonobondhu AI". Ask me anything regarding government services, required documentation, fees, or procedural steps.',
        time: _currentTimeString(isBn),
      ),
    );
  }

  String _currentTimeString(bool isBn) {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute';
    return isBn ? AppConstants.toBengaliNumber(timeStr) : timeStr;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? customText]) async {
    final text = (customText ?? _inputController.text).trim();
    if (text.isEmpty) return;

    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isBn = langProvider.isBn;

    _inputController.clear();

    final userMsg = ChatMessage(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      isUser: true,
      text: text,
      time: _currentTimeString(isBn),
    );

    setState(() {
      _messages.add(userMsg);
      _isTyping = true;
    });
    if (_modalSetState != null) {
      _modalSetState!(() {});
    }
    _scrollToBottom();

    // Prepare recent history for AI context
    final history = _messages
        .where((m) => m.id != 'welcome')
        .map((m) => (isUser: m.isUser, text: m.text))
        .toList();

    // Call AgentService (reads GEMINI_API_KEY / OPENAI_API_KEY from .env, or falls back to civic catalog)
    try {
      final reply = await AgentService.getReply(
        prompt: text,
        isBn: isBn,
        history: history,
      );

      if (!mounted) return;

      final aiMsg = ChatMessage(
        id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
        isUser: false,
        text: reply,
        time: _currentTimeString(isBn),
      );

      setState(() {
        _isTyping = false;
        _messages.add(aiMsg);
      });
      if (_modalSetState != null) {
        _modalSetState!(() {});
      }
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(
          ChatMessage(
            id: 'ai-err-${DateTime.now().millisecondsSinceEpoch}',
            isUser: false,
            text: AgentService.getLocalFallbackReply(text, isBn),
            time: _currentTimeString(isBn),
          ),
        );
      });
      if (_modalSetState != null) {
        _modalSetState!(() {});
      }
      _scrollToBottom();
    }
  }

  void _openChatDialog() {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isBn = langProvider.isBn;

    final quickPrompts = isBn
        ? [
            'পাসপোর্ট করতে কী কাগজপত্র লাগে?',
            'অনলাইনে জন্ম নিবন্ধন যাচাই কীভাবে করব?',
            'NID সংশোধন প্রক্রিয়ায় কত ফি লাগে?',
            'বয়স্ক ভাতার যোগ্যতার নিয়ম কী?',
            'ই-নামজারিতে মোট কত টাকা খরচ হয়?',
            'ই-ট্রেড লাইসেন্স করতে কী লাগে?',
          ]
        : [
            'Documents required for passport?',
            'How to verify birth registration?',
            'Fee required for NID correction?',
            'Eligibility for old-age allowance?',
            'How much does e-Namjari cost?',
            'Documents needed for Trade License?',
          ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            _modalSetState = setModalState;

            final keyboardHeight = MediaQuery.of(modalContext).viewInsets.bottom;
            final sheetHeight = MediaQuery.of(modalContext).size.height * 0.82;

            return Padding(
              padding: EdgeInsets.only(bottom: keyboardHeight),
              child: Container(
                height: sheetHeight,
                decoration: const BoxDecoration(
                  color: AppColors.bgSurface,
                  border: Border(
                    top: BorderSide(color: AppColors.primaryGreen, width: 3),
                  ),
                ),
                child: Column(
                  children: [
                    // Chat Title Bar - Styled to match web JonobondhuChat exactly
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        color: AppColors.bgSurface,
                        border: Border(
                          bottom: BorderSide(color: AppColors.border, width: 1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              // Circular White Avatar matching website Jonobondhu AI
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.border, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(4),
                                child: SvgPicture.asset(
                                  'assets/icons/jonobondhu.svg',
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        isBn ? 'জনবন্ধু AI' : 'Jonobondhu AI',
                                        style: GoogleFonts.notoSansBengali(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      if (EnvConfig.hasAiConfigured) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: AppColors.lightGreen50,
                                            border: Border.all(color: AppColors.primaryGreen, width: 0.5),
                                          ),
                                          child: Text(
                                            'AI ACTIVE',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.primaryGreen,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: const BoxDecoration(
                                          color: AppColors.accentGreen,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        isBn ? 'নাগরিক সেবা সহায়ক · সক্রিয়' : 'Civic Service Assistant · Online',
                                        style: GoogleFonts.notoSansBengali(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                            onPressed: () => Navigator.pop(modalContext),
                          ),
                        ],
                      ),
                    ),

                    // Messages Scrollable List
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length + (_isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Typing Indicator Bubble
                          if (index == _messages.length && _isTyping) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Bot Avatar
                                  Container(
                                    width: 30,
                                    height: 30,
                                    margin: const EdgeInsets.only(right: 8, top: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.border, width: 1),
                                    ),
                                    padding: const EdgeInsets.all(3),
                                    child: SvgPicture.asset(
                                      'assets/icons/jonobondhu.svg',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: AppColors.bgMuted,
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          isBn ? 'জনবন্ধু AI লিখছে...' : 'Jonobondhu AI is typing...',
                                          style: GoogleFonts.notoSansBengali(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final msg = _messages[index];

                          // User message: right aligned, green background
                          if (msg.isUser) {
                            return Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.78,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen,
                                  border: Border.all(color: AppColors.primaryGreen),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      msg.text,
                                      style: GoogleFonts.notoSansBengali(
                                        fontSize: 13,
                                        color: Colors.white,
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      msg.time,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          // AI message: left aligned with circular Jonobondhu logo avatar (matching website)
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Circular White Avatar next to AI message (Matching Website)
                                Container(
                                  width: 30,
                                  height: 30,
                                  margin: const EdgeInsets.only(right: 8, top: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.border, width: 1),
                                  ),
                                  padding: const EdgeInsets.all(3),
                                  child: SvgPicture.asset(
                                    'assets/icons/jonobondhu.svg',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxWidth: MediaQuery.of(context).size.width * 0.76,
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: AppColors.bgMuted,
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SelectableText(
                                          msg.text,
                                          style: GoogleFonts.notoSansBengali(
                                            fontSize: 13,
                                            color: AppColors.textPrimary,
                                            height: 1.5,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          msg.time,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    // Quick Suggestion Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Row(
                        children: quickPrompts.map((prompt) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: InkWell(
                              onTap: () {
                                _sendMessage(prompt);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.bgPage,
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  prompt,
                                  style: GoogleFonts.notoSansBengali(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // Input Box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: const BoxDecoration(
                        color: AppColors.bgSurface,
                        border: Border(
                          top: BorderSide(color: AppColors.border, width: 1),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _inputController,
                                style: GoogleFonts.notoSansBengali(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: isBn
                                      ? 'যেকোনো সরকারি সেবা সম্পর্কে প্রশ্ন করুন...'
                                      : 'Ask anything about citizen services...',
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: const OutlineInputBorder(
                                    borderRadius: BorderRadius.zero,
                                    borderSide: BorderSide(color: AppColors.border),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.zero,
                                    borderSide: BorderSide(color: AppColors.primaryGreen, width: 1.5),
                                  ),
                                ),
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
                                foregroundColor: Colors.white,
                                shape: const RoundedRectangleBorder(),
                              ),
                              icon: const Icon(Icons.send, size: 16),
                              onPressed: () => _sendMessage(),
                            ),
                          ],
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
    ).whenComplete(() {
      _modalSetState = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final langProvider = Provider.of<LanguageProvider>(context);
    final isBn = langProvider.isBn;

    return Stack(
      children: [
        widget.child,

        // Floating Movable Jonobondhu AI Bubble (Styled 100% Identical to Website)
        Positioned(
          left: _x,
          top: _y,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _x = (_x + details.delta.dx).clamp(8.0, size.width - 72.0);
                _y = (_y + details.delta.dy).clamp(60.0, size.height - 140.0);
              });
            },
            onPanEnd: (details) {
              // Snap to nearest side (left or right) keeping released vertical height
              setState(() {
                if (_x + 30 < size.width / 2) {
                  _x = 12;
                } else {
                  _x = size.width - 72;
                }
              });
            },
            onTap: _openChatDialog,
            child: Material(
              color: Colors.transparent,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Circular White Bubble with Bangladesh Green Border (Matches Website JonobondhuChat)
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: AppColors.primaryGreen, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(8),
                    child: SvgPicture.asset(
                      'assets/icons/jonobondhu.svg',
                      fit: BoxFit.contain,
                    ),
                  ),

                  // Active AI Indicator Dot
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accentGreen,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),

                  // Tooltip badge pill
                  Positioned(
                    bottom: -6,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        color: AppColors.darkGreen,
                        child: Text(
                          isBn ? 'জনবন্ধু AI' : 'Jonobondhu',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
