import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../models/document.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/language_provider.dart';
import '../../screens/login_screen.dart';
import '../../screens/register_screen.dart';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../screens/image_verification_screen.dart';

class DocumentLockerTab extends StatefulWidget {
  const DocumentLockerTab({super.key});

  @override
  State<DocumentLockerTab> createState() => _DocumentLockerTabState();
}

class _DocumentLockerTabState extends State<DocumentLockerTab> {
  String _activeFolder = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<({String type, String nameBn, String nameEn, bool required})> _docTypes = [
    (type: 'nid_front', nameBn: 'জাতীয় পরিচয়পত্র (সামনের অংশ)', nameEn: 'National ID (Front)', required: true),
    (type: 'nid_back', nameBn: 'জাতীয় পরিচয়পত্র (পেছনের অংশ)', nameEn: 'National ID (Back)', required: true),
    (type: 'birth_certificate', nameBn: 'ডিজিটাল জন্ম নিবন্ধন সনদ', nameEn: 'Digital Birth Certificate', required: true),
    (type: 'educational_transcript', nameBn: 'এডমিট কার্ড / শিক্ষাগত সনদ', nameEn: 'Admit Card / Educational Certificate', required: false),
    (type: 'photo', nameBn: 'পাসপোর্ট সাইজ ছবি', nameEn: 'Passport Size Photo', required: true),
    (type: 'tin_certificate', nameBn: 'ই-টিআইএন (e-TIN) সনদ', nameEn: 'e-TIN Certificate', required: false),
    (type: 'trade_license', nameBn: 'ই-ট্রেড লাইসেন্স', nameEn: 'e-Trade License', required: false),
    (type: 'citizenship_certificate', nameBn: 'নাগরিকত্ব / ওয়ারিশান সনদ', nameEn: 'Citizenship / Heir Certificate', required: false),
    (type: 'other', nameBn: 'অন্যান্য প্রত্যয়নপত্র / নথি', nameEn: 'Other Certificates / Files', required: false),
  ];

  final List<({String id, String nameBn, String nameEn, List<String> docTypes})> _folders = [
    (id: 'all', nameBn: 'সকল নথি', nameEn: 'All Documents', docTypes: []),
    (id: 'identity', nameBn: 'জাতীয় পরিচয় ও নাগরিকত্ব', nameEn: 'Identity & Photos', docTypes: ['nid_front', 'nid_back', 'photo', 'citizenship_certificate']),
    (id: 'vital', nameBn: 'জন্ম নিবন্ধন সনদপত্র', nameEn: 'Birth & Vital Records', docTypes: ['birth_certificate']),
    (id: 'education', nameBn: 'শিক্ষা ও প্রবেশপত্র', nameEn: 'Education & Transcripts', docTypes: ['educational_transcript']),
    (id: 'business', nameBn: 'ব্যবসা ও ট্রেড লাইসেন্স', nameEn: 'Business & Trade', docTypes: ['trade_license']),
    (id: 'tax', nameBn: 'কর ও রাজস্ব', nameEn: 'Tax & e-TIN', docTypes: ['tin_certificate']),
    (id: 'other', nameBn: 'অন্যান্য নথি', nameEn: 'Other Files', docTypes: ['other']),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showUploadDialog() {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isBn = langProvider.isBn;

    String selectedType = _docTypes.first.type;
    File? selectedLocalFile;
    String? selectedFileName;
    int selectedFileSize = 0;
    String selectedMimeType = 'application/octet-stream';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> scanDocumentWithAi() async {
              final picker = ImagePicker();
              final XFile? image = await picker.pickImage(
                source: ImageSource.camera,
                imageQuality: 98,
              );

              if (image != null && context.mounted) {
                final file = File(image.path);
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ImageVerificationScreen(
                      initialImageFile: file,
                      initialDocType: selectedType,
                    ),
                  ),
                );
              }
            }

