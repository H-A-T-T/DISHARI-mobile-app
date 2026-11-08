import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/language_provider.dart';

class DeadlinesTab extends StatelessWidget {
  const DeadlinesTab({super.key});

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

    final deadlines = dashboard.deadlines;

    return RefreshIndicator(
      onRefresh: () => dashboard.loadDashboardData(auth.user?.id, isDemo: auth.user?.id == 1),
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
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
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
            const SizedBox(height: 14),

            // Deadlines Cards List
            if (deadlines.isEmpty)
              Container(
                padding: const EdgeInsets.all(28),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.event_available, size: 36, color: AppColors.textMuted),
                    const SizedBox(height: 8),
                    Text(
                      isBn ? 'এই মুহূর্তে কোনো জরুরি ডেডলাইন নেই' : 'No urgent deadlines at the moment',
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
                itemCount: deadlines.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = deadlines[index];
                  final isUrgent = item.isUrgent;

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      border: Border(
                        top: BorderSide(
                          color: isUrgent ? AppColors.primaryRed : AppColors.primaryGreen,
                          width: 3,
                        ),
                        left: const BorderSide(color: AppColors.border, width: 1),
                        right: const BorderSide(color: AppColors.border, width: 1),
                        bottom: const BorderSide(color: AppColors.border, width: 1),
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
                              color: isUrgent ? AppColors.lightRed50 : AppColors.lightGreen50,
                              child: Text(
                                isUrgent
                                    ? (isBn ? 'জরুরি শেষ তারিখ' : 'Critical Deadline')
                                    : (isBn ? 'আসন্ন সময়সীমা' : 'Upcoming Deadline'),
                                style: GoogleFonts.notoSansBengali(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isUrgent ? AppColors.primaryRed : AppColors.primaryGreen,
                                ),
                              ),
                            ),
                            Text(
                              isBn
                                  ? AppConstants.toBengaliNumber(item.deadline)
                                  : item.deadline,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isUrgent ? AppColors.primaryRed : AppColors.textSecondary,
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
                                      isBn ? 'বিস্তারিত পোর্টাল' : 'Official Portal',
                                      style: GoogleFonts.notoSansBengali(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryGreen,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.open_in_new, size: 12, color: AppColors.primaryGreen),
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
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
