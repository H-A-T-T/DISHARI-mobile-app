import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../screens/login_screen.dart';
import '../../screens/register_screen.dart';
import '../../screens/opportunities_screen.dart';
import '../../screens/about_screen.dart';
import 'dishari_logo.dart';

class ActionCenterDrawer extends StatelessWidget {
  final Function(int targetTab)? onNavigateTab;

  const ActionCenterDrawer({
    super.key,
    this.onNavigateTab,
  });

  Future<void> _makeCall(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isBn = langProvider.isBn;
    final user = authProvider.user;
    final isLoggedIn = authProvider.isLoggedIn;

    return Drawer(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      backgroundColor: Colors.white,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Top 3px Bangladesh Green Accent Strip (Windows 10 Flat)
            Container(
              height: 3,
              color: AppColors.primaryGreen,
            ),

            // Drawer Header with DishariLogo and Close button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFB),
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DishariLogo(height: 32, isBn: isBn),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.zero,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Navigation & Helplines List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // Citizen Greeting / Profile Banner (if logged in)
                  if (isLoggedIn && user != null) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.zero,
                        border: Border.all(color: AppColors.primaryGreen, width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.zero,
                            ),
                            child: const Icon(
                              Icons.verified_user,
                              color: AppColors.primaryGreen,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isBn ? 'স্বাগতম নাগরিক' : 'Welcome Citizen',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryGreen,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  user.fullName,
                                  style: GoogleFonts.notoSansBengali(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'ID: ${user.citizenId}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Navigation Links (Windows 10 Flat Paper List)
                  _buildNavItem(
                    icon: Icons.description_outlined,
                    iconColor: AppColors.primaryGreen,
                    title: isBn ? 'সেবা সমূহ' : 'All Services',
                    onTap: () {
                      Navigator.pop(context);
                      onNavigateTab?.call(1);
                    },
                  ),
                  _buildNavItem(
                    icon: Icons.auto_awesome_outlined,
                    iconColor: const Color(0xFF047857),
                    title: isBn ? 'সরকারি সুযোগ ও সহায়তা' : 'Government Opportunities',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OpportunitiesScreen(),
                        ),
                      );
                    },
                  ),
                  _buildNavItem(
                    icon: Icons.dashboard_outlined,
                    iconColor: const Color(0xFF1D4ED8),
                    title: isBn ? 'নাগরিক ড্যাশবোর্ড ও লকার' : 'Citizen Dashboard & Locker',
                    onTap: () {
                      Navigator.pop(context);
                      onNavigateTab?.call(4);
                    },
                  ),
                  _buildNavItem(
                    icon: Icons.help_outline,
                    iconColor: const Color(0xFFB45309),
                    title: isBn ? 'কীভাবে কাজ করে' : 'How It Works',
                    onTap: () {
                      Navigator.pop(context);
                      onNavigateTab?.call(0);
                    },
                  ),
                  _buildNavItem(
                    icon: Icons.info_outline,
                    iconColor: const Color(0xFF7E22CE),
                    title: isBn ? 'আমাদের সম্পর্কে' : 'About Dishari',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AboutScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 18),

                  // Emergency National Helpline Strip (৩৩৩, ৯৯৯, ১০৬)
                  Text(
                    isBn ? 'জরুরি জাতীয় সেবা নম্বর' : 'EMERGENCY NATIONAL HELPLINES',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMuted,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: _buildHelplineTile(
                          number: isBn ? '৩৩৩' : '333',
                          title: isBn ? 'তথ্য সেবা' : 'Civic Info',
                          isDanger: false,
                          onTap: () => _makeCall('333'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildHelplineTile(
                          number: isBn ? '৯৯৯' : '999',
                          title: isBn ? 'জরুরি' : 'Emergency',
                          isDanger: true,
                          onTap: () => _makeCall('999'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildHelplineTile(
                          number: isBn ? '১০৬' : '106',
                          title: isBn ? 'দুদক' : 'Anti-Corruption',
                          isDanger: false,
                          onTap: () => _makeCall('106'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Drawer Footer Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFB),
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: isLoggedIn
                  ? InkWell(
                      onTap: () {
                        authProvider.logout();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isBn
                                  ? 'লগআউট সফল হয়েছে'
                                  : 'Logged out successfully',
                            ),
                          ),
                        );
                      },
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.zero,
                          border: Border.all(
                            color: const Color(0xFFFCA5A5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.logout,
                              size: 16,
                              color: AppColors.primaryRed,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isBn ? 'লগআউট করুন' : 'Log Out',
                              style: GoogleFonts.notoSansBengali(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            },
                            child: Container(
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.zero,
                                border: Border.all(color: AppColors.border),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                isBn ? 'লগইন' : 'Log In',
                                style: GoogleFonts.notoSansBengali(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: Container(
                              height: 42,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryGreen,
                                borderRadius: BorderRadius.zero,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                isBn ? 'নিবন্ধন' : 'Register',
                                style: GoogleFonts.notoSansBengali(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
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

  Widget _buildNavItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.zero,
                border: Border.all(color: AppColors.border, width: 0.8),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.notoSansBengali(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelplineTile({
    required String number,
    required String title,
    required bool isDanger,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isDanger ? const Color(0xFFFEF2F2) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: isDanger ? const Color(0xFFFECACA) : AppColors.border,
          ),
        ),
        child: Column(
          children: [
            Text(
              number,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: isDanger ? AppColors.primaryRed : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: GoogleFonts.notoSansBengali(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
