import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/constants.dart';
import '../../models/application.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/language_provider.dart';
import '../../screens/services_screen.dart';
import '../common/jonobondhu_chat_overlay.dart';

class ApplicationsTab extends StatelessWidget {
  final Function(int targetTab)? onNavigateTab;

  const ApplicationsTab({super.key, this.onNavigateTab});

  void _goToServices(BuildContext context) {
    if (onNavigateTab != null) {
      onNavigateTab!(1);
    } else if (JonobondhuChatOverlay.globalNavigateTab != null) {
      JonobondhuChatOverlay.globalNavigateTab!(1);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ServicesScreen()),
      );
    }
  }

  Future<void> _openPortal(String? url) async {
    if (url != null && url.isNotEmpty && url != '#') {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  void _showDocketSlipDialog(BuildContext context, CitizenApplication app, bool isBn) {
    final applicant = app.applicantData;
    final fullName = applicant['fullName']?.toString() ??
        applicant['name']?.toString() ??
        (isBn ? 'নাগরিক' : 'Citizen');
    final citizenId = applicant['citizenId']?.toString() ??
        applicant['nid']?.toString() ??
        app.docketId;
    final phone = applicant['phone']?.toString() ?? '—';
    final dob = applicant['dob']?.toString();
    final father = applicant['fatherName']?.toString();
    final mother = applicant['motherName']?.toString();
    final blood = applicant['bloodGroup']?.toString();
    final address = applicant['address']?.toString();
    final roll = applicant['roll']?.toString();
    final board = applicant['board']?.toString();
    final regNo = applicant['regNo']?.toString();

    final attachedDocs = app.documentsAttached.isNotEmpty
        ? app.documentsAttached
        : [isBn ? 'জাতীয় পরিচয়পত্র' : 'National ID', isBn ? 'পাসপোর্ট সাইজ ছবি' : 'Photo'];

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(),
        insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(18),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(height: 3, color: AppColors.primaryGreen, margin: const EdgeInsets.only(bottom: 12)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isBn
                                ? 'গণপ্রজাতন্ত্রী বাংলাদেশ নাগরিক সেবা কার্যপত্র'
                                : 'Government Citizen Service Assistance Docket',
                            style: GoogleFonts.notoSansBengali(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${app.serviceNameBn} (${app.serviceNameEn})',
                            style: GoogleFonts.notoSansBengali(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.bgMuted,
                            border: Border.all(color: AppColors.textPrimary),
                          ),
                          child: Text(
                            app.docketId,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          app.submittedAt.split('T').first,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Section 1: Applicant Information
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: const BoxDecoration(
                    color: AppColors.bgMuted,
                    border: Border(left: BorderSide(color: AppColors.primaryGreen, width: 3)),
                  ),
                  child: Text(
                    isBn ? '১. আবেদনকারীর পরিচিতি ও বিবরণ' : '1. Applicant Information',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                _buildDataRow(isBn ? 'নাগরিক নাম:' : 'Name:', fullName),
                _buildDataRow(isBn ? 'জাতীয় পরিচয়পত্র / আইডি:' : 'Citizen ID / NID:', citizenId),
                if (dob != null) _buildDataRow(isBn ? 'জন্মতারিখ:' : 'DOB:', dob),
                if (father != null) _buildDataRow(isBn ? 'পিতার নাম:' : "Father's Name:", father),
                if (mother != null) _buildDataRow(isBn ? 'মাতার নাম:' : "Mother's Name:", mother),
                if (blood != null) _buildDataRow(isBn ? 'রক্তের গ্রুপ:' : 'Blood Group:', blood),
                if (roll != null) _buildDataRow(isBn ? 'রোল ও শিক্ষা বোর্ড:' : 'Roll & Board:', 'রোল: $roll, রেজি: ${regNo ?? ''} (${board ?? ''})'),
                if (address != null) _buildDataRow(isBn ? 'ঠিকানা:' : 'Address:', address),
                _buildDataRow(isBn ? 'মোবাইল:' : 'Phone:', phone),
                _buildDataRow(
                  isBn ? 'স্থিতি:' : 'Status:',
                  '✓ ${app.status.toUpperCase()} (কার্যপত্র প্রস্তুত)',
                  isGreen: true,
                ),
                const SizedBox(height: 12),

                // Section 2: Attached Documents
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: const BoxDecoration(
                    color: AppColors.bgMuted,
                    border: Border(left: BorderSide(color: AppColors.primaryGreen, width: 3)),
                  ),
                  child: Text(
                    isBn ? '২. সংযুক্ত নথিপত্র ও লকার নিরীক্ষা' : '2. Attached Documents & Vault Audit',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                ...attachedDocs.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Text('${entry.key + 1}. ', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted)),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: GoogleFonts.notoSansBengali(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          '✓ যাচাইকৃত',
                          style: GoogleFonts.notoSansBengali(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primaryGreen),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),

                // Counter Slip Section
                Container(
                  padding: const EdgeInsets.only(top: 10),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.black26, width: 1)),
                  ),
                  child: Column(
                    children: [
                      Center(
                        child: Text(
                          isBn
                              ? '— — — ইউনিয়ন পরিষদ / উপজেলা / ডাকঘর কাউন্টার প্রাপ্তিস্বীকার অংশ — — —'
                              : '— — — Official Counter Receipt Slip — — —',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.only(top: 4),
                              decoration: const BoxDecoration(
                                border: Border(top: BorderSide(color: Colors.black87, width: 1)),
                              ),
                              child: Text(
                                isBn ? 'আবেদনকারী নাগরিকের স্বাক্ষর' : 'Citizen Applicant Signature',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.notoSansBengali(fontSize: 10, color: AppColors.textSecondary),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.only(top: 4),
                              decoration: const BoxDecoration(
                                border: Border(top: BorderSide(color: Colors.black87, width: 1)),
                              ),
                              child: Text(
                                isBn ? 'গ্রহণকারী কর্মকর্তার সিল ও স্বাক্ষর' : 'Receiving Officer Seal & Signature',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.notoSansBengali(fontSize: 10, color: AppColors.textSecondary),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Footer Note
                Center(
                  child: Text(
                    isBn
                        ? 'এই কার্যপত্রটি সরকারি সিটিজেন চার্টার অনুযায়ী প্রস্তুতকৃত। কোনো দালাল বা মধ্যস্বত্বভোগীর প্রয়োজন নেই।'
                        : 'Generated strictly in accordance with Bangladesh Citizen Charter. Official direct processing.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSansBengali(fontSize: 9, color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: const RoundedRectangleBorder(),
                    ),
                    child: Text(
                      isBn ? 'বন্ধ করুন' : 'Close',
                      style: GoogleFonts.notoSansBengali(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value, {bool isGreen = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: GoogleFonts.notoSansBengali(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.notoSansBengali(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isGreen ? AppColors.primaryGreen : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
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
          // Top Banner (Windows 10 Flat Tile)
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
                Text(
                  isBn ? 'আবেদন ট্র্যাকিং কেন্দ্র' : 'APPLICATION TRACKING CENTER',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryGreen,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isBn ? 'আমার সরকারি আবেদনসমূহ' : 'My Government Applications',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isBn
                      ? 'এখানে আপনার সকল প্রস্তুতকৃত আবেদন ডকেট, ট্র্যাকিং নম্বর ও কাউন্টার স্লিপ সংরক্ষিত আছে।'
                      : 'All your prepared application dockets, tracking IDs, and official counter slips stored in one place.',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () => _goToServices(context),
                  icon: const Icon(Icons.add, size: 14),
                  label: Text(
                    isBn ? 'নতুন সেবা বেছে নিন' : 'Apply For Service',
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

          // Applications List
          if (applications.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    color: AppColors.bgMuted,
                    child: const Icon(Icons.assignment_outlined, size: 24, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isBn ? 'বর্তমানে কোনো সক্রিয় আবেদন প্রক্রিয়াধীন নেই' : 'No active applications in progress',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isBn
                        ? 'যেকোনো সরকারি সেবার পেজে গিয়ে "আবেদন শুরু করুন" বাটনে ক্লিক করলে স্বয়ংক্রিয়ভাবে একটি আবেদন ডকেট তৈরি হবে।'
                        : 'Visit any government service page and click "Start Application" to create a pre-filled docket.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _goToServices(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: Text(
                      isBn ? 'সেবাসমূহ দেখুন' : 'Explore All Services',
                      style: GoogleFonts.notoSansBengali(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ...applications.map((app) {
              final date = app.submittedAt.split('T').first;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
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
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          color: AppColors.bgMuted,
                          child: Text(
                            'DOCKET: ${app.docketId}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.lightGreen50,
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle, size: 10, color: AppColors.primaryGreen),
                              const SizedBox(width: 3),
                              Text(
                                isBn ? 'আবেদন প্রস্তুত' : 'Ready / Active',
                                style: GoogleFonts.notoSansBengali(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${isBn ? 'তারিখ:' : 'Date:'} $date',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Text(
                      isBn ? app.serviceNameBn : app.serviceNameEn,
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isBn
                          ? 'নাগরিক লকার থেকে প্রয়োজনীয় সকল কাগজপত্র ও বিবরণ সফলভাবে সংযুক্ত হয়েছে।'
                          : 'All required documents and citizen credentials prefilled from personal locker.',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _showDocketSlipDialog(context, app, isBn),
                          icon: const Icon(Icons.print_outlined, size: 14),
                          label: Text(
                            isBn ? 'কাউন্টার ফরম প্রিন্ট' : 'Print Docket',
                            style: GoogleFonts.notoSansBengali(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                        if (app.officialPortalUrl != null && app.officialPortalUrl!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => _openPortal(app.officialPortalUrl),
                            icon: const Icon(Icons.open_in_new, size: 12),
                            label: Text(
                              isBn ? 'সরকারি পোর্টাল' : 'Gov Portal',
                              style: GoogleFonts.notoSansBengali(fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              shape: const RoundedRectangleBorder(),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
