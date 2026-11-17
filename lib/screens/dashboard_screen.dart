import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/language_provider.dart';
import '../widgets/dashboard/applications_tab.dart';
import '../widgets/dashboard/deadlines_tab.dart';
import '../widgets/dashboard/document_locker_tab.dart';
import '../widgets/dashboard/profile_tab.dart';
import 'login_screen.dart';
import 'opportunities_screen.dart';
import 'register_screen.dart';
import 'services_screen.dart';

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
  // 0: Overview, 1: Locker, 2: Applications, 3: Deadlines, 4: Opportunities, 5: Profile
  int _activeSubTab = 0;

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

  String _calculateStorageText(int totalBytes) {
    if (totalBytes == 0) return '0.00 MB / 100 MB';
    final mb = totalBytes / (1024 * 1024);
    if (mb < 0.05) {
      final kb = (totalBytes / 1024).toStringAsFixed(1);
      return '$kb KB / 100 MB';
    }
    return '${mb.toStringAsFixed(2)} MB / 100 MB';
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
                      shape: const RoundedRectangleBorder(),
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
                      shape: const RoundedRectangleBorder(),
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

                // 1-Click Demo Login
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await auth.loginAsDemoCitizen();
                      await dashboard.seedDemoData();
                    },
                    icon: const Icon(Icons.person_pin_outlined, size: 16, color: AppColors.primaryGreen),
                    label: Text(
                      isBn ? 'ডেমো নাগরিক হিসেবে প্রবেশ করুন (১-ক্লিক)' : 'Enter as Demo Citizen (1-Click)',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryGreen),
                      shape: const RoundedRectangleBorder(),
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

    // ─── AUTHENTICATED DASHBOARD (1:1 WITH WEBSITE DASHBOARD) ───────────────
    final docs = dashboard.documents;
    final apps = dashboard.applications;
    final deadlines = dashboard.deadlines;
    final urgentCount = deadlines.where((d) => d.urgency == 'high').length;

    final subTabs = [
      (
        id: 'home',
        labelBn: 'সারসংক্ষেপ (হোম)',
        labelEn: 'Overview (Home)',
        icon: Icons.home_outlined,
        badge: null as String?,
      ),
      (
        id: 'locker',
        labelBn: 'আমার নথিপত্র (লকার)',
        labelEn: 'My Documents',
        icon: Icons.folder_shared_outlined,
        badge: docs.isNotEmpty ? '${docs.length}' : null,
      ),
      (
        id: 'applications',
        labelBn: 'আমার আবেদনসমূহ',
        labelEn: 'My Applications',
        icon: Icons.assignment_outlined,
        badge: apps.isNotEmpty ? '${apps.length}' : null,
      ),
      (
        id: 'deadlines',
        labelBn: 'নোটিফিকেশন ও ডেডলাইন',
        labelEn: 'Alerts & Deadlines',
        icon: Icons.notifications_none_outlined,
        badge: urgentCount > 0 ? '!' : null,
      ),
      (
        id: 'opportunities',
        labelBn: 'সরকারি সুযোগ ও সহায়তা',
        labelEn: 'Opportunities',
        icon: Icons.auto_awesome,
        badge: 'New',
      ),
      (
        id: 'settings',
        labelBn: 'সেটিংস ও প্রোফাইল',
        labelEn: 'Settings & Profile',
        icon: Icons.settings_outlined,
        badge: null,
      ),
    ];

    return Container(
      color: AppColors.bgPage,
      child: Column(
        children: [
          // Top Docket Header (1:1 with Web Header)
          Container(
            color: AppColors.bgSurface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.primaryGreen, width: 3),
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBn
                            ? 'গণপ্রজাতন্ত্রী বাংলাদেশ — নাগরিক ডিজিটাল ওয়ার্কস্পেস'
                            : "PEOPLE'S REPUBLIC OF BANGLADESH — CITIZEN WORKSPACE",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryGreen,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isBn ? 'আমার ড্যাশবোর্ড ও ক্লাউড লকার' : 'Citizen Dashboard & Cloud Vault',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.bgMuted,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, size: 12, color: AppColors.primaryGreen),
                      const SizedBox(width: 4),
                      Text(
                        auth.citizenId,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Horizontal 6-Tab Navigation Rail
          Container(
            decoration: const BoxDecoration(
              color: AppColors.bgSurface,
              border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: List.generate(subTabs.length, (idx) {
                  final tab = subTabs[idx];
                  final isSel = _activeSubTab == idx;

                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () => setState(() => _activeSubTab = idx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.primaryGreen : Colors.white,
                          border: Border.all(
                            color: isSel ? AppColors.primaryGreen : AppColors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              tab.icon,
                              size: 14,
                              color: isSel ? Colors.white : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isBn ? tab.labelBn : tab.labelEn,
                              style: GoogleFonts.notoSansBengali(
                                fontSize: 11,
                                fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                color: isSel ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            if (tab.badge != null) ...[
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isSel ? Colors.white : const Color(0xFFE5E7EB),
                                ),
                                child: Text(
                                  tab.badge!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    color: isSel ? AppColors.primaryGreen : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ],
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
              index: _activeSubTab,
              children: [
                _buildOverviewTab(context, isBn),
                const DocumentLockerTab(),
                const ApplicationsTab(),
                const DeadlinesTab(),
                const OpportunitiesScreen(isEmbedded: true),
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

    final user = auth.user;
    final docs = dashboard.documents;
    final apps = dashboard.applications;

    final totalSizeBytes = docs.fold<int>(0, (acc, d) => acc + (d.fileSize > 0 ? d.fileSize : 0));
    final storageText = _calculateStorageText(totalSizeBytes);
    final storagePercent = (totalSizeBytes / (100 * 1024 * 1024)).clamp(0.02, 1.0);

    return RefreshIndicator(
      onRefresh: () => dashboard.loadDashboardData(auth.user?.id, isDemo: auth.user?.id == 1),
      color: AppColors.primaryGreen,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Civic Greeting Banner — Windows 10 Flat Card (1:1 with Web)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.bgSurface,
                border: Border(
                  left: BorderSide(color: AppColors.primaryGreen, width: 4),
                  top: BorderSide(color: AppColors.border, width: 1),
                  right: BorderSide(color: AppColors.border, width: 1),
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isBn ? 'ডিজিটাল নাগরিক ওয়ার্কস্পেস' : 'DIGITAL CITIZEN WORKSPACE',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryGreen,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isBn ? 'সুপ্রভাত, ${user?.fullName ?? "নাগরিক"}' : 'Welcome, ${user?.fullName ?? "Citizen"}',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isBn
                        ? 'আপনার সকল সরকারি নথিপত্র, চলমান আবেদন ও সেবা সংক্রান্ত তথ্য এখানে সংরক্ষিত আছে।'
                        : 'All your government credentials, active application dockets, and civic deadlines stored here.',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2 Big Action Cards (Locker + Applications) 1:1 with Web
            Row(
              children: [
                // Card 1: Document Locker Quick Card
                Expanded(
                  child: Container(
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
                            Container(
                              padding: const EdgeInsets.all(6),
                              color: AppColors.lightGreen50,
                              child: const Icon(Icons.folder_shared_outlined, size: 18, color: AppColors.primaryGreen),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              color: AppColors.lightGreen50,
                              child: Text(
                                '${docs.length} ${isBn ? "টি ফাইল" : "files"}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isBn ? 'আমার নথিপত্র' : 'My Documents',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isBn
                              ? 'পাসপোর্ট, এনআইডি ও জন্ম সনদ ডিজিটাল লকারে সংরক্ষণ করুন।'
                              : 'Store NID, birth cert, and credentials securely.',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => setState(() => _activeSubTab = 1), // switch to Locker tab
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              foregroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: Text(
                              isBn ? 'লকার খুলুন' : 'Open Locker',
                              style: GoogleFonts.notoSansBengali(fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Card 2: Applications Quick Card
                Expanded(
                  child: Container(
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
                            Container(
                              padding: const EdgeInsets.all(6),
                              color: const Color(0xFFF3E8FF), // purple-50
                              child: const Icon(Icons.assignment_outlined, size: 18, color: Color(0xFF7E22CE)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              color: AppColors.bgMuted,
                              child: Text(
                                '${apps.length} ${isBn ? "টি আবেদন" : "dockets"}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isBn ? 'চলমান আবেদনসমূহ' : 'Active Applications',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isBn
                              ? 'প্রস্তুতকৃত সকল কার্যপত্র ও ট্র্যাকিং তথ্য এখানে প্রদর্শিত হয়।'
                              : 'Track your government application dockets.',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => setState(() => _activeSubTab = 2), // switch to Applications tab
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black87,
                              foregroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: Text(
                              isBn ? 'আবেদন দেখুন' : 'View Dockets',
                              style: GoogleFonts.notoSansBengali(fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Google Drive Style Storage Meter
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
                      Row(
                        children: [
                          const Icon(Icons.cloud_done_outlined, size: 16, color: AppColors.primaryGreen),
                          const SizedBox(width: 6),
                          Text(
                            isBn ? 'ব্যবহৃত ক্লাউড স্পেস:' : 'Cloud Storage Quota:',
                            style: GoogleFonts.notoSansBengali(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        storageText,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: storagePercent,
                    backgroundColor: AppColors.bgMuted,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                    minHeight: 5,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lock_outline, size: 11, color: AppColors.primaryGreen),
                          const SizedBox(width: 3),
                          Text(
                            '256-Bit AES Encryption',
                            style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.primaryGreen, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      Text(
                        '100 MB Free Tier',
                        style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Deadlines Alert Strip (1:1 with Web)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB), // amber-50
                border: Border(
                  left: const BorderSide(color: Color(0xFFF59E0B), width: 4), // amber-500
                  top: BorderSide(color: Colors.amber.shade300),
                  right: BorderSide(color: Colors.amber.shade300),
                  bottom: BorderSide(color: Colors.amber.shade300),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notifications_active, color: Color(0xFFB45309), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isBn ? 'আসন্ন আয়কর ও সরকারি সময়সীমা' : 'Upcoming Tax & Government Deadlines',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isBn
                        ? 'ব্যক্তিশ্রেণীর আয়কর রিটার্ন জমা দেওয়ার জাতীয় সময়সীমা: ৩০ নভেম্বর ২০২৬।'
                        : 'Annual Individual Income Tax filing deadline: November 30, 2026.',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => setState(() => _activeSubTab = 3), // switch to Deadlines tab
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: Text(
                      isBn ? 'সব সময়সীমা দেখুন' : 'View All Deadlines',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Browse Services CTA Card (1:1 with Web)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isBn ? 'কোন সরকারি সেবাটি আপনার প্রয়োজন?' : 'Which government service do you need?',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isBn
                        ? 'পাসপোর্ট, এনআইডি সংশোধন, ভূমি নামজারি ও ভাতাসহ সকল সেবার সঠিক নিয়ম ও ফি জেনে নিন।'
                        : 'Explore gazette requirements, official fees, and step-by-step procedures.',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ServicesScreen()),
                      );
                    },
                    icon: const Icon(Icons.arrow_forward, size: 14),
                    label: Text(
                      isBn ? 'সকল সেবা ডিরেক্টরি' : 'All Services Directory',
                      style: GoogleFonts.notoSansBengali(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Emergency Helpline Widget (1:1 with Web)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isBn ? 'জরুরি নাগরিক হেল্পলাইন:' : 'Helplines:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryGreen,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('৩৩৩ — সরকারি সেবা ও তথ্য', style: GoogleFonts.notoSansBengali(fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 3),
                  Text('৯৯৯ — জাতীয় জরুরি পুলিশ/অ্যাম্বুলেন্স', style: GoogleFonts.notoSansBengali(fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 3),
                  Text('১০৬ — দুর্নীতি দমন কমিশন (দুদক)', style: GoogleFonts.notoSansBengali(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
