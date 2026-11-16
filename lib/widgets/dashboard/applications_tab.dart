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

  void _showDocketModal(BuildContext context, app, bool isBn) {
    final applicant = app.applicantData;
    final name = applicant['name']?.toString() ?? (isBn ? 'নাগরিক আবেদনকারী' : 'Citizen Applicant');
    final phone = applicant['phone']?.toString() ?? '—';
    final nid = applicant['nid']?.toString() ?? applicant['birth_reg']?.toString() ?? '—';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.primaryGreen, width: 4),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Title & Close
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryGreen.withValues(alpha: 0.1),
                        ),
                        child: const Icon(Icons.shield_outlined, size: 20, color: AppColors.primaryGreen),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isBn ? 'নাগরিক আবেদন ডকেট স্লিপ' : 'Official Application Docket Slip',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Docket ID Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.bgMuted,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isBn ? 'ডকেট ট্র্যাকিং নম্বর:' : 'Docket ID:',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      app.docketId,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Service Name
              Text(
                isBn ? app.serviceNameBn : app.serviceNameEn,
                style: GoogleFonts.notoSansBengali(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // Status Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.lightGreen50,
                  border: Border.all(color: AppColors.primaryGreen, width: 0.8),
                ),
                child: Text(
                  '${isBn ? 'অবস্থা:' : 'Status:'} ${app.getStatusDisplay(isBn)}',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Applicant Details
              Text(
                isBn ? 'আবেদনকারীর তথ্য' : 'Applicant Information',
                style: GoogleFonts.notoSansBengali(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildRow(isBn ? 'নাম:' : 'Name:', name),
                    const Divider(height: 12),
                    _buildRow(isBn ? 'মোবাইল:' : 'Phone:', phone),
                    const Divider(height: 12),
                    _buildRow(isBn ? 'পরিচয়পত্র নম্বর:' : 'ID / NID:', nid),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Attached Documents
              if (app.documentsAttached.isNotEmpty) ...[
                Text(
                  isBn ? 'সংযুক্ত নথিপত্র' : 'Attached Documents',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: (app.documentsAttached as List<String>)
                        .map(
                          (doc) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, size: 14, color: AppColors.primaryGreen),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    doc,
                                    style: GoogleFonts.notoSansBengali(
                                      fontSize: 12,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Advisory Notice Box
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  border: Border.all(color: const Color(0xFFF59E0B), width: 0.8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 15, color: Color(0xFFB45309)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isBn
                            ? 'দিশারী নিশ্চিত করে যে আপনার আবেদনটি প্রস্তুত। সরকারি যাচাইয়ের জন্য মূল কাগজপত্র সঙ্গে রাখুন।'
                            : 'Dishari confirms this docket has been generated. Keep original documents ready for official verification.',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 11,
                          color: const Color(0xFF92400E),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  if (app.officialPortalUrl != null && app.officialPortalUrl!.isNotEmpty)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openPortal(app.officialPortalUrl),
                        icon: const Icon(Icons.open_in_new, size: 14),
                        label: Text(
                          isBn ? 'অফিসিয়াল পোর্টাল' : 'Official Portal',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  if (app.officialPortalUrl != null && app.officialPortalUrl!.isNotEmpty)
                    const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: Text(
                        isBn ? 'বন্ধ করুন' : 'Close',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.notoSansBengali(fontSize: 12, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: GoogleFonts.notoSansBengali(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
      ],
    );
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

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          InkWell(
                            onTap: () => _showDocketModal(context, app, isBn),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: AppColors.primaryGreen, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.receipt_long, size: 13, color: AppColors.primaryGreen),
                                  const SizedBox(width: 4),
                                  Text(
                                    isBn ? 'ডকেট স্লিপ' : 'View Docket',
                                    style: GoogleFonts.notoSansBengali(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (app.officialPortalUrl != null && app.officialPortalUrl!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            InkWell(
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
                          ],
                        ],
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
