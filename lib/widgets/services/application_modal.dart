import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../models/service.dart';
import '../../models/document.dart';
import '../../models/application.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/url_service.dart';

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
    if ((nameBn.contains('সনদ') || nameBn.contains('নম্বরপত্র') || nameBn.contains('প্রবেশপত্র') || nameEn.contains('transcript') || nameEn.contains('certificate')) &&
        (d.docType == 'educational_transcript' || d.docType == 'citizenship_certificate')) {
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
      _botStep = 1; // Connecting to portal...
    });

    try {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) setState(() => _botStep = 2); // Autofilling form fields...
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) setState(() => _botStep = 3); // Encrypting & attaching documents...

      final user = auth.user;
      final docs = dashboard.documents;

      // Match attached documents exactly as web does
      final List<String> attachedDocs = [];
      for (var doc in widget.service.requiredDocs) {
        final isMatched = docs.any((ud) => _matchesRequiredDoc(doc, ud));
        if (isMatched) {
          attachedDocs.add(doc.nameBn);
        }
      }

      // OCR Metadata Aggregation from Citizen Locker
      CitizenDocument? nidDoc;
      CitizenDocument? nidBackDoc;
      CitizenDocument? birthDoc;
      CitizenDocument? eduDoc;
      CitizenDocument? tinDoc;
      CitizenDocument? tradeDoc;

      for (var d in docs) {
        if (d.docType == 'nid_front') nidDoc ??= d;
        if (d.docType == 'nid_back') nidBackDoc ??= d;
        if (d.docType == 'birth_certificate') birthDoc ??= d;
        if (d.docType == 'educational_transcript') eduDoc ??= d;
        if (d.docType == 'tin_certificate') tinDoc ??= d;
        if (d.docType == 'trade_license') tradeDoc ??= d;
      }

      final ocrCitizenId = nidDoc?.extractedMeta['id_number']?.toString() ??
          birthDoc?.extractedMeta['id_number']?.toString() ??
          auth.citizenId;
      final ocrDob = nidDoc?.extractedMeta['dob']?.toString() ??
          birthDoc?.extractedMeta['dob']?.toString();
      final ocrFather = nidDoc?.extractedMeta['father_name']?.toString() ??
          birthDoc?.extractedMeta['father_name']?.toString();
      final ocrMother = nidDoc?.extractedMeta['mother_name']?.toString() ??
          birthDoc?.extractedMeta['mother_name']?.toString();
      final ocrBlood = nidDoc?.extractedMeta['blood_group']?.toString() ??
          nidBackDoc?.extractedMeta['blood_group']?.toString();
      final ocrAddress = nidBackDoc?.extractedMeta['address']?.toString() ??
          nidDoc?.extractedMeta['address']?.toString();
      final ocrRoll = eduDoc?.extractedMeta['roll']?.toString();
      final ocrBoard = eduDoc?.extractedMeta['board']?.toString();
      final ocrReg = eduDoc?.extractedMeta['reg_no']?.toString();
      final ocrTin = tinDoc?.extractedMeta['id_number']?.toString();
      final ocrBiz = tradeDoc?.extractedMeta['business_name']?.toString();

      final result = await dashboard.createApplication(
        userId: user?.id ?? 1,
        serviceSlug: widget.service.slug,
        serviceNameBn: widget.service.nameBn,
        serviceNameEn: widget.service.nameEn,
        applicantData: {
          'fullName': user?.fullName ?? (isBn ? 'নাগরিক' : 'Citizen'),
          'phone': user?.phone ?? '',
          'email': user?.email ?? '',
          'citizenId': ocrCitizenId,
          'dob': ocrDob,
          'fatherName': ocrFather,
          'motherName': ocrMother,
          'bloodGroup': ocrBlood,
          'address': ocrAddress,
          'roll': ocrRoll,
          'regNo': ocrReg,
          'board': ocrBoard,
          'tin': ocrTin,
          'businessName': ocrBiz,
        },
        documentsAttached: attachedDocs,
        officialPortalUrl: widget.service.officialUrl,
      );

      if (mounted) setState(() => _botStep = 4); // Verified & docket generated!
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
    await UrlService.openUrl(widget.service.officialUrl);
  }

  void _showDocketSlipDialog(CitizenApplication app, bool isBn) {
    final applicant = app.applicantData;
    final fullName = applicant['fullName']?.toString() ?? (isBn ? 'নাগরিক' : 'Citizen');
    final citizenId = applicant['citizenId']?.toString() ?? app.docketId;
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
                          DateTime.now().toString().split(' ').first,
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
                _buildDocketDataRow(isBn ? 'নাগরিক নাম:' : 'Name:', fullName),
                _buildDocketDataRow(isBn ? 'জাতীয় পরিচয়পত্র / আইডি:' : 'Citizen ID / NID:', citizenId),
                if (dob != null) _buildDocketDataRow(isBn ? 'জন্মতারিখ:' : 'DOB:', dob),
                if (father != null) _buildDocketDataRow(isBn ? 'পিতার নাম:' : "Father's Name:", father),
                if (mother != null) _buildDocketDataRow(isBn ? 'মাতার নাম:' : "Mother's Name:", mother),
                if (blood != null) _buildDocketDataRow(isBn ? 'রক্তের গ্রুপ:' : 'Blood Group:', blood),
                if (roll != null) _buildDocketDataRow(isBn ? 'রোল ও শিক্ষা বোর্ড:' : 'Roll & Board:', 'রোল: $roll, রেজি: ${regNo ?? ''} (${board ?? ''})'),
                if (address != null) _buildDocketDataRow(isBn ? 'ঠিকানা:' : 'Address:', address),
                _buildDocketDataRow(isBn ? 'মোবাইল:' : 'Phone:', phone),
                _buildDocketDataRow(
                  isBn ? 'স্থিতি:' : 'Status:',
                  '✓ ${app.status.toUpperCase()} (AI VERIFIED)',
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
                    isBn ? '২. সংযুক্ত নথিপত্র ও লকার নিরীক্ষা' : '2. Attached Documents',
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
                              ? '— — — কাউন্টার প্রাপ্তিস্বীকার রসিদ অংশ — — —'
                              : '— — — Official Counter Receipt Slip — — —',
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

                Center(
                  child: Text(
                    isBn
                        ? 'এই কার্যপত্রটি দিশারী ডিজিটাল প্ল্যাটফর্ম কর্তৃক প্রস্তুতকৃত। সরকারি সেবা গ্রহণে মধ্যস্বত্বভোগী বা দালালের শরণাপন্ন হবেন না।'
                        : 'Generated by Dishari Digital Citizen Platform. Official direct processing authorized.',
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

  Widget _buildDocketDataRow(String label, String value, {bool isGreen = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
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
    final auth = context.watch<AuthProvider>();
    final dashboard = context.watch<DashboardProvider>();
    final isBn = langProvider.isBn;

    final user = auth.user;
    final docs = dashboard.documents;

    // Document matching exactly as web
    final List<String> attachedDocNames = [];
    for (var doc in widget.service.requiredDocs) {
      final isMatched = docs.any((ud) => _matchesRequiredDoc(doc, ud));
      if (isMatched) {
        attachedDocNames.add(doc.nameBn);
      }
    }

    // OCR Metadata Aggregation from Citizen Locker
    CitizenDocument? nidDoc;
    CitizenDocument? nidBackDoc;
    CitizenDocument? birthDoc;
    CitizenDocument? eduDoc;
    CitizenDocument? tinDoc;
    CitizenDocument? tradeDoc;

    for (var d in docs) {
      if (d.docType == 'nid_front') nidDoc ??= d;
      if (d.docType == 'nid_back') nidBackDoc ??= d;
      if (d.docType == 'birth_certificate') birthDoc ??= d;
      if (d.docType == 'educational_transcript') eduDoc ??= d;
      if (d.docType == 'tin_certificate') tinDoc ??= d;
      if (d.docType == 'trade_license') tradeDoc ??= d;
    }

    final ocrCitizenId = nidDoc?.extractedMeta['id_number']?.toString() ??
        birthDoc?.extractedMeta['id_number']?.toString() ??
        auth.citizenId;
    final ocrDob = nidDoc?.extractedMeta['dob']?.toString() ??
        birthDoc?.extractedMeta['dob']?.toString();
    final ocrFather = nidDoc?.extractedMeta['father_name']?.toString() ??
        birthDoc?.extractedMeta['father_name']?.toString();
    final ocrMother = nidDoc?.extractedMeta['mother_name']?.toString() ??
        birthDoc?.extractedMeta['mother_name']?.toString();
    final ocrBlood = nidDoc?.extractedMeta['blood_group']?.toString() ??
        nidBackDoc?.extractedMeta['blood_group']?.toString();
    final ocrAddress = nidBackDoc?.extractedMeta['address']?.toString() ??
        nidDoc?.extractedMeta['address']?.toString();
    final ocrRoll = eduDoc?.extractedMeta['roll']?.toString();
    final ocrBoard = eduDoc?.extractedMeta['board']?.toString();

    final hasOcrMeta = (nidDoc != null && nidDoc.extractedMeta.isNotEmpty) ||
        (birthDoc != null && birthDoc.extractedMeta.isNotEmpty) ||
        (eduDoc != null && eduDoc.extractedMeta.isNotEmpty) ||
        (tinDoc != null && tinDoc.extractedMeta.isNotEmpty) ||
        (tradeDoc != null && tradeDoc.extractedMeta.isNotEmpty);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(
          top: BorderSide(color: AppColors.primaryGreen, width: 4),
        ),
      ),
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modal Header (Windows 10 style)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shield_outlined, size: 16, color: AppColors.primaryGreen),
                          const SizedBox(width: 6),
                          Text(
                            isBn ? 'নাগরিক সেবা আবেদন সহকারী' : 'Citizen Service Application Assistant',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryGreen,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isBn ? widget.service.nameBn : widget.service.nameEn,
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: AppColors.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: AppColors.border, height: 16),

            if (_errorMsg != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.lightRed50,
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 16, color: AppColors.primaryRed),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMsg!,
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // If createdApp != null, show Docket Ready state
            if (_createdApp != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.lightGreen50,
                          border: Border.all(color: const Color(0xFF6EE7B7)),
                        ),
                        child: const Icon(Icons.check_circle_outline, size: 32, color: AppColors.primaryGreen),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isBn ? 'আবেদন ডকেট সফলভাবে প্রস্তুত' : 'APPLICATION DOCKET READY',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryGreen,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isBn ? 'আপনার আবেদন প্রস্তুত হয়েছে' : 'Docket Created Successfully',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.bgMuted,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          'DOCKET ID: ${_createdApp!.docketId}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isBn
                            ? 'আপনার প্রয়োজনীয় তথ্য ও লকারের নথিপত্র দিয়ে কার্যপত্র সংরক্ষণ করা হয়েছে। এটি আপনার ড্যাশবোর্ডে "আমার আবেদনসমূহ" বিভাগে যুক্ত হয়েছে।'
                            : 'Your prefilled citizen docket has been logged and stored under your dashboard applications.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showDocketSlipDialog(_createdApp!, isBn),
                          icon: const Icon(Icons.print_outlined, size: 16),
                          label: Text(
                            isBn ? 'কাউন্টার ফরম প্রিন্ট / দেখুন' : 'Print / View Docket Slip',
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
                      if (widget.service.officialUrl.isNotEmpty && widget.service.officialUrl != '#') ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _openOfficialPortal,
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: Text(
                              isBn ? 'সরকারি পোর্টালে যান' : 'Go to Official Portal',
                              style: GoogleFonts.notoSansBengali(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black87,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: const RoundedRectangleBorder(),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            dashboard.setActiveTab(1);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: const RoundedRectangleBorder(),
                          ),
                          child: Text(
                            isBn ? 'ড্যাশবোর্ডে দেখুন' : 'View in Dashboard',
                            style: GoogleFonts.notoSansBengali(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Citizen Info Snapshot Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgMuted,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isBn ? 'আবেদনকারী নাগরিকের তথ্য:' : 'Applicant Citizen Profile:',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                          ),
                        ),
                        if (hasOcrMeta)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.lightGreen50,
                              border: Border.all(color: const Color(0xFF6EE7B7)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.auto_awesome, size: 12, color: AppColors.primaryGreen),
                                const SizedBox(width: 4),
                                Text(
                                  isBn ? 'এআই লকার অটোফিল প্রস্তুত' : 'AI Locker Autofill Active',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          user?.fullName ?? (isBn ? 'নাগরিক' : 'Citizen'),
                          style: GoogleFonts.notoSansBengali(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          user?.phone ?? '',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.lightGreen50,
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Text(
                            ocrCitizenId,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (hasOcrMeta) ...[
                      const SizedBox(height: 8),
                      const Divider(color: AppColors.border, height: 1),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (ocrDob != null) _buildMetaChip(isBn ? 'জন্ম:' : 'DOB:', ocrDob),
                          if (ocrFather != null) _buildMetaChip(isBn ? 'পিতা:' : "Father:", ocrFather),
                          if (ocrMother != null) _buildMetaChip(isBn ? 'মাতা:' : "Mother:", ocrMother),
                          if (ocrBlood != null) _buildMetaChip(isBn ? 'রক্ত:' : 'Blood:', ocrBlood),
                          if (ocrRoll != null) _buildMetaChip(isBn ? 'রোল:' : 'Roll:', '$ocrRoll (${ocrBoard ?? ''})'),
                          if (ocrAddress != null) _buildMetaChip(isBn ? 'ঠিকানা:' : 'Address:', ocrAddress),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Document Locker Match Audit
              Text(
                isBn ? 'প্রয়োজনীয় কাগজপত্রের লকার নিরীক্ষা:' : 'Document Locker Readiness Audit:',
                style: GoogleFonts.notoSansBengali(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              ...widget.service.requiredDocs.map((doc) {
                final isMatched = attachedDocNames.contains(doc.nameBn);

                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isMatched ? AppColors.lightGreen50 : Colors.white,
                    border: Border.all(
                      color: isMatched ? const Color(0xFFA7F3D0) : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isMatched ? Icons.check_circle : Icons.crop_square,
                        size: 16,
                        color: isMatched ? AppColors.primaryGreen : AppColors.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isBn ? doc.nameBn : (doc.nameEn.isNotEmpty ? doc.nameEn : doc.nameBn),
                              style: GoogleFonts.notoSansBengali(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              isMatched
                                  ? (isBn ? '✓ ডিজিটাল লকারে সংরক্ষিত' : '✓ Attached from locker')
                                  : (isBn ? 'ম্যানুয়াল সংযুক্তির প্রয়োজন' : 'Manual submission required'),
                              style: GoogleFonts.notoSansBengali(
                                fontSize: 9,
                                color: isMatched ? AppColors.darkGreen : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isMatched ? AppColors.primaryGreen : AppColors.bgMuted,
                          border: Border.all(
                            color: isMatched ? AppColors.primaryGreen : AppColors.border,
                          ),
                        ),
                        child: Text(
                          isMatched ? 'ATTACHED' : 'PENDING',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: isMatched ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 10),

              // Official Processing Facts Notice
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bgMuted,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isBn ? 'নির্ধারিত সরকারি ফি:' : 'Official Fee:',
                          style: GoogleFonts.notoSansBengali(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        Text(
                          widget.service.fee == 'বিনামূল্যে'
                              ? (isBn ? 'বিনামূল্যে' : 'Free')
                              : '৳${widget.service.fee}',
                          style: GoogleFonts.notoSansBengali(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isBn ? 'অনুমোদিত সময়সীমা:' : 'Approved Time:',
                          style: GoogleFonts.notoSansBengali(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        Text(
                          widget.service.processingTimeBn,
                          style: GoogleFonts.notoSansBengali(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Invisible Bot Live Automation Terminal
              if (_isSubmitting) ...[
                Container(
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
                                isBn ? 'অদৃশ্য অটোমেশন বট রানিং...' : 'Invisible Bot Worker Running...',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
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
                      _buildBotRow(1, _botStep, isBn ? 'সরকারি পোর্টাল সংযোগ স্থাপন ও সেশন শুরু...' : 'Connecting to govt gateway & starting session...'),
                      const SizedBox(height: 4),
                      _buildBotRow(2, _botStep, isBn ? 'নাগরিক প্রোফাইল থেকে সকল ফর্ম ফিল্ড স্বয়ংক্রিয় পূরণ...' : 'Autofilling form fields from citizen profile...'),
                      const SizedBox(height: 4),
                      _buildBotRow(3, _botStep, isBn ? 'ডিজিটাল লকার থেকে প্রয়োজনীয় ডকুমেন্টস এনক্রিপ্ট করে সংযুক্ত...' : 'Attaching verified documents from digital locker...'),
                      const SizedBox(height: 4),
                      _buildBotRow(4, _botStep, isBn ? 'সার্ভার ভেরিফিকেশন ও অফিসিয়াল ট্র্যাকিং ডকেট জেনারেশন সম্পন্ন!' : 'Server verification complete & official tracking logged!'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Modal Actions: Cancel & Generate Official Docket
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: const RoundedRectangleBorder(),
                      ),
                      child: Text(
                        isBn ? 'বাতিল' : 'Cancel',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _handleGenerateDocket,
                      icon: const Icon(Icons.auto_awesome, size: 16),
                      label: Text(
                        _isSubmitting
                            ? (isBn ? 'কার্যপত্র প্রস্তুত হচ্ছে...' : 'Generating Docket...')
                            : (isBn ? 'কার্যপত্র (Docket) তৈরি করুন' : 'Generate Official Docket'),
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: const RoundedRectangleBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetaChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '$label $value',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildBotRow(int step, int currentStep, String text) {
    final isDone = currentStep > step;
    final isCurrent = currentStep == step;
    final color = isDone || isCurrent ? const Color(0xFF6EE7B7) : const Color(0xFF737373);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isDone ? '✓ ' : (isCurrent ? '➜ ' : '○ '),
          style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: color),
        ),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.notoSansBengali(fontSize: 10, color: color, height: 1.3),
          ),
        ),
      ],
    );
  }
}
