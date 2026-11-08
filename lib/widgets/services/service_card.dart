import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/constants.dart';
import '../../models/service.dart';

class ServiceCard extends StatelessWidget {
  final Service service;
  final bool isBn;
  final VoidCallback onTap;

  const ServiceCard({
    super.key,
    required this.service,
    required this.isBn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final meta = AppConstants.categories[service.category] ??
        AppConstants.categories['identity']!;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(
          color: AppColors.bgSurface,
          border: Border(
            left: BorderSide(color: AppColors.primaryGreen, width: 3),
            top: BorderSide(color: AppColors.border, width: 1),
            right: BorderSide(color: AppColors.border, width: 1),
            bottom: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category & Submission Tag
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  color: meta.bgColor,
                  child: Text(
                    isBn ? meta.nameBn : meta.nameEn,
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: meta.color,
                    ),
                  ),
                ),
                Text(
                  AppConstants.formatFee(service.fee, isBn),
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Service Title
            Text(
              isBn ? service.nameBn : service.nameEn,
              style: GoogleFonts.notoSansBengali(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 3),

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

            // Metadata footer (processing time & required docs count)
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
                const SizedBox(width: 14),
                const Icon(Icons.description_outlined, size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  isBn
                      ? '${AppConstants.toBengaliNumber(service.requiredDocs.length)}টি প্রয়োজনীয় কাগজ'
                      : '${service.requiredDocs.length} required docs',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.primaryGreen),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
