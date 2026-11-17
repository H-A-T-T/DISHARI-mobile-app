import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../models/document.dart';
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
  State<ImageVerificationScreen> createState() => _ImageVerificationScreenState();
}

class _ImageVerificationScreenState extends State<ImageVerificationScreen> {
  late File _currentImageFile;
  bool _isProcessing = false;
  String? _extractionSource;
  String? _errorMessage;
  final ImagePicker _picker = ImagePicker();

  // Field Controllers for inline user editing
  late final TextEditingController _docTitleController;
  late final TextEditingController _fullNameBnController;
  late final TextEditingController _fullNameEnController;
  late final TextEditingController _idNumberController;
  late final TextEditingController _dobController;
  late final TextEditingController _fatherNameController;
  late final TextEditingController _motherNameController;
  late final TextEditingController _bloodGroupController;
  late final TextEditingController _addressController;
  late final TextEditingController _rollController;
  late final TextEditingController _boardController;
  late final TextEditingController _regNoController;
  late final TextEditingController _businessNameController;

  bool _showAllFields = false;

  @override
  void initState() {
    super.initState();
    _currentImageFile = widget.initialImageFile;

    _docTitleController = TextEditingController();
    _fullNameBnController = TextEditingController();
    _fullNameEnController = TextEditingController();
    _idNumberController = TextEditingController();
    _dobController = TextEditingController();
    _fatherNameController = TextEditingController();
    _motherNameController = TextEditingController();
    _bloodGroupController = TextEditingController();
    _addressController = TextEditingController();
    _rollController = TextEditingController();
    _boardController = TextEditingController();
    _regNoController = TextEditingController();
    _businessNameController = TextEditingController();

    // Auto-start extraction on open
    _processWithN8nWorkflow();
  }

  @override
  void dispose() {
    _docTitleController.dispose();
    _fullNameBnController.dispose();
    _fullNameEnController.dispose();
    _idNumberController.dispose();
    _dobController.dispose();
    _fatherNameController.dispose();
    _motherNameController.dispose();
    _bloodGroupController.dispose();
    _addressController.dispose();
    _rollController.dispose();
    _boardController.dispose();
    _regNoController.dispose();
    _businessNameController.dispose();
    super.dispose();
  }

  void _populateControllers(Map<String, dynamic> data) {
    String getVal(List<String> keys) {
      for (final k in keys) {
        if (data.containsKey(k) && data[k] != null && data[k].toString().trim().isNotEmpty) {
          return data[k].toString().trim();
        }
      }
      return '';
    }

    _docTitleController.text = getVal(['doc_title', 'document_type', 'type']);
    _fullNameBnController.text = getVal(['full_name_bn', 'name_bn', 'name', 'full_name', 'candidate_name']);
    _fullNameEnController.text = getVal(['full_name_en', 'name_en', 'english_name']);
    _idNumberController.text = getVal(['id_number', 'nid_number', 'br_number', 'tin_number', 'tin', 'registration_number']);
    _dobController.text = getVal(['dob', 'date_of_birth', 'birth_date']);
    _fatherNameController.text = getVal(['father_name', 'father']);
    _motherNameController.text = getVal(['mother_name', 'mother']);
    _bloodGroupController.text = getVal(['blood_group', 'blood']);
    _addressController.text = getVal(['address', 'present_address', 'permanent_address']);
    _rollController.text = getVal(['roll', 'roll_no']);
    _boardController.text = getVal(['board', 'education_board']);
    _regNoController.text = getVal(['reg_no', 'registration_no']);
    _businessNameController.text = getVal(['business_name', 'org_name', 'trade_name']);

    if (_rollController.text.isNotEmpty ||
        _boardController.text.isNotEmpty ||
        _businessNameController.text.isNotEmpty) {
      _showAllFields = true;
    }
  }

  Map<String, dynamic> _collectMetadata() {
    final Map<String, dynamic> meta = {};
    if (_docTitleController.text.trim().isNotEmpty) meta['doc_title'] = _docTitleController.text.trim();
    if (_fullNameBnController.text.trim().isNotEmpty) meta['full_name_bn'] = _fullNameBnController.text.trim();
    if (_fullNameEnController.text.trim().isNotEmpty) meta['full_name_en'] = _fullNameEnController.text.trim();
    if (_idNumberController.text.trim().isNotEmpty) meta['id_number'] = _idNumberController.text.trim();
    if (_dobController.text.trim().isNotEmpty) meta['dob'] = _dobController.text.trim();
    if (_fatherNameController.text.trim().isNotEmpty) meta['father_name'] = _fatherNameController.text.trim();
    if (_motherNameController.text.trim().isNotEmpty) meta['mother_name'] = _motherNameController.text.trim();
    if (_bloodGroupController.text.trim().isNotEmpty) meta['blood_group'] = _bloodGroupController.text.trim();
    if (_addressController.text.trim().isNotEmpty) meta['address'] = _addressController.text.trim();
    if (_rollController.text.trim().isNotEmpty) meta['roll'] = _rollController.text.trim();
    if (_boardController.text.trim().isNotEmpty) meta['board'] = _boardController.text.trim();
    if (_regNoController.text.trim().isNotEmpty) meta['reg_no'] = _regNoController.text.trim();
    if (_businessNameController.text.trim().isNotEmpty) meta['business_name'] = _businessNameController.text.trim();
    return meta;
  }

