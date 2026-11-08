import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../providers/language_provider.dart';

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final size = MediaQuery.of(context).size;
      // Position bottom-right by default
      _x = size.width - 70;
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

  void _sendMessage([String? customText]) {
    final text = (customText ?? _inputController.text).trim();
    if (text.isEmpty) return;

    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isBn = langProvider.isBn;

    setState(() {
      _messages.add(
        ChatMessage(
          id: 'user-${DateTime.now().millisecondsSinceEpoch}',
          isUser: true,
          text: text,
          time: _currentTimeString(isBn),
        ),
      );
      _inputController.clear();
    });

    _scrollToBottom();

    // Generate response matching web simulation
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;

      String reply = '';
      final lower = text.toLowerCase();

      if (text.contains('পাসপোর্ট') || lower.contains('passport')) {
        reply = isBn
            ? 'পাসপোর্ট আবেদনের জন্য আপনার অনলাইন ভেরিফায়েড জন্ম নিবন্ধন বা এনআইডি (NID), পূর্বের পাসপোর্ট (যদি থাকে) এবং নাগরিক সনদ প্রয়োজন। সাধারণ ফি ৪,০২৫ টাকা এবং ২১ কার্যদিবসের মধ্যে ডেলিভারি হয়।'
            : 'For passport applications, you need your online verified birth certificate or NID, old passport (if renewing), and citizen certificate. Standard fee is 4,025 BDT with 21 business days delivery.';
      } else if (text.contains('জন্ম নিবন্ধন') || lower.contains('birth')) {
        reply = isBn
            ? 'অনলাইন জন্ম নিবন্ধনের জন্য bdris.gov.bd পোর্টালে ১৭ ডিজিটের জন্ম নিবন্ধন নম্বর ও জন্মতারিখ প্রদান করে সরাসরি যাচাই বা সংশোধনের আবেদন করতে পারবেন।'
            : 'For online birth registration, submit your 17-digit certificate number and date of birth at bdris.gov.bd to verify or request amendments.';
      } else if (text.contains('NID') || text.contains('এনআইডি') || lower.contains('nid')) {
        reply = isBn
            ? 'এনআইডি সংশোধনের জন্য services.nidw.gov.bd পোর্টালে রক্তের গ্রুপ, শিক্ষাগত সনদ বা জন্ম নিবন্ধনের অনলাইন প্রমাণক জমা দিন। ক্যাটাগরিভেদে ফি ২৩০ থেকে ৩৪৫ টাকা।'
            : 'For NID corrections, upload educational certificates, blood test report, or birth certificate at services.nidw.gov.bd. Fees range from 230 to 345 BDT depending on type.';
      } else if (text.contains('ভাতা') || lower.contains('allowance')) {
        reply = isBn
            ? 'বিধবা, বয়স্ক ও প্রতিবন্ধী ভাতার জন্য সমাজসেবা অধিদপ্তর (dss.gov.bd) পোর্টালে অথবা ইউনিয়ন পরিষদে আবেদন করতে হয়। এটি সম্পূর্ণ বিনামূল্যে এবং টাকা সরাসরি নগদ মোবাইল ব্যাংকিংয়ে আসে।'
            : 'For widow, old-age, or disability allowances, apply at dss.gov.bd or your local Union Council. It is completely free and allowance funds are deposited directly to your Nagad wallet.';
      } else if (text.contains('ট্রেড লাইসেন্স') || lower.contains('trade')) {
        reply = isBn
            ? 'ই-ট্রেড লাইসেন্সের জন্য etradelicense.gov.bd পোর্টালে ব্যবসার ধরন ও ভাড়ার চুক্তিপত্র জমা দিতে হয়। ফি ব্যবসার ধরনভেদে ১,২০০ টাকা থেকে শুরু।'
            : 'For an e-Trade License, apply at etradelicense.gov.bd with business type and commercial rent deed. Government fees start from 1,200 BDT based on capital.';
      } else if (text.contains('নামজারি') || text.contains('জমি') || lower.contains('land')) {
        reply = isBn
            ? 'ই-নামজারির জন্য mutation.land.gov.bd পোর্টালে ক্রয় দলিল, খতিয়ান ও হালনাগাদ দাখিলা জমা দিতে হবে। সরকারি মোট ফি ১,১৭০ টাকা এবং সময়সীমা ২৮ কার্যদিবস।'
            : 'For e-Mutation, apply on mutation.land.gov.bd with registered deed, previous khatian, and up-to-date land tax receipt. Total official fee is 1,170 BDT and takes 28 working days.';
      } else {
        reply = isBn
            ? 'আপনার প্রশ্নের জন্য ধন্যবাদ। দিশারীর ডাটাবেজে ৫০টির বেশি সরকারি সেবার বিস্তারিত নিয়মাবলী ও কাগজপত্রের তালিকা রয়েছে। সেবাসমূহ ট্যাবে গিয়ে সরাসরি অনুসন্ধান করতে পারেন।'
            : 'Thank you for your question. Dishari features comprehensive step-by-step guides and documentation requirements for 50+ government services. Visit the Services directory to browse.';
      }

      setState(() {
        _messages.add(
          ChatMessage(
            id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
            isUser: false,
            text: reply,
            time: _currentTimeString(isBn),
          ),
        );
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
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
          ]
        : [
            'Documents required for passport?',
            'How to verify birth registration?',
            'Fee required for NID correction?',
            'Eligibility for old-age allowance?',
          ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.78,
              decoration: const BoxDecoration(
                color: AppColors.bgSurface,
                border: Border(
                  top: BorderSide(color: AppColors.primaryGreen, width: 3),
                ),
              ),
              child: Column(
                children: [
                  // Chat Title Bar
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
                            Container(
                              width: 32,
                              height: 32,
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.darkGreen,
                              ),
                              child: SvgPicture.asset('assets/icons/jonobondhu.svg'),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isBn ? 'জনবন্ধু AI (নাগরিক সহকারী)' : 'Jonobondhu AI (Assistant)',
                                  style: GoogleFonts.notoSansBengali(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: AppColors.accentGreen,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isBn ? 'সার্বক্ষণিক সক্রিয়' : 'Online & Ready',
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
                          icon: const Icon(Icons.close, color: AppColors.textPrimary, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),

                  // Messages List
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        return Align(
                          alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.78,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: msg.isUser ? AppColors.primaryGreen : AppColors.bgMuted,
                              border: Border.all(
                                color: msg.isUser ? AppColors.primaryGreen : AppColors.border,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg.text,
                                  style: GoogleFonts.notoSansBengali(
                                    fontSize: 13,
                                    color: msg.isUser ? Colors.white : AppColors.textPrimary,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  msg.time,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    color: msg.isUser ? Colors.white70 : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
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
                              setModalState(() {});
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
                    padding: EdgeInsets.only(
                      left: 12,
                      right: 12,
                      top: 8,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.bgSurface,
                      border: Border(
                        top: BorderSide(color: AppColors.border, width: 1),
                      ),
                    ),
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
                            ),
                            onSubmitted: (_) {
                              _sendMessage();
                              setModalState(() {});
                            },
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
                          onPressed: () {
                            _sendMessage();
                            setModalState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        widget.child,

        // Floating Movable Jonobondhu AI Bubble
        Positioned(
          left: _x,
          top: _y,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _x = (_x + details.delta.dx).clamp(8.0, size.width - 66.0);
                _y = (_y + details.delta.dy).clamp(60.0, size.height - 130.0);
              });
            },
            onPanEnd: (details) {
              // Snap to nearest side (left or right)
              setState(() {
                if (_x + 28 < size.width / 2) {
                  _x = 12;
                } else {
                  _x = size.width - 66;
                }
              });
            },
            onTap: _openChatDialog,
            child: Material(
              elevation: 4,
              color: Colors.transparent,
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.darkGreen,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(7),
                child: SvgPicture.asset(
                  'assets/icons/jonobondhu.svg',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
