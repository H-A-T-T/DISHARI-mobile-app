import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/constants.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/language_provider.dart';

class ApplicationsTab extends StatelessWidget {
  const ApplicationsTab({super.key});

  Future<void> _openPortal(String? url) async {
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
    final dashboard = context.watch<DashboardProvider>();
    final isBn = langProvider.isBn;

    final applications = dashboard.applications;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    const Icon(Icons.assignment_outlined, size: 18, color: AppColors.primaryGreen),
                    const SizedBox(width: 8),
                    Text(
                      isBn ? 'আমার সরকারি আবেদন ডকেটসমূহ' : 'My Citizen Application Dockets',
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
                      ? 'দিশারীর মাধ্যমে প্রস্তুতকৃত সরকারি আবেদনসমূহের বর্তমান অবস্থা এবং সংরক্ষিত কপি।'
                      : 'Current status and printable docket copies prepared through Dishari.',
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

          // Applications List
          if (applications.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const Icon(Icons.assignment_late_outlined, size: 36, color: AppColors.textMuted),
                  const SizedBox(height: 8),
                  Text(
                    isBn ? 'এখনও কোনো আবেদন ডকেট তৈরি হয়নি' : 'No application dockets created yet',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isBn
                        ? 'যেকোনো সেবার বিস্তারিত পাতায় গিয়ে "স্বয়ংক্রিয় আবেদন ও ডকেট প্রস্তুত করুন" চাপুন।'
                        : 'Visit any service guide page and tap "Auto-Generate Application Docket".',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: applications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final app = applications[index];
                return Container(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Docket ID & Status Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            color: AppColors.bgMuted,
                            child: Text(
                              app.docketId,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            color: AppColors.lightGreen50,
                            child: Text(
                              app.getStatusDisplay(isBn),
                              style: GoogleFonts.notoSansBengali(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Service Title
                      Text(
                        isBn ? app.serviceNameBn : app.serviceNameEn,
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Attached docs count
                      if (app.documentsAttached.isNotEmpty)
                        Text(
                          isBn
                              ? 'সংযুক্ত কাগজ: ${app.documentsAttached.join(", ")}'
                              : 'Attached: ${app.documentsAttached.join(", ")}',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 10),

                      // Action button
                      if (app.officialPortalUrl != null && app.officialPortalUrl!.isNotEmpty)
                        Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: () => _openPortal(app.officialPortalUrl),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              color: AppColors.darkGreen,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    isBn ? 'অফিসিয়াল পোর্টাল' : 'Official Portal',
                                    style: GoogleFonts.notoSansBengali(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.open_in_new, size: 12, color: Colors.white),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
