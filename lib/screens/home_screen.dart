import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../providers/language_provider.dart';
import '../providers/services_provider.dart';
import '../widgets/home/hero_section.dart';
import '../widgets/home/ai_teaser.dart';
import '../widgets/home/weather_advisory.dart';
import '../widgets/home/category_grid.dart';
import '../widgets/home/featured_services.dart';
import '../widgets/home/how_it_works.dart';
import 'service_detail_screen.dart';
import 'opportunities_screen.dart';

class HomeScreen extends StatelessWidget {
  final Function(int targetTab) onNavigateTab;

  const HomeScreen({
    super.key,
    required this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final servicesProvider =
        Provider.of<ServicesProvider>(context, listen: false);
    final isBn = langProvider.isBn;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero Section
          HeroSection(
            onSelectService: (slug) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ServiceDetailScreen(slug: slug),
                ),
              );
            },
            onSearchSubmit: (query) {
              servicesProvider.setSearchQuery(query);
              onNavigateTab(1); // Navigate to Services tab
            },
          ),
          const SizedBox(height: 8),

          // Jonobondhu AI Citizen Assistant Banner Card
          const AiTeaser(),
          const SizedBox(height: 8),

          // Weather & Rural Civic Advisory
          const WeatherAdvisory(),
          const SizedBox(height: 8),

          // Categories Grid
          CategoryGrid(
            onSelectCategory: (slug) {
              servicesProvider.setCategory(slug);
              onNavigateTab(1); // Navigate to Services tab
            },
            onViewAll: () {
              servicesProvider.clearFilters();
              onNavigateTab(1);
            },
          ),
          const SizedBox(height: 8),

          // Featured Popular Services
          FeaturedServices(
            onSelectService: (slug) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ServiceDetailScreen(slug: slug),
                ),
              );
            },
            onViewAll: () {
              servicesProvider.clearFilters();
              onNavigateTab(1);
            },
          ),
          const SizedBox(height: 8),

          // Government Opportunities Banner
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkGreen,
              border: Border.all(color: AppColors.primaryGreen),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome,
                        size: 16, color: Color(0xFF6EE7B7)),
                    const SizedBox(width: 6),
                    Text(
                      isBn ? 'নাগরিক সুযোগ হাব' : 'CITIZEN OPPORTUNITY HUB',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF6EE7B7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isBn
                      ? 'আপনার জন্য প্রযোজ্য সরকারি সুযোগ, ঋণ ও উপবৃত্তি'
                      : 'Government Opportunities, Loans & Stipends',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isBn
                      ? 'বেকার যুব ঋণ, কৃষক প্রণোদনা, বিধবা ভাতা কিংবা উপবৃত্তির চলমান সার্কুলারগুলো দেখতে সুযোগ সার্চার ব্যবহার করুন।'
                      : 'Browse active quotas for youth skill training, farmer stimuli, and educational stipends.',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 11,
                    color: const Color(0xFFD1FAE5),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OpportunitiesScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    color: Colors.white,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isBn ? 'সকল সুযোগ ব্রাউজ করুন' : 'Browse All Schemes',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkGreen,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward,
                            size: 13, color: AppColors.darkGreen),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // How It Works Flow
          const HowItWorks(),
          const SizedBox(height: 8),

          // Footer Info Box
          Container(
            color: AppColors.darkGreen,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 2, color: AppColors.primaryRed),
                const SizedBox(height: 14),
                Text(
                  isBn
                      ? 'দিশারী — ডিজিটাল নাগরিক সহায়ক'
                      : 'Dishari — Digital Citizen Assistant',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  langProvider.t('footer.mission'),
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 11,
                    color: const Color(0xFFD1FAE5),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                const Divider(color: Color(0xFF065F46)),
                const SizedBox(height: 10),
                Text(
                  langProvider.t('footer.copyright'),
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 10,
                    color: const Color(0xFFA7F3D0),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 70), // Bottom nav bar breathing space
        ],
      ),
    );
  }
}
