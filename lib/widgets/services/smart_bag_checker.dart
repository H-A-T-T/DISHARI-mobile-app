import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../models/service.dart';
import '../../providers/language_provider.dart';

class SmartBagChecker extends StatefulWidget {
  final Service service;
  final List<String> userLockerDocTypes;
  final Map<int, bool>? checkedInBag;
  final ValueChanged<Map<int, bool>>? onCheckedChange;

  const SmartBagChecker({
    super.key,
    required this.service,
    this.userLockerDocTypes = const [],
    this.checkedInBag,
    this.onCheckedChange,
  });

  @override
  State<SmartBagChecker> createState() => _SmartBagCheckerState();
}

class _SmartBagCheckerState extends State<SmartBagChecker> {
  late Map<int, bool> _internalChecked;

  @override
  void initState() {
    super.initState();
    _internalChecked = Map<int, bool>.from(widget.checkedInBag ?? {});
    _initializeAutoChecks();
  }

  @override
  void didUpdateWidget(covariant SmartBagChecker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.checkedInBag != null) {
      _internalChecked = Map<int, bool>.from(widget.checkedInBag!);
    }
  }

  void _initializeAutoChecks() {
    if (_internalChecked.isNotEmpty) return;
    final initial = <int, bool>{};
    for (int i = 0; i < widget.service.requiredDocs.length; i++) {
      if (_isDocInLocker(widget.service.requiredDocs[i])) {
        initial[i] = true;
      }
    }
    if (initial.isNotEmpty) _updateChecked(initial);
  }

  void _updateChecked(Map<int, bool> newChecked) {
    setState(() => _internalChecked = newChecked);
    widget.onCheckedChange?.call(newChecked);
  }

  void _toggleDoc(int index) {
    final updated = Map<int, bool>.from(_internalChecked);
    updated[index] = !(updated[index] ?? false);
    _updateChecked(updated);
  }

  void _markAll(bool status) {
    final updated = <int, bool>{};
    for (int i = 0; i < widget.service.requiredDocs.length; i++) {
      updated[i] = status;
    }
    _updateChecked(updated);
  }

  bool _isDocInLocker(RequiredDoc doc) {
    final docName = '${doc.nameEn} ${doc.nameBn}'.toLowerCase();
    return widget.userLockerDocTypes.any((t) {
      if (t.contains('nid') &&
          (docName.contains('nid') || docName.contains('পরিচয়'))) return true;
      if (t.contains('birth') &&
          (docName.contains('birth') || docName.contains('জন্ম'))) return true;
      if (t.contains('photo') &&
          (docName.contains('photo') || docName.contains('ছবি'))) return true;
      if (t.contains('tin') &&
          (docName.contains('tin') ||
              docName.contains('কর') ||
              docName.contains('টিআইএন'))) return true;
      if (t.contains('trade') &&
          (docName.contains('trade') || docName.contains('লাইসেন্স')))
        return true;
      if (t.contains('citizenship') &&
          (docName.contains('citizenship') || docName.contains('নাগরিকত্ব')))
        return true;
      return false;
    });
  }

  String _copyTypeLabel(String type, bool isBn) {
    switch (type) {
      case 'original':
        return isBn ? 'মূল কপি প্রয়োজন' : 'Original Required';
      case 'photocopy':
        return isBn ? 'সত্যায়িত ফটোকপি' : 'Attested Photocopy';
      case 'both':
        return isBn ? 'মূল + ফটোকপি উভয়ই' : 'Both Original & Copy';
      default:
        return isBn ? 'অনলাইন প্রিন্ট কপি' : 'Digital / Online Copy';
    }
  }

  Color _copyTypeBg(String type) {
    switch (type) {
      case 'original':
        return const Color(0xFFD1FAE5);
      case 'photocopy':
        return const Color(0xFFDBEAFE);
      case 'both':
        return const Color(0xFFFEF3C7);
      default:
        return const Color(0xFFF3E8FF);
    }
  }

  Color _copyTypeFg(String type) {
    switch (type) {
      case 'original':
        return const Color(0xFF065F46);
      case 'photocopy':
        return const Color(0xFF1E40AF);
      case 'both':
        return const Color(0xFF92400E);
      default:
        return const Color(0xFF6B21A8);
    }
  }

  Color _copyTypeBorder(String type) {
    switch (type) {
      case 'original':
        return const Color(0xFF6EE7B7);
      case 'photocopy':
        return const Color(0xFF93C5FD);
      case 'both':
        return const Color(0xFFFCD34D);
      default:
        return const Color(0xFFD8B4FE);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBn = context.watch<LanguageProvider>().isBn;
    final totalDocs = widget.service.requiredDocs.length;
    final checkedCount = _internalChecked.values.where((v) => v).length;
    final percentReady =
        totalDocs > 0 ? ((checkedCount / totalDocs) * 100).round() : 100;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: Border.all(color: AppColors.primaryGreen, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: AppColors.darkGreen,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      color: AppColors.primaryGreen,
                      alignment: Alignment.center,
                      child: const Icon(Icons.work_outline,
                          color: Color(0xFFA7F3D0), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                color: AppColors.primaryRed,
                                child: Text(
                                  isBn
                                      ? 'প্রস্তুতি মিটার'
                                      : 'PRE-FLIGHT BAG CHECK',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                              Text(
                                isBn
                                    ? 'কম্পিউটার দোকানে যাওয়ার আগে'
                                    : 'Before visiting service desk',
                                style: GoogleFonts.notoSansBengali(
                                    fontSize: 11,
                                    color: const Color(0xFFA7F3D0)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isBn
                                ? '“আমার ব্যাগে সব কাগজ আছে তো?”'
                                : '"Do I have all documents in my bag?"',
                            style: GoogleFonts.notoSansBengali(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        border: Border.all(
                            color:
                                const Color(0xFF6EE7B7).withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            isBn ? 'প্রস্তুতি অগ্রগতি' : 'Readiness Score',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: const Color(0xFFA7F3D0),
                                fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '$percentReady%',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white),
                          ),
                          Text(
                            '($checkedCount/$totalDocs)',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 10, color: const Color(0xFFA7F3D0)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                LinearProgressIndicator(
                  value: totalDocs > 0 ? checkedCount / totalDocs : 1.0,
                  minHeight: 8,
                  backgroundColor: Colors.black.withValues(alpha: 0.25),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    percentReady == 100
                        ? const Color(0xFF34D399)
                        : percentReady >= 50
                            ? const Color(0xFFFBBF24)
                            : const Color(0xFFF87171),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: percentReady == 100
                  ? const Color(0xFFECFDF5)
                  : percentReady >= 50
                      ? const Color(0xFFFFFBEB)
                      : const Color(0xFFFFF1F2),
              border: Border(
                bottom: BorderSide(
                  color: percentReady == 100
                      ? const Color(0xFFA7F3D0)
                      : percentReady >= 50
                          ? const Color(0xFFFDE68A)
                          : const Color(0xFFFECDD3),
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  percentReady == 100
                      ? Icons.check_circle
                      : Icons.warning_amber_rounded,
                  size: 16,
                  color: percentReady == 100
                      ? AppColors.primaryGreen
                      : AppColors.amber500,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    percentReady == 100
                        ? (isBn
                            ? 'দারুণ! সব প্রয়োজনীয় কাগজপত্র আপনার ব্যাগে প্রস্তুত। আপনি এখন সেবা কেন্দ্রে যেতে পারেন।'
                            : 'Excellent! All required documents are packed and ready.')
                        : (isBn
                            ? 'এখনো ${AppConstants.toBengaliNumber(totalDocs - checkedCount)}টি জরুরি নথি প্রস্তুত করা বাকি রয়েছে। তালিকা মিলিয়ে ব্যাগে রাখুন।'
                            : 'Still missing ${totalDocs - checkedCount} required document(s). Pack them before leaving.'),
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: percentReady == 100
                          ? const Color(0xFF064E3B)
                          : const Color(0xFF78350F),
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _markAll(percentReady != 100),
                  child: Text(
                    percentReady == 100
                        ? (isBn ? 'সব মুছুন' : 'Reset')
                        : (isBn ? 'সব সিলেক্ট করুন' : 'Select All'),
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(14),
            itemCount: widget.service.requiredDocs.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 20, color: AppColors.border),
            itemBuilder: (context, idx) {
              final doc = widget.service.requiredDocs[idx];
              final isPacked = _internalChecked[idx] ?? false;
              final inLocker = _isDocInLocker(doc);
              return InkWell(
                onTap: () => _toggleDoc(idx),
                child: Container(
                  color: isPacked
                      ? const Color(0xFFECFDF5).withValues(alpha: 0.4)
                      : Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2, right: 10),
                        child: Icon(
                          isPacked
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 20,
                          color: isPacked
                              ? AppColors.primaryGreen
                              : AppColors.textMuted,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  isBn
                                      ? doc.nameBn
                                      : (doc.nameEn.isNotEmpty
                                          ? doc.nameEn
                                          : doc.nameBn),
                                  style: GoogleFonts.notoSansBengali(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    decoration: isPacked
                                        ? TextDecoration.lineThrough
                                        : null,
                                    decorationColor: AppColors.primaryGreen,
                                    decorationThickness: 2,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _copyTypeBg(doc.copyType),
                                    border: Border.all(
                                        color: _copyTypeBorder(doc.copyType)),
                                  ),
                                  child: Text(
                                    _copyTypeLabel(doc.copyType, isBn),
                                    style: GoogleFonts.notoSansBengali(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: _copyTypeFg(doc.copyType),
                                    ),
                                  ),
                                ),
                                if (inLocker)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.lightGreen50,
                                      border: Border.all(
                                          color: const Color(0xFFA7F3D0)),
                                    ),
                                    child: Text(
                                      isBn ? 'লকারে আছে' : 'In Locker',
                                      style: GoogleFonts.notoSansBengali(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryGreen,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (doc.noteBn != null &&
                                doc.noteBn!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 1),
                                    child: Icon(Icons.info_outline,
                                        size: 13, color: AppColors.textMuted),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      doc.noteBn!,
                                      style: GoogleFonts.notoSansBengali(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                          height: 1.4),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPacked
                              ? AppColors.primaryGreen
                              : AppColors.bgMuted,
                          border: Border.all(
                              color: isPacked
                                  ? AppColors.primaryGreen
                                  : AppColors.border),
                        ),
                        child: Text(
                          isPacked
                              ? (isBn ? 'ব্যাগে আছে ✓' : 'Packed ✓')
                              : (isBn ? 'বাকি' : 'Missing'),
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isPacked
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.bgCardSubtle,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Text(
              isBn
                  ? 'টিপস: কোনো কাগজ বাদ পড়লে ইউনিয়ন ডিজিটাল সেন্টার বা দোকানে ২ বার যেতে হতে পারে।'
                  : 'Tip: Double check all original IDs before traveling to the center.',
              style: GoogleFonts.notoSansBengali(
                  fontSize: 11, color: AppColors.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
