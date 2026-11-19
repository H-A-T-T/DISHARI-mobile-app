import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../models/document.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/language_provider.dart';
import '../services/n8n_service.dart';

class ImageVerificationScreen extends StatefulWidget {
  final File initialImageFile;
  final String? initialDocType;

  const ImageVerificationScreen({
    super.key,
    required this.initialImageFile,
    this.initialDocType,
  });

  @override
  State<ImageVerificationScreen> createState() =>
      _ImageVerificationScreenState();
}

class _ImageVerificationScreenState extends State<ImageVerificationScreen> {
  /// ড্রপডাউনে থাকা সব বৈধ নথির ধরন
  static const List<String> _validDocTypes = [
    'nid_front',
    'nid_back',
    'passport',
    'birth_certificate',
    'educational_transcript',
    'academic_certificate',
    'driving_license',
    'utility_bill',
    'bank_statement',
    'tin_certificate',
    'trade_license',
    'citizenship_certificate',
    'other',
  ];

  late File _currentImageFile;
  bool _isProcessing = false;
  String? _extractionSource;
  String? _errorMessage;
  final ImagePicker _picker = ImagePicker();

  // Field controllers
  final _docTitleController = TextEditingController();
  final _fullNameBnController = TextEditingController();
  final _fullNameEnController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _dobController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  final _addressController = TextEditingController();
  final _issueDateController = TextEditingController();
  final _rollController = TextEditingController();
  final _boardController = TextEditingController();
  final _regNoController = TextEditingController();
  final _examNameController = TextEditingController();
  final _gpaController = TextEditingController();
  final _passingYearController = TextEditingController();
  final _institutionController = TextEditingController();
  final _businessNameController = TextEditingController();

  // Passport
  final _passportNoController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _mrzLine1Controller = TextEditingController();
  final _mrzLine2Controller = TextEditingController();
  final _genderController = TextEditingController();

  // Utility bill
  final _accountNoController = TextEditingController();
  final _meterNoController = TextEditingController();
  final _billMonthController = TextEditingController();
  final _billAmountController = TextEditingController();
  final _dueDateController = TextEditingController();

  // Driving license
  final _licenseNoController = TextEditingController();
  final _vehicleClassController = TextEditingController();

  String? _selectedDocType;
  int _confidenceScore = 95;
  bool _showAllFields = false;

  /// metadata key -> controller (সংগ্রহের জন্য)
  late final Map<String, TextEditingController> _metaControllers = {
    'doc_title': _docTitleController,
    'full_name_bn': _fullNameBnController,
    'full_name_en': _fullNameEnController,
    'id_number': _idNumberController,
    'dob': _dobController,
    'father_name': _fatherNameController,
    'mother_name': _motherNameController,
    'blood_group': _bloodGroupController,
    'address': _addressController,
    'issue_date': _issueDateController,
    'passport_number': _passportNoController,
    'nationality': _nationalityController,
    'expiry_date': _expiryDateController,
    'mrz_line1': _mrzLine1Controller,
    'mrz_line2': _mrzLine2Controller,
    'gender': _genderController,
    'roll': _rollController,
    'board': _boardController,
    'reg_no': _regNoController,
    'exam_name': _examNameController,
    'gpa': _gpaController,
    'passing_year': _passingYearController,
    'institution': _institutionController,
    'business_name': _businessNameController,
    'account_number': _accountNoController,
    'meter_number': _meterNoController,
    'bill_month': _billMonthController,
    'bill_amount': _billAmountController,
    'due_date': _dueDateController,
    'license_number': _licenseNoController,
    'vehicle_class': _vehicleClassController,
  };

  @override
  void initState() {
    super.initState();
    _currentImageFile = widget.initialImageFile;
    _selectedDocType = _normalizeDocType(widget.initialDocType);

    // Auto-start extraction on open
    _processWithN8nWorkflow();
  }

