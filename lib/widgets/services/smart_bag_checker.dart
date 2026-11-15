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
      final doc = widget.service.requiredDocs[i];
      final docName = '${doc.nameEn} ${doc.nameBn}'.toLowerCase();

      final hasInLocker = widget.userLockerDocTypes.any((t) {
        if (t.contains('nid') &&
            (docName.contains('nid') || docName.contains('পরিচয়'))) {
          return true;
        }
        if (t.contains('birth') &&
            (docName.contains('birth') || docName.contains('জন্ম'))) {
          return true;
        }
        if (t.contains('photo') &&
            (docName.contains('photo') || docName.contains('ছবি'))) {
          return true;
        }
        if (t.contains('tin') &&
            (docName.contains('tin') || docName.contains('কর') || docName.contains('টিআইএন'))) {
          return true;
        }
        if (t.contains('trade') &&
            (docName.contains('trade') || docName.contains('লাইসেন্স'))) {
          return true;
        }
        if (t.contains('citizenship') &&
            (docName.contains('citizenship') || docName.contains('নাগরিকত্ব'))) {
          return true;
        }
        return false;
      });

      if (hasInLocker) {
        initial[i] = true;
      }
    }

    if (initial.isNotEmpty) {
      _updateChecked(initial);
    }
  }

  void _updateChecked(Map<int, bool> newChecked) {
    setState(() {
      _internalChecked = newChecked;
    });
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
          (docName.contains('nid') || docName.contains('পরিচয়'))) {
        return true;
      }
      if (t.contains('birth') &&
          (docName.contains('birth') || docName.contains('জন্ম'))) {
        return true;
      }
      if (t.contains('photo') &&
          (docName.contains('photo') || docName.contains('ছবি'))) {
        return true;
      }
      if (t.contains('tin') &&
          (docName.contains('tin') || docName.contains('কর') || docName.contains('টিআইএন'))) {
        return true;
      }
      if (t.contains('trade') &&
          (docName.contains('trade') || docName.contains('লাইসেন্স'))) {
        return true;
      }
      if (t.contains('citizenship') &&
          (docName.contains('citizenship') || docName.contains('নাগরিকত্ব'))) {
        return true;
      }
      return false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final isBn = langProvider.isBn;

    final totalDocs = widget.service.requiredDocs.length;
    final checkedCount =
        _internalChecked.values.where((checked) => checked).length;
    final percentReady = totalDocs > 0
        ? ((checkedCount / totalDocs) * 100).round()
        : 100;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: Border.all(color: AppColors.primaryGreen, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Banner (Bangladesh Flag Green with Red Accent)
          Container(
            color: AppColors.darkGreen,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        border: Border.all(color: const Color(0xFF34D399)),
                      ),
                      child: const Icon(
                        Icons.work_outline,
                        color: Color(0xFFA7F3D0),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                color: AppColors.primaryRed,
                                child: Text(
                                  isBn ? 'প্রস্তুতি মিটার' : 'PRE-FLIGHT CHECK',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  isBn
                                      ? 'কম্পিউটার দোকানে যাওয়ার আগে'
                                      : 'Before visiting service desk',
                                  style: GoogleFonts.notoSansBengali(
                                    fontSize: 10,
                                    color: const Color(0xFFA7F3D0),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isBn
                                ? '“আমার ব্যাগে সব কাগজ আছে তো?”'
                                : '"Do I have all documents in my bag?"',
                            style: GoogleFonts.notoSansBengali(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Readiness Progress Bar
                Container(
                  padding: const EdgeInsets.all(10),
                  color: const Color(0xFF064E3B),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                color: percentReady == 100
                                    ? AppColors.primaryGreen
                                    : percentReady >= 50
                                        ? Colors.amber[700]
                                        : AppColors.primaryRed,
                                child: Text(
                                  '${isBn ? AppConstants.toBengaliNumber(percentReady) : percentReady}% ${isBn ? "প্রস্তুত" : "Ready"}',
                                  style: GoogleFonts.notoSansBengali(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isBn
                                    ? '${AppConstants.toBengaliNumber(checkedCount)}/${AppConstants.toBengaliNumber(totalDocs)} কাগজ ব্যাগে রাখা হয়েছে'
                                    : '$checkedCount of $totalDocs docs in bag',
                                style: GoogleFonts.notoSansBengali(
                                  fontSize: 11,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.zero,
                        child: LinearProgressIndicator(
                          value: totalDocs > 0 ? checkedCount / totalDocs : 1.0,
                          minHeight: 6,
                          backgroundColor: const Color(0xFF042F2E),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            percentReady == 100
                                ? const Color(0xFF34D399)
                                : percentReady >= 50
                                    ? Colors.amber[400]!
                                    : Colors.red[300]!,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Control Toolbar (Select All / Reset)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.bgMuted,
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isBn ? 'কাগজপত্রের চেকলিস্ট' : 'Document Checklist',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: () => _markAll(true),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        child: Text(
                          isBn ? 'সব প্রস্তুত' : 'Select All',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () => _markAll(false),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        child: Text(
                          isBn ? 'রিসেট' : 'Reset',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Document Checklist Items
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.service.requiredDocs.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppColors.border),
            itemBuilder: (context, idx) {
              final doc = widget.service.requiredDocs[idx];
              final isChecked = _internalChecked[idx] ?? false;
              final isInLocker = _isDocInLocker(doc);

              return InkWell(
                onTap: () => _toggleDoc(idx),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  color: isChecked ? AppColors.lightGreen50 : AppColors.bgSurface,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Checkbox Icon
                      Padding(
                        padding: const EdgeInsets.only(top: 2, right: 10),
                        child: Icon(
                          isChecked
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          size: 20,
                          color: isChecked
                              ? AppColors.primaryGreen
                              : AppColors.textMuted,
                        ),
                      ),

                      // Document Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isBn ? doc.nameBn : doc.nameEn,
                              style: GoogleFonts.notoSansBengali(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isChecked
                                    ? AppColors.textMuted
                                    : AppColors.textPrimary,
                                decoration: isChecked
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Badge Pills Row
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                // Copy Type Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  color: doc.copyType == 'original'
                                      ? AppColors.lightGreen50
                                      : doc.copyType == 'photocopy'
                                          ? const Color(0xFFEFF6FF)
                                          : doc.copyType == 'both'
                                              ? AppColors.amber50
                                              : const Color(0xFFFAF5FF),
                                  child: Text(
                                    doc.copyType == 'original'
                                        ? (isBn ? 'মূল কপি প্রয়োজন' : 'Original Required')
                                        : doc.copyType == 'photocopy'
                                            ? (isBn ? 'সত্যায়িত ফটোকপি' : 'Attested Photocopy')
                                            : doc.copyType == 'both'
                                                ? (isBn ? 'মূল + ফটোকপি উভয়ই' : 'Both Original & Copy')
                                                : (isBn ? 'অনলাইন প্রিন্ট কপি' : 'Digital / Online Copy'),
                                    style: GoogleFonts.notoSansBengali(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: doc.copyType == 'original'
                                          ? AppColors.darkGreen
                                          : doc.copyType == 'photocopy'
                                              ? const Color(0xFF1E40AF)
                                              : doc.copyType == 'both'
                                                  ? Colors.amber[900]
                                                  : const Color(0xFF6B21A8),
                                    ),
                                  ),
                                ),

                                // In Locker Badge
                                if (isInLocker)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    color: AppColors.lightGreen50,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.check,
                                            size: 10,
                                            color: AppColors.primaryGreen),
                                        const SizedBox(width: 3),
                                        Text(
                                          isBn ? 'লকারে বিদ্যমান' : 'In Locker',
                                          style: GoogleFonts.notoSansBengali(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primaryGreen,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),

                            // Note Callout if present
                            if (doc.noteBn != null && doc.noteBn!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppColors.amber50,
                                  border: Border(
                                    left: BorderSide(
                                        color: AppColors.amber500, width: 2),
                                  ),
                                ),
                                child: Text(
                                  '${isBn ? "নির্দেশনা:" : "Note:"} ${doc.noteBn!}',
                                  style: GoogleFonts.notoSansBengali(
                                    fontSize: 10,
                                    color: Colors.amber[950],
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Footer Status Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.bgMuted,
              border: Border(
                top: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  percentReady == 100
                      ? (isBn ? '✓ আপনার ব্যাগে সব প্রস্তুত!' : '✓ All papers ready in bag!')
                      : (isBn
                          ? '○ দোকানে যাওয়ার আগে বাকি কাগজগুলো সংগ্রহ করুন'
                          : '○ Complete missing papers before visiting'),
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: percentReady == 100
                        ? AppColors.primaryGreen
                        : AppColors.textSecondary,
                  ),
                ),
                Text(
                  isBn ? 'ক্লিক করে টিক দিন' : 'Tap to toggle',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 9,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
