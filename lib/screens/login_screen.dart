import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/language_provider.dart';
import '../widgets/common/dishari_logo.dart';
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
  bool _isPhoneMode = true;
  bool _showPassword = false;
  String? _errorMessage;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
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

  Future<void> _handleLogin() async {
    setState(() => _errorMessage = null);
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isBn = langProvider.isBn;

    final rawIdentifier = _identifierController.text.trim();
    if (rawIdentifier.isEmpty) {
      setState(() {
        _errorMessage = isBn
            ? (_isPhoneMode ? 'মোবাইল নম্বর লিখুন' : 'ইমেইল ঠিকানা লিখুন')
            : (_isPhoneMode ? 'Please enter your phone number' : 'Please enter your email');
      });
      return;
    }

    String identifier = rawIdentifier;

    if (_isPhoneMode) {
      // Clean phone number and convert any Bengali digits to English
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

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final result = await auth.login(
      identifier: identifier,
      password: !_isPhoneMode && _passwordController.text.trim().isNotEmpty
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
                  ? (_isPhoneMode
                      ? 'স্বাগতম! ওটিপি যাচাই সম্পন্ন হয়েছে।'
                      : 'সফলভাবে লগইন সম্পন্ন হয়েছে!')
                  : (_isPhoneMode
                      ? 'Welcome! OTP verified successfully.'
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
                  // Mode Toggle (Phone vs Email)
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _isPhoneMode = true;
                              _errorMessage = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _isPhoneMode ? AppColors.primaryGreen : AppColors.bgMuted,
                              border: Border.all(
                                color: _isPhoneMode ? AppColors.primaryGreen : AppColors.border,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.phone_android,
                                  size: 14,
                                  color: _isPhoneMode ? Colors.white : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isBn ? 'মোবাইল নম্বর' : 'Phone Number',
                                  style: GoogleFonts.notoSansBengali(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _isPhoneMode ? Colors.white : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _isPhoneMode = false;
                              _errorMessage = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: !_isPhoneMode ? AppColors.primaryGreen : AppColors.bgMuted,
                              border: Border.all(
                                color: !_isPhoneMode ? AppColors.primaryGreen : AppColors.border,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.email_outlined,
                                  size: 14,
                                  color: !_isPhoneMode ? Colors.white : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isBn ? 'ইমেইল ঠিকানা' : 'Email Address',
                                  style: GoogleFonts.notoSansBengali(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: !_isPhoneMode ? Colors.white : AppColors.textPrimary,
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

                  // Identifier Input (Phone or Email)
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
                  if (!_isPhoneMode) ...[
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
                                  _isPhoneMode
                                      ? langProvider.t('auth.otpBtn')
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