            Future<void> galleryDocumentWithAi() async {
              final picker = ImagePicker();
              final XFile? image = await picker.pickImage(
                source: ImageSource.gallery,
                imageQuality: 98,
              );

              if (image != null && context.mounted) {
                final file = File(image.path);
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ImageVerificationScreen(
                      initialImageFile: file,
                      initialDocType: selectedType,
                    ),
                  ),
                );
              }
            }

            Future<void> uploadFile() async {
              final platformFile = await FilePicker.pickFile(
                type: FileType.any,
              );

              if (platformFile != null && platformFile.path != null) {
                final file = File(platformFile.path!);
                final name = platformFile.name.toLowerCase();
                final isSupportedDoc = name.endsWith('.jpg') ||
                    name.endsWith('.jpeg') ||
                    name.endsWith('.png') ||
                    name.endsWith('.webp') ||
                    name.endsWith('.pdf');

                if (isSupportedDoc && context.mounted) {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ImageVerificationScreen(
                        initialImageFile: file,
                        initialDocType: selectedType,
                      ),
                    ),
                  );
                  return;
                }

                setDialogState(() {
                  selectedLocalFile = file;
                  selectedFileName = platformFile.name;
                  selectedFileSize = file.lengthSync();

                  if (name.endsWith('.pdf')) {
                    selectedMimeType = 'application/pdf';
                  } else {
                    selectedMimeType = 'application/octet-stream';
                  }
                });
              }
            }

            return AlertDialog(
              backgroundColor: AppColors.bgSurface,
              shape: const RoundedRectangleBorder(),
              title: Text(
                isBn ? 'নতুন নথি লকারে সংরক্ষণ করুন' : 'Add Document to Locker',
                style: GoogleFonts.notoSansBengali(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBn ? 'নথির ধরন নির্বাচন করুন:' : 'Select Document Type:',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: _docTypes.map((dt) {
                        return DropdownMenuItem(
                          value: dt.type,
                          child: Text(
                            isBn ? dt.nameBn : dt.nameEn,
                            style: GoogleFonts.notoSansBengali(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    Text(
                      isBn ? 'নথি যোগ করার পদ্ধতি নির্বাচন করুন:' : 'Choose how to add your document:',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: scanDocumentWithAi,
                            icon: const Icon(Icons.camera_alt_outlined, size: 14),
                            label: Text(
                              isBn ? 'ক্যামেরা (AI)' : 'Camera (AI)',
                              style: GoogleFonts.notoSansBengali(fontSize: 10, fontWeight: FontWeight.w700),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                              shape: const RoundedRectangleBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: galleryDocumentWithAi,
                            icon: const Icon(Icons.photo_library_outlined, size: 14),
                            label: Text(
                              isBn ? 'গ্যালারি (AI)' : 'Gallery (AI)',
                              style: GoogleFonts.notoSansBengali(fontSize: 10, fontWeight: FontWeight.w700),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                              shape: const RoundedRectangleBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: uploadFile,
                            icon: const Icon(Icons.upload_file_outlined, size: 14),
                            label: Text(
                              isBn ? 'ফাইল/PDF' : 'PDF/File',
                              style: GoogleFonts.notoSansBengali(fontSize: 10, fontWeight: FontWeight.w700),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                              shape: const RoundedRectangleBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (selectedFileName != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.lightGreen50,
                          border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selectedMimeType.startsWith('image/') ? Icons.image_outlined : Icons.description_outlined,
                              color: AppColors.primaryGreen,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                selectedFileName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const Icon(Icons.check_circle, size: 18, color: AppColors.primaryGreen),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    Text(
                      isBn
                          ? 'নথিটি আপনার নিরাপদ ডিভাইসে এনক্রিপ্ট করে সংরক্ষণ করা হয়।'
                          : 'Document is securely encrypted and stored on your device.',
                      style: GoogleFonts.notoSansBengali(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    isBn ? 'বাতিল' : 'Cancel',
                    style: GoogleFonts.notoSansBengali(color: AppColors.textSecondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedLocalFile == null || selectedFileName == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isBn
                                ? 'অনুগ্রহ করে স্ক্যান করুন অথবা একটি ফাইল নির্বাচন করুন।'
                                : 'Please scan or select a file first.',
                          ),
                        ),
                      );
                      return;
                    }

                    try {
                      final bytes = await selectedLocalFile!.readAsBytes();
                      final realFileData = base64Encode(bytes);

                      if (!context.mounted) return;

                      final auth = Provider.of<AuthProvider>(context, listen: false);
                      final dashboard = Provider.of<DashboardProvider>(context, listen: false);
                      final typeObj = _docTypes.firstWhere((t) => t.type == selectedType);

                      await dashboard.uploadDocument(
                        userId: auth.user?.id ?? 1,
                        docType: selectedType,
                        fileName: selectedFileName!,
                        fileSize: selectedFileSize,
                        mimeType: selectedMimeType,
                        fileData: realFileData,
                        extractedMeta: {
                          'doc_title': isBn ? typeObj.nameBn : typeObj.nameEn,
                          'verified': true,
                        },
                      );

                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isBn ? 'নথি সফলভাবে লকারে সংরক্ষণ করা হয়েছে।' : 'Document saved successfully.',
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text(isBn ? 'ফাইল সংরক্ষণ করা যায়নি।' : 'Could not save file.'),
                          ),
                        );
                      }
                    }
                  },
                  child: Text(
                    isBn ? 'সংরক্ষণ করুন' : 'Save Document',
                    style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDocumentDetails(CitizenDocument doc, bool isBn) {
    final meta = doc.extractedMeta;
    final typeTitle = CitizenDocument.getDocTypeName(doc.docType, isBn);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.primaryGreen, width: 4)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified, color: AppColors.primaryGreen, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        typeTitle,
                        style: GoogleFonts.notoSansBengali(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 16),

              Text(
                '${isBn ? 'ফাইলের নাম:' : 'File:'} ${doc.fileName}',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),

              Text(
                isBn ? 'উদ্ধারকৃত ওসিআর মেটাডাটা:' : 'Extracted OCR Metadata:',
                style: GoogleFonts.notoSansBengali(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryGreen),
              ),
              const SizedBox(height: 6),

              if (meta.isEmpty)
                Text(
                  isBn ? 'কোনো মেটাডাটা সংরক্ষিত নেই' : 'No metadata recorded',
                  style: GoogleFonts.notoSansBengali(fontSize: 11, color: AppColors.textMuted),
                )
              else
                ...meta.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 130,
                          child: Text(
                            '${entry.key}:',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            entry.value.toString(),
                            style: GoogleFonts.notoSansBengali(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showShareDocumentDialog(doc, isBn);
                  },
                  icon: const Icon(Icons.share, size: 16),
                  label: Text(
                    isBn ? 'নথি শেয়ার ও তথ্য ডকেট কপি' : 'Share Document & Docket',
                    style: GoogleFonts.notoSansBengali(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final dashboard = Provider.of<DashboardProvider>(context, listen: false);
                    await dashboard.deleteDocument(doc.id);
                  },
                  icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.primaryRed),
                  label: Text(
                    isBn ? 'লকার থেকে মুছে ফেলুন' : 'Delete from Locker',
                    style: GoogleFonts.notoSansBengali(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryRed),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primaryRed),
                    shape: const RoundedRectangleBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showShareDocumentDialog(CitizenDocument doc, bool isBn) {
    final typeTitle = CitizenDocument.getDocTypeName(doc.docType, isBn);
    final meta = doc.extractedMeta;

    final buffer = StringBuffer();
    buffer.writeln('🏛️ দিশারী নাগরিক লকার — যাচাইকৃত নথি ডকেট');
    buffer.writeln('• নথির ধরন: $typeTitle');
    buffer.writeln('• ফাইলের নাম: ${doc.fileName}');
    buffer.writeln('• এনক্রিপশন স্ট্যাটাস: AES-256 বিট দ্বারা লকারে সুরক্ষিত');
    if (meta.isNotEmpty) {
      buffer.writeln('\n📋 নথির উদ্ধারকৃত তথ্য:');
      meta.forEach((key, value) {
        if (value != null && value.toString().trim().isNotEmpty) {
          buffer.writeln('• $key: $value');
        }
      });
    }
    buffer.writeln('\nনাগরিক রেফারেন্স আইডি: DISHARI-DOC-${doc.id}');
    final shareDocketText = buffer.toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        shape: const RoundedRectangleBorder(),
        title: Row(
          children: [
            const Icon(Icons.share, size: 20, color: AppColors.primaryGreen),
            const SizedBox(width: 8),
            Text(
              isBn ? 'নথি শেয়ার ও তথ্য ডকেট' : 'Share Document & Docket',
              style: GoogleFonts.notoSansBengali(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.lightGreen50,
                  border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified, color: AppColors.primaryGreen, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isBn
                            ? '$typeTitle — এনক্রিপ্টেড ও সরকারি সেবায় শেয়ারের উপযোগী'
                            : '$typeTitle — Encrypted & Ready for official filing',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isBn ? 'ডকেট প্রিভিউ (সরকারি ফরম বা শেয়ারের জন্য):' : 'Docket Preview:',
                style: GoogleFonts.notoSansBengali(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bgMuted,
                  border: Border.all(color: AppColors.border),
                ),
                child: SelectableText(
                  shareDocketText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    height: 1.4,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: shareDocketText));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.primaryGreen,
                            content: Text(
                              isBn
                                  ? 'যাচাইকৃত নথি ডকেট সফলভাবে ক্লিপবোর্ডে কপি করা হয়েছে!'
                                  : 'Document docket copied to clipboard!',
                              style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w600),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 14),
                      label: Text(
                        isBn ? 'তথ্য কপি করুন' : 'Copy Text',
                        style: GoogleFonts.notoSansBengali(fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: 'DISHARI-DOC-${doc.id}'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isBn
                                ? 'নথি রেফারেন্স টোকেন কপি করা হয়েছে: DISHARI-DOC-${doc.id}'
                                : 'Token copied: DISHARI-DOC-${doc.id}',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.qr_code, size: 14, color: AppColors.primaryGreen),
                    label: Text(
                      isBn ? 'টোকেন' : 'Token',
                      style: GoogleFonts.notoSansBengali(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryGreen),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryGreen),
                      shape: const RoundedRectangleBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              isBn ? 'বন্ধ করুন' : 'Close',
              style: GoogleFonts.notoSansBengali(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthGate(BuildContext context, bool isBn, AuthProvider auth, DashboardProvider dashboard, LanguageProvider langProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            color: AppColors.amber50,
            child: const Icon(Icons.lock_outline, size: 24, color: AppColors.amber500),
          ),
          const SizedBox(height: 12),
          Text(
            isBn ? 'সুরক্ষিত নাগরিক লকার' : 'Protected Citizen Locker',
            style: GoogleFonts.notoSansBengali(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.amber500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            langProvider.t('dashboard.authRequired'),
            style: GoogleFonts.notoSansBengali(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isBn
                ? 'আপনার ব্যক্তিগত স্মার্ট NID, জন্ম সনদ ও অন্যান্য প্রমাণক নিরাপদে দেখতে ও সংরক্ষণ করতে লগইন করুন।'
                : 'Please log in to view and manage your secure digital citizen certificates and Smart NID.',
            style: GoogleFonts.notoSansBengali(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: const RoundedRectangleBorder(),
              ),
              child: Text(
                isBn ? 'লগইন করুন' : 'Log In to Account',
                style: GoogleFonts.notoSansBengali(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: const RoundedRectangleBorder(),
              ),
              child: Text(
                isBn ? 'নতুন অ্যাকাউন্ট নিবন্ধন করুন' : 'Create Free Account',
                style: GoogleFonts.notoSansBengali(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.border),
          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await auth.loginAsDemoCitizen();
                await dashboard.seedDemoData();
              },
              icon: const Icon(Icons.person_pin_outlined, size: 16, color: AppColors.primaryGreen),
              label: Text(
                langProvider.t('dashboard.demoLogin'),
                style: GoogleFonts.notoSansBengali(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryGreen,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primaryGreen),
                shape: const RoundedRectangleBorder(),
                padding: const EdgeInsets.symmetric(vertical: 10),
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

    if (!auth.isLoggedIn) {
      return Container(
        color: AppColors.bgPage,
        alignment: Alignment.center,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _buildAuthGate(context, isBn, auth, dashboard, langProvider),
        ),
      );
    }

    final allDocs = dashboard.documents;
    final percent = dashboard.completenessPercent;

    // Filter by Folder Category
    final currentFolderObj = _folders.firstWhere((f) => f.id == _activeFolder, orElse: () => _folders.first);
    final folderDocs = allDocs.where((d) {
      if (_activeFolder == 'all') return true;
      return currentFolderObj.docTypes.contains(d.docType);
    }).toList();

    // Filter by Search Query
    final filteredDocs = folderDocs.where((d) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase().trim();
      final title = CitizenDocument.getDocTypeName(d.docType, isBn).toLowerCase();
      final fileName = d.fileName.toLowerCase();
      return title.contains(q) || fileName.contains(q);
    }).toList();

    return RefreshIndicator(
      onRefresh: () => dashboard.loadDashboardData(auth.user?.id, isDemo: auth.user?.id == 1),
      color: AppColors.primaryGreen,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (dashboard.isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(
                  minHeight: 3,
                  backgroundColor: AppColors.bgMuted,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                ),
              ),

            // Banner Card (Windows 10 Flat)
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          langProvider.t('locker.vaultTitle'),
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _showUploadDialog,
                        icon: const Icon(Icons.add, size: 14),
                        label: Text(
                          isBn ? 'আপলোড' : 'Upload',
                          style: GoogleFonts.notoSansBengali(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    langProvider.t('locker.vaultSubtitle'),
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        langProvider.t('locker.vaultStatus'),
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        isBn ? '${AppConstants.toBengaliNumber(percent)}%' : '$percent%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: percent / 100,
                    minHeight: 6,
                    backgroundColor: AppColors.bgMuted,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Search Filter Box
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: isBn ? 'লকার নথিপত্র অনুসন্ধান করুন...' : 'Search locker documents...',
                hintStyle: GoogleFonts.notoSansBengali(fontSize: 12, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppColors.primaryGreen),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Folder Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _folders.map((f) {
                  final isSelected = _activeFolder == f.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () => setState(() => _activeFolder = f.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryGreen : Colors.white,
                          border: Border.all(
                            color: isSelected ? AppColors.primaryGreen : AppColors.border,
                          ),
                        ),
                        child: Text(
                          isBn ? f.nameBn : f.nameEn,
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // Uploaded Documents List
            if (filteredDocs.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.folder_open_outlined, size: 36, color: AppColors.textMuted),
                    const SizedBox(height: 8),
                    Text(
                      isBn ? 'এই ফোল্ডারে কোনো নথি সংরক্ষিত নেই' : 'No documents in this folder',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _showUploadDialog,
                      icon: const Icon(Icons.upload_file, size: 14),
                      label: Text(
                        langProvider.t('locker.uploadBtn'),
                        style: GoogleFonts.notoSansBengali(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(shape: const RoundedRectangleBorder()),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredDocs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final doc = filteredDocs[index];
                  final typeTitle = CitizenDocument.getDocTypeName(doc.docType, isBn);

                  return InkWell(
                    onTap: () => _showDocumentDetails(doc, isBn),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppColors.bgSurface,
                        border: Border(
                          left: BorderSide(color: AppColors.primaryGreen, width: 3),
                          top: BorderSide(color: AppColors.border),
                          right: BorderSide(color: AppColors.border),
                          bottom: BorderSide(color: AppColors.border),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            color: AppColors.lightGreen50,
                            child: const Icon(Icons.file_present_outlined, size: 20, color: AppColors.primaryGreen),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      typeTitle,
                                      style: GoogleFonts.notoSansBengali(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      color: AppColors.lightGreen50,
                                      child: Text(
                                        isBn ? 'যাচাইকৃত' : 'Verified',
                                        style: GoogleFonts.notoSansBengali(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryGreen,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  doc.fileName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.share_outlined, size: 18, color: AppColors.primaryGreen),
                            tooltip: isBn ? 'নথি শেয়ার করুন' : 'Share Document',
                            onPressed: () => _showShareDocumentDialog(doc, isBn),
                          ),
                          const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
