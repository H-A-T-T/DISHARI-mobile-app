import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/constants.dart';
import '../../providers/language_provider.dart';
import 'dishari_logo.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onNotificationTap;

  const CustomAppBar({
    super.key,
    this.onNotificationTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(63);

  Future<void> _callHelpline() async {
    final uri = Uri.parse('tel:333');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final isBn = langProvider.isBn;

    return SafeArea(
      bottom: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top 3px Bangladesh Green Accent Strip
          Container(
            height: 3,
            color: AppColors.primaryGreen,
          ),
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: AppColors.bgSurface,
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Logo
                DishariLogo(
                  height: 34,
                  isBn: isBn,
                ),

                // Action Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Helpline 333 Button
                    InkWell(
                      onTap: _callHelpline,
                      borderRadius: BorderRadius.zero,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.lightGreen50,
                          border: Border.all(
                            color:
                                AppColors.primaryGreen.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.phone,
                              size: 13,
                              color: AppColors.primaryGreen,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isBn ? '৩৩৩' : '333',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Language Switcher Pill
                    InkWell(
                      onTap: () => langProvider.toggleLanguage(),
                      borderRadius: BorderRadius.zero,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.bgMuted,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          isBn ? 'EN' : 'বাং',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),

                    // Notifications Icon
                    if (onNotificationTap != null) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_none_outlined,
                          color: AppColors.textPrimary,
                          size: 22,
                        ),
                        onPressed: onNotificationTap,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