  @override
  void dispose() {
    for (final c in _metaControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// অজানা ধরন এলে ড্রপডাউন যেন crash না করে
  String? _normalizeDocType(String? t) {
    if (t == null) return null;
    final v = t.trim().toLowerCase();
    return _validDocTypes.contains(v) ? v : null;
  }

  String _mimeTypeOf(File f) {
    final p = f.path.toLowerCase();
    if (p.endsWith('.pdf')) return 'application/pdf';
    if (p.endsWith('.png')) return 'image/png';
    if (p.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  void _populateControllers(Map<String, dynamic> data) {
    String getVal(List<String> keys) {
      for (final k in keys) {
        if (data.containsKey(k) &&
            data[k] != null &&
            data[k].toString().trim().isNotEmpty) {
          return data[k].toString().trim();
        }
      }
      return '';
    }

    _docTitleController.text = getVal(['doc_title', 'document_type', 'type']);
    _fullNameBnController.text = getVal(
        ['full_name_bn', 'name_bn', 'name', 'full_name', 'candidate_name']);
    _fullNameEnController.text =
        getVal(['full_name_en', 'name_en', 'english_name']);
    _idNumberController.text = getVal([
      'id_number',
      'nid_number',
      'br_number',
      'tin_number',
      'tin',
      'registration_number',
      'passport_number'
    ]);
    _dobController.text = getVal(['dob', 'date_of_birth', 'birth_date']);
    _fatherNameController.text = getVal(['father_name', 'father']);
    _motherNameController.text = getVal(['mother_name', 'mother']);
    _bloodGroupController.text = getVal(['blood_group', 'blood']);
    _addressController.text =
        getVal(['address', 'present_address', 'permanent_address']);
    _issueDateController.text = getVal(['issue_date', 'date_of_issue']);

    // Academic
    _rollController.text = getVal(['roll', 'roll_no']);
    _boardController.text = getVal(['board', 'education_board']);
    _regNoController.text = getVal(['reg_no', 'registration_no']);
    _examNameController.text = getVal(['exam_name', 'exam']);
    _gpaController.text = getVal(['gpa', 'result', 'cgpa']);
    _passingYearController.text = getVal(['passing_year', 'year']);
    _institutionController.text = getVal(['institution', 'institute']);
    _businessNameController.text =
        getVal(['business_name', 'org_name', 'trade_name']);

    // Passport
    _passportNoController.text =
        getVal(['passport_number', 'passport_no', 'id_number']);
    _nationalityController.text = getVal(['nationality']);
    _expiryDateController.text = getVal(['expiry_date', 'date_of_expiry']);
    _mrzLine1Controller.text = getVal(['mrz_line1']);
    _mrzLine2Controller.text = getVal(['mrz_line2']);
    _genderController.text = getVal(['gender', 'sex']);

    // Utility
    _accountNoController.text =
        getVal(['account_number', 'account_no', 'customer_no']);
    _meterNoController.text = getVal(['meter_number', 'meter_no']);
    _billMonthController.text = getVal(['bill_month', 'billing_month']);
    _billAmountController.text = getVal(['bill_amount', 'total_amount']);
    _dueDateController.text = getVal(['due_date']);

    // Driving
    _licenseNoController.text = getVal(['license_number', 'license_no']);
    _vehicleClassController.text = getVal(['vehicle_class']);

    // Confidence
    final rawConf = data['confidence_score'];
    if (rawConf is int) {
      _confidenceScore = rawConf.clamp(70, 99);
    } else if (rawConf != null) {
      _confidenceScore = int.tryParse(rawConf.toString())?.clamp(70, 99) ?? 95;
    }

    final detected = _detectDocType(data);
    _selectedDocType = _normalizeDocType(detected) ?? 'other';
    if (_selectedDocType != 'nid_front') {
      _showAllFields = true;
    }
  }

  Map<String, dynamic> _collectMetadata() {
    final Map<String, dynamic> meta = {};
    _metaControllers.forEach((key, controller) {
      final v = controller.text.trim();
      if (v.isNotEmpty) meta[key] = v;
    });
    meta['confidence_score'] = _confidenceScore;
    meta['doc_type'] = _selectedDocType ?? _detectDocType(meta);
    return meta;
  }

  String _detectDocType(Map<String, dynamic> meta) {
    if (_selectedDocType != null && _selectedDocType != 'other') {
      return _selectedDocType!;
    }
    if (widget.initialDocType != null && widget.initialDocType != 'other') {
      return widget.initialDocType!;
    }
    final docType = (meta['doc_type']?.toString() ?? '').toLowerCase();
    if (docType.isNotEmpty && docType != 'other') {
      return docType;
    }
    final title = (meta['doc_title']?.toString() ?? '').toLowerCase();
    final id = meta['id_number']?.toString() ?? '';
    final addr = meta['address']?.toString() ?? '';
    final hasName = (meta['full_name_bn']?.toString().isNotEmpty ?? false) ||
        (meta['full_name_en']?.toString().isNotEmpty ?? false);

    // Passport
    if (title.contains('passport') ||
        title.contains('পাসপোর্ট') ||
        _passportNoController.text.isNotEmpty ||
        meta.containsKey('passport_number') ||
        _mrzLine1Controller.text.isNotEmpty ||
        meta.containsKey('mrz_line1')) {
      return 'passport';
    }

    // Utility Bill
    if (title.contains('bill') ||
        title.contains('বিল') ||
        title.contains('বিদ্যুৎ') ||
        title.contains('electricity') ||
        title.contains('gas') ||
        title.contains('wasa') ||
        title.contains('পানি') ||
        title.contains('নেসকো') ||
        title.contains('ডেসকো') ||
        title.contains('পল্লী বিদ্যুৎ') ||
        _accountNoController.text.isNotEmpty ||
        meta.containsKey('meter_number') ||
        meta.containsKey('account_number')) {
      return 'utility_bill';
    }

    // Driving License
    if (title.contains('driving') ||
        title.contains('ড্রাইভিং') ||
        _licenseNoController.text.isNotEmpty ||
        meta.containsKey('vehicle_class')) {
      return 'driving_license';
    }

    // Bank Statement
    if (title.contains('bank') ||
        title.contains('ব্যাংক') ||
        title.contains('statement') ||
        title.contains('হিসাব বিবরণী')) {
      return 'bank_statement';
    }

    // Academic Certificate vs Transcript
    if (title.contains('সনদ') ||
        title.contains('certificate') ||
        title.contains('degree') ||
        title.contains('ডিগ্রি')) {
      return 'academic_certificate';
    }
    if (title.contains('প্রবেশপত্র') ||
        title.contains('admit') ||
        title.contains('মার্কশিট') ||
        title.contains('transcript') ||
        meta.containsKey('roll') ||
        _rollController.text.isNotEmpty) {
      return 'educational_transcript';
    }

    // NID Back
    if (title.contains('পেছন') ||
        title.contains('back') ||
        (addr.isNotEmpty && !hasName && id.isEmpty)) {
      return 'nid_back';
    }

    // Birth Certificate
    if (title.contains('জন্ম') || title.contains('birth') || id.length == 17) {
      return 'birth_certificate';
    }

    // e-TIN
    if (title.contains('টিআইএন') || title.contains('tin')) {
      return 'tin_certificate';
    }

    // Trade License
    if (title.contains('ট্রেড লাইসেন্স') || title.contains('trade')) {
      return 'trade_license';
    }

    // Citizenship / Succession
    if (title.contains('নাগরিকত্ব') || title.contains('ওয়ারিশ')) {
      return 'citizenship_certificate';
    }

    return 'nid_front';
  }

  Future<void> _pickNewImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2000,
      );
      if (picked != null) {
        setState(() {
          _currentImageFile = File(picked.path);
          _errorMessage = null;
        });
        await _processWithN8nWorkflow();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ছবি নির্বাচনে সমস্যা হয়েছে: $e')),
        );
      }
    }
  }

