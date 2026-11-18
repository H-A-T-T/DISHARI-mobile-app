import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/services_provider.dart';
import '../../screens/opportunities_screen.dart';
import '../../screens/service_detail_screen.dart';

class PersonalizedFeed extends StatelessWidget {
  final Function(int targetTab) onNavigateTab;

  const PersonalizedFeed({
    super.key,
    required this.onNavigateTab,
  });

  String _getGreeting(bool isBn) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return isBn ? 'শুভ সকাল' : 'Good Morning';
    } else if (hour < 17) {
      return isBn ? 'শুভ অপরাহ্ন' : 'Good Afternoon';
    } else {
      return isBn ? 'শুভ সন্ধ্যা' : 'Good Evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final isBn = langProvider.isBn;
    final auth = context.watch<AuthProvider>();
    final dashboard = context.watch<DashboardProvider>();
    final servicesProvider = context.watch<ServicesProvider>();

    final user = auth.user;
    final documents = dashboard.documents;
    final applications = dashboard.applications;
    final deadlines = dashboard.deadlines;
    final services = servicesProvider.services;

    final userName = user?.fullName.isNotEmpty == true
        ? user!.fullName
        : (isBn ? 'নাগরিক' : 'Citizen');
    final citizenId = user?.citizenId.isNotEmpty == true
        ? user!.citizenId
        : (user?.phone.isNotEmpty == true ? user!.phone : 'CITIZEN-AUTH');

    // 4 Essential Documents Checklist
    final essentialDocs = [
      {
        'type': 'nid_front',
        'titleBn': 'জাতীয় পরিচয়পত্র (NID)',
        'titleEn': 'National ID (NID)',
        'descBn': 'স্মার্ট কার্ড বা মূল অনলাইন কপি',
        'descEn': 'Smart Card or Digital Copy',
      },
      {
        'type': 'birth_certificate',
        'titleBn': 'জন্ম নিবন্ধন সনদ',
        'titleEn': 'Digital Birth Certificate',
        'descBn': '১৭ ডিজিট অনলাইন যাচাইকৃত সনদ',
        'descEn': '17-digit digital verified cert',
      },
      {
        'type': 'photo',
        'titleBn': 'পাসপোর্ট সাইজ ছবি',
        'titleEn': 'Passport Size Photo',
        'descBn': 'সাম্প্রতিক রঙিন ছবি',
        'descEn': 'Recent color photo',
      },
      {
        'type': 'tin_certificate',
        'titleBn': 'ই-টিআইএন সনদ (TIN)',
        'titleEn': 'e-TIN Tax Certificate',
        'descBn': 'এনবিআর ১২ ডিজিট করদাতা নম্বর',
        'descEn': 'NBR 12-digit tax certificate',
      },
    ];

    final uploadedTypes = documents.map((d) => d.docType).toSet();
    final matchedCount = essentialDocs.where((e) => uploadedTypes.contains(e['type'])).length;
    final readinessPercent = ((matchedCount / essentialDocs.length) * 100).round();

    // Priority Services (e-Passport, NID Correction, Birth Registration, Land Mutation, Trade License)
    final prioritySlugs = ['e-passport', 'nid-correction', 'birth-registration', 'land-mutation', 'trade-license'];
    final recommendedServices = services.where((s) => prioritySlugs.contains(s.slug)).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── 1. Civic Greeting Banner (Windows 10 Flat Card) ───────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.zero,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: const BoxDecoration(
                        color: AppColors.lightGreen50,
                        border: Border(left: BorderSide(color: AppColors.primaryGreen, width: 3)),
                      ),
                      child: Text(
                        isBn ? 'ব্যক্তিগত নাগরিক ফিড' : 'PERSONAL CIVIC FEED',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryGreen,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      color: AppColors.bgMuted,
                      child: Text(
                        citizenId,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${_getGreeting(isBn)}, $userName',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isBn
                      ? 'আপনার সংরক্ষিত নথিপত্র, চলমান আবেদন ও আসন্ন সরকারি সময়সীমা নিচে পর্যবেক্ষণ করুন।'
                      : 'Track your encrypted documents, active application dockets, and deadlines below.',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ─── 2. 4 Status Metric Tiles (2x2 Grid) ──────────────────────────
          Row(
            children: [
              // Tile 1: Digital Vault
              Expanded(
                child: _buildTile(
                  topLabel: isBn ? 'ডিজিটাল লকার' : 'Doc Vault',
                  icon: Icons.folder_shared_outlined,
                  iconColor: AppColors.primaryGreen,
                  accentColor: AppColors.primaryGreen,
                  primaryText: '${documents.length} ${isBn ? "টি নথি" : "files"}',
                  subText: isBn ? 'প্রস্তুতি: $readinessPercent%' : 'Readiness: $readinessPercent%',
                  footerActionText: isBn ? 'লকার খুলুন' : 'Open Vault',
                  onTap: () => onNavigateTab(2), // Locker tab
                ),
              ),
              const SizedBox(width: 10),

              // Tile 2: Active Dockets
              Expanded(
                child: _buildTile(
                  topLabel: isBn ? 'চলমান আবেদন' : 'Active Dockets',
                  icon: Icons.assignment_outlined,
                  iconColor: const Color(0xFF7E22CE),
                  accentColor: const Color(0xFF7E22CE),
                  primaryText: '${applications.length} ${isBn ? "টি ডকেট" : "dockets"}',
                  subText: applications.isNotEmpty
                      ? (isBn ? 'ট্র্যাকিং সক্রিয়' : 'Live tracking')
                      : (isBn ? 'নতুন আবেদন নেই' : 'Queue empty'),
                  footerActionText: isBn ? 'আবেদন দেখুন' : 'View Dockets',
                  onTap: () => onNavigateTab(4), // Dashboard tab
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              // Tile 3: Deadlines
              Expanded(
                child: _buildTile(
                  topLabel: isBn ? 'সরকারি ডেডলাইন' : 'Deadlines',
                  icon: Icons.notifications_active_outlined,
                  iconColor: const Color(0xFFEA580C),
                  accentColor: const Color(0xFFEA580C),
                  primaryText: '${deadlines.length} ${isBn ? "টি সতর্কতা" : "alerts"}',
                  subText: deadlines.isNotEmpty
                      ? (isBn ? deadlines[0].titleBn : deadlines[0].titleEn)
                      : (isBn ? 'কোনো জরুরি ডেডলাইন নেই' : 'No urgent alerts'),
                  footerActionText: isBn ? 'ক্যালেন্ডার' : 'Check Dates',
                  onTap: () => onNavigateTab(3), // Deadlines tab
                ),
              ),
              const SizedBox(width: 10),

              // Tile 4: Grants & Subsidies
              Expanded(
                child: _buildTile(
                  topLabel: isBn ? 'সরকারি সুযোগ' : 'Civic Grants',
                  icon: Icons.auto_awesome_outlined,
                  iconColor: const Color(0xFF006A4E),
                  accentColor: const Color(0xFF006A4E),
                  primaryText: '৪+ ${isBn ? "সহায়তা" : "grants"}',
                  subText: isBn ? 'প্রণোদনা ও ভাতা' : 'Subsidies & aid',
                  footerActionText: isBn ? 'এক্সপ্লোর করুন' : 'Explore Hub',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OpportunitiesScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ─── 3. Active Applications Radar ────────────────────────────────
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
                        const Icon(Icons.radar, size: 16, color: Color(0xFF7E22CE)),
                        const SizedBox(width: 6),
                        Text(
                          isBn ? 'চলমান আবেদন রাডার' : 'ACTIVE APPLICATION RADAR',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF7E22CE),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => onNavigateTab(4),
                      child: Text(
                        isBn ? 'সকল আবেদন →' : 'All Dockets →',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (applications.isEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                    color: AppColors.bgMuted,
                    child: Column(
                      children: [
                        const Icon(Icons.inbox_outlined, size: 24, color: AppColors.textMuted),
                        const SizedBox(height: 6),
                        Text(
                          isBn ? 'বর্তমানে কোনো সক্রিয় আবেদন প্রক্রিয়াধীন নেই' : 'No active applications in queue',
                          style: GoogleFonts.notoSansBengali(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isBn ? 'যেকোনো সেবায় আবেদন করলে এখানে ট্র্যাকিং ডকেট তৈরি হবে।' : 'Start any service application to track progress here.',
                          style: GoogleFonts.notoSansBengali(fontSize: 10.5, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ...applications.take(2).map((app) {
                    final isSubmitted = app.status == 'submitted' || app.status == 'processing';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.bgMuted,
                        border: Border(left: BorderSide(color: AppColors.primaryGreen, width: 3)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isBn ? app.serviceNameBn : app.serviceNameEn,
                                  style: GoogleFonts.notoSansBengali(fontSize: 12.5, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'DOCKET: ${app.docketId}',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            color: isSubmitted ? const Color(0xFFDCFCE7) : AppColors.lightGreen50,
                            child: Text(
                              app.getStatusDisplay(isBn),
                              style: GoogleFonts.notoSansBengali(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isSubmitted ? const Color(0xFF15803D) : AppColors.primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── 4. Essential Documents Readiness Checklist ────────────────────
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
                      isBn ? 'মৌলিক নাগরিক নথি প্রস্তুতি সূচক' : 'CORE CITIZEN CREDENTIALS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryGreen,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '$readinessPercent%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Progress Bar
                LinearProgressIndicator(
                  value: readinessPercent / 100.0,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                  minHeight: 5,
                ),
                const SizedBox(height: 12),

                ...essentialDocs.map((item) {
                  final isAttached = uploadedTypes.contains(item['type']);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          isAttached ? Icons.check_circle : Icons.radio_button_unchecked,
                          size: 16,
                          color: isAttached ? AppColors.primaryGreen : AppColors.textMuted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isBn ? item['titleBn']! : item['titleEn']!,
                                style: GoogleFonts.notoSansBengali(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isAttached ? AppColors.textPrimary : AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                isBn ? item['descBn']! : item['descEn']!,
                                style: GoogleFonts.notoSansBengali(fontSize: 10, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        if (!isAttached)
                          InkWell(
                            onTap: () => onNavigateTab(2), // Jump to Locker to upload
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.primaryGreen),
                                color: Colors.white,
                              ),
                              child: Text(
                                isBn ? '+ যোগ করুন' : '+ Add',
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
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── 5. Recommended Priority Citizen Services ─────────────────────
          if (recommendedServices.isNotEmpty) ...[
            Text(
              isBn ? 'আপনার জন্য প্রস্তাবিত নাগরিক সেবা:' : 'Recommended Citizen Services:',
              style: GoogleFonts.notoSansBengali(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            ...recommendedServices.map((s) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      color: AppColors.lightGreen50,
                      child: const Icon(Icons.shield_outlined, size: 20, color: AppColors.primaryGreen),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isBn ? s.nameBn : s.nameEn,
                            style: GoogleFonts.notoSansBengali(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${isBn ? "ফি:" : "Fee:"} ${s.fee} • ${s.processingTimeBn}',
                            style: GoogleFonts.notoSansBengali(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ServiceDetailScreen(slug: s.slug),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        isBn ? 'আবেদন' : 'Apply',
                        style: GoogleFonts.notoSansBengali(fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildTile({
    required String topLabel,
    required IconData icon,
    required Color iconColor,
    required Color accentColor,
    required String primaryText,
    required String subText,
    required String footerActionText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          border: Border(
            top: BorderSide(color: accentColor, width: 3),
            left: const BorderSide(color: AppColors.border),
            right: const BorderSide(color: AppColors.border),
            bottom: const BorderSide(color: AppColors.border),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  topLabel,
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                Icon(icon, size: 16, color: iconColor),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              primaryText,
              style: GoogleFonts.notoSansBengali(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.notoSansBengali(
                fontSize: 10.5,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Divider(color: AppColors.border.withValues(alpha: 0.6), height: 1),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  footerActionText,
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
                Icon(Icons.chevron_right, size: 14, color: accentColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
