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
  Map<String, dynamic>? _extractedData;
  String? _extractionSource;
  String? _errorMessage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _currentImageFile = widget.initialImageFile;
    // Auto-start extraction on open
    _processWithN8nWorkflow();
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
          _extractedData = null;
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
            _extractedData = result['data'] as Map<String, dynamic>?;
            _extractionSource = result['source'] as String?;
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

    // Read bytes for base64 fileData
    String fileDataStr = '';
    try {
      final bytes = await _currentImageFile.readAsBytes();
      fileDataStr = base64Encode(bytes);
    } catch (_) {}

    // Save document to locker
    final newDoc = CitizenDocument(
      id: DateTime.now().millisecondsSinceEpoch,
      userId: 1,
      docType: widget.initialDocType ?? 'nid_front',
      fileName: _currentImageFile.path.split(Platform.pathSeparator).last,
      fileSize: _currentImageFile.lengthSync(),
      mimeType: 'image/jpeg',
      verified: true,
      extractedMeta: _extractedData ?? {},
      uploadedAt: DateTime.now().toIso8601String(),
      fileData: fileDataStr,
    );

    dashboard.addVerifiedDocument(newDoc);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primaryGreen,
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
        title: Text(
          isBn ? 'নথি যাচাই ও অনুমোদন' : 'Document Verification & Approval',
          style: GoogleFonts.notoSansBengali(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instruction header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightGreen50,
                border: Border.all(
                  color: AppColors.primaryGreen.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    color: AppColors.primaryGreen,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isBn
                          ? 'ছবিটি যাচাই করুন। AI (n8n & Gemini) দ্বারা স্বয়ংক্রিয়ভাবে তথ্য উদ্ধার করা হয়েছে। সঠিক হলে অনুমোদন করুন।'
                          : 'Verify the document. Text and details are extracted via AI (n8n & Gemini). Confirm if accurate.',
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

            // Image Preview Card
            Container(
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Display
                  ClipRRect(
                    borderRadius: BorderRadius.zero,
                    child: Container(
                      height: 220,
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

                  // Image Action Toolbar (Retake / Re-upload)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: const BoxDecoration(
                      color: AppColors.bgMuted,
                      border: Border(
                        top: BorderSide(color: AppColors.border),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickNewImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt_outlined, size: 16),
                            label: Text(
                              isBn ? 'পুনরায় ছবি তুলুন' : 'Retake Camera',
                              style: GoogleFonts.notoSansBengali(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickNewImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_outlined, size: 16),
                            label: Text(
                              isBn ? 'গ্যালারি থেকে নিন' : 'Choose Gallery',
                              style: GoogleFonts.notoSansBengali(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
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

            // Extracted Details Section
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
                          const Icon(Icons.auto_awesome, size: 18, color: AppColors.primaryGreen),
                          const SizedBox(width: 6),
                          Text(
                            isBn ? 'উদ্ধারকৃত তথ্য (Gemini AI)' : 'Extracted Data (Gemini AI)',
                            style: GoogleFonts.notoSansBengali(
                              fontSize: 14,
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
                            _extractionSource == 'n8n' ? 'via n8n' : 'Direct AI',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Divider(height: 20, color: AppColors.border),

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
                                  ? 'n8n workflow ও Gemini AI দ্বারা নথি যাচাই করা হচ্ছে...'
                                  : 'Analyzing document with n8n workflow & Gemini AI...',
                              style: GoogleFonts.notoSansBengali(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: AppColors.lightRed50,
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 12,
                          color: AppColors.primaryRed,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton.icon(
                        onPressed: _processWithN8nWorkflow,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: Text(
                          isBn ? 'পুনরায় চেষ্টা করুন' : 'Retry Extraction',
                          style: GoogleFonts.notoSansBengali(),
                        ),
                      ),
                    ),
                  ] else if (_extractedData != null) ...[
                    ..._buildExtractedFieldsList(isBn),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Confirm & Approve Button
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildExtractedFieldsList(bool isBn) {
    if (_extractedData == null) return [];

    final entries = _extractedData!.entries.toList();
    return entries.map((entry) {
      final key = entry.key;
      final val = entry.value?.toString() ?? '';

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                _formatFieldKey(key, isBn),
                style: GoogleFonts.notoSansBengali(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SelectableText(
                val,
                style: GoogleFonts.notoSansBengali(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _formatFieldKey(String key, bool isBn) {
    final lower = key.toLowerCase();
    if (lower.contains('name') && !lower.contains('father') && !lower.contains('mother')) {
      return isBn ? 'নাম:' : 'Name:';
    }
    if (lower.contains('id') || lower.contains('nid') || lower.contains('number')) {
      return isBn ? 'নম্বর / আইডি:' : 'ID / Number:';
    }
    if (lower.contains('birth') || lower.contains('dob')) {
      return isBn ? 'জন্ম তারিখ:' : 'Date of Birth:';
    }
    if (lower.contains('blood')) {
      return isBn ? 'রক্তের গ্রুপ:' : 'Blood Group:';
    }
    if (lower.contains('father')) {
      return isBn ? 'পিতার নাম:' : 'Father\'s Name:';
    }
    if (lower.contains('mother')) {
      return isBn ? 'মাতার নাম:' : 'Mother\'s Name:';
    }
    if (lower.contains('address')) {
      return isBn ? 'ঠিকানা:' : 'Address:';
    }
    return '$key:';
  }
}