  Future<void> _pickPdfOrDocument() async {
    try {
      // নতুন file_picker এ FilePicker.platform নেই, সরাসরি pickFile
      final picked = await FilePicker.pickFile(type: FileType.any);
      if (picked != null && picked.path != null) {
        setState(() {
          _currentImageFile = File(picked.path!);
          _errorMessage = null;
        });
        await _processWithN8nWorkflow();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ডকুমেন্ট ফাইল নির্বাচনে সমস্যা হয়েছে: $e')),
        );
      }
    }
  }

  Future<void> _processWithN8nWorkflow() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final result = await N8nService.extractImageInfo(
        imageFile: _currentImageFile,
        docType: widget.initialDocType,
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
          if (result['success'] == true) {
            final data = result['data'] as Map<String, dynamic>? ?? {};
            _extractionSource = result['source'] as String?;
            _populateControllers(data);
          } else {
            _errorMessage =
                result['error']?.toString() ?? 'তথ্য উদ্ধার সম্ভব হয়নি';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _approveAndSave() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final isBn = lang.isBn;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final dashboard = Provider.of<DashboardProvider>(context, listen: false);

    final meta = _collectMetadata();
    final docType = _detectDocType(meta);
    final fileName = _currentImageFile.path.split(Platform.pathSeparator).last;
    final fileSize = _currentImageFile.lengthSync();
    final mime = _mimeTypeOf(_currentImageFile);

    // Read bytes for base64 fileData
    String fileDataStr = '';
    try {
      final bytes = await _currentImageFile.readAsBytes();
      fileDataStr = base64Encode(bytes);
    } catch (_) {}

    final userId = auth.user?.id ?? 1;

    // Save to server & local cache via dashboard provider
    await dashboard.uploadDocument(
      userId: userId,
      docType: docType,
      fileName: fileName,
      fileSize: fileSize,
      mimeType: mime,
      fileData: fileDataStr,
      extractedMeta: meta,
    );

    final newDoc = CitizenDocument(
      id: (DateTime.now().millisecondsSinceEpoch % 2000000000),
      userId: userId,
      docType: docType,
      fileName: fileName,
      fileSize: fileSize,
      mimeType: mime,
      verified: true,
      extractedMeta: meta,
      uploadedAt: DateTime.now().toIso8601String(),
      fileData: fileDataStr,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primaryGreen,
        shape: const RoundedRectangleBorder(),
        behavior: SnackBarBehavior.floating,
        content: Text(
          isBn
              ? 'নথিটি সফলভাবে যাচাইকৃত ও লকারে সংরক্ষিত হয়েছে!'
              : 'Document verified and saved to locker successfully!',
          style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w600),
        ),
      ),
    );

    Navigator.of(context).pop(newDoc);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final isBn = lang.isBn;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        backgroundColor: AppColors.bgSurface,
        elevation: 0,
        title: Text(
          isBn ? 'নথি যাচাই ও অনুমোদন' : 'Document Verification & Approval',
          style: GoogleFonts.notoSansBengali(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(3),
          child:
              Divider(height: 3, thickness: 3, color: AppColors.primaryGreen),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAdvisory(isBn),
            const SizedBox(height: 14),
            _buildImageCard(isBn),
            const SizedBox(height: 16),
            _buildFieldsCard(isBn),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _approveAndSave,
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: Text(
                  isBn
                      ? 'তথ্য সঠিক — অনুমোদন ও লকারে সংরক্ষণ করুন'
                      : 'Approve & Save to Locker',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvisory(bool isBn) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGreen50,
        border:
            Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_user_outlined,
            color: AppColors.primaryGreen,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isBn
                  ? 'ছবিটি স্ক্যান করে নিচের তথ্যগুলো উদ্ধার করা হয়েছে। কোনো তথ্য ভুল থাকলে এখনই সম্পাদনা করে নিশ্চিত করুন।'
                  : 'Extracted data from your document. You can verify and edit any field below before saving to your secure locker.',
              style: GoogleFonts.notoSansBengali(
                fontSize: 12,
                color: AppColors.darkGreen,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 13),
        label: Text(
          label,
          style: GoogleFonts.notoSansBengali(
              fontSize: 11, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: const RoundedRectangleBorder(),
        ),
      ),
    );
  }

  Widget _buildImageCard(bool isBn) {
    final isPdf = _currentImageFile.path.toLowerCase().endsWith('.pdf');
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 200,
            width: double.infinity,
            color: Colors.black12,
            child: isPdf
                ? Container(
                    color: const Color(0xFFF8FAFC),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.picture_as_pdf,
                          size: 56,
                          color: AppColors.primaryRed,
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            _currentImageFile.path
                                .split(Platform.pathSeparator)
                                .last,
                            style: GoogleFonts.notoSansBengali(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isBn
                              ? 'পিডিএফ ডকুমেন্ট নির্বাচিত হয়েছে'
                              : 'PDF document selected',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 11,
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                : Image.file(
                    _currentImageFile,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image,
                          size: 48, color: Colors.grey),
                    ),
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.bgMuted,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                _toolbarButton(
                  icon: Icons.camera_alt_outlined,
                  label: isBn ? 'ক্যামেরা' : 'Camera',
                  onPressed: () => _pickNewImage(ImageSource.camera),
                ),
                const SizedBox(width: 6),
                _toolbarButton(
                  icon: Icons.photo_library_outlined,
                  label: isBn ? 'গ্যালারি' : 'Gallery',
                  onPressed: () => _pickNewImage(ImageSource.gallery),
                ),
                const SizedBox(width: 6),
                _toolbarButton(
                  icon: Icons.picture_as_pdf_outlined,
                  label: isBn ? 'পিডিএফ' : 'PDF/File',
                  onPressed: _pickPdfOrDocument,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldsCard(bool isBn) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(
          top: BorderSide(color: AppColors.primaryGreen, width: 3),
          left: BorderSide(color: AppColors.border),
          right: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
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
                  const Icon(Icons.auto_awesome,
                      size: 16, color: AppColors.primaryGreen),
                  const SizedBox(width: 6),
                  Text(
                    isBn
                        ? 'যাচাইকৃত তথ্য সম্পাদনা'
                        : 'Verify & Edit Extracted Fields',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (_extractionSource != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  color: AppColors.lightGreen50,
                  child: Text(
                    _extractionSource == 'n8n' ? 'via n8n' : 'AI Verified',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
            ],
          ),
          const Divider(height: 18, color: AppColors.border),
          if (_isProcessing)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isBn
                          ? 'AI ও n8n দ্বারা নথির তথ্য উদ্ধার করা হচ্ছে...'
                          : 'Extracting document information with AI & n8n...',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            if (_errorMessage != null) _buildErrorBox(isBn),
            _buildConfidenceBadge(isBn),
            _buildDocTypeDropdown(isBn),
            ..._buildTypeSpecificFields(isBn),
            if (_showAllFields) ..._buildExtraFields(isBn),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _showAllFields = !_showAllFields;
                });
              },
              icon: Icon(
                _showAllFields
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                size: 16,
                color: AppColors.primaryGreen,
              ),
              label: Text(
                _showAllFields
                    ? (isBn ? 'কম ফিল্ড দেখান' : 'Show Fewer Fields')
                    : (isBn
                        ? 'অন্যান্য সকল ফিল্ড দেখান ও সম্পাদনা করুন'
                        : 'Show All Available Fields'),
                style: GoogleFonts.notoSansBengali(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorBox(bool isBn) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      color: AppColors.lightRed50,
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              size: 18, color: AppColors.primaryRed),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.notoSansBengali(
                  fontSize: 11, color: AppColors.primaryRed),
            ),
          ),
          InkWell(
            onTap: _processWithN8nWorkflow,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.primaryRed, width: 1),
              ),
              child: Text(
                isBn ? 'পুনরায় চেষ্টা করুন' : 'Retry OCR',
                style: GoogleFonts.notoSansBengali(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryRed,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceBadge(bool isBn) {
    final high = _confidenceScore >= 85;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: high ? AppColors.lightGreen50 : const Color(0xFFFFFBEB),
        border: Border.all(
          color: high
              ? AppColors.primaryGreen.withValues(alpha: 0.4)
              : const Color(0xFFFDE68A),
        ),
      ),
      child: Row(
        children: [
          Icon(
            high ? Icons.verified : Icons.help_outline,
            size: 18,
            color: high ? AppColors.primaryGreen : const Color(0xFFB45309),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isBn
                  ? 'AI নির্ভুলতা স্তর: $_confidenceScore% (${high ? "উচ্চ নির্ভুলতা" : "পুনর্বিবেচনা প্রয়োজন"})'
                  : 'AI Confidence Score: $_confidenceScore% (${high ? "High Accuracy" : "Review Advised"})',
              style: GoogleFonts.notoSansBengali(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: high ? AppColors.darkGreen : const Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocTypeDropdown(bool isBn) {
    final labels = <String, String>{
      'nid_front': isBn ? 'জাতীয় পরিচয়পত্র (সামনের পাতা)' : 'NID Front Side',
      'nid_back': isBn ? 'জাতীয় পরিচয়পত্র (পেছনের পাতা)' : 'NID Back Side',
      'passport':
          isBn ? 'আন্তর্জাতিক পাসপোর্ট (Passport)' : 'Passport (ICAO 9303)',
      'birth_certificate':
          isBn ? 'জন্ম নিবন্ধন সনদ (Birth Certificate)' : 'Birth Certificate',
      'educational_transcript':
          isBn ? 'শিক্ষাগত মার্কশিট / ট্রান্সক্রিপ্ট' : 'Marksheet / Transcript',
      'academic_certificate':
          isBn ? 'শিক্ষা সনদ / সার্টিফিকেট' : 'Academic Certificate',
      'driving_license':
          isBn ? 'ড্রাইভিং লাইসেন্স (Driving License)' : 'Driving License',
      'utility_bill': isBn
          ? 'ইউটিলিটি বিল (বিদ্যুৎ/গ্যাস/পানি)'
          : 'Utility Bill (Power/Gas/Water)',
      'bank_statement':
          isBn ? 'ব্যাংক স্টেটমেন্ট (Bank Statement)' : 'Bank Statement',
      'tin_certificate': isBn ? 'ই-টিআইএন সনদ (e-TIN)' : 'e-TIN Certificate',
      'trade_license':
          isBn ? 'ট্রেড লাইসেন্স (Trade License)' : 'Trade License',
      'citizenship_certificate':
          isBn ? 'নাগরিকত্ব / ওয়ারিশ সনদ' : 'Citizenship Certificate',
      'other': isBn ? 'অন্যান্য নথি' : 'Other Document',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isBn ? 'নথির ধরন / ক্যাটাগরি:' : 'Document Category:',
            style: GoogleFonts.notoSansBengali(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: _normalizeDocType(_selectedDocType) ?? 'nid_front',
            isDense: true,
            isExpanded: true,
            decoration: const InputDecoration(
              filled: true,
              fillColor: AppColors.bgMuted,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide:
                      BorderSide(color: AppColors.primaryGreen, width: 1.5)),
            ),
            items: _validDocTypes
                .map((t) => DropdownMenuItem<String>(
                      value: t,
                      child: Text(
                        labels[t] ?? t,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedDocType = val;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _pair(Widget a, Widget b) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: 8),
        Expanded(child: b),
      ],
    );
  }

  List<Widget> _buildTypeSpecificFields(bool isBn) {
    switch (_selectedDocType) {
      case 'passport':
        return [
          _buildFieldInput(
            labelBn: 'পাসপোর্ট নম্বর',
            labelEn: 'Passport Number',
            controller: _passportNoController,
            isBn: isBn,
          ),
          _buildFieldInput(
            labelBn: 'পূর্ণ নাম (ইংরেজি)',
            labelEn: 'Full Name (English)',
            controller: _fullNameEnController,
            isBn: isBn,
          ),
          _pair(
            _buildFieldInput(
              labelBn: 'জাতীয়তা',
              labelEn: 'Nationality',
              controller: _nationalityController,
              isBn: isBn,
            ),
            _buildFieldInput(
              labelBn: 'লিঙ্গ',
              labelEn: 'Sex / Gender',
              controller: _genderController,
              isBn: isBn,
            ),
          ),
          _pair(
            _buildFieldInput(
              labelBn: 'জন্মতারিখ',
              labelEn: 'Date of Birth (YYYY-MM-DD)',
              controller: _dobController,
              isBn: isBn,
            ),
            _buildFieldInput(
              labelBn: 'মেয়াদ উত্তীর্ণের তারিখ',
              labelEn: 'Date of Expiry (YYYY-MM-DD)',
              controller: _expiryDateController,
              isBn: isBn,
            ),
          ),
          _buildFieldInput(
            labelBn: 'জাতীয় পরিচয়পত্র / ব্যক্তিগত নম্বর',
            labelEn: 'Personal No / NID',
            controller: _idNumberController,
            isBn: isBn,
          ),
          _buildFieldInput(
            labelBn: 'ইস্যু তারিখ',
            labelEn: 'Issue Date',
            controller: _issueDateController,
            isBn: isBn,
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.qr_code,
                        size: 14, color: AppColors.primaryGreen),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        isBn
                            ? 'মেশিন রিডেবল জোন (MRZ - 2 Lines):'
                            : 'Machine Readable Zone (MRZ 44-chars):',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _buildFieldInput(
                  labelBn: 'MRZ লাইন ১',
                  labelEn: 'MRZ Line 1',
                  controller: _mrzLine1Controller,
                  isBn: isBn,
                  isMonospace: true,
                ),
                _buildFieldInput(
                  labelBn: 'MRZ লাইন ২',
                  labelEn: 'MRZ Line 2',
                  controller: _mrzLine2Controller,
                  isBn: isBn,
                  isMonospace: true,
                ),
              ],
            ),
          ),
        ];

      case 'utility_bill':
        return [
          _buildFieldInput(
            labelBn: 'হিসাব / গ্রাহক নম্বর',
            labelEn: 'Account / Customer No',
            controller: _accountNoController,
            isBn: isBn,
          ),
          _buildFieldInput(
            labelBn: 'মিটার নম্বর',
            labelEn: 'Meter Number',
            controller: _meterNoController,
            isBn: isBn,
          ),
          _pair(
            _buildFieldInput(
              labelBn: 'বিল মাস',
              labelEn: 'Billing Month',
              controller: _billMonthController,
              isBn: isBn,
            ),
            _buildFieldInput(
              labelBn: 'পরিশোধের পরিমাণ (টাকা)',
              labelEn: 'Bill Amount (BDT)',
              controller: _billAmountController,
              isBn: isBn,
            ),
          ),
          _buildFieldInput(
            labelBn: 'পরিশোধের শেষ তারিখ',
            labelEn: 'Payment Due Date',
            controller: _dueDateController,
            isBn: isBn,
          ),
          _buildFieldInput(
            labelBn: 'গ্রাহকের নাম',
            labelEn: 'Customer Name',
            controller: _fullNameBnController,
            isBn: isBn,
          ),
          _buildFieldInput(
            labelBn: 'বিলিং ঠিকানা',
            labelEn: 'Billing Address',
            controller: _addressController,
            isBn: isBn,
            maxLines: 2,
          ),
        ];

      case 'driving_license':
        return [
          _buildFieldInput(
            labelBn: 'লাইসেন্স নম্বর',
            labelEn: 'Driving License No',
            controller: _licenseNoController,
            isBn: isBn,
          ),
          _buildFieldInput(
            labelBn: 'যানবাহনের শ্রেণি (Vehicle Class)',
            labelEn: 'Vehicle Class',
            controller: _vehicleClassController,
            isBn: isBn,
          ),
          _buildFieldInput(
            labelBn: 'চালকের নাম',
            labelEn: 'Driver Name',
            controller: _fullNameEnController,
            isBn: isBn,
          ),
          _pair(
            _buildFieldInput(
              labelBn: 'রক্তের গ্রুপ',
              labelEn: 'Blood Group',
              controller: _bloodGroupController,
              isBn: isBn,
            ),
            _buildFieldInput(
              labelBn: 'জন্মতারিখ',
              labelEn: 'Date of Birth',
              controller: _dobController,
              isBn: isBn,
            ),
          ),
          _pair(
            _buildFieldInput(
              labelBn: 'ইস্যু তারিখ',
              labelEn: 'Issue Date',
              controller: _issueDateController,
              isBn: isBn,
            ),
            _buildFieldInput(
              labelBn: 'মেয়াদ উত্তীর্ণের তারিখ',
              labelEn: 'Expiry Date',
              controller: _expiryDateController,
              isBn: isBn,
            ),
          ),
          _buildFieldInput(
            labelBn: 'ঠিকানা',
            labelEn: 'Address',
            controller: _addressController,
            isBn: isBn,
            maxLines: 2,
          ),
        ];

      case 'educational_transcript':
      case 'academic_certificate':
        return [
          _buildFieldInput(
            labelBn: 'শিক্ষার্থীর নাম (ইংরেজি)',
            labelEn: 'Student Name (English)',
            controller: _fullNameEnController,
            isBn: isBn,
          ),
          _buildFieldInput(
            labelBn: 'পরীক্ষার নাম (SSC/HSC/Degree)',
            labelEn: 'Examination Name',
            controller: _examNameController,
            isBn: isBn,
          ),
          _pair(
            _buildFieldInput(
              labelBn: 'রোল নম্বর',
              labelEn: 'Roll Number',
              controller: _rollController,
              isBn: isBn,
            ),
            _buildFieldInput(
              labelBn: 'রেজিস্ট্রেশন নম্বর',
              labelEn: 'Registration No',
              controller: _regNoController,
              isBn: isBn,
            ),
          ),
          _pair(
            _buildFieldInput(
              labelBn: 'শিক্ষা বোর্ড / বিশ্ববিদ্যালয়',
              labelEn: 'Board / University',
              controller: _boardController,
              isBn: isBn,
            ),
            _buildFieldInput(
              labelBn: 'জিপিএ / ফলাফল',
              labelEn: 'GPA / CGPA',
              controller: _gpaController,
              isBn: isBn,
            ),
          ),
          _buildFieldInput(
            labelBn: 'পাসের সন',
            labelEn: 'Passing Year',
            controller: _passingYearController,
            isBn: isBn,
          ),
          _buildFieldInput(
            labelBn: 'শিক্ষা প্রতিষ্ঠান',
            labelEn: 'Institution Name',
            controller: _institutionController,
            isBn: isBn,
          ),
        ];

      case 'nid_back':
        return [
          _buildFieldInput(
            labelBn: 'ঠিকানা',
            labelEn: 'Address',
            controller: _addressController,
            isBn: isBn,
            maxLines: 3,
          ),
          _pair(
            _buildFieldInput(
              labelBn: 'রক্তের গ্রুপ',
              labelEn: 'Blood Group',
              controller: _bloodGroupController,
              isBn: isBn,
            ),
            _buildFieldInput(
              labelBn: 'প্রদানের তারিখ / ইস্যু তারিখ',
              labelEn: 'Issue Date',
              controller: _issueDateController,
              isBn: isBn,
            ),
          ),
        ];

      default:
        // NID Front / Birth Certificate / Other
        return [
          _buildFieldInput(
            labelBn: 'নথির নাম',
            labelEn: 'Document Title',
            controller: _docTitleController,
            isBn: isBn,
          ),
          _buildFieldInput(
            labelBn: 'নাগরিক নাম (বাংলা)',
            labelEn: 'Name (Bengali)',
            controller: _fullNameBnController,
            isBn: isBn,
          ),
          _buildFieldInput(
            labelBn: 'নাগরিক নাম (ইংরেজি)',
            labelEn: 'Name (English)',
            controller: _fullNameEnController,
            isBn: isBn,
          ),
          _buildFieldInput(
            labelBn: 'পরিচয়পত্র / নিবন্ধন নম্বর',
            labelEn: 'ID / Registration Number',
            controller: _idNumberController,
            isBn: isBn,
          ),
          _buildFieldInput(
            labelBn: 'জন্মতারিখ',
            labelEn: 'Date of Birth (YYYY-MM-DD)',
            controller: _dobController,
            isBn: isBn,
          ),
          _buildFieldInput(
            labelBn: 'পিতার নাম',
            labelEn: "Father's Name",
            controller: _fatherNameController,
            isBn: isBn,
          ),
          _buildFieldInput(
            labelBn: 'মাতার নাম',
            labelEn: "Mother's Name",
            controller: _motherNameController,
            isBn: isBn,
          ),
          _pair(
            _buildFieldInput(
              labelBn: 'রক্তের গ্রুপ',
              labelEn: 'Blood Group',
              controller: _bloodGroupController,
              isBn: isBn,
            ),
            _buildFieldInput(
              labelBn: 'ইস্যু তারিখ',
              labelEn: 'Issue Date',
              controller: _issueDateController,
              isBn: isBn,
            ),
          ),
          _buildFieldInput(
            labelBn: 'ঠিকানা / জন্মস্থান',
            labelEn: 'Address',
            controller: _addressController,
            isBn: isBn,
            maxLines: 2,
          ),
        ];
    }
  }

  List<Widget> _buildExtraFields(bool isBn) {
    return [
      const Divider(height: 20, color: AppColors.border),
      Text(
        isBn ? 'অন্যান্য সকল অতিরিক্ত তথ্য:' : 'All Extra Fields:',
        style: GoogleFonts.notoSansBengali(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryGreen,
        ),
      ),
      const SizedBox(height: 8),
      _buildFieldInput(
          labelBn: 'ব্যবসা প্রতিষ্ঠানের নাম',
          labelEn: 'Business Name',
          controller: _businessNameController,
          isBn: isBn),
      _buildFieldInput(
          labelBn: 'পাসপোর্ট নম্বর',
          labelEn: 'Passport No',
          controller: _passportNoController,
          isBn: isBn),
      _buildFieldInput(
          labelBn: 'ড্রাইভিং লাইসেন্স নম্বর',
          labelEn: 'Driving License No',
          controller: _licenseNoController,
          isBn: isBn),
      _buildFieldInput(
          labelBn: 'হিসাব নম্বর',
          labelEn: 'Account No',
          controller: _accountNoController,
          isBn: isBn),
      _buildFieldInput(
          labelBn: 'মিটার নম্বর',
          labelEn: 'Meter No',
          controller: _meterNoController,
          isBn: isBn),
      _buildFieldInput(
          labelBn: 'রোল নম্বর',
          labelEn: 'Roll No',
          controller: _rollController,
          isBn: isBn),
      _buildFieldInput(
          labelBn: 'রেজিস্ট্রেশন নম্বর',
          labelEn: 'Reg No',
          controller: _regNoController,
          isBn: isBn),
      _buildFieldInput(
          labelBn: 'শিক্ষা বোর্ড',
          labelEn: 'Board',
          controller: _boardController,
          isBn: isBn),
      _buildFieldInput(
          labelBn: 'ফলাফল / জিপিএ',
          labelEn: 'GPA',
          controller: _gpaController,
          isBn: isBn),
    ];
  }

  Widget _buildFieldInput({
    required String labelBn,
    required String labelEn,
    required TextEditingController controller,
    required bool isBn,
    int maxLines = 1,
    bool isMonospace = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isBn ? labelBn : labelEn,
            style: GoogleFonts.notoSansBengali(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            style: isMonospace
                ? const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)
                : GoogleFonts.notoSansBengali(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              fillColor: AppColors.bgMuted,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide:
                    BorderSide(color: AppColors.primaryGreen, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}