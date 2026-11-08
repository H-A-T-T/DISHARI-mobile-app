import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/language_provider.dart';
import '../widgets/dashboard/applications_tab.dart';
import '../widgets/dashboard/profile_tab.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int targetTab)? onNavigateTab;

  const DashboardScreen({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _subTab = 0; // 0: Overview, 1: Applications, 2: Profile

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.isLoggedIn) {
        final dashboard = Provider.of<DashboardProvider>(context, listen: false);
        dashboard.loadDashboardData(auth.user?.id, isDemo: auth.user?.id == 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final auth = context.watch<AuthProvider>();
    final dashboard = context.watch<DashboardProvider>();
    final isBn = langProvider.isBn;

    // ─── AUTH GATE (FLAT WINDOWS 10 STYLE) ──────────────────────────────────
    if (!auth.isLoggedIn) {
      return Container(
        color: AppColors.bgPage,
        alignment: Alignment.center,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.bgSurface,
              border: Border(
                top: BorderSide(color: AppColors.primaryGreen, width: 3),
                left: BorderSide(color: AppColors.border, width: 1),
                right: BorderSide(color: AppColors.border, width: 1),
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  color: AppColors.amber50,
                  child: const Icon(Icons.lock_outline, size: 24, color: AppColors.amber500),
                ),
                const SizedBox(height: 12),
                Text(
                  isBn ? 'সুরক্ষিত নাগরিক ড্যাশবোর্ড' : 'Protected Citizen Workspace',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.amber500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  langProvider.t('dashboard.authRequired'),
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isBn
                      ? 'ব্যক্তিগত নথিপত্র, ডিজিটাল লকার এবং সরকারি আবেদন ডকেট সংরক্ষণের জন্য অনুগ্রহ করে আপনার অ্যাকাউন্টে লগইন করুন।'
                      : 'Please log in to access your secure document locker, citizen dockets, and saved credentials.',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      isBn ? 'লগইন করুন' : 'Log In to Account',
                      style: GoogleFonts.notoSansBengali(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Register Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      isBn ? 'নতুন অ্যাকাউন্ট নিবন্ধন করুন' : 'Create Free Account',
                      style: GoogleFonts.notoSansBengali(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Divider(color: AppColors.border),
                const SizedBox(height: 14),

                // 1-Click Demo Login Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await auth.loginAsDemoCitizen();
                      await dashboard.seedDemoData();
                    },
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
                      side: const BorderSide(color: AppColors.primaryGreen, style: BorderStyle.solid),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ─── AUTHENTICATED DASHBOARD ───────────────────────────────────────────
    final subTabTitles = [
      langProvider.t('dashboard.tabOverview'),
      langProvider.t('dashboard.tabApps'),
      langProvider.t('dashboard.tabProfile'),
    ];

    return Container(
      color: AppColors.bgPage,
      child: Column(
        children: [
          // User Header Bar
          Container(
            color: AppColors.bgSurface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auth.user?.fullName ?? (isBn ? 'নাগরিক' : 'Citizen'),
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${langProvider.t("dashboard.citizenId")}: ${auth.citizenId}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  color: AppColors.lightGreen50,
                  child: Text(
                    isBn ? 'সক্রিয় নাগরিক' : 'Verified Citizen',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Horizontal Subtab Chips
          Container(
            decoration: const BoxDecoration(
              color: AppColors.bgSurface,
              border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: List.generate(subTabTitles.length, (idx) {
                  final isSel = _subTab == idx;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () => setState(() => _subTab = idx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.primaryGreen : AppColors.bgMuted,
                          border: Border.all(
                            color: isSel ? AppColors.primaryGreen : AppColors.border,
                          ),
                        ),
                        child: Text(
                          subTabTitles[idx],
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 11,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                            color: isSel ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // Subtab Content
          Expanded(
            child: IndexedStack(
              index: _subTab,
              children: [
                _buildOverviewTab(context, isBn),
                const ApplicationsTab(),
                const ProfileTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, bool isBn) {
    final dashboard = context.watch<DashboardProvider>();
    final auth = context.watch<AuthProvider>();

    return RefreshIndicator(
      onRefresh: () => dashboard.loadDashboardData(auth.user?.id, isDemo: auth.user?.id == 1),
      color: AppColors.primaryGreen,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Tiles
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    title: isBn ? 'লকার নথিপত্র' : 'Locker Docs',
                    value: isBn
                        ? AppConstants.toBengaliNumber(dashboard.documents.length)
                        : '${dashboard.documents.length}',
                    icon: Icons.folder_special_outlined,
                    color: AppColors.primaryGreen,
                    onTap: () => widget.onNavigateTab?.call(2), // Jump to Locker bottom nav tab
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    title: isBn ? 'আবেদন ডকেট' : 'Application Dockets',
                    value: isBn
                        ? AppConstants.toBengaliNumber(dashboard.applications.length)
                        : '${dashboard.applications.length}',
                    icon: Icons.assignment_outlined,
                    color: AppColors.catIdentity,
                    onTap: () => setState(() => _subTab = 1), // Switch to Applications subtab
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    title: isBn ? 'আসন্ন ডেডলাইন' : 'Deadlines',
                    value: isBn
                        ? AppConstants.toBengaliNumber(dashboard.deadlines.length)
                        : '${dashboard.deadlines.length}',
                    icon: Icons.notifications_active_outlined,
                    color: AppColors.catTax,
                    onTap: () => widget.onNavigateTab?.call(3), // Jump to Deadlines bottom nav tab
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Quick Locker Status Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isBn ? 'ডিজিটাল লকার প্রস্তুতি' : 'Locker Completeness',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        isBn
                            ? '${AppConstants.toBengaliNumber(dashboard.completenessPercent)}%'
                            : '${dashboard.completenessPercent}%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: dashboard.completenessPercent / 100,
                    backgroundColor: AppColors.bgMuted,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                    minHeight: 6,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isBn
                        ? 'NID ও জন্ম সনদ যুক্ত থাকলে যেকোনো সরকারি সেবা ফরম ১-ক্লিকে স্বয়ংক্রিয়ভাবে পূরণ করা যায়।'
                        : 'Save NID and birth certificates once to auto-fill government forms with 1-click.',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick Action Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: AppColors.bgSurface,
                border: Border(
                  left: BorderSide(color: AppColors.primaryGreen, width: 3),
                  top: BorderSide(color: AppColors.border, width: 1),
                  right: BorderSide(color: AppColors.border, width: 1),
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, size: 24, color: AppColors.primaryGreen),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isBn ? 'নিরাপদ সরকারি সেবা সহকারী' : 'Verified Civic Companion',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          isBn
                              ? 'দিশারী কোনো ব্যক্তিগত তথ্য অননুমোদিতভাবে সংরক্ষণ করে না।'
                              : 'Dishari never stores or shares personal data without authorization.',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 18, color: color),
                const Icon(Icons.arrow_forward, size: 12, color: AppColors.textMuted),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.notoSansBengali(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
