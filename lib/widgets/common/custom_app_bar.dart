import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../providers/language_provider.dart';
import 'dishari_logo.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onNotificationTap;
  final VoidCallback? onMenuTap;

  const CustomAppBar({
    super.key,
    this.onNotificationTap,
    this.onMenuTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(63);

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final isBn = langProvider.isBn;

    return SafeArea(
      bottom: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top 3px Bangladesh Green Accent Strip (Windows 10 Flat)
          Container(
            height: 3,
            color: AppColors.primaryGreen,
          ),
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              color: AppColors.bgSurface,
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Dishari Logo (Matches web Navbar)
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: DishariLogo(
                      height: 34,
                      isBn: isBn,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Action Controls Row (Language Switcher, Notifications, Mobile Hamburger)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 2. Dual Segmented Language Switcher (বাং | EN matching web Navbar.tsx)
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.zero,
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () {
                              if (!isBn) langProvider.setLanguage('bn');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isBn
                                    ? AppColors.primaryGreen
                                    : Colors.transparent,
                                borderRadius: BorderRadius.zero,
                              ),
                              child: Text(
                                'বাং',
                                style: GoogleFonts.notoSansBengali(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isBn
                                      ? Colors.white
                                      : const Color(0xFF374151),
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              if (isBn) langProvider.setLanguage('en');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: !isBn
                                    ? AppColors.primaryGreen
                                    : Colors.transparent,
                                borderRadius: BorderRadius.zero,
                              ),
                              child: Text(
                                'EN',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: !isBn
                                      ? Colors.white
                                      : const Color(0xFF374151),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 6),

                    // 3. Citizen Notification Bell with Alert Dot
                    InkWell(
                      onTap: onNotificationTap,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.zero,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(
                              Icons.notifications_none_outlined,
                              color: AppColors.textPrimary,
                              size: 20,
                            ),
                          ),
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.primaryRed,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 6),

                    // 4. Mobile Hamburger Menu Toggle (Square Windows 10 Flat)
                    Builder(
                      builder: (scaffoldContext) {
                        return InkWell(
                          onTap: onMenuTap ??
                              () {
                                Scaffold.of(scaffoldContext).openEndDrawer();
                              },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.zero,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(
                              Icons.menu,
                              color: AppColors.textPrimary,
                              size: 20,
                            ),
                          ),
                        );
                      },
                    ),
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
