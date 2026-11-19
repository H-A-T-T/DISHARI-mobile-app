import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../config/env.dart';
import '../../providers/language_provider.dart';
import '../../services/agent_service.dart';
import '../../services/tts_service.dart';
import '../../screens/opportunities_screen.dart';
import '../../screens/about_screen.dart';
import '../../screens/service_detail_screen.dart';
import 'jonobondhu_mascot.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ChatMessage {
  final String id;
  final bool isUser;
  final String text;
  final String time;
  final File? imageFile;

  ChatMessage({
    required this.id,
    required this.isUser,
    required this.text,
    required this.time,
    this.imageFile,
  });
}

class JonobondhuChatOverlay extends StatefulWidget {
  final Widget child;
  final void Function(int tabIndex)? onNavigateTab;

  /// Global navigator key to allow opening modals & routes anywhere in the app
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Global tab navigation handler
  static void Function(int tabIndex)? globalNavigateTab;

  const JonobondhuChatOverlay({
    super.key,
    required this.child,
    this.onNavigateTab,
  });

  /// অ্যাপের যেকোনো জায়গা থেকে জনবন্ধু AI চ্যাট খোলার স্ট্যাটিক মেথড
  static void openChat(BuildContext context) {
    _JonobondhuChatOverlayState.openChatFromContext(context);
  }

  @override
  State<JonobondhuChatOverlay> createState() => _JonobondhuChatOverlayState();
}

class _JonobondhuChatOverlayState extends State<JonobondhuChatOverlay> {
  // ভাসমান বাবলের অবস্থান
  double _x = 0;
  double _y = 0;

  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  static final List<ChatMessage> _sharedMessages = [];

  bool _isTyping = false;
  bool _isChatOpen = false;
  bool _showHeroGreeting = true;
  File? _stagedImage;
  StateSetter? _modalSetState;

  // ভয়েস ইনপুট
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  static _JonobondhuChatOverlayState? _activeState;

  @override
  void initState() {
    super.initState();
    _activeState = this;
    TtsService.instance.addListener(_onTtsStateChanged);
    if (widget.onNavigateTab != null) {
      JonobondhuChatOverlay.globalNavigateTab = widget.onNavigateTab;
    }
    if (_sharedMessages.isEmpty) {
      _initDefaultMessages();
    }
  }

  void _onTtsStateChanged() {
    _refreshUi();
  }

