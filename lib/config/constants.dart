import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors (Bangladesh Bottle Green & Crimson Red)
  static const Color primaryGreen = Color(0xFF006A4E);
  static const Color darkGreen = Color(0xFF004D38);
  static const Color darkestGreen = Color(0xFF003627);
  static const Color lightGreen50 = Color(0xFFF0FDF4);
  static const Color lightGreen100 = Color(0xFFDCFCE7);
  static const Color accentGreen = Color(0xFF16A34A);

  static const Color primaryRed = Color(0xFFC8102E);
  static const Color lightRed50 = Color(0xFFFEF2F2);
  static const Color crimson500 = Color(0xFFEF4444);

  static const Color amber500 = Color(0xFFF59E0B);
  static const Color amber50 = Color(0xFFFFFBEB);
  static const Color amber100 = Color(0xFFFEF3C7);

  // Neutral Palette (Clean Windows 10 Flat Warm Paper)
  static const Color bgPage = Color(0xFFFAFAF8);
  static const Color bgSurface = Color(0xFFFFFFFF);
  static const Color bgMuted = Color(0xFFF4F4F2);
  static const Color bgCardSubtle = Color(0xFFF9F9F8);

  static const Color textPrimary = Color(0xFF1C1917);
  static const Color textSecondary = Color(0xFF78716C);
  static const Color textMuted = Color(0xFFA8A29E);

  static const Color border = Color(0xFFE7E5E4);
  static const Color borderStrong = Color(0xFFD6D3D1);
  static const Color borderSubtle = Color(0xFFF0EFEB);

  // Service Category Colors
  static const Color catIdentity = Color(0xFF3B82F6);   // Blue
  static const Color catEducation = Color(0xFF8B5CF6);  // Purple
  static const Color catLand = Color(0xFFF59E0B);       // Amber
  static const Color catWelfare = Color(0xFFEC4899);    // Pink
  static const Color catBusiness = Color(0xFF14B8A6);   // Teal
  static const Color catTax = Color(0xFFF97316);        // Orange
  static const Color catOverseas = Color(0xFF06B6D4);   // Cyan
  static const Color catHealth = Color(0xFF22C55E);     // Green
}

class CategoryMeta {
  final String slug;
  final String nameBn;
  final String nameEn;
  final Color color;
  final Color bgColor;
  final Color badgeBg;
  final IconData icon;

  const CategoryMeta({
    required this.slug,
    required this.nameBn,
    required this.nameEn,
    required this.color,
    required this.bgColor,
    required this.badgeBg,
    required this.icon,
  });
}

class AppConstants {
  static const String appNameBn = 'দিশারী';
  static const String appNameEn = 'Dishari';
  static const String taglineBn = 'সরকারি সেবা এখন আপনার হাতের মুঠোয়';
  static const String taglineEn = 'Government services, now within your reach';

  static const String helplineNational = '৩৩৩';
  static const String helplineEmergency = '৯৯৯';
  static const String helplineAntiCorruption = '১০৬';

  static const Map<String, CategoryMeta> categories = {
    'identity': CategoryMeta(
      slug: 'identity',
      nameBn: 'পরিচয় ও নথিপত্র',
      nameEn: 'Identity & Documents',
      color: AppColors.catIdentity,
      bgColor: Color(0xFFEFF6FF),
      badgeBg: Color(0xFFDBEAFE),
      icon: Icons.badge_outlined,
    ),
    'education': CategoryMeta(
      slug: 'education',
      nameBn: 'শিক্ষা ও বৃত্তি',
      nameEn: 'Education & Scholarship',
      color: AppColors.catEducation,
      bgColor: Color(0xFFF5F3FF),
      badgeBg: Color(0xFFEDE9FE),
      icon: Icons.school_outlined,
    ),
    'land': CategoryMeta(
      slug: 'land',
      nameBn: 'ভূমি ও সম্পত্তি',
      nameEn: 'Land & Property',
      color: AppColors.catLand,
      bgColor: Color(0xFFFFFBEB),
      badgeBg: Color(0xFFFEF3C7),
      icon: Icons.landscape_outlined,
    ),
    'welfare': CategoryMeta(
      slug: 'welfare',
      nameBn: 'কল্যাণ ও ভাতা',
      nameEn: 'Welfare & Allowance',
      color: AppColors.catWelfare,
      bgColor: Color(0xFFFDF2F8),
      badgeBg: Color(0xFFFCE7F3),
      icon: Icons.volunteer_activism_outlined,
    ),
    'business': CategoryMeta(
      slug: 'business',
      nameBn: 'ব্যবসা ও উদ্যোগ',
      nameEn: 'Business & Enterprise',
      color: AppColors.catBusiness,
      bgColor: Color(0xFFF0FDFA),
      badgeBg: Color(0xFFCCFBF1),
      icon: Icons.business_center_outlined,
    ),
    'tax': CategoryMeta(
      slug: 'tax',
      nameBn: 'কর ও রাজস্ব',
      nameEn: 'Tax & Revenue',
      color: AppColors.catTax,
      bgColor: Color(0xFFFFF7ED),
      badgeBg: Color(0xFFFFEDD5),
      icon: Icons.receipt_long_outlined,
    ),
    'overseas': CategoryMeta(
      slug: 'overseas',
      nameBn: 'প্রবাসী সেবা',
      nameEn: 'Overseas Services',
      color: AppColors.catOverseas,
      bgColor: Color(0xFFECFEFF),
      badgeBg: Color(0xFFCFFAFE),
      icon: Icons.flight_takeoff_outlined,
    ),
    'health': CategoryMeta(
      slug: 'health',
      nameBn: 'স্বাস্থ্যসেবা',
      nameEn: 'Health Services',
      color: AppColors.catHealth,
      bgColor: Color(0xFFF0FDF4),
      badgeBg: Color(0xFFDCFCE7),
      icon: Icons.medical_services_outlined,
    ),
  };

  static String toBengaliNumber(dynamic number) {
    const bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    final str = number.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final char = str[i];
      final digit = int.tryParse(char);
      if (digit != null) {
        buffer.write(bnDigits[digit]);
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  static String toEnglishNumber(String input) {
    const bnToEn = {
      '০': '0', '১': '1', '২': '2', '৩': '3', '৪': '4',
      '৫': '5', '৬': '6', '৭': '7', '৮': '8', '৯': '9',
    };
    final buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      if (bnToEn.containsKey(char)) {
        buffer.write(bnToEn[char]);
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  static String formatFee(String fee, bool isBn) {
    if (fee == '0' || fee.toLowerCase() == 'free' || fee == 'বিনামূল্যে') {
      return isBn ? 'বিনামূল্যে' : 'Free';
    }
    return '৳$fee';
  }
}

