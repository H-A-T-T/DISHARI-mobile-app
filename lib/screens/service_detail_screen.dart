import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/constants.dart';
import '../models/service.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/language_provider.dart';
import '../providers/services_provider.dart';
import '../services/api_service.dart';
import '../widgets/services/application_modal.dart';

class ServiceDetailScreen extends StatefulWidget {
  final String slug;

  const ServiceDetailScreen({
    super.key,
    required this.slug,
  });

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  Service? _service;
  bool _isLoading = true;
  final Map<int, bool> _checkedDocs = {};

  @override
  void initState() {
    super.initState();
    _loadService();
  }

  Future<void> _loadService() async {
    setState(() => _isLoading = true);

    // Try finding in services provider first
    final provider = Provider.of<ServicesProvider>(context, listen: false);
    final match = provider.services.where((s) => s.slug == widget.slug).firstOrNull;

    if (match != null) {
      _service = match;
      setState(() => _isLoading = false);
    } else {
      final fetched = await ApiService.fetchServiceBySlug(widget.slug);
      if (mounted) {
        setState(() {
          _service = fetched;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openOfficialPortal(String url) async {
    if (url.isNotEmpty) {
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
    final isBn = langProvider.isBn;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isBn ? 'সেবা বিস্তারিত' : 'Service Details'),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
      );
    }

    if (_service == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isBn ? 'সেবা পাওয়া যায়নি' : 'Service Not Found'),
        ),
        body: Center(
          child: Text(
            isBn ? 'দুঃখিত, সেবাটির তথ্য পাওয়া যায়নি।' : 'Service information not found.',
            style: GoogleFonts.notoSansBengali(),
          ),
        ),
      );
    }

    final s = _service!;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        title: Text(
          isBn ? s.nameBn : s.nameEn,
          style: GoogleFonts.notoSansBengali(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Verified Portal Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: const BoxDecoration(
                color: AppColors.lightGreen50,
                border: Border(
                  left: BorderSide(color: AppColors.primaryGreen, width: 3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified, size: 14, color: AppColors.primaryGreen),
                  const SizedBox(width: 6),
                  Text(
                    langProvider.t('detail.verified'),
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Title and Department
            Text(
              isBn ? s.nameBn : s.nameEn,
              style: GoogleFonts.notoSansBengali(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isBn ? s.departmentBn : s.departmentEn,
              style: GoogleFonts.notoSansBengali(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // 3 Key Metrics Cards
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          langProvider.t('detail.officialFee'),
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppConstants.formatFee(s.fee, isBn),
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          langProvider.t('detail.time'),
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.processingTimeBn,
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          langProvider.t('detail.submissionMethod'),
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.submissionType == 'online_bot'
                              ? (isBn ? 'সম্পূর্ণ অনলাইন' : 'Fully Online')
                              : (isBn ? 'অনলাইন + যাচাই' : 'Hybrid'),
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Where to apply box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgMuted,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.place_outlined, size: 16, color: AppColors.primaryGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          langProvider.t('detail.where'),
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.applyLocationBn,
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Required Documents Interactive Checklist
            Text(
              langProvider.t('detail.requiredPapers'),
              style: GoogleFonts.notoSansBengali(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              langProvider.t('detail.papersSubtitle'),
              style: GoogleFonts.notoSansBengali(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            ...s.requiredDocs.asMap().entries.map((entry) {
              final idx = entry.key;
              final doc = entry.value;
              final isChecked = _checkedDocs[idx] ?? false;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isChecked ? AppColors.lightGreen50 : AppColors.bgSurface,
                  border: Border.all(
                    color: isChecked ? AppColors.primaryGreen : AppColors.border,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          _checkedDocs[idx] = !isChecked;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2, right: 8),
                        child: Icon(
                          isChecked ? Icons.check_box : Icons.check_box_outline_blank,
                          size: 18,
                          color: isChecked ? AppColors.primaryGreen : AppColors.textMuted,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  isBn ? doc.nameBn : doc.nameEn,
                                  style: GoogleFonts.notoSansBengali(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                color: AppColors.bgMuted,
                                child: Text(
                                  doc.copyType == 'both'
                                      ? (isBn ? 'মূল ও ফটোকপি' : 'Both')
                                      : doc.copyType == 'photocopy'
                                          ? (isBn ? 'ফটোকপি' : 'Copy')
                                          : (isBn ? 'মূল কপি' : 'Original'),
                                  style: GoogleFonts.notoSansBengali(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (doc.noteBn != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              doc.noteBn!,
                              style: GoogleFonts.notoSansBengali(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),

            // Step-by-Step Instructions
            Text(
              langProvider.t('detail.stepsTitle'),
              style: GoogleFonts.notoSansBengali(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            ...s.steps.map((st) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      color: AppColors.lightGreen50,
                      child: Text(
                        isBn ? AppConstants.toBengaliNumber(st.step) : '${st.step}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            st.titleBn,
                            style: GoogleFonts.notoSansBengali(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            st.descriptionBn,
                            style: GoogleFonts.notoSansBengali(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 14),

            // Important Notes
            if (s.importantNotesBn.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppColors.amber50,
                  border: Border(
                    left: BorderSide(color: AppColors.amber500, width: 3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: AppColors.amber500),
                        const SizedBox(width: 6),
                        Text(
                          langProvider.t('detail.importantNotes'),
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...s.importantNotesBn.map((n) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• $n',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 11,
                            color: const Color(0xFF92400E),
                            height: 1.4,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 90), // Bottom button bar clearance
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.bgSurface,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (!auth.isLoggedIn) {
                    await auth.loginAsDemoCitizen();
                    if (context.mounted) {
                      await Provider.of<DashboardProvider>(context, listen: false).seedDemoData();
                    }
                  }
                  if (context.mounted) {
                    ApplicationModal.show(context, s);
                  }
                },
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: Text(
                  langProvider.t('detail.autoApply'),
                  style: GoogleFonts.notoSansBengali(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: const RoundedRectangleBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: () => _openOfficialPortal(s.officialUrl),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: const RoundedRectangleBorder(),
                ),
                child: const Icon(Icons.open_in_new, size: 18, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
