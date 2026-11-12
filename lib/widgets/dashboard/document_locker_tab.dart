import 'package:flutter/material.dart';
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

class DocumentLockerTab extends StatefulWidget {
  const DocumentLockerTab({super.key});

  @override
  State<DocumentLockerTab> createState() => _DocumentLockerTabState();
}

class _DocumentLockerTabState extends State<DocumentLockerTab> {
  final List<({String type, String nameBn, String nameEn, bool required})> _docTypes = [
    (type: 'nid_front', nameBn: 'জাতীয় পরিচয়পত্র (সামনে)', nameEn: 'National ID (Front)', required: true),
    (type: 'nid_back', nameBn: 'জাতীয় পরিচয়পত্র (পেছনে)', nameEn: 'National ID (Back)', required: true),
    (type: 'birth_certificate', nameBn: 'ডিজিটাল জন্ম নিবন্ধন সনদ', nameEn: 'Digital Birth Certificate', required: true),
    (type: 'photo', nameBn: 'পাসপোর্ট সাইজ ছবি', nameEn: 'Passport Size Photo', required: true),
    (type: 'tin_certificate', nameBn: 'ই-টিআইএন (e-TIN) সনদ', nameEn: 'e-TIN Certificate', required: false),
    (type: 'trade_license', nameBn: 'ই-ট্রেড লাইসেন্স', nameEn: 'e-Trade License', required: false),
    (type: 'citizenship_certificate', nameBn: 'নাগরিকত্ব সনদপত্র', nameEn: 'Citizenship Certificate', required: false),
  ];

void _showUploadDialog() {
  final langProvider =
      Provider.of<LanguageProvider>(context, listen: false);
  final isBn = langProvider.isBn;

  String selectedType = _docTypes.first.type;

  // নির্বাচিত আসল file-এর তথ্য
  File? selectedLocalFile;
  String? selectedFileName;
  int selectedFileSize = 0;
  String selectedMimeType = 'application/octet-stream';

  showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          // Camera দিয়ে Scan
          Future<void> scanDocument() async {
            final picker = ImagePicker();

            final XFile? image = await picker.pickImage(
              source: ImageSource.camera,
              imageQuality: 90,
            );

            if (image != null) {
              final file = File(image.path);

              setDialogState(() {
                selectedLocalFile = file;
                selectedFileName = image.name;
                selectedFileSize = file.lengthSync();
                selectedMimeType = 'image/jpeg';
              });
            }
          }

          // File Explorer থেকে যেকোনো file নির্বাচন
         Future<void> uploadFile() async {
           final platformFile = await FilePicker.pickFile(
             type: FileType.any,
           );

  if (platformFile != null && platformFile.path != null) {
    final file = File(platformFile.path!);

    setDialogState(() {
      selectedLocalFile = file;
      selectedFileName = platformFile.name;
      selectedFileSize = file.lengthSync();

      // PDF/Image অনুযায়ী MIME type
      final name = platformFile.name.toLowerCase();

      if (name.endsWith('.pdf')) {
        selectedMimeType = 'application/pdf';
      } else if (name.endsWith('.png')) {
        selectedMimeType = 'image/png';
      } else if (name.endsWith('.jpg') || name.endsWith('.jpeg')) {
        selectedMimeType = 'image/jpeg';
      } else {
        selectedMimeType = 'application/octet-stream';
      }
    });
  }
}

          return AlertDialog(
            backgroundColor: AppColors.bgSurface,
            shape: const RoundedRectangleBorder(),

            // এই লেখা অপরিবর্তিত থাকবে
            title: Text(
              isBn
                  ? 'নতুন নথি লকারে সংরক্ষণ করুন'
                  : 'Add Document to Locker',
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
                  // এই লেখা অপরিবর্তিত থাকবে
                  Text(
                    isBn
                        ? 'নথির ধরন নির্বাচন করুন:'
                        : 'Select Document Type:',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Document Type Dropdown অপরিবর্তিত
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                    items: _docTypes.map((dt) {
                      return DropdownMenuItem(
                        value: dt.type,
                        child: Text(
                          isBn ? dt.nameBn : dt.nameEn,
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedType = val;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  // নতুন Scan এবং Upload File option
                  Text(
                    isBn
                        ? 'নথি যোগ করার পদ্ধতি নির্বাচন করুন:'
                        : 'Choose how to add your document:',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      // Scan Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: scanDocument,
                          icon: const Icon(
                            Icons.document_scanner_outlined,
                            size: 18,
                          ),
                          label: Text(
                            isBn ? 'স্ক্যান' : 'Scan',
                            style: GoogleFonts.notoSansBengali(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Upload File Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: uploadFile,
                          icon: const Icon(
                            Icons.upload_file_outlined,
                            size: 18,
                          ),
                          label: Text(
                            isBn ? 'ফাইল আপলোড' : 'Upload File',
                            style: GoogleFonts.notoSansBengali(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // File নির্বাচিত হলে নাম দেখাবে
                  if (selectedFileName != null) ...[
                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.lightGreen50,
                        border: Border.all(
                          color: AppColors.primaryGreen
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selectedMimeType.startsWith('image/')
                                ? Icons.image_outlined
                                : Icons.description_outlined,
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
                          const Icon(
                            Icons.check_circle,
                            size: 18,
                            color: AppColors.primaryGreen,
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // এই security লেখা অপরিবর্তিত থাকবে
                  Text(
                    isBn
                        ? 'নথিটি আপনার নিরাপদ ডিভাইসে এনক্রিপ্ট করে সংরক্ষণ করা হয়।'
                        : 'Document is securely encrypted and stored on your device.',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            actions: [
              // Cancel Button অপরিবর্তিত
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  isBn ? 'বাতিল' : 'Cancel',
                  style: GoogleFonts.notoSansBengali(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),

              // Save আসল File-এর data ব্যবহার করবে
              ElevatedButton(
                onPressed: () async {
                  // File ছাড়া Save করা যাবে না
                  if (selectedLocalFile == null ||
                      selectedFileName == null) {
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
                    // আসল file-এর bytes পড়া হচ্ছে
                    final bytes =
                        await selectedLocalFile!.readAsBytes();

                    // আসল file data Base64-এ convert করা হচ্ছে
                    final realFileData = base64Encode(bytes);

                    final auth = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    );

                    final dashboard =
                        Provider.of<DashboardProvider>(
                      context,
                      listen: false,
                    );

                    final typeObj = _docTypes.firstWhere(
                      (t) => t.type == selectedType,
                    );

                    // MOCK_BASE64_DATA আর নেই
                    // আসল নির্বাচিত file-এর data পাঠানো হচ্ছে
                    await dashboard.uploadDocument(
                      userId: auth.user?.id ?? 1,
                      docType: selectedType,
                      fileName: selectedFileName!,
                      fileSize: selectedFileSize,
                      mimeType: selectedMimeType,
                      fileData: realFileData,
                      extractedMeta: {
                        'title':
                            isBn ? typeObj.nameBn : typeObj.nameEn,
                        'verified': true,
                      },
                    );

                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }

                    if (mounted) {
                      ScaffoldMessenger.of(this.context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            isBn
                                ? 'নথি সফলভাবে লকারে সংরক্ষণ করা হয়েছে।'
                                : 'Document successfully saved to your locker.',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(this.context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            isBn
                                ? 'ফাইল সংরক্ষণ করা যায়নি। আবার চেষ্টা করুন।'
                                : 'Could not save the file. Please try again.',
                          ),
                        ),
                      );
                    }
                  }
                },
                child: Text(
                  isBn ? 'সংরক্ষণ করুন' : 'Save Document',
                  style: GoogleFonts.notoSansBengali(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
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

          // Login Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
              child: Text(
                isBn ? 'লগইন করুন' : 'Log In to Account',
                style: GoogleFonts.notoSansBengali(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Register Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
              child: Text(
                isBn ? 'নতুন অ্যাকাউন্ট নিবন্ধন করুন' : 'Create Free Account',
                style: GoogleFonts.notoSansBengali(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.border),
          const SizedBox(height: 14),

          // 1-Click Demo Login
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
                side: const BorderSide(color: AppColors.primaryGreen, style: BorderStyle.solid),
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

    // Show Auth Gate if not logged in
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

    final documents = dashboard.documents;
    final percent = dashboard.completenessPercent;

    return RefreshIndicator(
      onRefresh: () => dashboard.loadDashboardData(auth.user?.id, isDemo: auth.user?.id == 1),
      color: AppColors.primaryGreen,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Loading Bar
            if (dashboard.isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(
                  minHeight: 3,
                  backgroundColor: AppColors.bgMuted,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                ),
              ),

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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        langProvider.t('locker.vaultTitle'),
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showUploadDialog,
                        icon: const Icon(Icons.add, size: 14),
                        label: Text(
                          isBn ? 'আপলোড' : 'Upload',
                          style: GoogleFonts.notoSansBengali(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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

                  // Vault Completeness Progress Bar
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
                  ClipRRect(
                    borderRadius: BorderRadius.zero,
                    child: LinearProgressIndicator(
                      value: percent / 100,
                      minHeight: 6,
                      backgroundColor: AppColors.bgMuted,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Uploaded Documents List
            if (documents.isEmpty)
              Container(
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
                      isBn ? 'লকারে এখনও কোনো নথি সংরক্ষিত নেই' : 'No documents in locker yet',
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
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: documents.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final doc = documents[index];
                  final typeTitle = CitizenDocument.getDocTypeName(doc.docType, isBn);

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          color: AppColors.lightGreen50,
                          child: const Icon(Icons.file_present_outlined,
                              size: 20, color: AppColors.primaryGreen),
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
                          icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.primaryRed),
                          onPressed: () async {
                            await dashboard.deleteDocument(doc.id);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