  String _detectDocType(Map<String, dynamic> meta) {
    if (widget.initialDocType != null && widget.initialDocType != 'other') {
      return widget.initialDocType!;
    }
    final title = (meta['doc_title']?.toString() ?? '').toLowerCase();
    final id = meta['id_number']?.toString() ?? '';
    if (title.contains('জন্ম') || title.contains('birth') || id.length == 17) {
      return 'birth_certificate';
    }
    if (title.contains('প্রবেশপত্র') || title.contains('admit') || meta.containsKey('roll')) {
      return 'educational_transcript';
    }
    if (title.contains('টিআইএন') || title.contains('tin')) {
      return 'tin_certificate';
    }
    if (title.contains('ট্রেড লাইসেন্স') || title.contains('trade')) {
      return 'trade_license';
    }
    return 'nid_front';
  }

  Future<void> _pickNewImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 90,
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

  Future<void> _processWithN8nWorkflow() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final result = await N8nService.extractImageInfo(
        imageFile: _currentImageFile,
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
          if (result['success'] == true) {
            final data = result['data'] as Map<String, dynamic>? ?? {};
            _extractionSource = result['source'] as String?;
            _populateControllers(data);
          } else {
            _errorMessage = result['error']?.toString() ?? 'তথ্য উদ্ধার সম্ভব হয়নি';
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
    final dashboard = Provider.of<DashboardProvider>(context, listen: false);

    final meta = _collectMetadata();
    final docType = _detectDocType(meta);

    // Read bytes for base64 fileData
    String fileDataStr = '';
    try {
      final bytes = await _currentImageFile.readAsBytes();
      fileDataStr = base64Encode(bytes);
    } catch (_) {}

    final newDoc = CitizenDocument(
      id: DateTime.now().millisecondsSinceEpoch,
      userId: 1,
      docType: docType,
      fileName: _currentImageFile.path.split(Platform.pathSeparator).last,
      fileSize: _currentImageFile.lengthSync(),
      mimeType: 'image/jpeg',
      verified: true,
      extractedMeta: meta,
      uploadedAt: DateTime.now().toIso8601String(),
      fileData: fileDataStr,
    );

    dashboard.addVerifiedDocument(newDoc);

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
          child: Divider(height: 3, thickness: 3, color: AppColors.primaryGreen),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Advisory
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightGreen50,
                border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
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
            ),
            const SizedBox(height: 14),

            // Image Preview Card with Windows 10 flat border
            Container(
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.zero,
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.black12,
                      child: Image.file(
                        _currentImageFile,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),

                  // Image Action Toolbar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: const BoxDecoration(
                      color: AppColors.bgMuted,
                      border: Border(top: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickNewImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt_outlined, size: 14),
                            label: Text(
                              isBn ? 'পুনরায় ছবি তুলুন' : 'Retake Camera',
                              style: GoogleFonts.notoSansBengali(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: const RoundedRectangleBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickNewImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_outlined, size: 14),
                            label: Text(
                              isBn ? 'গ্যালারি থেকে নিন' : 'Choose Gallery',
                              style: GoogleFonts.notoSansBengali(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: const RoundedRectangleBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Editable Extracted Fields Section
            Container(
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
                          const Icon(Icons.auto_awesome, size: 16, color: AppColors.primaryGreen),
                          const SizedBox(width: 6),
                          Text(
                            isBn ? 'যাচাইকৃত তথ্য সম্পাদনা' : 'Verify & Edit Extracted Fields',
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
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

                  if (_isProcessing) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Column(
                          children: [
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
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
                    ),
                  ] else ...[
                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(10),
                        color: AppColors.lightRed50,
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.notoSansBengali(fontSize: 11, color: AppColors.primaryRed),
                        ),
                      ),

                    // Primary Fields
                    _buildFieldInput(
                      labelBn: 'নথির ধরন / নাম',
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
                    _buildFieldInput(
                      labelBn: 'রক্তের গ্রুপ',
                      labelEn: 'Blood Group',
                      controller: _bloodGroupController,
                      isBn: isBn,
                    ),
                    _buildFieldInput(
                      labelBn: 'ঠিকানা / জন্মস্থান',
                      labelEn: 'Address',
                      controller: _addressController,
                      isBn: isBn,
                      maxLines: 2,
                    ),

                    if (_showAllFields) ...[
                      const Divider(height: 16, color: AppColors.border),
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
                      _buildFieldInput(
                        labelBn: 'শিক্ষা বোর্ড / কর্তৃপক্ষ',
                        labelEn: 'Education Board / Authority',
                        controller: _boardController,
                        isBn: isBn,
                      ),
                      _buildFieldInput(
                        labelBn: 'প্রতিষ্ঠানের নাম (ব্যবসা)',
                        labelEn: 'Business Name',
                        controller: _businessNameController,
                        isBn: isBn,
                      ),
                    ],

                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _showAllFields = !_showAllFields;
                        });
                      },
                      icon: Icon(
                        _showAllFields ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 16,
                        color: AppColors.primaryGreen,
                      ),
                      label: Text(
                        _showAllFields
                            ? (isBn ? 'কম ফিল্ড দেখান' : 'Show Fewer Fields')
                            : (isBn ? 'শিক্ষা / ব্যবসায়িক অতিরিক্ত ফিল্ড দেখান' : 'Show Education & Business Fields'),
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
            ),
            const SizedBox(height: 18),

            // Confirm & Save Button
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

  Widget _buildFieldInput({
    required String labelBn,
    required String labelEn,
    required TextEditingController controller,
    required bool isBn,
    int maxLines = 1,
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
            style: GoogleFonts.notoSansBengali(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 9),
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
                borderSide: BorderSide(color: AppColors.primaryGreen, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
