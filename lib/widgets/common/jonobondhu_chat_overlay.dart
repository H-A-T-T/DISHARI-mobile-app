import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../config/env.dart';
import '../../providers/language_provider.dart';
import '../../screens/image_verification_screen.dart';
import '../../screens/opportunities_screen.dart';
import '../../screens/service_detail_screen.dart';
import '../../screens/about_screen.dart';
import '../../services/agent_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

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
  final void Function(int tabIndex)? onNavigateTab;

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
  StateSetter? _modalSetState;

  // ভয়েস ইনপুট
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  static _JonobondhuChatOverlayState? _activeState;
  static void Function(int tabIndex)? globalNavigateTab;

  @override
  void initState() {
    super.initState();
    _activeState = this;
    globalNavigateTab = widget.onNavigateTab;
    if (_sharedMessages.isEmpty) {
      _initDefaultMessages();
    }
  }

  @override
  void didUpdateWidget(covariant JonobondhuChatOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onNavigateTab != null) {
      globalNavigateTab = widget.onNavigateTab;
    }
  }

  static void navigateFromAction(BuildContext context, String type, String target) {
    // Dismiss chat sheet or dialog
    Navigator.of(context, rootNavigator: true).pop();

    if (type == 'tab') {
      final tabIdx = int.tryParse(target) ?? 0;
      globalNavigateTab?.call(tabIdx);
    } else if (type == 'service') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ServiceDetailScreen(slug: target),
        ),
      );
    } else if (type == 'screen') {
      if (target == 'opportunities') {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const OpportunitiesScreen(),
          ),
        );
      } else if (target == 'about') {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const AboutScreen(),
          ),
        );
      }
    }
  }

  static Widget buildAiMessageContent(BuildContext context, String rawText, String time) {
    final regExp = RegExp(r'\[ACTION:([^:]+):([^:]+):([^\]]+)\]');
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
        if (actionType != null && actionTarget != null && actionLabel != null) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: () => navigateFromAction(
              context,
              actionType!,
              actionTarget!,
            ),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel,
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
        if (time.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            time,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
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

      // প্রথমে bn_BD খুঁজি
      for (final l in locales) {
        if (norm(l.localeId) == 'bn_bd') return l.localeId;
      }
      // না পেলে যেকোনো বাংলা locale
      for (final l in locales) {
        if (norm(l.localeId).startsWith('bn')) return l.localeId;
      }
    } catch (_) {}

    // বাংলা সমর্থিত না হলে ইংরেজিতে ফিরে যাই
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
    // শোনা চলাকালীন পাঠালে আগে মাইক বন্ধ করি
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
      _refreshUi();
    }

    final text = (customText ?? _inputController.text).trim();
    if (text.isEmpty) return;

    if (!mounted) return;
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
      _sharedMessages.add(userMsg);
      _isTyping = true;
    });
    if (_modalSetState != null) {
      _modalSetState!(() {});
    }
    _scrollToBottom();

    // AI-এর জন্য সাম্প্রতিক কথোপকথন
    final history = _sharedMessages
        .where((m) => m.id != 'welcome')
        .map((m) => (isUser: m.isUser, text: m.text))
        .toList();

    // AgentService কল (.env থেকে GEMINI_API_KEY / OPENAI_API_KEY, না থাকলে লোকাল ক্যাটালগ)
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
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _sharedMessages.add(
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

  Future<void> _handleAttachmentOption(String option, BuildContext modalContext) async {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isBn = langProvider.isBn;

    if (option == 'camera') {
      try {
        final picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 90,
        );

        if (image != null && mounted) {
          final file = File(image.path);

          final userMsg = ChatMessage(
            id: 'user-img-${DateTime.now().millisecondsSinceEpoch}',
            isUser: true,
            text: isBn
                ? '📷 [ক্যামেরা দিয়ে ছবি তোলা হয়েছে: ${image.name}]'
                : '📷 [Image captured via Camera: ${image.name}]',
            time: _currentTimeString(isBn),
          );

          setState(() {
            _sharedMessages.add(userMsg);
            _isTyping = true;
          });
          if (_modalSetState != null) _modalSetState!(() {});
          _scrollToBottom();

          if (modalContext.mounted) {
            Navigator.push(
              modalContext,
              MaterialPageRoute(
                builder: (_) => ImageVerificationScreen(
                  initialImageFile: file,
                ),
              ),
            ).then((_) {
              if (mounted) {
                setState(() {
                  _isTyping = false;
                  _sharedMessages.add(
                    ChatMessage(
                      id: 'ai-doc-${DateTime.now().millisecondsSinceEpoch}',
                      isUser: false,
                      text: isBn
                          ? '✅ আপনার নথির ছবি সফলভাবে বিশ্লেষণ করা হয়েছে! এটি যাচাই ও লকারে সংরক্ষণের জন্য প্রস্তুত।\n\n'
                            '[ACTION:tab:2:নাগরিক লকারে সংরক্ষিত নথি দেখুন]'
                          : '✅ Document image analyzed successfully! Ready in your locker.\n\n'
                            '[ACTION:tab:2:View in Document Locker]',
                      time: _currentTimeString(isBn),
                    ),
                  );
                });
                if (_modalSetState != null) _modalSetState!(() {});
                _scrollToBottom();
              }
            });
          }
        }
      } catch (e) {
        debugPrint('Camera capture error: $e');
      }
    } else if (option == 'gallery') {
      try {
        final picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 90,
        );

        if (image != null && mounted) {
          final file = File(image.path);

          final userMsg = ChatMessage(
            id: 'user-img-${DateTime.now().millisecondsSinceEpoch}',
            isUser: true,
            text: isBn
                ? '🖼️ [গ্যালারি থেকে ছবি আপলোড করা হয়েছে: ${image.name}]'
                : '🖼️ [Image uploaded from Gallery: ${image.name}]',
            time: _currentTimeString(isBn),
          );

          setState(() {
            _sharedMessages.add(userMsg);
            _isTyping = true;
          });
          if (_modalSetState != null) _modalSetState!(() {});
          _scrollToBottom();

          if (modalContext.mounted) {
            Navigator.push(
              modalContext,
              MaterialPageRoute(
                builder: (_) => ImageVerificationScreen(
                  initialImageFile: file,
                ),
              ),
            ).then((_) {
              if (mounted) {
                setState(() {
                  _isTyping = false;
                  _sharedMessages.add(
                    ChatMessage(
                      id: 'ai-doc-${DateTime.now().millisecondsSinceEpoch}',
                      isUser: false,
                      text: isBn
                          ? '✅ গ্যালারি থেকে আপলোডকৃত নথিটি AI দিয়ে যাচাই করা হয়েছে। এটি লকারে সংরক্ষিত হয়েছে।\n\n'
                            '[ACTION:tab:2:নাগরিক লকারে দেখুন]'
                          : '✅ Document from gallery verified with AI and saved to locker.\n\n'
                            '[ACTION:tab:2:View in Document Locker]',
                      time: _currentTimeString(isBn),
                    ),
                  );
                });
                if (_modalSetState != null) _modalSetState!(() {});
                _scrollToBottom();
              }
            });
          }
        }
      } catch (e) {
        debugPrint('Gallery upload error: $e');
      }
    } else if (option == 'file') {
      try {
        final platformFile = await FilePicker.pickFile(
          type: FileType.any,
        );

        if (platformFile != null && platformFile.path != null && mounted) {
          final file = File(platformFile.path!);
          final name = platformFile.name.toLowerCase();

          final userMsg = ChatMessage(
            id: 'user-file-${DateTime.now().millisecondsSinceEpoch}',
            isUser: true,
            text: isBn
                ? '📄 [ফাইল সংযুক্ত করা হয়েছে: ${platformFile.name}]'
                : '📄 [File attached: ${platformFile.name}]',
            time: _currentTimeString(isBn),
          );

          setState(() {
            _sharedMessages.add(userMsg);
            _isTyping = true;
          });
          if (_modalSetState != null) _modalSetState!(() {});
          _scrollToBottom();

          if (name.endsWith('.jpg') || name.endsWith('.jpeg') || name.endsWith('.png') || name.endsWith('.webp')) {
            if (modalContext.mounted) {
              Navigator.push(
                modalContext,
                MaterialPageRoute(
                  builder: (_) => ImageVerificationScreen(
                    initialImageFile: file,
                  ),
                ),
              );
            }
          } else {
            if (mounted) {
              setState(() {
                _isTyping = false;
                _sharedMessages.add(
                  ChatMessage(
                    id: 'ai-file-${DateTime.now().millisecondsSinceEpoch}',
                    isUser: false,
                    text: isBn
                        ? '📄 আপনার ফাইলটি (${platformFile.name}) সফলভাবে গ্রহণ করা হয়েছে। এটি যে সরকারি সেবায় যুক্ত করতে চান, নিচের বাটন থেকে সরাসরি সেই সেবায় যেতে পারেন:'
                        : '📄 File (${platformFile.name}) received. Select the service below where you want to attach it:',
                    time: _currentTimeString(isBn),
                  ),
                );
              });
              if (_modalSetState != null) _modalSetState!(() {});
              _scrollToBottom();
            }
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
      // বিকল্প: সরাসরি বটম শিট
      _showDirectChatSheet(context);
    }
  }

  static void _showDirectChatSheet(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isBn = langProvider.isBn;
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final keyboardHeight = MediaQuery.of(modalCtx).viewInsets.bottom;
          return Padding(
            padding: EdgeInsets.only(bottom: keyboardHeight),
            child: Container(
              height: MediaQuery.of(modalCtx).size.height * 0.82,
              decoration: const BoxDecoration(
                color: AppColors.bgSurface,
                border: Border(
                    top: BorderSide(color: AppColors.primaryGreen, width: 3)),
              ),
              child: Column(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      color: AppColors.bgSurface,
                      border: Border(
                          bottom:
                              BorderSide(color: AppColors.border, width: 1)),
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
                                    color: AppColors.border, width: 1.5),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: SvgPicture.asset(
                                  'assets/icons/jonobondhu.svg'),
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
                                  : AppColors.bgMuted,
                              borderRadius: m.isUser
                                  ? const BorderRadius.only(
                                      topLeft: Radius.circular(18),
                                      topRight: Radius.circular(18),
                                      bottomLeft: Radius.circular(18),
                                      bottomRight: Radius.circular(4),
                                    )
                                  : const BorderRadius.only(
                                      topLeft: Radius.circular(4),
                                      topRight: Radius.circular(18),
                                      bottomLeft: Radius.circular(18),
                                      bottomRight: Radius.circular(18),
                                    ),
                              border: Border.all(
                                  color: m.isUser
                                      ? AppColors.primaryGreen
                                      : AppColors.border),
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
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                          PopupMenuButton<String>(
                            tooltip: isBn ? 'ফাইল ও ছবি আপলোড' : 'Attach file or image',
                            offset: const Offset(0, -180),
                            color: Colors.white,
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            onSelected: (val) {
                              if (_activeState != null) {
                                _activeState!._handleAttachmentOption(val, ctx);
                              }
                            },
                            itemBuilder: (menuCtx) => [
                              PopupMenuItem(
                                value: 'camera',
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
                                      child: const Icon(Icons.camera_alt_rounded, color: AppColors.primaryGreen, size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      isBn ? 'ক্যামেরা (ছবি তুলুন)' : 'Take Photo (Camera)',
                                      style: GoogleFonts.notoSansBengali(fontSize: 13, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(height: 1),
                              PopupMenuItem(
                                value: 'gallery',
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
                                      child: const Icon(Icons.photo_library_rounded, color: AppColors.primaryGreen, size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      isBn ? 'ছবি আপলোড (গ্যালারি)' : 'Upload Photo (Gallery)',
                                      style: GoogleFonts.notoSansBengali(fontSize: 13, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(height: 1),
                              PopupMenuItem(
                                value: 'file',
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
                                      child: const Icon(Icons.attach_file_rounded, color: AppColors.primaryGreen, size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      isBn ? 'ফাইল / পিডিএফ আপলোড' : 'Upload File / PDF',
                                      style: GoogleFonts.notoSansBengali(fontSize: 13, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.bgMuted,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Icon(Icons.add_rounded, size: 22, color: AppColors.textPrimary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.bgMuted,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: AppColors.border),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: TextField(
                                controller: controller,
                                style: GoogleFonts.notoSansBengali(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: isBn ? 'বার্তা লিখুন...' : 'Message Jonobondhu AI...',
                                  hintStyle: GoogleFonts.notoSansBengali(fontSize: 13, color: AppColors.textMuted),
                                  isDense: true,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () async {
                              final q = controller.text.trim();
                              if (q.isEmpty) return;
                              controller.clear();
                              final time = _currentTimeString(isBn);
                              _sharedMessages.add(ChatMessage(
                                  id: 'u-${DateTime.now().millisecondsSinceEpoch}',
                                  isUser: true,
                                  text: q,
                                  time: time));
                              setModalState(() {});
                              final reply = await AgentService.getReply(
                                  prompt: q, isBn: isBn);
                              _sharedMessages.add(ChatMessage(
                                  id: 'a-${DateTime.now().millisecondsSinceEpoch}',
                                  isUser: false,
                                  text: reply,
                                  time: _currentTimeString(isBn)));
                              setModalState(() {});
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primaryGreen,
                              ),
                              child: const Icon(
                                Icons.arrow_upward_rounded,
                                size: 20,
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
    );
  }

  void _openChatDialog() {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isBn = langProvider.isBn;

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
      context: context,
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
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  border: Border(
                    top: BorderSide(color: AppColors.primaryGreen, width: 3),
                  ),
                ),
                child: Column(
                  children: [
                    // চ্যাট টাইটেল বার
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
                                      color: AppColors.border, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.05),
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
                                      Text(
                                        isBn
                                            ? 'নাগরিক সেবা সহায়ক · সক্রিয়'
                                            : 'Civic Service Assistant · Online',
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
                          InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              _speech.stop();
                              _isListening = false;
                              Navigator.pop(modalContext);
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: AppColors.bgMuted,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // মেসেজ তালিকা
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 30,
                                    height: 30,
                                    margin:
                                        const EdgeInsets.only(right: 8, top: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: AppColors.border, width: 1),
                                    ),
                                    padding: const EdgeInsets.all(3),
                                    child: SvgPicture.asset(
                                      'assets/icons/jonobondhu.svg',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: AppColors.bgMuted,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(4),
                                        topRight: Radius.circular(18),
                                        bottomLeft: Radius.circular(18),
                                        bottomRight: Radius.circular(18),
                                      ),
                                      border:
                                          Border.all(color: AppColors.border),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    AppColors.primaryGreen),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          isBn
                                              ? 'জনবন্ধু AI লিখছে...'
                                              : 'Jonobondhu AI is typing...',
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

                          final msg = _sharedMessages[index];

                          // ইউজার মেসেজ: ডানে, সবুজ ব্যাকগ্রাউন্ড
                          if (msg.isUser) {
                            return Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.78,
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryGreen,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(18),
                                    topRight: Radius.circular(18),
                                    bottomLeft: Radius.circular(18),
                                    bottomRight: Radius.circular(4),
                                  ),
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

                          // AI মেসেজ: বামে, গোল লোগো অ্যাভাটারসহ
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  margin:
                                      const EdgeInsets.only(right: 8, top: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: AppColors.border, width: 1),
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
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                              0.76,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: AppColors.bgMuted,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(4),
                                        topRight: Radius.circular(18),
                                        bottomLeft: Radius.circular(18),
                                        bottomRight: Radius.circular(18),
                                      ),
                                      border:
                                          Border.all(color: AppColors.border),
                                    ),
                                    child: buildAiMessageContent(
                                      context,
                                      msg.text,
                                      msg.time,
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: Row(
                        children: quickPrompts.map((prompt) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: InkWell(
                              onTap: () {
                                _sendMessage(prompt);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: AppColors.bgPage,
                                  borderRadius: BorderRadius.circular(20),
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

                    // ইনপুট বক্স (ChatGPT স্টাইল: গোল বাটন, কোনো চারকোনা বাটন নেই, এবং (+) ড্রপডাউন বাটন)
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
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // (+) ড্রপডাউন বাটন (ChatGPT-র মতো ফাইল ও ছবি আপলোড অপশন)
                            PopupMenuButton<String>(
                              tooltip: isBn ? 'ফাইল ও ছবি আপলোড' : 'Attach file or image',
                              offset: const Offset(0, -180),
                              color: Colors.white,
                              elevation: 6,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: AppColors.border),
                              ),
                              onSelected: (val) => _handleAttachmentOption(val, modalContext),
                              itemBuilder: (ctx) => [
                                PopupMenuItem(
                                  value: 'camera',
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
                                        child: const Icon(
                                          Icons.camera_alt_rounded,
                                          color: AppColors.primaryGreen,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isBn ? 'ক্যামেরা (ছবি তুলুন)' : 'Take Photo (Camera)',
                                            style: GoogleFonts.notoSansBengali(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            isBn ? 'AI দিয়ে তাৎক্ষণিক স্ক্যান ও যাচাই' : 'Instant AI document scan',
                                            style: GoogleFonts.notoSansBengali(
                                              fontSize: 10.5,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuDivider(height: 1),
                                PopupMenuItem(
                                  value: 'gallery',
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
                                        child: const Icon(
                                          Icons.photo_library_rounded,
                                          color: AppColors.primaryGreen,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isBn ? 'ছবি আপলোড (গ্যালারি)' : 'Upload Photo (Gallery)',
                                            style: GoogleFonts.notoSansBengali(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            isBn ? 'NID, পাসপোর্ট বা ডিজিটাল সনদ' : 'NID, Passport or Certificate',
                                            style: GoogleFonts.notoSansBengali(
                                              fontSize: 10.5,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuDivider(height: 1),
                                PopupMenuItem(
                                  value: 'file',
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
                                        child: const Icon(
                                          Icons.attach_file_rounded,
                                          color: AppColors.primaryGreen,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isBn ? 'ফাইল / পিডিএফ আপলোড' : 'Upload File / PDF',
                                            style: GoogleFonts.notoSansBengali(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            isBn ? 'অন্যান্য দলিল ও ডকুমেন্ট' : 'Other official documents',
                                            style: GoogleFonts.notoSansBengali(
                                              fontSize: 10.5,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.bgMuted,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  size: 22,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            // টেক্সট ইনপুট ক্যাপসুল (ChatGPT-র মতো গোল বর্ডার)
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.bgMuted,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: _isListening
                                        ? Colors.red
                                        : AppColors.border,
                                    width: 1,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 14),
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
                                                  ? 'বার্তা লিখুন...'
                                                  : 'Message Jonobondhu AI...'),
                                          hintStyle: GoogleFonts.notoSansBengali(
                                            fontSize: 13,
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

                                    // 🎤 গোল ভয়েস বাটন
                                    InkWell(
                                      onTap: _toggleVoiceInput,
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _isListening
                                              ? Colors.red
                                              : Colors.transparent,
                                        ),
                                        child: Icon(
                                          _isListening
                                              ? Icons.stop_rounded
                                              : Icons.mic_rounded,
                                          size: 19,
                                          color: _isListening
                                              ? Colors.white
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            // গোল সেন্ড বাটন (ChatGPT-র মতো গোল সবুজ সার্কেলে সাদা তীর)
                            InkWell(
                              onTap: () => _sendMessage(),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primaryGreen,
                                ),
                                child: const Icon(
                                  Icons.arrow_upward_rounded,
                                  size: 20,
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
        );
      },
    ).whenComplete(() {
      _modalSetState = null;
      _speech.stop();
      _isListening = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final langProvider = Provider.of<LanguageProvider>(context);
    final isBn = langProvider.isBn;

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

        // ভাসমান, সরানোযোগ্য জনবন্ধু AI বাবলে
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
              // ছেড়ে দিলে নিকটতম পাশে (বাম/ডান) স্ন্যাপ করবে
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
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border:
                          Border.all(color: AppColors.primaryGreen, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(8),
                    child: SvgPicture.asset(
                      'assets/icons/jonobondhu.svg',
                      fit: BoxFit.contain,
                    ),
                  ),

                  // সক্রিয় AI ইন্ডিকেটর ডট
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

                  // টুলটিপ ব্যাজ
                  Positioned(
                    bottom: -6,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1.5),
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