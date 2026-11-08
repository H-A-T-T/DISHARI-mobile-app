import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../providers/language_provider.dart';

class CategoryGrid extends StatelessWidget {
  final Function(String categorySlug) onSelectCategory;
  final VoidCallback onViewAll;

  const CategoryGrid({
    super.key,
    required this.onSelectCategory,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final isBn = langProvider.isBn;

    const categoryOrder = [
      'identity',
      'education',
      'land',
      'welfare',
      'business',
      'tax',
      'overseas',
      'health',
    ];

    return Container(
      color: AppColors.bgSurface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      langProvider.t('sections.categories'),
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      langProvider.t('sections.categoriesSub'),
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: onViewAll,
                child: Row(
                  children: [
                    Text(
                      langProvider.t('sections.viewAll'),
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 16, color: AppColors.primaryGreen),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2-Column Responsive Grid (Clean Paper Tiles)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categoryOrder.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.2,
            ),
            itemBuilder: (context, index) {
              final slug = categoryOrder[index];
              final meta = AppConstants.categories[slug]!;
              final title = isBn ? meta.nameBn : meta.nameEn;
              final subTitle = isBn ? meta.nameEn : meta.nameBn;

              return InkWell(
                onTap: () => onSelectCategory(slug),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: meta.bgColor,
                        ),
                        child: Icon(meta.icon, size: 18, color: meta.color),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.notoSansBengali(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subTitle,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                color: AppColors.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 14, color: AppColors.textMuted),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