  @override
  void didUpdateWidget(covariant JonobondhuChatOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onNavigateTab != null) {
      JonobondhuChatOverlay.globalNavigateTab = widget.onNavigateTab;
    }
  }

  // ---------------------------------------------------------------------------
  // Navigation metadata  [bnTitle, enTitle, bnBreadcrumb, enBreadcrumb]
  // ---------------------------------------------------------------------------
  static const Map<String, String> _navAlias = {
    'passport': 'passport',
    'e-passport': 'passport',
    'epassport': 'passport',
    'land-mutation': 'land',
    'e-namjari': 'land',
    'namjari': 'land',
    'nid-correction': 'nid',
    'nid': 'nid',
    'birth-registration': 'birth',
    'birth': 'birth',
    'trade-license': 'trade',
    'tin-certificate': 'tin',
    'tin': 'tin',
    'widow-allowance': 'allowance',
    'allowance': 'allowance',
    'driving-license': 'driving',
  };

  static const Map<String, List<String>> _navData = {
    'passport': [
      'ই-পাসপোর্ট আবেদন',
      'E-Passport Application',
      'হোম > নাগরিক সেবা > পাসপোর্ট ও ভিসা',
      'Home > Civic Services > Passport & Visa',
    ],
    'land': [
      'ই-নামজারি (ভূমি রেকর্ড)',
      'Land Mutation (E-Namjari)',
      'হোম > নাগরিক সেবা > ভূমি ও ভূমি জরিপ',
      'Home > Civic Services > Land & Survey',
    ],
    'nid': [
      'জাতীয় পরিচয়পত্র (NID) সংশোধন',
      'National ID (NID) Correction',
      'হোম > নাগরিক সেবা > পরিচয় ও নিবন্ধন',
      'Home > Civic Services > Identity & NID',
    ],
    'birth': [
      'ডিজিটাল জন্ম নিবন্ধন',
      'Digital Birth Registration',
      'হোম > নাগরিক সেবা > জন্ম ও মৃত্যু নিবন্ধন',
      'Home > Civic Services > Birth & Death',
    ],
    'trade': [
      'ডিজিটাল ট্রেড লাইসেন্স',
      'Digital Trade License',
      'হোম > নাগরিক সেবা > ব্যবসা ও বাণিজ্য',
      'Home > Civic Services > Business & Trade',
    ],
    'tin': [
      'ই-টিআইএন ও আয়কর রিটার্ন',
      'e-TIN & Tax Return (NBR)',
      'হোম > নাগরিক সেবা > অর্থ ও রাজস্ব',
      'Home > Civic Services > Finance & Tax',
    ],
    'allowance': [
      'বিধবা ও সামাজিক নিরাপত্তা ভাতা',
      'Widow & Social Safety Allowance',
      'হোম > নাগরিক সেবা > সমাজসেবা ও অনুদান',
      'Home > Civic Services > Social Welfare',
    ],
    'driving': [
      'স্মার্ট ড্রাইভিং লাইসেন্স',
      'Smart Driving License',
      'হোম > নাগরিক সেবা > পরিবহন ও সড়ক',
      'Home > Civic Services > Transport',
    ],
    'tab:1': [
      'নাগরিক সেবা ক্যাটালগ',
      'Citizen Service Directory',
      'হোম > সকল সরকারি নাগরিক সেবা',
      'Home > All Citizen Services',
    ],
    'tab:2': [
      'স্মার্ট ডকুমেন্ট লকার',
      'Smart Document Locker',
      'হোম > ড্যাশবোর্ড > নাগরিক লকার ও ওয়ালেট',
      'Home > Dashboard > Locker & Wallet',
    ],
    'tab:3': [
      'নাগরিক সেবা ডেডলাইন ট্র্যাকার',
      'Civic Deadlines Tracker',
      'হোম > জরুরি সময়সীমা ও নোটিস',
      'Home > Urgent Deadlines',
    ],
    'tab:4': [
      'নাগরিক ড্যাশবোর্ড',
      'Citizen Dashboard',
      'হোম > নাগরিক প্রোফাইল',
      'Home > Profile',
    ],
    'tab:default': [
      'নাগরিক ফিড ড্যাশবোর্ড',
      'Citizen Feed Dashboard',
      'হোম > নাগরিক ফিড',
      'Home > Citizen Feed',
    ],
    'screen:opportunities': [
      'সরকারি সুযোগ ও যুব ঋণ হাব',
      'Govt Opportunities & Youth Grants',
      'হোম > তরুণ উদ্যোক্তা ও কৃষক অনুদান',
      'Home > Youth Grants & Loans',
    ],
    'screen:about': [
      'দিশারী প্ল্যাটফর্ম পরিচিতি',
      'About Dishari Platform',
      'হোম > আমাদের রূপকল্প ও পরিচিতি',
      'Home > About & Mission',
    ],
  };

  static (String title, String breadcrumb) _getNavMetadata(
    String type,
    String target,
    bool isBn, {
    String? customTitle,
    String? customBreadcrumb,
  }) {
    if (customTitle != null && customBreadcrumb != null) {
      return (customTitle, customBreadcrumb);
    }

    final t = target.toLowerCase();
    List<String>? entry = _navData[_navAlias[t] ?? ''];
    if (entry == null && type == 'tab') {
      entry = _navData['tab:$t'] ?? _navData['tab:default'];
    }
    if (entry == null && type == 'screen') {
      entry = _navData['screen:$t'];
    }

    if (entry != null) {
      return (
        customTitle ?? (isBn ? entry[0] : entry[1]),
        customBreadcrumb ?? (isBn ? entry[2] : entry[3]),
      );
    }

    return (
      customTitle ?? target,
      customBreadcrumb ??
          (isBn
              ? 'হোম > নাগরিক সেবা > অফিসিয়াল সার্ভিস'
              : 'Home > Civic Services > Official Service'),
    );
  }

  /// Triggers the Autonomous AI Navigation Transit HUD overlay and executes route
  static Future<void> triggerAutonomousNavigation(
    BuildContext context, {
    required String type,
    required String target,
    String? customTitle,
    String? customBreadcrumb,
  }) async {
    final navContext =
        JonobondhuChatOverlay.navigatorKey.currentContext ?? context;

    // শুধু চ্যাট শিট খোলা থাকলেই সেটা বন্ধ করি (অ্যাপের আসল পেজ নয়)
    if (_activeState?._isChatOpen ?? false) {
      try {
        Navigator.of(navContext, rootNavigator: true).pop();
      } catch (_) {}
    }

    final langProvider =
        Provider.of<LanguageProvider>(navContext, listen: false);
    final isBn = langProvider.isBn;

    final meta = _getNavMetadata(
      type,
      target,
      isBn,
      customTitle: customTitle,
      customBreadcrumb: customBreadcrumb,
    );

    await showGeneralDialog(
      context: navContext,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (dialogCtx, anim1, anim2) {
        return _AutonomousTransitHUDDialog(
          type: type,
          target: target,
          title: meta.$1,
          breadcrumb: meta.$2,
          isBn: isBn,
        );
      },
    );
  }

  static Widget buildAiMessageContent(
    BuildContext context,
    String rawText,
    String time, {
    String? msgId,
    bool isBn = true,
  }) {
    final regExp = RegExp(r'\[ACTION:([^:\]]+):([^:\]]+):([^\]]+)\]');
    final match = regExp.firstMatch(rawText);

    String cleanText = rawText;
    String? actionType;
    String? actionTarget;
    String? actionLabel;

    if (match != null) {
      cleanText = rawText.replaceAll(match.group(0)!, '').trim();
      actionType = match.group(1);
      actionTarget = match.group(2);
      actionLabel = match.group(3);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(
          cleanText,
          style: GoogleFonts.notoSansBengali(
            fontSize: 13,
            color: AppColors.textPrimary,
            height: 1.5,
          ),
        ),
        if (actionType != null &&
            actionTarget != null &&
            actionLabel != null) ...[
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF0FAF5),
              borderRadius: BorderRadius.zero,
              border: Border.all(color: AppColors.primaryGreen, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  color: AppColors.primaryGreen,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bolt,
                              size: 14, color: Color(0xFFFDE68A)),
                          const SizedBox(width: 4),
                          Text(
                            isBn
                                ? 'স্বয়ংক্রিয় নেভিগেশন'
                                : 'Autonomous Navigation',
                            style: GoogleFonts.notoSansBengali(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        isBn ? 'সক্রিয় রুট' : 'Active Route',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFA7F3D0),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: InkWell(
                    onTap: () => triggerAutonomousNavigation(
                      context,
                      type: actionType!,
                      target: actionTarget!,
                      customTitle: actionLabel,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.zero,
                        border: Border.all(
                            color: AppColors.primaryGreen, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.open_in_new,
                            size: 13,
                            color: AppColors.primaryGreen,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              actionLabel,
                              style: GoogleFonts.notoSansBengali(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (time.isNotEmpty)
              Text(
                time,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              )
            else
              const SizedBox.shrink(),
            if (msgId != null)
              AnimatedBuilder(
                animation: TtsService.instance,
                builder: (context, _) {
                  final isSpeakingThis =
                      TtsService.instance.currentSpeakingId == msgId &&
                          TtsService.instance.isPlaying;
                  return InkWell(
                    onTap: () {
                      TtsService.instance.speak(
                        text: cleanText,
                        msgId: msgId,
                        isBn: isBn,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isSpeakingThis
                            ? const Color(0xFFD1FAE5)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.zero,
                        border: Border.all(
                          color: isSpeakingThis
                              ? AppColors.primaryGreen
                              : const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSpeakingThis
                                ? Icons.volume_off
                                : Icons.volume_up,
                            size: 13,
                            color: isSpeakingThis
                                ? const Color(0xFFC8102E)
                                : AppColors.primaryGreen,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isSpeakingThis
                                ? (isBn ? 'থামুন' : 'Stop')
                                : (isBn ? 'ভয়েসে শুনুন' : 'Listen'),
                            style: GoogleFonts.notoSansBengali(
                              fontSize: 10,
                              fontWeight: isSpeakingThis
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isSpeakingThis
                                  ? AppColors.primaryGreen
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    TtsService.instance.removeListener(_onTtsStateChanged);
    TtsService.instance.stop();
    if (_activeState == this) {
      _activeState = null;
    }
    _speech.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initDefaultMessages() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute';

    _sharedMessages.clear();
    _sharedMessages.add(
      ChatMessage(
        id: 'welcome',
        isUser: false,
        text:
            'আসসালামু আলাইকুম ও স্বাগতম! আমি দিশারীর ‘জনবন্ধু AI’। সরকারি সেবা, প্রয়োজনীয় কাগজপত্র, ফি কিংবা আবেদন প্রক্রিয়া সম্পর্কে আমাকে যেকোনো প্রশ্ন করতে পারেন।',
        time: AppConstants.toBengaliNumber(timeStr),
      ),
    );
  }

  static String _currentTimeString(bool isBn) {
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
          _scrollController.position.maxScrollExtent + 90,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// মডাল ও মূল উইজেট—দুটোকেই রিফ্রেশ করার সহায়ক মেথড
  void _refreshUi() {
    if (mounted) setState(() {});
    if (_modalSetState != null) {
      _modalSetState!(() {});
    }
  }

  /// ডিভাইসে সমর্থিত সঠিক বাংলা/ইংরেজি locale ID খুঁজে বের করে
  Future<String> _resolveLocaleId(bool isBn) async {
    if (!isBn) return 'en_US';

    try {
      final locales = await _speech.locales();
      String norm(String s) => s.toLowerCase().replaceAll('-', '_');

      for (final l in locales) {
        if (norm(l.localeId) == 'bn_bd') return l.localeId;
      }
      for (final l in locales) {
        if (norm(l.localeId).startsWith('bn')) return l.localeId;
      }
    } catch (_) {}

    return 'en_US';
  }

  Future<void> _toggleVoiceInput() async {
    if (!_isListening) {
      final langProvider =
          Provider.of<LanguageProvider>(context, listen: false);
      final isBn = langProvider.isBn;

      final available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) {
              _isListening = false;
              _refreshUi();
            }
          }
        },
        onError: (error) {
          if (mounted) {
            _isListening = false;
            _refreshUi();
          }
        },
      );

      if (!available) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isBn
                    ? 'মাইক্রোফোন ব্যবহারের অনুমতি দিন অথবা ভয়েস সেবা চালু করুন।'
                    : 'Please allow microphone access or enable the speech service.',
                style: GoogleFonts.notoSansBengali(fontSize: 12),
              ),
            ),
          );
        }
        return;
      }

      final localeId = await _resolveLocaleId(isBn);

      _isListening = true;
      _refreshUi();

      await _speech.listen(
        // ignore: deprecated_member_use
        localeId: localeId,
        onResult: (result) {
          if (!mounted) return;

          _inputController.text = result.recognizedWords;
          _inputController.selection = TextSelection.fromPosition(
            TextPosition(offset: _inputController.text.length),
          );
          _isListening = !result.finalResult;

          _refreshUi();
        },
      );
    } else {
      await _speech.stop();
      if (mounted) {
        _isListening = false;
        _refreshUi();
      }
    }
  }

  Future<void> _sendMessage([String? customText]) async {
    // একসাথে দুটো রিকোয়েস্ট যেন না যায়
    if (_isTyping) return;

    // শোনা চলাকালীন পাঠালে আগে মাইক বন্ধ করি
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
      _refreshUi();
    }

    final text = (customText ?? _inputController.text).trim();
    final hasImage = _stagedImage != null;
    if (text.isEmpty && !hasImage) return;

    if (!mounted) return;
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isBn = langProvider.isBn;

    final imageToSend = _stagedImage;
    _stagedImage = null;
    _inputController.clear();
    _showHeroGreeting = false;

    final userMsg = ChatMessage(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      isUser: true,
      text: text.isNotEmpty
          ? text
          : (imageToSend != null
              ? (isBn
                  ? '📷 নথির ছবি বিশ্লেষণ করুন'
                  : '📷 Analyze this document image')
              : ''),
      time: _currentTimeString(isBn),
      imageFile: imageToSend,
    );

    setState(() {
      _sharedMessages.add(userMsg);
      _isTyping = true;
    });
    if (_modalSetState != null) {
      _modalSetState!(() {});
    }
    _scrollToBottom();

    // ছবি পাঠানো হলে AI সরাসরি বিশ্লেষণ করবে
    if (imageToSend != null) {
      try {
        final reply = await AgentService.analyzeImage(
          imageFile: imageToSend,
          userPrompt: text.isNotEmpty ? text : null,
          isBn: isBn,
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
          _sharedMessages.add(aiMsg);
        });
        if (_modalSetState != null) {
          _modalSetState!(() {});
        }
        _scrollToBottom();

        if (TtsService.instance.soundEnabled) {
          TtsService.instance.speak(
            text: aiMsg.text,
            msgId: aiMsg.id,
            isBn: isBn,
          );
        }
        return;
      } catch (e) {
        debugPrint('Image analysis error: $e');
        if (!mounted) return;
        setState(() {
          _isTyping = false;
          _sharedMessages.add(
            ChatMessage(
              id: 'ai-err-${DateTime.now().millisecondsSinceEpoch}',
              isUser: false,
              text: isBn
                  ? '⚠️ ছবিটি বিশ্লেষণে সাময়িক সমস্যা হয়েছে। অনুগ্রহ করে পরিষ্কার ছবি দিয়ে পুনরায় চেষ্টা করুন।'
                  : '⚠️ Failed to analyze image. Please provide a clearer photo.',
              time: _currentTimeString(isBn),
            ),
          );
        });
        if (_modalSetState != null) {
          _modalSetState!(() {});
        }
        _scrollToBottom();
        return;
      }
    }

    // AI-এর জন্য সাম্প্রতিক টেক্সট কথোপকথন
    final history = _sharedMessages
        .where((m) => m.id != 'welcome')
        .map((m) => (isUser: m.isUser, text: m.text))
        .toList();

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
        _sharedMessages.add(aiMsg);
      });
      if (_modalSetState != null) {
        _modalSetState!(() {});
      }
      _scrollToBottom();

      if (TtsService.instance.soundEnabled) {
        TtsService.instance.speak(
          text: aiMsg.text,
          msgId: aiMsg.id,
          isBn: isBn,
        );
      }
    } catch (_) {
      if (!mounted) return;
      final fallbackReply = AgentService.getLocalFallbackReply(text, isBn);
      final errId = 'ai-err-${DateTime.now().millisecondsSinceEpoch}';
      setState(() {
        _isTyping = false;
        _sharedMessages.add(
          ChatMessage(
            id: errId,
            isUser: false,
            text: fallbackReply,
            time: _currentTimeString(isBn),
          ),
        );
      });
      if (_modalSetState != null) {
        _modalSetState!(() {});
      }
      _scrollToBottom();

      if (TtsService.instance.soundEnabled) {
        TtsService.instance.speak(
          text: fallbackReply,
          msgId: errId,
          isBn: isBn,
        );
      }
    }
  }

  Future<void> _handleAttachmentOption(String option) async {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isBn = langProvider.isBn;

    if (option == 'camera' || option == 'gallery') {
      try {
        final picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source:
              option == 'camera' ? ImageSource.camera : ImageSource.gallery,
          imageQuality: 90,
        );

        if (image != null && mounted) {
          _stagedImage = File(image.path);
          _refreshUi();
          await _sendMessage();
        }
      } catch (e) {
        debugPrint('Image pick error: $e');
      }
    } else if (option == 'file') {
      try {
        final platformFile = await FilePicker.pickFile(
          type: FileType.any,
        );

        if (platformFile != null && platformFile.path != null && mounted) {
          final file = File(platformFile.path!);
          final name = platformFile.name.toLowerCase();

          if (name.endsWith('.jpg') ||
              name.endsWith('.jpeg') ||
              name.endsWith('.png') ||
              name.endsWith('.webp')) {
            _stagedImage = file;
            _refreshUi();
            await _sendMessage();
          } else {
            final userMsg = ChatMessage(
              id: 'user-file-${DateTime.now().millisecondsSinceEpoch}',
              isUser: true,
              text: isBn
                  ? '📄 [ফাইল সংযুক্ত করা হয়েছে: ${platformFile.name}]'
                  : '📄 [File attached: ${platformFile.name}]',
              time: _currentTimeString(isBn),
            );

            setState(() {
              _showHeroGreeting = false;
              _sharedMessages.add(userMsg);
              _isTyping = true;
            });
            if (_modalSetState != null) _modalSetState!(() {});
            _scrollToBottom();

            await Future.delayed(const Duration(milliseconds: 600));
            if (!mounted) return;
            setState(() {
              _isTyping = false;
              _sharedMessages.add(
                ChatMessage(
                  id: 'ai-file-${DateTime.now().millisecondsSinceEpoch}',
                  isUser: false,
                  text: isBn
                      ? '📄 আপনার ফাইলটি (${platformFile.name}) সফলভাবে গ্রহণ করা হয়েছে। এই নথিটি ব্যবহারের জন্য সংশ্লিষ্ট সেবায় আবেদন করতে পারেন:'
                      : '📄 File (${platformFile.name}) received. You can use it in your official application:',
                  time: _currentTimeString(isBn),
                ),
              );
            });
            if (_modalSetState != null) _modalSetState!(() {});
            _scrollToBottom();
          }
        }
      } catch (e) {
        debugPrint('File upload error: $e');
      }
    }
  }

  static void openChatFromContext(BuildContext context) {
    if (_activeState != null) {
      _activeState!._openChatDialog();
    } else {
      _showDirectChatSheet(context);
    }
  }

  /// বিকল্প সিম্পল চ্যাট শিট (overlay state না থাকলে)
  static void _showDirectChatSheet(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isBn = langProvider.isBn;
    final controller = TextEditingController();
    bool busy = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final keyboardHeight = MediaQuery.of(modalCtx).viewInsets.bottom;

          Future<void> send() async {
            final q = controller.text.trim();
            if (q.isEmpty || busy) return;
            controller.clear();
            busy = true;
            _sharedMessages.add(ChatMessage(
              id: 'u-${DateTime.now().millisecondsSinceEpoch}',
              isUser: true,
              text: q,
              time: _currentTimeString(isBn),
            ));
            setModalState(() {});
            String reply;
            try {
              reply = await AgentService.getReply(prompt: q, isBn: isBn);
            } catch (_) {
              reply = AgentService.getLocalFallbackReply(q, isBn);
            }
            _sharedMessages.add(ChatMessage(
              id: 'a-${DateTime.now().millisecondsSinceEpoch}',
              isUser: false,
              text: reply,
              time: _currentTimeString(isBn),
            ));
            busy = false;
            if (modalCtx.mounted) setModalState(() {});
          }

          return Padding(
            padding: EdgeInsets.only(bottom: keyboardHeight),
            child: Container(
              height: MediaQuery.of(modalCtx).size.height * 0.82,
              decoration: const BoxDecoration(
                color: AppColors.bgSurface,
                border: Border(
                  top: BorderSide(color: AppColors.primaryGreen, width: 3),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
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
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.primaryGreen,
                                    width: 1.5),
                              ),
                              padding: const EdgeInsets.all(2),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/mascot/jonobondhu_head.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              isBn
                                  ? 'জনবন্ধু AI (নাগরিক সহকারী)'
                                  : 'Jonobondhu AI (Assistant)',
                              style: GoogleFonts.notoSansBengali(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _sharedMessages.length,
                      itemBuilder: (c, idx) {
                        final m = _sharedMessages[idx];
                        return Align(
                          alignment: m.isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: m.isUser
                                  ? AppColors.primaryGreen
                                  : Colors.white,
                              border: m.isUser
                                  ? Border.all(
                                      color: const Color(0xFF004D38),
                                      width: 1)
                                  : const Border(
                                      left: BorderSide(
                                          color: AppColors.primaryGreen,
                                          width: 3),
                                      top: BorderSide(color: AppColors.border),
                                      right:
                                          BorderSide(color: AppColors.border),
                                      bottom:
                                          BorderSide(color: AppColors.border),
                                    ),
                            ),
                            child: m.isUser
                                ? Text(
                                    m.text,
                                    style: GoogleFonts.notoSansBengali(
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                  )
                                : buildAiMessageContent(
                                    modalCtx,
                                    m.text,
                                    m.time,
                                    isBn: isBn,
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
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
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: AppColors.border),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: TextField(
                                controller: controller,
                                style: GoogleFonts.notoSansBengali(
                                    fontSize: 13),
                                onSubmitted: (_) => send(),
                                decoration: InputDecoration(
                                  hintText: isBn
                                      ? 'কী সরকারি সেবা প্রয়োজন? লিখুন...'
                                      : 'Ask about government services...',
                                  hintStyle: GoogleFonts.notoSansBengali(
                                    fontSize: 12.5,
                                    color: AppColors.textMuted,
                                  ),
                                  isDense: true,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: send,
                            child: Container(
                              width: 36,
                              height: 36,
                              color: AppColors.primaryGreen,
                              child: const Icon(
                                Icons.send,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
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
      ),
    ).whenComplete(controller.dispose);
  }

  // ---------------------------------------------------------------------------
  // Chat sheet
  // ---------------------------------------------------------------------------
  void _openChatDialog() {
    if (_isChatOpen) return; // দ্বিতীয়বার খোলা আটকাই

    final navContext =
        JonobondhuChatOverlay.navigatorKey.currentContext ?? context;
    final langProvider =
        Provider.of<LanguageProvider>(navContext, listen: false);
    final isBn = langProvider.isBn;

    setState(() {
      _isChatOpen = true;
      _showHeroGreeting = _sharedMessages.length <= 1;
    });

    final quickPrompts = isBn
        ? [
            'বাবার মৃত্যুর পর জমির নামজারি করার নিয়ম কী?',
            'বিধবা ভাতার জন্য কোনো দালাল বা ফি লাগবে কি?',
            'ডিগ্রী পাস বেকারদের সরকারি যুব প্রশিক্ষণ ও ঋণ কীভাবে পাব?',
            'ই-পাসপোর্টের প্রয়োজনীয় কাগজ ও সরকারি ফি কত?',
            'উপবৃত্তি পাওয়ার অনলাইন আবেদন প্রক্রিয়া কী?',
            'পাসপোর্ট আবেদনে ইনভ্যালিড দেখালে কী করব?',
          ]
        : [
            'How to apply for land mutation after father’s death?',
            'Is there any fee or middleman for Widow Allowance?',
            'Govt youth skill training & loans for graduates?',
            'Documents and official fee for E-Passport?',
            'Online application process for student stipend?',
            'What to do if passport application shows invalid?',
          ];

    showModalBottomSheet(
      context: navContext,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            _modalSetState = setModalState;

            final keyboardHeight =
                MediaQuery.of(modalContext).viewInsets.bottom;
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
                    _buildHeader(modalContext, isBn),
                    Expanded(
                      child: _showHeroGreeting
                          ? _buildHeroGreetingView(
                              modalContext, isBn, quickPrompts)
                          : _buildConversationView(
                              modalContext, isBn, quickPrompts),
                    ),
                    _buildInputBar(isBn),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      _modalSetState = null;
      _speech.stop();
      _isListening = false;
      TtsService.instance.stop();
      if (mounted) {
        setState(() => _isChatOpen = false);
      }
    });
  }

  Widget _buildHeader(BuildContext modalContext, bool isBn) {
    return Container(
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
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: AppColors.primaryGreen, width: 1.5),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/mascot/jonobondhu_head.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.lightGreen50,
                                border: Border.all(
                                    color: AppColors.primaryGreen,
                                    width: 0.5),
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
                          Flexible(
                            child: Text(
                              isBn
                                  ? 'নাগরিক সেবা সহায়ক · সক্রিয়'
                                  : 'Civic Service Assistant · Online',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.notoSansBengali(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              // সাউন্ড টগল
              AnimatedBuilder(
                animation: TtsService.instance,
                builder: (context, _) {
                  final soundOn = TtsService.instance.soundEnabled;
                  return InkWell(
                    onTap: () {
                      TtsService.instance.toggleSound();
                      _refreshUi();
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: soundOn
                            ? const Color(0xFFE8F5E9)
                            : AppColors.bgMuted,
                        borderRadius: BorderRadius.zero,
                        border: Border.all(
                          color: soundOn
                              ? AppColors.primaryGreen
                              : AppColors.border,
                        ),
                      ),
                      child: Icon(
                        soundOn ? Icons.volume_up : Icons.volume_off,
                        size: 15,
                        color: soundOn
                            ? AppColors.primaryGreen
                            : AppColors.textMuted,
                      ),
                    ),
                  );
                },
              ),

              // হিরো/চ্যাট ভিউ টগল
              InkWell(
                onTap: () {
                  _showHeroGreeting = !_showHeroGreeting;
                  _refreshUi();
                },
                child: Container(
                  width: 30,
                  height: 30,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: _showHeroGreeting
                        ? const Color(0xFFFEF3C7)
                        : AppColors.bgMuted,
                    borderRadius: BorderRadius.zero,
                    border: Border.all(
                      color: _showHeroGreeting
                          ? const Color(0xFFF59E0B)
                          : AppColors.border,
                    ),
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    size: 15,
                    color: _showHeroGreeting
                        ? const Color(0xFFD97706)
                        : AppColors.textSecondary,
                  ),
                ),
              ),

              // ক্লোজ বাটন
              InkWell(
                onTap: () {
                  _speech.stop();
                  _isListening = false;
                  TtsService.instance.stop();
                  Navigator.pop(modalContext);
                },
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.bgMuted,
                    borderRadius: BorderRadius.zero,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroGreetingView(
      BuildContext ctx, bool isBn, List<String> quickPrompts) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryGreen, width: 2),
            ),
            padding: const EdgeInsets.all(4),
            child: ClipOval(
              child: Image.asset(
                'assets/mascot/jonobondhu_head.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isBn ? 'আমি জনবন্ধু AI' : 'I am Jonobondhu AI',
            style: GoogleFonts.notoSansBengali(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isBn
                ? 'সরকারি সেবা, কাগজপত্র, ফি ও আবেদন নিয়ে যেকোনো প্রশ্ন করুন।'
                : 'Ask anything about government services, documents, fees and applications.',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansBengali(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ...quickPrompts.map(
            (prompt) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: InkWell(
                onTap: () => _sendMessage(prompt),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    prompt,
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () {
              _showHeroGreeting = false;
              _refreshUi();
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              color: AppColors.primaryGreen,
              child: Text(
                isBn ? 'চ্যাট শুরু করুন' : 'Start chat',
                style: GoogleFonts.notoSansBengali(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationView(
      BuildContext ctx, bool isBn, List<String> quickPrompts) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _sharedMessages.length + (_isTyping ? 1 : 0),
            itemBuilder: (context, index) {
              // টাইপিং ইন্ডিকেটর
              if (index == _sharedMessages.length && _isTyping) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryGreen),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isBn
                            ? 'জনবন্ধু AI পর্যবেক্ষণ ও বিশ্লেষণ করছে...'
                            : 'Jonobondhu AI is analyzing & typing...',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final msg = _sharedMessages[index];

              // ইউজার মেসেজ
              if (msg.isUser) {
                return Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.78,
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      borderRadius: BorderRadius.zero,
                      border: Border.all(
                          color: const Color(0xFF004D38), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (msg.imageFile != null) ...[
                          Image.file(
                            msg.imageFile!,
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                          ),
                          const SizedBox(height: 8),
                        ],
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

              // AI মেসেজ
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      margin: const EdgeInsets.only(right: 8, top: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      padding: const EdgeInsets.all(1.5),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/mascot/jonobondhu_head.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.zero,
                          border: Border(
                            left: BorderSide(
                                color: AppColors.primaryGreen, width: 3),
                            top: BorderSide(color: AppColors.border),
                            right: BorderSide(color: AppColors.border),
                            bottom: BorderSide(color: AppColors.border),
                          ),
                        ),
                        child: buildAiMessageContent(
                          context,
                          msg.text,
                          msg.time,
                          msgId: msg.id,
                          isBn: isBn,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // দ্রুত প্রশ্নের চিপ
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: quickPrompts.map((prompt) {
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  onTap: () => _sendMessage(prompt),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.zero,
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
      ],
    );
  }

  PopupMenuItem<String> _attachItem({
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return PopupMenuItem<String>(
      value: value,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AppColors.lightGreen50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primaryGreen, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.notoSansBengali(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.notoSansBengali(
                  fontSize: 10.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isBn) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_stagedImage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8, left: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.lightGreen50,
                  borderRadius: BorderRadius.zero,
                  border: Border.all(
                      color: AppColors.primaryGreen.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.file(_stagedImage!,
                        width: 36, height: 36, fit: BoxFit.cover),
                    const SizedBox(width: 8),
                    Text(
                      isBn ? 'ছবি সংযুক্ত হয়েছে' : 'Image attached',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () {
                        _stagedImage = null;
                        _refreshUi();
                      },
                      child: const Icon(Icons.close_rounded,
                          size: 16, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // (+) অ্যাটাচমেন্ট মেনু
                PopupMenuButton<String>(
                  tooltip:
                      isBn ? 'ফাইল ও ছবি আপলোড' : 'Attach file or image',
                  offset: const Offset(0, -180),
                  color: Colors.white,
                  elevation: 6,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                    side: BorderSide(color: AppColors.border),
                  ),
                  onSelected: _handleAttachmentOption,
                  itemBuilder: (_) => [
                    _attachItem(
                      value: 'camera',
                      icon: Icons.camera_alt_rounded,
                      title:
                          isBn ? 'ক্যামেরা (ছবি তুলুন)' : 'Take Photo (Camera)',
                      subtitle: isBn
                          ? 'AI দিয়ে তাৎক্ষণিক স্ক্যান ও যাচাই'
                          : 'Instant AI document scan',
                    ),
                    const PopupMenuDivider(height: 1),
                    _attachItem(
                      value: 'gallery',
                      icon: Icons.photo_library_rounded,
                      title: isBn
                          ? 'ছবি আপলোড (গ্যালারি)'
                          : 'Upload Photo (Gallery)',
                      subtitle: isBn
                          ? 'NID, পাসপোর্ট বা ডিজিটাল সনদ'
                          : 'NID, Passport or Certificate',
                    ),
                    const PopupMenuDivider(height: 1),
                    _attachItem(
                      value: 'file',
                      icon: Icons.attach_file_rounded,
                      title: isBn
                          ? 'ফাইল / পিডিএফ আপলোড'
                          : 'Upload File / PDF',
                      subtitle: isBn
                          ? 'অন্যান্য দলিল ও ডকুমেন্ট'
                          : 'Other official documents',
                    ),
                  ],
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.bgMuted,
                      borderRadius: BorderRadius.zero,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // টেক্সট ইনপুট + মাইক
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.zero,
                      border: Border.all(
                        color: _isListening ? Colors.red : AppColors.border,
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _inputController,
                            style: GoogleFonts.notoSansBengali(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: _isListening
                                  ? (isBn
                                      ? 'শুনছি... বলুন'
                                      : 'Listening... speak now')
                                  : (isBn
                                      ? 'কী সরকারি সেবা প্রয়োজন? লিখুন...'
                                      : 'Ask about government services...'),
                              hintStyle: GoogleFonts.notoSansBengali(
                                fontSize: 12.5,
                                color: AppColors.textMuted,
                              ),
                              isDense: true,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        InkWell(
                          onTap: _toggleVoiceInput,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.zero,
                              color: _isListening
                                  ? Colors.red.withValues(alpha: 0.15)
                                  : Colors.transparent,
                              border: _isListening
                                  ? Border.all(color: Colors.red)
                                  : null,
                            ),
                            child: Icon(
                              _isListening ? Icons.mic_off : Icons.mic_rounded,
                              size: 18,
                              color: _isListening
                                  ? Colors.red
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // সেন্ড বাটন
                InkWell(
                  onTap: () => _sendMessage(),
                  child: Container(
                    width: 36,
                    height: 36,
                    color: AppColors.primaryGreen,
                    child: const Icon(
                      Icons.send,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 2, right: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isBn ? 'ইন্টারফেস সংস্করণ ২.০' : 'Interface v2.0',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Text(
                    isBn ? 'দিশারী জনবন্ধু সহায়ক' : 'Dishari Jonobondhu',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // বাবলকে সবসময় স্ক্রিনের ভেতরে রাখার হিসাব
    final double screenW = size.width > 50 ? size.width : 390.0;
    final double screenH = size.height > 100 ? size.height : 800.0;

    if (_x <= 0 || _x > screenW - 64) {
      _x = screenW - 74.0;
    }
    if (_y <= 0 || _y > screenH - 120) {
      _y = screenH - 170.0;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,

        // ভাসমান, সরানোযোগ্য জনবন্ধু AI বাবল (চ্যাট খোলা থাকলে লুকানো)
        if (!_isChatOpen)
          Positioned(
            left: _x,
            top: _y,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (details) {
                setState(() {
                  _x = (_x + details.delta.dx).clamp(10.0, screenW - 70.0);
                  _y = (_y + details.delta.dy).clamp(60.0, screenH - 130.0);
                });
              },
              onPanEnd: (details) {
                // ছেড়ে দিলে নিকটতম পাশে স্ন্যাপ করবে
                setState(() {
                  if (_x + 30 < screenW / 2) {
                    _x = 12;
                  } else {
                    _x = screenW - 74;
                  }
                });
              },
              onTap: _openChatDialog,
              child: Material(
                color: Colors.transparent,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    JonobondhuMascot(
                      side: (_x + 30 < screenW / 2)
                          ? MascotSide.left
                          : MascotSide.right,
                      isListening: _isListening,
                      isOpen: _isChatOpen,
                      isSpeaking: _isTyping,
                      width: 66,
                      height: 84,
                      onTap: _openChatDialog,
                    ),

                    // সক্রিয় AI ইন্ডিকেটর ডট
                    Positioned(
                      top: 4,
                      right: 6,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accentGreen,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                            ),
                          ],
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

// -----------------------------------------------------------------------------
// Autonomous Navigation Transit HUD
// -----------------------------------------------------------------------------
class _AutonomousTransitHUDDialog extends StatefulWidget {
  final String type;
  final String target;
  final String title;
  final String breadcrumb;
  final bool isBn;

  const _AutonomousTransitHUDDialog({
    required this.type,
    required this.target,
    required this.title,
    required this.breadcrumb,
    required this.isBn,
  });

  @override
  State<_AutonomousTransitHUDDialog> createState() =>
      _AutonomousTransitHUDDialogState();
}

class _AutonomousTransitHUDDialogState
    extends State<_AutonomousTransitHUDDialog> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1400), _go);
  }

  void _go() {
    if (!mounted) return;
    final nav = Navigator.of(context, rootNavigator: true);
    nav.pop(); // HUD বন্ধ

    if (widget.type == 'tab') {
      final idx = int.tryParse(widget.target);
      if (idx != null) {
        JonobondhuChatOverlay.globalNavigateTab?.call(idx);
      }
    } else if (widget.type == 'screen') {
      final target = widget.target.toLowerCase();
      if (target == 'opportunities') {
        nav.push(MaterialPageRoute(builder: (_) => const OpportunitiesScreen()));
      } else if (target == 'about') {
        nav.push(MaterialPageRoute(builder: (_) => const AboutScreen()));
      }
    } else if (widget.type == 'service') {
      nav.push(MaterialPageRoute(builder: (_) => ServiceDetailScreen(slug: widget.target)));
    } else {
      nav.push(MaterialPageRoute(builder: (_) => ServiceDetailScreen(slug: widget.target)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.primaryGreen, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.isBn ? 'নেভিগেট করা হচ্ছে...' : 'Navigating...',
                style: GoogleFonts.notoSansBengali(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansBengali(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.breadcrumb,
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansBengali(
                  fontSize: 10.5,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}