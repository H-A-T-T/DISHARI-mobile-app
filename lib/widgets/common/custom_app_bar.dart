import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/language_provider.dart';
import '../../screens/login_screen.dart';
import '../../screens/register_screen.dart';
import 'dishari_logo.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onNotificationTap;
  final VoidCallback? onMenuTap;

  const CustomAppBar({
    super.key,
    this.onNotificationTap,
    this.onMenuTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(63);

  static void showNotificationSheet(
    BuildContext context, {
    Function(int tabIndex)? onNavigateTab,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final langProvider = Provider.of<LanguageProvider>(ctx, listen: false);
        final auth = Provider.of<AuthProvider>(ctx, listen: false);
        final dashboard = Provider.of<DashboardProvider>(ctx, listen: false);
        final isBn = langProvider.isBn;
        final user = auth.user;
        final isLoggedIn = auth.isLoggedIn && user != null;

        final docs = dashboard.documents;
        final apps = dashboard.applications;
        final deadlines = dashboard.deadlines;

        // Build personalized notifications list matching web NotificationDropdown.tsx
        final List<Map<String, dynamic>> items = [];

        if (isLoggedIn) {
          // A. Submitted Applications
          for (final app in apps) {
            final statusText = app.status == 'ready'
                ? (isBn ? 'আবেদন প্রস্তুত ও ডকেটভুক্ত' : 'Application Prepared')
                : (app.status == 'submitted'
                    ? (isBn ? 'আবেদন জমা হয়েছে' : 'Application Submitted')
                    : (isBn ? 'আবেদন পর্যালোচনায়' : 'Under Review'));
            items.add({
              'id': 'app-${app.id}',
              'title': '${app.serviceNameBn} — $statusText',
              'desc': isBn
                  ? 'আপনার ডকেট আইডি ${app.docketId} সফলভাবে নথিভুক্ত হয়েছে।'
                  : 'Docket ID ${app.docketId} is recorded in system.',
              'category': 'application',
              'urgency': 'normal',
              'tabIndex': 4,
            });
          }

          // B. Missing Locker Documents Alerts
          final hasNid = docs.any((d) => d.docType == 'nid_front' || d.docType == 'nid_back');
          final hasPhoto = docs.any((d) => d.docType == 'photo');

          if (!hasNid) {
            items.add({
              'id': 'locker-missing-nid',
              'title': isBn ? 'নাগরিক লকারে NID আপলোড বাকি রয়েছে' : 'National ID (NID) Not Yet in Locker',
              'desc': isBn
                  ? 'সরকারি সেবা ও স্বয়ংক্রিয় ফর্ম পূরণের সুবিধা পেতে আপনার ডিজিটাল লকারে NID কপি যুক্ত করুন।'
                  : 'Upload your National ID to unlock 1-click government form auto-filling.',
              'category': 'locker',
              'urgency': 'high',
              'tabIndex': 2,
            });
          }

          if (!hasPhoto) {
            items.add({
              'id': 'locker-missing-photo',
              'title': isBn ? 'পাসপোর্ট সাইজ ছবি সংরক্ষণ করুন' : 'Add Passport Photo to Vault',
              'desc': isBn
                  ? 'পাসপোর্ট ও অন্যান্য নাগরিক আবেদনের জন্য ডিজিটাল লকারে পাসপোর্ট সাইজ রঙিন ছবি রাখুন।'
                  : 'Keep a certified passport photo in your vault for rapid filings.',
              'category': 'locker',
              'urgency': 'normal',
              'tabIndex': 2,
            });
          }

          // C. Deadlines Radar
          for (final dl in deadlines.take(2)) {
            items.add({
              'id': 'deadline-${dl.id}',
              'title': isBn ? dl.titleBn : dl.titleEn,
              'desc': isBn ? dl.descriptionBn : dl.descriptionEn,
              'category': 'deadline',
              'urgency': dl.urgency == 'high' ? 'high' : 'normal',
              'tabIndex': 3,
            });
          }

          // D. Account Welcome Card
          items.add({
            'id': 'account-welcome',
            'title': isBn ? 'স্বাগতম, ${user.fullName}!' : 'Welcome, ${user.fullName}!',
            'desc': isBn
                ? 'আপনার নাগরিক আইডি (${user.citizenId}) সক্রিয় রয়েছে। ড্যাশবোর্ড থেকে সকল সেবা পরিচালনা করুন।'
                : 'Your citizen account (${user.citizenId}) is active and secured.',
            'category': 'account',
            'urgency': 'normal',
            'tabIndex': 4,
          });
        }

        return Container(
          height: MediaQuery.of(ctx).size.height * 0.75,
          decoration: const BoxDecoration(
            color: AppColors.bgSurface,
            border: Border(
              top: BorderSide(color: AppColors.primaryGreen, width: 3),
            ),
          ),
          child: Column(
            children: [
              // Header
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
                        Text(
                          isBn ? 'নাগরিক নোটিফিকেশন' : 'Citizen Notifications',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (isLoggedIn) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            color: AppColors.lightGreen50,
                            child: Text(
                              isBn ? 'ব্যক্তিগত' : 'Personal',
                              style: GoogleFonts.notoSansBengali(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),

              // Content Area
              Expanded(
                child: !isLoggedIn
                    // LOGGED-OUT STATE: Polite Sign-In Prompt Card (Matches web)
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                            Container(
                              width: 54,
                              height: 54,
                              decoration: const BoxDecoration(
                                color: AppColors.bgMuted,
                                borderRadius: BorderRadius.zero,
                              ),
                              child: const Icon(
                                Icons.shield_outlined,
                                size: 28,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isBn
                                  ? 'ব্যক্তিগত নোটিফিকেশন পেতে লগইন করুন'
                                  : 'Sign In for Personalized Alerts',
                              style: GoogleFonts.notoSansBengali(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isBn
                                  ? 'আপনার জমা দেওয়া আবেদন ট্র্যাকিং, ডিজিটাল লকারে প্রয়োজনীয় কাগজের ঘাটতি এবং আপনার সাথে সম্পর্কিত সরকারি ডেডলাইন নোটিফিকেশন পেতে সাইন-ইন করুন।'
                                  : 'Sign in to receive real-time updates for your submitted applications, locker document status, and personalized deadlines.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.notoSansBengali(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const LoginScreen()),
                                  );
                                },
                                icon: const Icon(Icons.login, size: 16),
                                label: Text(
                                  isBn ? 'লগইন করুন' : 'Sign In',
                                  style: GoogleFonts.notoSansBengali(
                                      fontWeight: FontWeight.w700),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryGreen,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: const RoundedRectangleBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const RegisterScreen()),
                                  );
                                },
                                child: Text(
                                  isBn ? 'নতুন অ্যাকাউন্ট খুলুন' : 'Create Account',
                                  style: GoogleFonts.notoSansBengali(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: const RoundedRectangleBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    // LOGGED-IN STATE: Personalized List (Matches web)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        itemBuilder: (c, idx) {
                          final item = items[idx];
                          final category = item['category'] as String;
                          final urgency = item['urgency'] as String;

                          IconData iconData;
                          Color iconColor;
                          switch (category) {
                            case 'application':
                              iconData = Icons.description_outlined;
                              iconColor = AppColors.primaryGreen;
                              break;
                            case 'locker':
                              iconData = Icons.folder_shared_outlined;
                              iconColor = Colors.amber.shade800;
                              break;
                            case 'deadline':
                              iconData = Icons.calendar_today_outlined;
                              iconColor = AppColors.primaryRed;
                              break;
                            default:
                              iconData = Icons.verified_user_outlined;
                              iconColor = const Color(0xFF10B981);
                          }

                          return InkWell(
                            onTap: () {
                              Navigator.pop(ctx);
                              if (item['tabIndex'] != null &&
                                  onNavigateTab != null) {
                                onNavigateTab(item['tabIndex'] as int);
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: urgency == 'high'
                                    ? const Color(0xFFFEF2F2)
                                    : Colors.white,
                                border: Border.all(
                                  color: urgency == 'high'
                                      ? AppColors.primaryRed.withValues(alpha: 0.4)
                                      : AppColors.border,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: iconColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.zero,
                                    ),
                                    child: Icon(iconData,
                                        size: 16, color: iconColor),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['title'].toString(),
                                          style: GoogleFonts.notoSansBengali(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          item['desc'].toString(),
                                          style: GoogleFonts.notoSansBengali(
                                            fontSize: 11.5,
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
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final isBn = langProvider.isBn;

    return SafeArea(
      bottom: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top 3px Bangladesh Green Accent Strip (Windows 10 Flat)
          Container(
            height: 3,
            color: AppColors.primaryGreen,
          ),
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              color: AppColors.bgSurface,
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Dishari Logo (Matches web Navbar)
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: DishariLogo(
                      height: 34,
                      isBn: isBn,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Action Controls Row (Language Switcher, Notifications, Mobile Hamburger)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 2. Dual Segmented Language Switcher (বাং | EN matching web Navbar.tsx)
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.zero,
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () {
                              if (!isBn) langProvider.setLanguage('bn');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isBn
                                    ? AppColors.primaryGreen
                                    : Colors.transparent,
                                borderRadius: BorderRadius.zero,
                              ),
                              child: Text(
                                'বাং',
                                style: GoogleFonts.notoSansBengali(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isBn
                                      ? Colors.white
                                      : const Color(0xFF374151),
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              if (isBn) langProvider.setLanguage('en');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: !isBn
                                    ? AppColors.primaryGreen
                                    : Colors.transparent,
                                borderRadius: BorderRadius.zero,
                              ),
                              child: Text(
                                'EN',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: !isBn
                                      ? Colors.white
                                      : const Color(0xFF374151),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 6),

                    // 3. Citizen Notification Bell with Alert Dot
                    InkWell(
                      onTap: onNotificationTap ??
                          () => showNotificationSheet(context),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.zero,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(
                              Icons.notifications_none_outlined,
                              color: AppColors.textPrimary,
                              size: 20,
                            ),
                          ),
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.primaryRed,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 6),

                    // 4. Mobile Hamburger Menu Toggle (Square Windows 10 Flat)
                    Builder(
                      builder: (scaffoldContext) {
                        return InkWell(
                          onTap: onMenuTap ??
                              () {
                                Scaffold.of(scaffoldContext).openEndDrawer();
                              },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.zero,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(
                              Icons.menu,
                              color: AppColors.textPrimary,
                              size: 20,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
