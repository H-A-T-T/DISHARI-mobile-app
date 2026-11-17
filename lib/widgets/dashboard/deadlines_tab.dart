import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/language_provider.dart';
import '../../screens/service_detail_screen.dart';

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
      {'id': 'all', 'labelBn': 'সব ডেডলাইন', 'labelEn': 'All Deadlines'},
      {'id': 'tax', 'labelBn': 'আয়কর ও রাজস্ব', 'labelEn': 'Tax & Revenue'},
      {'id': 'education', 'labelBn': 'উপবৃত্তি ও শিক্ষা', 'labelEn': 'Education & Grants'},
      {'id': 'welfare', 'labelBn': 'ভাতা ও সমাজকল্যাণ', 'labelEn': 'Welfare & Allowances'},
    ];

    return RefreshIndicator(
      onRefresh: () => dashboard.loadDashboardData(auth.user?.id, isDemo: auth.user?.id == 1),
      color: AppColors.primaryGreen,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Banner (Windows 10 Flat Card)
            Container(
              padding: const EdgeInsets.all(16),
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
                      const Icon(Icons.notifications_active_outlined, size: 16, color: AppColors.primaryGreen),
                      const SizedBox(width: 6),
                      Text(
                        isBn ? 'জাতীয় নাগরিক ডেডলাইন ও সুযোগ রাডার' : 'National Citizen Deadlines & Welfare Radar',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryGreen,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isBn ? 'আসন্ন সরকারি সময়সীমা ও সুযোগ' : 'Upcoming Government Deadlines & Opportunities',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isBn
                        ? 'ট্যাক্স রিটার্ন, শিক্ষা উপবৃত্তি, সমাজকল্যাণ ভাতা কিংবা লাইসেন্স নবায়নের সরকারি শেষ তারিখগুলো এখানে আগে থেকে জানিয়ে দেওয়া হয়।'
                        : 'Stay ahead of national deadlines for tax filing, educational stipends, social allowances, and annual license renewals.',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Filter Chips
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
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primaryGreen : AppColors.bgMuted,
                                border: Border.all(
                                  color: isSelected ? AppColors.primaryGreen : AppColors.border,
                                ),
                              ),
                              child: Text(
                                isBn ? cat['labelBn']! : cat['labelEn']!,
                                style: GoogleFonts.notoSansBengali(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // SPECIAL FEATURE: DEDICATED TAX ASSISTANT PANEL (from DeadlinesView.tsx)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED), // orange-50
                border: Border.all(color: const Color(0xFFFDBA74), width: 1.5), // orange-300
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        color: const Color(0xFFEA580C), // orange-600
                        child: const Icon(Icons.receipt_long, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  color: const Color(0xFFFED7AA), // orange-200
                                  child: Text(
                                    isBn ? 'জাতীয় আয়কর সহকারী' : 'TAX & DEADLINE ASSISTANT',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF7C2D12),
                                    ),
                                  ),
                                ),
                                Text(
                                  isBn ? 'শেষ তারিখ: ৩০ নভেম্বর ২০২৬' : 'Deadline: Nov 30, 2026',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF9A3412),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isBn ? 'বার্ষিক আয়কর রিটার্ন দাখিলের বিশেষ নির্দেশিকা' : 'Annual Income Tax Return Special Filing Guide',
                              style: GoogleFonts.notoSansBengali(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isBn
                        ? 'কাদের জন্য রিটার্ন বাধ্যতামূলক? টিআইএন (TIN) সার্টিফিকেটধারী, মোটরগাড়ি মালিক, সিটি কর্পোরেশনে ট্রেড লাইসেন্সধারী এবং ৫০,০০০+ টাকার সঞ্চয়পত্র ক্রয়কারী ব্যক্তিদের ৩০ নভেম্বরের মধ্যে রিটার্ন জমা দেওয়া বাধ্যতামূলক।'
                        : 'Mandatory filing for TIN holders, vehicle owners, trade license holders, and savings cert purchasers over ৳50,000 before November 30.',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 12,
                      color: const Color(0xFF431407),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tax Checklist Strip
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      _buildTaxCheckItem(isBn ? 'বেতন বা আয়ের প্রমাণপত্র (Salary Cert)' : 'Salary & Income Proof'),
                      _buildTaxCheckItem(isBn ? 'ব্যাংক হিসাব বিবরণী (Bank Statement)' : 'Bank Statement'),
                      _buildTaxCheckItem(isBn ? 'সঞ্চয়পত্র বা বিনিয়োগ সনদ' : 'Investment & Savings Cert'),
                      _buildTaxCheckItem(isBn ? 'সম্পদ ও দায়ের বিবরণ (Asset Statement)' : 'Asset Statement'),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Actions: Go to eTax NBR Portal & Dishari Tax Guide
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _openLink('https://etaxnbr.gov.bd'),
                        icon: const Icon(Icons.open_in_new, size: 13),
                        label: Text(
                          isBn ? 'ই-ট্যাক্স এনবিআর পোর্টালে যান' : 'Go to eTax NBR Portal',
                          style: GoogleFonts.notoSansBengali(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEA580C),
                          foregroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ServiceDetailScreen(slug: 'tax-return'),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        child: Text(
                          isBn ? 'ট্যাক্স গাইড দেখুন' : 'Dishari Tax Guide',
                          style: GoogleFonts.notoSansBengali(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Deadlines List
            if (filteredDeadlines.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  isBn ? 'কোনো ডেডলাইন পাওয়া যায়নি' : 'No deadlines found',
                  style: GoogleFonts.notoSansBengali(color: AppColors.textMuted),
                ),
              ),
            ] else ...[
              ...filteredDeadlines.map((item) {
                final isUrgent = item.urgency == 'high';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    border: Border(
                      top: BorderSide(
                        color: isUrgent ? AppColors.primaryRed : AppColors.primaryGreen,
                        width: 3,
                      ),
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isUrgent ? AppColors.lightRed50 : AppColors.lightGreen50,
                              border: Border.all(
                                color: isUrgent ? Colors.red.shade200 : const Color(0xFFA7F3D0),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isUrgent ? Icons.warning_amber : Icons.calendar_today,
                                  size: 11,
                                  color: isUrgent ? AppColors.primaryRed : AppColors.primaryGreen,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isUrgent
                                      ? (isBn ? 'জরুরি ডেডলাইন' : 'High Urgency')
                                      : (isBn ? 'চলমান কার্যক্রম' : 'Ongoing Cycle'),
                                  style: GoogleFonts.notoSansBengali(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isUrgent ? AppColors.primaryRed : AppColors.primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 12, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                item.deadline,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isUrgent ? AppColors.primaryRed : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Text(
                        isBn ? item.titleBn : item.titleEn,
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isBn ? item.descriptionBn : item.descriptionEn,
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          if (item.officialLink != null && item.officialLink!.isNotEmpty) ...[
                            OutlinedButton.icon(
                              onPressed: () => _openLink(item.officialLink),
                              icon: const Icon(Icons.open_in_new, size: 12),
                              label: Text(
                                isBn ? 'অফিসিয়াল তথ্য' : 'Official Portal',
                                style: GoogleFonts.notoSansBengali(fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textPrimary,
                                shape: const RoundedRectangleBorder(),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          ElevatedButton(
                            onPressed: () {
                              final slug = item.category == 'tax'
                                  ? 'tax-return'
                                  : item.category == 'education'
                                      ? 'scholarship'
                                      : 'trade-license';
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ServiceDetailScreen(slug: slug),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              foregroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            child: Text(
                              isBn ? 'সেবা বিস্তারিত' : 'View Service',
                              style: GoogleFonts.notoSansBengali(fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTaxCheckItem(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, size: 14, color: Color(0xFFEA580C)),
        const SizedBox(width: 5),
        Text(
          text,
          style: GoogleFonts.notoSansBengali(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF431407),
          ),
        ),
      ],
    );
  }
}
