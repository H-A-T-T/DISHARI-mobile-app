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
import 'main_navigation_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _showPassword = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
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

  Future<void> _processNidRegister(ImageSource source) async {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isBn = langProvider.isBn;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 90);
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
                    ? 'দ্বিভাষিক অপটিক্যাল ওসিআর (OCR) দ্বারা নাম ও এনআইডি তথ্য বিশ্লেষণ চলছে...'
                    : 'Extracting citizen identity via OCR engine...',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansBengali(
                    fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                isBn
                    ? 'নাগরিক প্রোফাইল ও লকারে এনআইডি স্বয়ংক্রিয় সংরক্ষণ করা হচ্ছে...'
                    : 'Provisioning citizen account & syncing to secure locker...',
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

      final meta = (ocrResult['data'] as Map<String, dynamic>?) ?? {};
      final nidNumber = meta['id_number']
              ?.toString()
              .replaceAll(RegExp(r'[^0-9]'), '') ??
          '${DateTime.now().millisecondsSinceEpoch}';
      final cleanNid = nidNumber.isNotEmpty
          ? nidNumber
          : '${DateTime.now().millisecondsSinceEpoch}';
      final fullName = meta['full_name_bn']?.toString() ??
          meta['full_name_en']?.toString() ??
          (isBn ? 'নাগরিক' : 'Citizen');
      final phone =
          '017${cleanNid.length >= 8 ? cleanNid.substring(cleanNid.length - 8) : "12345678"}';

      final citizenUser = UserProfile(
        id: DateTime.now().millisecondsSinceEpoch,
        fullName: fullName,
        phone: phone,
        email: null,
        citizenId: 'NID-$cleanNid',
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
          extractedMeta: meta,
        );
      } catch (e) {
        debugPrint('NID auto save error: $e');
      }

      if (mounted) {
        Navigator.pop(context); // close scanning dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isBn
                  ? 'এনআইডি নিবন্ধন সফল! স্বাগতম, $fullName'
                  : 'Account Created via NID! Welcome, $fullName',
              style: GoogleFonts.notoSansBengali(),
            ),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        _navigateBackOrHome();
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
                    ? 'এনআইডি কার্ড স্ক্যান করে ১-ক্লিকে নিবন্ধন'
                    : '1-Click Smart NID Registration',
                style: GoogleFonts.notoSansBengali(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                isBn
                    ? 'আপনার জাতীয় পরিচয়পত্রের ছবি তুলুন। কৃত্রিম বুদ্ধিমত্তা চালিত অপটিক্যাল ভিশন সরাসরি তথ্য পড়ে নাগরিক অ্যাকাউন্ট তৈরি করবে।'
                    : 'Capture or select your NID card. AI will automatically provision your citizen profile.',
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
                        _processNidRegister(ImageSource.camera);
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
                        _processNidRegister(ImageSource.gallery);
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

  Future<void> _handleRegister() async {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isBn = langProvider.isBn;

    final name = _nameController.text.trim();
    final rawPhone = _phoneController.text.trim().replaceAll(' ', '');
    final phone = AppConstants.toEnglishNumber(rawPhone).replaceAll(RegExp(r'[\s\-]'), '');
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (name.isEmpty || phone.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = isBn ? 'সকল প্রয়োজনীয় তথ্য পূরণ করুন' : 'Please fill all required fields');
      return;
    }

    if (phone.length < 11) {
      setState(() => _errorMessage = isBn ? 'সঠিক ১১ ডিজিটের মোবাইল নম্বর দিন' : 'Enter valid 11-digit phone number');
      return;
    }

    if (password.length < 6) {
      setState(() => _errorMessage = isBn ? 'পাসওয়ার্ড অন্তত ৬ অক্ষরের হতে হবে' : 'Password must be at least 6 characters');
      return;
    }

    if (password != confirm) {
      setState(() => _errorMessage = isBn ? 'উভয় পাসওয়ার্ড একই হতে হবে' : 'Passwords do not match');
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final result = await auth.register(
      fullName: name,
      phone: phone,
      email: email.isNotEmpty ? email : null,
      password: password,
    );

    if (result.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isBn ? 'অ্যাকাউন্ট সফলভাবে তৈরি হয়েছে!' : 'Account created successfully!',
            style: GoogleFonts.notoSansBengali(),
          ),
          backgroundColor: AppColors.primaryGreen,
          duration: const Duration(seconds: 2),
        ),
      );
      _navigateBackOrHome();
    } else if (mounted) {
      setState(() => _errorMessage = result.error ?? (isBn ? 'নিবন্ধন ব্যর্থ হয়েছে' : 'Registration failed'));
    }
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
          isBn ? 'নাগরিক নিবন্ধন' : 'Citizen Registration',
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
        padding: const EdgeInsets.all(20),
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
                    isBn ? 'নতুন নাগরিক অ্যাকাউন্ট তৈরি করুন' : 'Create Free Citizen Account',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isBn
                        ? 'আপনার নথিপত্র ডিজিটাল লকারে একবার সংরক্ষণ করে রাখুন।'
                        : 'Securely preserve your credentials in your citizen locker.',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 11,
                      color: const Color(0xFFD1FAE5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Form
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1-Click Smart NID Registration Button
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
                                      isBn ? 'স্মার্ট এনআইডি স্ক্যান নিবন্ধন' : '1-Click Smart NID Register',
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
                                      ? 'এনআইডি ছবি তুললেই প্রোফাইল ও লকার একযোগে সক্রিয় হবে'
                                      : 'Scan NID to auto-provision account & secure vault',
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
                          isBn ? 'অথবা তথ্য লিখে নিবন্ধন করুন' : 'or enter details manually',
                          style: GoogleFonts.notoSansBengali(fontSize: 10.5, color: AppColors.textMuted),
                        ),
                      ),
                      const Expanded(child: Divider(color: AppColors.border)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Full Name
                  Text(
                    langProvider.t('auth.fullName'),
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _nameController,
                    style: GoogleFonts.notoSansBengali(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'আহমেদ জামিল / Ahmed Jamil',
                      prefixIcon: Icon(Icons.person_outline, size: 18, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Phone Number
                  Text(
                    langProvider.t('auth.phone'),
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: '01XXXXXXXXX',
                      prefixIcon: Icon(Icons.phone_android, size: 18, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Email
                  Text(
                    langProvider.t('auth.email'),
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'citizen@dishari.bd (ঐচ্ছিক)',
                      prefixIcon: Icon(Icons.email_outlined, size: 18, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Password
                  Text(
                    langProvider.t('auth.password'),
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'কমপক্ষে ৬ অক্ষর',
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
                  const SizedBox(height: 12),

                  // Confirm Password
                  Text(
                    isBn ? 'পাসওয়ার্ড নিশ্চিত করুন' : 'Confirm Password',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _confirmController,
                    obscureText: !_showPassword,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: '••••••••',
                      prefixIcon: Icon(Icons.lock_reset, size: 18, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.notoSansBengali(fontSize: 11, color: AppColors.primaryRed),
                      ),
                    ),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                      child: auth.isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              langProvider.t('auth.registerBtn'),
                              style: GoogleFonts.notoSansBengali(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Login Link
                  Center(
                    child: InkWell(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: Text(
                        langProvider.t('auth.haveAccount'),
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

