import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../providers/language_provider.dart';
import '../../providers/services_provider.dart';

class FeaturedServices extends StatelessWidget {
  final Function(String slug) onSelectService;
  final VoidCallback onViewAll;

  const FeaturedServices({
    super.key,
    required this.onSelectService,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final servicesProvider = context.watch<ServicesProvider>();
    final isBn = langProvider.isBn;

    final featured = servicesProvider.featuredServices;

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
                      langProvider.t('sections.featured'),
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      langProvider.t('sections.featuredSub'),
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

          // Cards List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: featured.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final service = featured[index];
              final meta = AppConstants.categories[service.category] ??
                  AppConstants.categories['identity']!;

              final docsCountStr = isBn
                  ? '${AppConstants.toBengaliNumber(service.requiredDocs.length)}টি প্রয়োজনীয় কাগজ'
                  : '${service.requiredDocs.length} required documents';

              return InkWell(
                onTap: () => onSelectService(service.slug),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: Category tag & fee
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: meta.bgColor,
                              border: Border.all(color: meta.color.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              isBn ? meta.nameBn : meta.nameEn,
                              style: GoogleFonts.notoSansBengali(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: meta.color,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: const BoxDecoration(
                              color: AppColors.lightGreen50,
                            ),
                            child: Text(
                              AppConstants.formatFee(service.fee, isBn),
                              style: GoogleFonts.notoSansBengali(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Service Title
                      Text(
                        isBn ? service.nameBn : service.nameEn,
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),

                      // Department
                      Text(
                        isBn ? service.departmentBn : service.departmentEn,
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),

                      // Bottom stats: Processing time & Docs count
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 13, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            service.processingTimeBn,
                            style: GoogleFonts.notoSansBengali(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.description_outlined, size: 13, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              docsCountStr,
                              style: GoogleFonts.notoSansBengali(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.primaryGreen),
                        ],
                      ),
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
