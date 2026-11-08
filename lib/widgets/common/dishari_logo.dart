import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/constants.dart';

class DishariLogo extends StatelessWidget {
  final double height;
  final bool isDark;
  final bool isBn;
  final bool showText;

  const DishariLogo({
    super.key,
    this.height = 36,
    this.isDark = false,
    this.isBn = true,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Dishari Mark SVG
        SvgPicture.asset(
          'assets/icons/dishari_mark.svg',
          height: height,
          width: height,
        ),
        if (showText) ...[
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isBn ? 'দিশারী' : 'Dishari',
                style: GoogleFonts.notoSansBengali(
                  fontSize: height * 0.48,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.darkGreen,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                isBn ? 'সরকারি সেবা সহজ ভাষায়' : 'Government Services Simplified',
                style: GoogleFonts.notoSansBengali(
                  fontSize: height * 0.24,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF6EE7B7) : AppColors.primaryGreen,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

