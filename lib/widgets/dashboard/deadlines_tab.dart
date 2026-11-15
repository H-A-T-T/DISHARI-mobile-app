import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/language_provider.dart';
import '../../screens/opportunities_screen.dart';

class DeadlinesTab extends StatefulWidget {
  const DeadlinesTab({super.key});

  @override
  State<DeadlinesTab> createState() => _DeadlinesTabState();
}

class _DeadlinesTabState extends State<DeadlinesTab> {
  String _selectedCategory = 'all';

  Future<void> _openLink(String? url) async {
    if (url != null && url.isNotEmpty) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  String _calculateDaysRemaining(String deadlineDateStr, bool isBn) {
    try {
      final clean = deadlineDateStr.trim();
      final parsed = DateTime.tryParse(clean);
      if (parsed != null) {
        final diff = parsed.difference(DateTime.now()).inDays;
        if (diff < 0) {
          return isBn ? 'সময় শেষ' : 'Expired';
        } else if (diff == 0) {
          return isBn ? 'আজই শেষ দিন!' : 'Last day today!';
        } else {
          return isBn
              ? '${AppConstants.toBengaliNumber(diff)} দিন বাকি'
              : '$diff days left';
        }
      }
    } catch (_) {}
    return isBn ? 'আসন্ন' : 'Upcoming';
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final auth = context.watch<AuthProvider>();
    final dashboard = context.watch<DashboardProvider>();
    final isBn = langProvider.isBn;

    final allDeadlines = dashboard.deadlines;
    final filteredDeadlines = allDeadlines.where((d) {
      if (_selectedCategory == 'all') return true;
      return d.category == _selectedCategory;
    }).toList();

    final categories = [
      {'id': 'all', 'labelBn': 'সকল ডেডলাইন', 'labelEn': 'All Deadlines'},
      {'id': 'tax', 'labelBn': 'কর ও রাজস্ব', 'labelEn': 'Tax & Revenue'},
      {'id': 'education', 'labelBn': 'শিক্ষা ও উপবৃত্তি', 'labelEn': 'Education'},
      {'id': 'welfare', 'labelBn': 'কল্যাণ ও ভাতা', 'labelEn': 'Welfare'},
      {'id': 'sme', 'labelBn': 'ব্যবসা ও বাণিজ্য', 'labelEn': 'Business & SME'},
    ];

    return RefreshIndicator(
      onRefresh: () => dashboard.loadDashboardData(auth.user?.id,
          isDemo: auth.user?.id == 1),
      color: AppColors.primaryGreen,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Loading Bar
            if (dashboard.isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(
                  minHeight: 3,
                  backgroundColor: AppColors.bgMuted,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                ),
              ),

            // Banner Card
            Container(
              padding: const EdgeInsets.all(14),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notifications_active_outlined,
                          size: 18, color: AppColors.primaryGreen),
                      const SizedBox(width: 8),
                      Text(
                        langProvider.t('deadlines.title'),
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isBn
                        ? 'ট্যাক্স রিটার্ন, শিক্ষা উপবৃত্তি, সমাজকল্যাণ ভাতা কিংবা লাইসেন্স নবায়নের সরকারি শেষ তারিখগুলো এখানে আগে থেকে জানিয়ে দেওয়া হয়।'
                        : 'Stay ahead of national deadlines for tax filing, educational stipends, social allowances, and annual license renewals.',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Category Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((cat) {
                  final isSelected = _selectedCategory == cat['id'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedCategory = cat['id']!;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryGreen
                              : AppColors.bgSurface,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryGreen
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          isBn ? cat['labelBn']! : cat['labelEn']!,
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // Deadlines Cards List
            if (filteredDeadlines.isEmpty)
              Container(
                padding: const EdgeInsets.all(28),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.event_available,
                        size: 36, color: AppColors.textMuted),
                    const SizedBox(height: 8),
                    Text(
                      isBn
                          ? 'এই ক্যাটাগরিতে কোনো জরুরি ডেডলাইন নেই'
                          : 'No deadlines in this category',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredDeadlines.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = filteredDeadlines[index];
                  final isUrgent = item.isUrgent;
                  final remaining = _calculateDaysRemaining(item.deadline, isBn);

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      border: Border(
                        top: BorderSide(
                          color: isUrgent
                              ? AppColors.primaryRed
                              : AppColors.primaryGreen,
                          width: 3,
                        ),
                        left:
                            const BorderSide(color: AppColors.border, width: 1),
                        right:
                            const BorderSide(color: AppColors.border, width: 1),
                        bottom:
                            const BorderSide(color: AppColors.border, width: 1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  color: isUrgent
                                      ? AppColors.lightRed50
                                      : AppColors.lightGreen50,
                                  child: Text(
                                    isUrgent
                                        ? (isBn
                                            ? 'জরুরি শেষ তারিখ'
                                            : 'Critical Deadline')
                                        : (isBn
                                            ? 'আসন্ন সময়সীমা'
                                            : 'Upcoming Deadline'),
                                    style: GoogleFonts.notoSansBengali(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isUrgent
                                          ? AppColors.primaryRed
                                          : AppColors.primaryGreen,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  color: isUrgent
                                      ? AppColors.primaryRed
                                      : AppColors.darkGreen,
                                  child: Text(
                                    remaining,
                                    style: GoogleFonts.notoSansBengali(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              isBn
                                  ? AppConstants.toBengaliNumber(item.deadline)
                                  : item.deadline,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isUrgent
                                    ? AppColors.primaryRed
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isBn ? item.titleBn : item.titleEn,
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isBn ? item.descriptionBn : item.descriptionEn,
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Divider(color: AppColors.border, height: 1),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isBn
                                  ? '${AppConstants.toBengaliNumber(item.requiredDocs.length)}টি নথি আবশ্যক'
                                  : '${item.requiredDocs.length} docs required',
                              style: GoogleFonts.notoSansBengali(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                            if (item.officialLink != null)
                              InkWell(
                                onTap: () => _openLink(item.officialLink),
                                child: Row(
                                  children: [
                                    Text(
                                      isBn ? 'অফিসিয়াল পোর্টাল' : 'Gov Portal',
                                      style: GoogleFonts.notoSansBengali(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryGreen,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.open_in_new,
                                        size: 12, color: AppColors.primaryGreen),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),

            // Welfare / Opportunity Radar Teaser Banner (Matching Website DeadlinesView)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.darkGreen,
                border: Border.all(color: AppColors.primaryGreen),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome,
                          size: 16, color: Color(0xFF6EE7B7)),
                      const SizedBox(width: 6),
                      Text(
                        isBn ? 'নাগরিক সুযোগ রাডার' : 'CITIZEN OPPORTUNITY HUB',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF6EE7B7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isBn
                        ? 'আপনার প্রোফাইলের সাথে ম্যাচিং সরকারি সুযোগ ও ভাতা'
                        : 'Personalized Grants & Scheme Matcher',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isBn
                        ? 'যুব প্রশিক্ষণ, কৃষক প্রণোদনা, বিধবা ভাতা কিংবা উপবৃত্তির চলমান সার্কুলারগুলো দেখতে সুযোগ সার্চার ব্যবহার করুন।'
                        : 'Browse active quotas for youth skill training, farmer stimuli, and educational stipends.',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 11,
                      color: const Color(0xFFD1FAE5),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OpportunitiesScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      color: Colors.white,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isBn
                                ? 'সকল সুযোগ ব্রাউজ করুন'
                                : 'Browse All Schemes',
                            style: GoogleFonts.notoSansBengali(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkGreen,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward,
                              size: 13, color: AppColors.darkGreen),
                        ],
                      ),
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
}
