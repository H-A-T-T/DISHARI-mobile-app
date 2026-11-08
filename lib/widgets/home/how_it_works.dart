import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../providers/language_provider.dart';

class HowItWorks extends StatelessWidget {
  const HowItWorks({super.key});

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final isBn = langProvider.isBn;

    final steps = [
      (
        num: 1,
        numStr: isBn ? '০১' : '01',
        icon: Icons.search,
        title: langProvider.t('steps.step1Title'),
        desc: langProvider.t('steps.step1Desc'),
      ),
      (
        num: 2,
        numStr: isBn ? '০২' : '02',
        icon: Icons.checklist_outlined,
        title: langProvider.t('steps.step2Title'),
        desc: langProvider.t('steps.step2Desc'),
      ),
      (
        num: 3,
        numStr: isBn ? '০৩' : '03',
        icon: Icons.verified_outlined,
        title: langProvider.t('steps.step3Title'),
        desc: langProvider.t('steps.step3Desc'),
      ),
    ];

    return Container(
      color: AppColors.bgSurface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Text(
            langProvider.t('sections.howItWorks'),
            style: GoogleFonts.notoSansBengali(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            langProvider.t('sections.howItWorksSub'),
            style: GoogleFonts.notoSansBengali(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),

          // 3 Flat Cards
          ...steps.map((step) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.bgSurface,
                border: Border(
                  top: BorderSide(color: AppColors.borderStrong, width: 2),
                  left: BorderSide(color: AppColors.border, width: 1),
                  right: BorderSide(color: AppColors.border, width: 1),
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.lightGreen50,
                    ),
                    child: Text(
                      step.numStr,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              step.title,
                              style: GoogleFonts.notoSansBengali(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Icon(step.icon, size: 16, color: AppColors.primaryGreen),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          step.desc,
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

