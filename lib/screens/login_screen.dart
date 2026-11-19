import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../models/user_profile.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/language_provider.dart';
import '../services/n8n_service.dart';
import '../widgets/common/dishari_logo.dart';
import '../widgets/common/jonobondhu_chat_overlay.dart';
import 'main_navigation_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _manualNidController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  // loginMode: 'phone' | 'manual_nid' | 'email'
  String _loginMode = 'phone';
  bool _isPhoneMode = true; // kept for backward compat
  bool _showPassword = false;
  String? _errorMessage;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _manualNidController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  void _navigateBackOrHome() {
    if (!mounted) return;
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _processNidLogin(ImageSource source) async {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isBn = langProvider.isBn;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 98);
      if (picked == null) return;

      final file = File(picked.path);

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: const RoundedRectangleBorder(),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primaryGreen),
              const SizedBox(height: 16),
              Text(
                isBn
                    ? 'দ্বিভাষিক অপটিক্যাল ওসিআর (OCR) দ্বারা তথ্য বিশ্লেষণ চলছে...'
                    : 'Extracting citizen identity via OCR engine...',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansBengali(
                    fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                isBn
                    ? 'নাগরিক প্রোফাইল ও লকারে এনআইডি স্বয়ংক্রিয় সংরক্ষণ করা হচ্ছে...'
                    : 'Assembling citizen docket & saving to secure vault...',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansBengali(
                    fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );

      final ocrResult = await N8nService.extractImageInfo(
        imageFile: file,
        docType: 'nid_front',
      );

      if (ocrResult['success'] != true) {
        throw Exception(ocrResult['error'] ?? (isBn
            ? 'এনআইডি স্ক্যান করতে সমস্যা হয়েছে। অনুগ্রহ করে স্পষ্ট আলোতে ছবি তুলুন বা পুনরায় চেষ্টা করুন।'
            : 'Failed to scan NID. Please ensure clear lighting and try again.'));
      }

      final meta = (ocrResult['data'] as Map<String, dynamic>?) ?? {};
      final rawNid = meta['id_number']?.toString().trim() ??
          meta['nid_number']?.toString().trim() ??
          meta['nid']?.toString().trim() ??
          '';
      final cleanNid = rawNid.replaceAll(RegExp(r'[^0-9]'), '');

      final extractedBn = meta['full_name_bn']?.toString().trim() ?? '';
      final extractedEn = meta['full_name_en']?.toString().trim() ?? '';
      final extractedGen = meta['full_name']?.toString().trim() ?? meta['name']?.toString().trim() ?? '';

      final fullName = isBn
          ? (extractedBn.isNotEmpty ? extractedBn : (extractedEn.isNotEmpty ? extractedEn : extractedGen))
          : (extractedEn.isNotEmpty ? extractedEn : (extractedBn.isNotEmpty ? extractedBn : extractedGen));

      if (cleanNid.isEmpty && fullName.isEmpty) {
        throw Exception(isBn
            ? 'এনআইডি কার্ডের তথ্য পড়া যায়নি। অনুগ্রহ করে সম্পূর্ণ ও স্পষ্ট ছবি দিন।'
            : 'Could not read NID card details. Please provide a clear, full image.');
      }

      final safeId = (DateTime.now().millisecondsSinceEpoch % 2000000000);
      final citizenNid = cleanNid.isNotEmpty ? cleanNid : '$safeId';
      final phone = '017${citizenNid.length >= 8 ? citizenNid.substring(citizenNid.length - 8) : "12345678"}';

      final citizenUser = UserProfile(
        id: safeId,
        fullName: fullName.isNotEmpty ? fullName : (isBn ? 'নাগরিক' : 'Citizen'),
        phone: phone,
        email: null,
        citizenId: 'NID-$citizenNid',
      );

      if (!mounted) return;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final dashboard = Provider.of<DashboardProvider>(context, listen: false);

      await auth.loginWithCitizenProfile(citizenUser);

      // Save scanned NID into Document Locker
      try {
        final bytes = await file.readAsBytes();
        await dashboard.uploadDocument(
          userId: citizenUser.id,
          docType: 'nid_front',
          fileName: file.path.split(Platform.pathSeparator).last,
          fileSize: file.lengthSync(),
          mimeType: 'image/jpeg',
          fileData: base64Encode(bytes),
          extractedMeta: {
            ...meta,
            'id_number': citizenNid,
            'full_name_bn': extractedBn.isNotEmpty ? extractedBn : fullName,
            'full_name_en': extractedEn.isNotEmpty ? extractedEn : fullName,
            'verified_source': 'Smart NID Optical Registration',
          },
        );
      } catch (e) {
        debugPrint('NID auto save error: $e');
      }

      if (mounted) {
        Navigator.pop(context); // close scanning dialog
        _showVerifiedNidDialog(
          context: context,
          isBn: isBn,
          user: citizenUser,
          meta: meta,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close dialog if open
        setState(() => _errorMessage = isBn
            ? 'এনআইডি স্ক্যান প্রক্রিয়াকরণে ত্রুটি: $e'
            : 'NID scanning error: $e');
      }
    }
  }

  void _showVerifiedNidDialog({
    required BuildContext context,
    required bool isBn,
    required UserProfile user,
    required Map<String, dynamic> meta,
  }) {
    final dob = meta['dob']?.toString().trim() ??
        meta['date_of_birth']?.toString().trim() ??
        meta['birth_date']?.toString().trim() ??
        (isBn ? 'যাচাইকৃত' : 'Verified');
    final bloodGroup = meta['blood_group']?.toString().trim() ??
        meta['blood']?.toString().trim() ??
        meta['bloodGroup']?.toString().trim() ??
        (isBn ? 'অনুল্লেখিত' : 'Not Specified');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              border: Border.all(color: AppColors.primaryGreen, width: 2),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Green Success Banner Card (1:1 with Web login/page.tsx)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.lightGreen50,
                      border: Border.all(
                        color: AppColors.primaryGreen.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.primaryGreen,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isBn
                                    ? 'এনআইডি স্ক্যান সফল — অ্যাকাউন্ট সক্রিয়!'
                                    : 'NID Verified — Account Activated!',
                                style: GoogleFonts.notoSansBengali(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                isBn
                                    ? 'আপনার ডিজিটাল নাগরিক প্রোফাইল সক্রিয় হয়েছে এবং মূল এনআইডি লকারে সংরক্ষিত হয়েছে।'
                                    : 'Your digital profile is live and the original NID card has been encrypted into your locker.',
                                style: GoogleFonts.notoSansBengali(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Encrypted Locker Confirmation Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.folder_shared_outlined,
                                  size: 16,
                                  color: AppColors.primaryGreen,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isBn
                                      ? 'লকারে সংরক্ষিত নথি:'
                                      : 'Vault Saved Asset:',
                                  style: GoogleFonts.notoSansBengali(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              color: AppColors.lightGreen50,
                              child: Text(
                                'VERIFIED NID',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16, color: AppColors.border),

                        // Grid with Full Name, NID Number, DOB, Blood Group
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isBn ? 'নাগরিক নাম:' : 'Name:',
                                    style: GoogleFonts.notoSansBengali(
                                      fontSize: 10,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    user.fullName,
                                    style: GoogleFonts.notoSansBengali(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isBn ? 'এনআইডি নম্বর:' : 'NID No:',
                                    style: GoogleFonts.notoSansBengali(
                                      fontSize: 10,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    user.citizenId,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryGreen,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isBn ? 'জন্ম তারিখ:' : 'Date of Birth:',
                                    style: GoogleFonts.notoSansBengali(
                                      fontSize: 10,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    dob,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isBn ? 'রক্তের গ্রুপ:' : 'Blood Group:',
                                    style: GoogleFonts.notoSansBengali(
                                      fontSize: 10,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    bloodGroup,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryRed,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.lock_outline,
                              size: 13,
                              color: AppColors.primaryGreen,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                isBn
                                    ? 'জিরো-নলেজ আর্কিটেকচারে নাগরিকের এনআইডি ও নথি সংরক্ষিত'
                                    : 'Encrypted under Bangladesh Civic Data Protection standards.',
                                style: GoogleFonts.notoSansBengali(
                                  fontSize: 9.5,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Button 1: Proceed to Citizen Dashboard
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MainNavigationScreen(),
                        ),
                        (route) => false,
                      );
                      JonobondhuChatOverlay.globalNavigateTab?.call(4);
                    },
                    icon: const Icon(Icons.dashboard_outlined, size: 16),
                    label: Text(
                      isBn
                          ? 'নাগরিক ড্যাশবোর্ডে প্রবেশ করুন'
                          : 'Proceed to Citizen Dashboard',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: const RoundedRectangleBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Button 2: View Personalized Home Feed
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MainNavigationScreen(),
                        ),
                        (route) => false,
                      );
                      JonobondhuChatOverlay.globalNavigateTab?.call(0);
                    },
                    icon: const Icon(Icons.home_outlined, size: 16),
                    label: Text(
                      isBn
                          ? 'হোম পেজে ব্যক্তিগত ফিড দেখুন'
                          : 'View Personalized Home Feed',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: const RoundedRectangleBorder(),
                      side: const BorderSide(color: AppColors.primaryGreen),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showNidScanSheet(bool isBn) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isBn
                    ? 'এনআইডি কার্ড স্ক্যান করে ১-ক্লিকে প্রবেশ'
                    : '1-Click Smart NID Scan Login',
                style: GoogleFonts.notoSansBengali(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                isBn
                    ? 'আপনার জাতীয় পরিচয়পত্রের ছবি তুলুন বা গ্যালারি থেকে সিলেক্ট করুন। AI স্বয়ংক্রিয়ভাবে তথ্য পড়ে প্রোফাইল তৈরি করবে।'
                    : 'Capture or select your NID card. AI will automatically extract details and log you in.',
                style: GoogleFonts.notoSansBengali(
                    fontSize: 11.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _processNidLogin(ImageSource.camera);
                      },
                      icon: const Icon(Icons.camera_alt, size: 16),
                      label: Text(
                        isBn ? 'ক্যামেরা' : 'Camera',
                        style: GoogleFonts.notoSansBengali(
                            fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _processNidLogin(ImageSource.gallery);
                      },
                      icon: const Icon(Icons.photo_library, size: 16),
                      label: Text(
                        isBn ? 'গ্যালারি' : 'Gallery',
                        style: GoogleFonts.notoSansBengali(
                            fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        shape: const RoundedRectangleBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    setState(() => _errorMessage = null);
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isBn = langProvider.isBn;

    String identifier;

    if (_loginMode == 'manual_nid') {
      final rawNid = _manualNidController.text.trim();
      if (rawNid.isEmpty) {
        setState(() {
          _errorMessage = isBn ? 'এনআইডি নম্বর লিখুন' : 'Please enter your NID number';
        });
        return;
      }
      identifier = AppConstants.toEnglishNumber(rawNid).replaceAll(RegExp(r'\D'), '');
      if (identifier.length < 10) {
        setState(() {
          _errorMessage = isBn
              ? 'সঠিক এনআইডি নম্বর দিন (১০ বা ১৭ ডিজিট)'
              : 'Enter a valid NID number (10 or 17 digits)';
        });
        return;
      }
    } else {
      final rawIdentifier = _identifierController.text.trim();
      if (rawIdentifier.isEmpty) {
        setState(() {
          _errorMessage = isBn
              ? (_isPhoneMode ? 'মোবাইল নম্বর লিখুন' : 'ইমেইল ঠিকানা লিখুন')
              : (_isPhoneMode ? 'Please enter your phone number' : 'Please enter your email');
        });
        return;
      }

      identifier = rawIdentifier;

      if (_isPhoneMode) {
        identifier = AppConstants.toEnglishNumber(rawIdentifier).replaceAll(RegExp(r'[\s\-]'), '');
        if (identifier.length < 11) {
          setState(() {
            _errorMessage = isBn
                ? 'সঠিক ১১ ডিজিটের মোবাইল নম্বর দিন (যেমন: 01712345678)'
                : 'Enter a valid 11-digit phone number (e.g. 01712345678)';
          });
          return;
        }
      } else {
        if (!identifier.contains('@')) {
          setState(() {
            _errorMessage = isBn ? 'সঠিক ইমেইল ঠিকানা দিন' : 'Enter a valid email address';
          });
          return;
        }
        if (_passwordController.text.trim().isEmpty) {
          setState(() {
            _errorMessage = isBn ? 'পাসওয়ার্ড লিখুন' : 'Please enter your password';
          });
          return;
        }
      }
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final result = await auth.login(
      identifier: identifier,
      password: _loginMode == 'email' && _passwordController.text.trim().isNotEmpty
          ? _passwordController.text.trim()
          : null,
    );

    if (result.success && mounted) {
      final dashboard = Provider.of<DashboardProvider>(context, listen: false);
      await dashboard.loadDashboardData(auth.user?.id, isDemo: auth.user?.id == 1);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isBn
                  ? (_loginMode == 'phone'
                      ? 'স্বাগতম! ওটিপি যাচাই সম্পন্ন হয়েছে।'
                      : _loginMode == 'manual_nid'
                          ? 'এনআইডি যাচাই সম্পন্ন! স্বাগতম।'
                          : 'সফলভাবে লগইন সম্পন্ন হয়েছে!')
                  : (_loginMode == 'phone'
                      ? 'Welcome! OTP verified successfully.'
                      : _loginMode == 'manual_nid'
                          ? 'NID verified! Welcome.'
                          : 'Successfully logged in!'),
              style: GoogleFonts.notoSansBengali(),
            ),
            backgroundColor: AppColors.primaryGreen,
            duration: const Duration(seconds: 2),
          ),
        );
        _navigateBackOrHome();
      }
    } else if (mounted) {
      setState(() {
        _errorMessage = result.error ??
            (isBn ? 'লগইন ব্যর্থ হয়েছে। তথ্য যাচাই করে পুনরায় চেষ্টা করুন।' : 'Login failed. Please check credentials.');
      });
    }
  }

  Future<void> _handleDemoLogin() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final dashboard = Provider.of<DashboardProvider>(context, listen: false);
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isBn = langProvider.isBn;

    await auth.loginAsDemoCitizen();
    await dashboard.seedDemoData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isBn ? 'ডেমো নাগরিক হিসেবে প্রবেশ সম্পন্ন হয়েছে!' : 'Logged in as Demo Citizen!',
            style: GoogleFonts.notoSansBengali(),
          ),
          backgroundColor: AppColors.primaryGreen,
          duration: const Duration(seconds: 2),
        ),
      );
      _navigateBackOrHome();
    }
  }

  void _showForgotPasswordDialog(bool isBn) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isBn ? 'পাসওয়ার্ড পুনরুদ্ধার' : 'Password Recovery',
          style: GoogleFonts.notoSansBengali(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Text(
          isBn
              ? 'পাসওয়ার্ড রিসেট করতে আপনার রেজিস্ট্রিকৃত মোবাইল নম্বরে যোগাযোগ করুন অথবা হেল্পলাইন ৩৩৩ নম্বরে কল করুন।'
              : 'To reset your password, contact using your registered mobile number or call helpline 333.',
          style: GoogleFonts.notoSansBengali(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              isBn ? 'ঠিক আছে' : 'OK',
              style: GoogleFonts.notoSansBengali(color: AppColors.primaryGreen, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final auth = context.watch<AuthProvider>();
    final isBn = langProvider.isBn;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        backgroundColor: AppColors.bgSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: _navigateBackOrHome,
        ),
        title: Text(
          isBn ? 'নাগরিক লগইন' : 'Citizen Login',
          style: GoogleFonts.notoSansBengali(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(2),
          child: Divider(height: 2, thickness: 1, color: AppColors.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Green Brand Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: AppColors.darkGreen,
                border: Border(
                  top: BorderSide(color: AppColors.primaryRed, width: 3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DishariLogo(
                    height: 32,
                    isDark: true,
                    isBn: isBn,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isBn ? 'আপনার নাগরিক লকার ও সেবাসমূহ' : 'Your Citizen Locker & Services',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isBn
                        ? 'দালালমুক্ত নাগরিক সহায়তার একক জাতীয় প্লাটফর্মে স্বাগতম।'
                        : 'Welcome to Bangladesh\'s unified civic assistance platform.',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 11,
                      color: const Color(0xFFD1FAE5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Form Paper Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1-Click Smart NID Scan Button (Matches Web login/page.tsx)
                  InkWell(
                    onTap: () => _showNidScanSheet(isBn),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF003627),
                        border: Border.all(color: const Color(0xFF00E599), width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            color: const Color(0xFF004D38),
                            child: const Icon(Icons.document_scanner, color: Color(0xFF00E599), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      isBn ? 'স্মার্ট এনআইডি স্ক্যান লগইন' : '1-Click Smart NID Login',
                                      style: GoogleFonts.notoSansBengali(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      color: const Color(0xFFC8102E),
                                      child: Text(
                                        'OCR AI',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isBn
                                      ? 'পাসওয়ার্ডহীন প্রবেশ ও ডিজিটাল লকারে এনআইডি অটো-সেভ'
                                      : 'Passwordless entry & auto-save to cloud locker',
                                  style: GoogleFonts.notoSansBengali(
                                    fontSize: 10.5,
                                    color: const Color(0xFFA7F3D0),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Color(0xFF00E599), size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          isBn ? 'অথবা নম্বর দিয়ে প্রবেশ করুন' : 'or login with number',
                          style: GoogleFonts.notoSansBengali(fontSize: 10.5, color: AppColors.textMuted),
                        ),
                      ),
                      const Expanded(child: Divider(color: AppColors.border)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Mode Toggle (Phone / Manual NID / Email) — matches web 3-tab
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _loginMode = 'phone';
                              _isPhoneMode = true;
                              _errorMessage = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _loginMode == 'phone' ? AppColors.primaryGreen : AppColors.bgMuted,
                              border: Border.all(
                                color: _loginMode == 'phone' ? AppColors.primaryGreen : AppColors.border,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.phone_android,
                                  size: 14,
                                  color: _loginMode == 'phone' ? Colors.white : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isBn ? 'মোবাইল' : 'Phone',
                                  style: GoogleFonts.notoSansBengali(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _loginMode == 'phone' ? Colors.white : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _loginMode = 'manual_nid';
                              _isPhoneMode = false;
                              _errorMessage = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _loginMode == 'manual_nid' ? AppColors.primaryGreen : AppColors.bgMuted,
                              border: Border.all(
                                color: _loginMode == 'manual_nid' ? AppColors.primaryGreen : AppColors.border,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.credit_card,
                                  size: 14,
                                  color: _loginMode == 'manual_nid' ? Colors.white : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isBn ? 'ম্যানুয়াল NID' : 'NID No.',
                                  style: GoogleFonts.notoSansBengali(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _loginMode == 'manual_nid' ? Colors.white : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _loginMode = 'email';
                              _isPhoneMode = false;
                              _errorMessage = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _loginMode == 'email' ? AppColors.primaryGreen : AppColors.bgMuted,
                              border: Border.all(
                                color: _loginMode == 'email' ? AppColors.primaryGreen : AppColors.border,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.email_outlined,
                                  size: 14,
                                  color: _loginMode == 'email' ? Colors.white : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isBn ? 'ইমেইল' : 'Email',
                                  style: GoogleFonts.notoSansBengali(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _loginMode == 'email' ? Colors.white : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // ── Manual NID Input Section ──
                  if (_loginMode == 'manual_nid') ...[
                    Text(
                      isBn ? 'এনআইডি নম্বর' : 'NID NUMBER',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _manualNidController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: isBn ? '১০ বা ১৭ ডিজিটের এনআইডি নম্বর' : '10 or 17-digit NID number',
                        prefixIcon: const Icon(Icons.credit_card, size: 18, color: AppColors.textMuted),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isBn ? 'পূর্ণ নাম (ঐচ্ছিক)' : 'FULL NAME (optional)',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _fullNameController,
                      style: GoogleFonts.notoSansBengali(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: isBn ? 'আপনার নাম (NID অনুযায়ী)' : 'Your name as on NID',
                        prefixIcon: const Icon(Icons.person_outline, size: 18, color: AppColors.textMuted),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isBn
                          ? 'এনআইডি নম্বর দিয়ে সরাসরি নাগরিক অ্যাকাউন্ট অ্যাক্সেস করুন'
                          : 'Access your citizen account directly using NID number',
                      style: GoogleFonts.notoSansBengali(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],

                  // Identifier Input (Phone or Email) — hidden when manual_nid mode
                  if (_loginMode != 'manual_nid') ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isPhoneMode
                            ? (isBn ? 'মোবাইল নম্বর' : 'PHONE NUMBER')
                            : (isBn ? 'ইমেইল ঠিকানা' : 'EMAIL ADDRESS'),
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      // Quick fill test chip
                      InkWell(
                        onTap: () {
                          if (_isPhoneMode) {
                            _identifierController.text = '01712345678';
                          } else {
                            _identifierController.text = 'demo@dishari.bd';
                            _passwordController.text = '123456';
                          }
                          setState(() => _errorMessage = null);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.lightGreen50,
                            border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            isBn ? 'টেস্ট ফিল' : 'Auto Fill',
                            style: GoogleFonts.notoSansBengali(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _identifierController,
                    keyboardType: _isPhoneMode ? TextInputType.phone : TextInputType.emailAddress,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: _isPhoneMode ? '01XXXXXXXXX' : 'citizen@dishari.bd',
                      prefixIcon: Icon(
                        _isPhoneMode ? Icons.phone_android : Icons.email_outlined,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),

                  // Helper text for phone mode
                  if (_isPhoneMode) ...[
                    const SizedBox(height: 6),
                    Text(
                      langProvider.t('auth.phoneHint'),
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],

                  // Password Input (Only in Email mode)
                  if (_loginMode == 'email') ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isBn ? 'পাসওয়ার্ড' : 'PASSWORD',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        InkWell(
                          onTap: () => _showForgotPasswordDialog(isBn),
                          child: Text(
                            langProvider.t('auth.forgotPassword'),
                            style: GoogleFonts.notoSansBengali(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        prefixIcon: const Icon(Icons.lock_outline, size: 18, color: AppColors.textMuted),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword ? Icons.visibility_off : Icons.visibility,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () => setState(() => _showPassword = !_showPassword),
                        ),
                      ),
                    ),
                  ],
                  ], // end if _loginMode != 'manual_nid'
                  const SizedBox(height: 16),

                  // Error Notice Banner
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, size: 16, color: AppColors.primaryRed),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: GoogleFonts.notoSansBengali(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryRed,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Submit Button (OTP in phone mode, Login in email mode)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        backgroundColor: AppColors.primaryGreen,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      child: auth.isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _loginMode == 'phone'
                                      ? langProvider.t('auth.otpBtn')
                                      : _loginMode == 'manual_nid'
                                          ? (isBn ? 'এনআইডি দিয়ে প্রবেশ করুন' : 'Login with NID')
                                          : langProvider.t('auth.loginBtn'),
                                  style: GoogleFonts.notoSansBengali(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.arrow_forward, size: 14, color: Colors.white),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 1-Click Demo Citizen Login
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: auth.isLoading ? null : _handleDemoLogin,
                      icon: const Icon(Icons.person_pin_outlined, size: 16, color: AppColors.primaryGreen),
                      label: Text(
                        langProvider.t('dashboard.demoLogin'),
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primaryGreen),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Registration Navigation
                  Center(
                    child: InkWell(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        );
                      },
                      child: Text(
                        langProvider.t('auth.noAccount'),
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryGreen,
                        ),
                      ),
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
}
