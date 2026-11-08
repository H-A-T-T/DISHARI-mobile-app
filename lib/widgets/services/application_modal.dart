import 'package:flutter/material.dart';
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
    });

    final user = auth.user;
    final docs = dashboard.documents;

    // Match attached documents
    final List<String> attachedDocs = [];
    for (var doc in widget.service.requiredDocs) {
      final isMatched = docs.any((ud) => _matchesRequiredDoc(doc, ud));
      if (isMatched) {
        attachedDocs.add(doc.nameBn);
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

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        if (result.success && result.application != null) {
          _createdApp = result.application;
        } else {
          _errorMsg = result.error ?? (isBn ? 'কার্যপত্র তৈরিতে সমস্যা হয়েছে' : 'Failed to generate docket');
        }
      });
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
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: AppColors.textPrimary),
                  onPressed: () => Navigator.pop(context),
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
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
}
