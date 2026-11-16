import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/constants.dart';
import '../../models/service.dart';
import '../../models/document.dart';
import '../../models/application.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/language_provider.dart';
import '../common/jonobondhu_chat_overlay.dart';

class ApplicationModal extends StatefulWidget {
  final Service service;

  const ApplicationModal({
    super.key,
    required this.service,
  });

  static Future<void> show(BuildContext context, Service service) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ApplicationModal(service: service),
    );
  }

  @override
  State<ApplicationModal> createState() => _ApplicationModalState();
}

class _ApplicationModalState extends State<ApplicationModal> {
  bool _isSubmitting = false;
  int _botStep = 0;
  CitizenApplication? _createdApp;
  String? _errorMsg;

  bool _matchesRequiredDoc(RequiredDoc doc, CitizenDocument d) {
    final nameBn = doc.nameBn;
    final nameEn = doc.nameEn.toLowerCase();
    if ((nameBn.contains('পরিচয়পত্র') || nameBn.contains('NID') || nameEn.contains('nid') || nameEn.contains('national id')) &&
        (d.docType == 'nid_front' || d.docType == 'nid_back')) {
      return true;
    }
    if ((nameBn.contains('জন্ম নিবন্ধন') || nameEn.contains('birth')) && d.docType == 'birth_certificate') {
      return true;
    }
    if ((nameBn.contains('ছবি') || nameEn.contains('photo')) && d.docType == 'photo') {
      return true;
    }
    if ((nameBn.contains('টিআইএন') || nameBn.contains('TIN') || nameEn.contains('tin')) && d.docType == 'tin_certificate') {
      return true;
    }
    if ((nameBn.contains('ট্রেড লাইসেন্স') || nameEn.contains('trade license')) && d.docType == 'trade_license') {
      return true;
    }
    if ((nameBn.contains('নাগরিকত্ব') || nameEn.contains('citizenship')) && d.docType == 'citizenship_certificate') {
      return true;
    }
    return false;
  }

  Future<void> _handleGenerateDocket() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final dashboard = Provider.of<DashboardProvider>(context, listen: false);
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isBn = langProvider.isBn;

    setState(() {
      _isSubmitting = true;
      _errorMsg = null;
      _botStep = 1;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) setState(() => _botStep = 2);
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) setState(() => _botStep = 3);

      final user = auth.user;
      final docs = dashboard.documents;

      // Match attached documents
      final List<String> attachedDocs = [];
      for (var doc in widget.service.requiredDocs) {
        final isMatched = docs.any((ud) => _matchesRequiredDoc(doc, ud));
        if (isMatched) {
          attachedDocs.add(isBn ? doc.nameBn : doc.nameEn);
        }
      }

      final result = await dashboard.createApplication(
        userId: user?.id ?? 1,
        serviceSlug: widget.service.slug,
        serviceNameBn: widget.service.nameBn,
        serviceNameEn: widget.service.nameEn,
        applicantData: {
          'fullName': user?.fullName ?? 'নাগরিক',
          'phone': user?.phone ?? '',
          'email': user?.email ?? '',
          'citizenId': auth.citizenId,
        },
        documentsAttached: attachedDocs,
        officialPortalUrl: widget.service.officialUrl,
      );

