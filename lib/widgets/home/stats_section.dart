import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../providers/language_provider.dart';

class StatsSection extends StatelessWidget {
  const StatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final isBn = langProvider.isBn;

    final stats = [
      {
        'num': isBn ? '৫০+' : '50+',
        'label': isBn ? '৫০+ সরকারি সেবা' : '50+ Govt Services',
      },
      {
        'num': isBn ? '৮' : '8',
        'label': isBn ? '৮ বিভাগে সেবা' : '8 Divisions Covered',
      },
      {
        'num': isBn ? '৩৩৩' : '333',
        'label': isBn ? '৩৩৩ হেল্পলাইন' : '333 Helpline',
      },
      {
        'num': isBn ? '১০০%' : '100%',
        'label': isBn ? '১০০% বিনামূল্যে' : '100% Free Access',
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.bgMuted,
        border: Border.symmetric(
          horizontal: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTile(
                  numText: stats[0]['num']!,
                  labelText: stats[0]['label']!,
                  isBn: isBn,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTile(
                  numText: stats[1]['num']!,
                  labelText: stats[1]['label']!,
                  isBn: isBn,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildTile(
                  numText: stats[2]['num']!,
                  labelText: stats[2]['label']!,
                  isBn: isBn,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTile(
                  numText: stats[3]['num']!,
                  labelText: stats[3]['label']!,
                  isBn: isBn,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTile({
    required String numText,
    required String labelText,
    required bool isBn,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
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
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              numText,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryGreen,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              labelText,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansBengali(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