      if (mounted) setState(() => _botStep = 4);
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _botStep = 0;
          if (result.success && result.application != null) {
            _createdApp = result.application;
          } else {
            _errorMsg = result.error ??
                (isBn ? 'কার্যপত্র তৈরিতে সমস্যা হয়েছে' : 'Failed to generate docket');
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _botStep = 0;
          _errorMsg = isBn ? 'কার্যপত্র তৈরিতে সমস্যা হয়েছে' : 'Failed to generate docket';
        });
      }
    }
  }

  Future<void> _openOfficialPortal() async {
    final url = widget.service.officialUrl;
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
    final dashboard = context.watch<DashboardProvider>();
    final isBn = langProvider.isBn;

    final user = auth.user;
    final docs = dashboard.documents;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(
          top: BorderSide(color: AppColors.primaryGreen, width: 3),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modal Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_user_outlined, size: 20, color: AppColors.primaryGreen),
                    const SizedBox(width: 8),
                    Text(
                      isBn ? 'স্বয়ংক্রিয় আবেদন ডকেট' : 'Auto Application Docket',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        JonobondhuChatOverlay.openChat(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.lightGreen50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primaryGreen, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              'assets/icons/jonobondhu.svg',
                              width: 14,
                              height: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isBn ? 'জনবন্ধু AI' : 'Jonobondhu',
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
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: AppColors.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(color: AppColors.border),
            const SizedBox(height: 12),

            // If Docket already created, show success screen
            if (_createdApp != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: AppColors.lightGreen50,
                  border: Border(
                    left: BorderSide(color: AppColors.primaryGreen, width: 3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, size: 18, color: AppColors.primaryGreen),
                        const SizedBox(width: 8),
                        Text(
                          isBn ? 'আবেদন ডকেট সফলভাবে প্রস্তুত!' : 'Application Docket Ready!',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isBn
                          ? 'আপনার ট্র্যাকিং ডকেট নম্বর: ${_createdApp!.docketId}। প্রয়োজনীয় তথ্যাবলী স্বয়ংক্রিয়ভাবে অন্তর্ভুক্ত হয়েছে।'
                          : 'Your docket tracking ID: ${_createdApp!.docketId}. Information has been securely compiled.',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons: Official Portal & Done
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openOfficialPortal,
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: Text(
                    isBn ? 'অফিসিয়াল সরকারি পোর্টালে যান' : 'Go to Official Government Portal',
                    style: GoogleFonts.notoSansBengali(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const RoundedRectangleBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: const RoundedRectangleBorder(),
                  ),
                  child: Text(
                    isBn ? 'ড্যাশবোর্ডে সংরক্ষণ দেখুন' : 'View in Saved Dockets',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Docket Generation Form
              Text(
                isBn ? widget.service.nameBn : widget.service.nameEn,
                style: GoogleFonts.notoSansBengali(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                isBn ? widget.service.departmentBn : widget.service.departmentEn,
                style: GoogleFonts.notoSansBengali(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),

              // Applicant summary box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgMuted,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBn ? 'নাগরিক তথ্য (প্রোফাইল থেকে সংগৃহীত):' : 'Citizen Info (From Profile):',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          user?.fullName ?? (isBn ? 'ডেমো নাগরিক' : 'Demo Citizen'),
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          auth.citizenId,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                    if (user?.phone.isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Text(
                        user!.phone,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Attached documents checklist
              Text(
                isBn ? 'সংযুক্ত নথিপত্র (নাগরিক লকার থেকে):' : 'Attached Documents (From Locker):',
                style: GoogleFonts.notoSansBengali(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              ...widget.service.requiredDocs.map((doc) {
                final hasDoc = docs.any((d) => _matchesRequiredDoc(doc, d));

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        hasDoc ? Icons.check_circle : Icons.radio_button_unchecked,
                        size: 16,
                        color: hasDoc ? AppColors.primaryGreen : AppColors.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isBn ? doc.nameBn : doc.nameEn,
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 12,
                            color: hasDoc ? AppColors.textPrimary : AppColors.textMuted,
                            fontWeight: hasDoc ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        color: hasDoc ? AppColors.lightGreen50 : AppColors.bgMuted,
                        child: Text(
                          hasDoc
                              ? (isBn ? 'সংযুক্ত' : 'Attached')
                              : (isBn ? 'লকারে নেই' : 'Missing'),
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: hasDoc ? AppColors.primaryGreen : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),

              if (_errorMsg != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _errorMsg!,
                    style: GoogleFonts.notoSansBengali(fontSize: 12, color: AppColors.primaryRed),
                  ),
                ),

              // Invisible Bot Live Automation Terminal
              if (_isSubmitting) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF171717),
                    border: Border.all(color: AppColors.primaryGreen, width: 2),
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
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF34D399),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isBn
                                    ? 'অদৃশ্য অটোমেশন বট রানিং...'
                                    : 'Invisible Bot Worker Running...',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF34D399),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Playwright Worker #01',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              color: const Color(0xFFA3A3A3),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(color: Color(0xFF404040), height: 1),
                      const SizedBox(height: 8),
                      _buildBotStepRow(
                        step: 1,
                        currentStep: _botStep,
                        text: isBn
                            ? 'সরকারি পোর্টাল সংযোগ স্থাপন ও সেশন শুরু...'
                            : 'Connecting to govt gateway & starting session...',
                      ),
                      const SizedBox(height: 5),
                      _buildBotStepRow(
                        step: 2,
                        currentStep: _botStep,
                        text: isBn
                            ? 'নাগরিক প্রোফাইল থেকে সকল ফর্ম ফিল্ড স্বয়ংক্রিয় পূরণ...'
                            : 'Autofilling form fields from citizen profile...',
                      ),
                      const SizedBox(height: 5),
                      _buildBotStepRow(
                        step: 3,
                        currentStep: _botStep,
                        text: isBn
                            ? 'ডিজিটাল লকার থেকে প্রয়োজনীয় ডকুমেন্টস এনক্রিপ্ট করে সংযুক্ত...'
                            : 'Attaching verified documents from digital locker...',
                      ),
                      const SizedBox(height: 5),
                      _buildBotStepRow(
                        step: 4,
                        currentStep: _botStep,
                        text: isBn
                            ? 'সার্ভার ভেরিফিকেশন ও অফিসিয়াল ট্র্যাকিং ডকেট জেনারেশন সম্পন্ন!'
                            : 'Server verification complete & official tracking logged!',
                      ),
                    ],
                  ),
                ),
              ],

              // Generate Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleGenerateDocket,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const RoundedRectangleBorder(),
                  ),
                  child: _isSubmitting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              height: 14,
                              width: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isBn ? 'স্বয়ংক্রিয় পূরণ চলছে...' : 'Autofilling in progress...',
                              style: GoogleFonts.notoSansBengali(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          isBn ? 'ডকেট প্রস্তুত ও নিশ্চিত করুন' : 'Confirm & Generate Docket',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBotStepRow({
    required int step,
    required int currentStep,
    required String text,
  }) {
    final isDone = currentStep > step;
    final isCurrent = currentStep == step;

    final color = isDone || isCurrent
        ? const Color(0xFF6EE7B7)
        : const Color(0xFF737373);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isDone ? '✓ ' : (isCurrent ? '➜ ' : '○ '),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.notoSansBengali(
              fontSize: 10,
              color: color,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
