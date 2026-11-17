import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/constants.dart';
import '../../providers/language_provider.dart';
import '../../screens/about_screen.dart';
import '../../screens/opportunities_screen.dart';
import 'dishari_logo.dart';

class FooterWidget extends StatelessWidget {
  final Function(int targetTab)? onNavigateTab;

  const FooterWidget({
    super.key,
    this.onNavigateTab,
  });

  Future<void> _callHelpline(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final isBn = langProvider.isBn;

    return Container(
      color: AppColors.darkGreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top 3px Bangladesh Red Accent Strip (Windows 10 Flat)
          Container(
            height: 3,
            color: AppColors.primaryRed,
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Column 1: Branding & Mission
                DishariLogo(height: 32, isBn: isBn, isDark: true),
                const SizedBox(height: 10),
                Text(
                  isBn
                      ? 'বাংলাদেশের সরকারি সেবা সম্পর্কে সহজ ভাষায় তথ্য পান। কোন কাগজ লাগবে, কোথায় যেতে হবে, কত খরচ — সব এক জায়গায়।'
                      : 'Get simplified information about Bangladesh government services. Documents needed, office locations, fees — all in one place.',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 12,
                    color: const Color(0xFFD1FAE5),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 20),

                // Column 2: Quick Links (Windows 10 Flat)
                Container(
                  padding: const EdgeInsets.only(bottom: 6),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFF0D8262), width: 1.5),
                    ),
                  ),
                  child: Text(
                    isBn ? 'প্রয়োজনীয় লিংক' : 'QUICK LINKS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildQuickLink(
                  title: isBn ? 'নাগরিক সেবা সমূহ' : 'All Citizen Services',
                  onTap: () => onNavigateTab?.call(1),
                ),
                _buildQuickLink(
                  title: isBn ? 'সরকারি সুযোগ ও সহায়তা' : 'Government Opportunities',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OpportunitiesScreen(),
                      ),
                    );
                  },
                ),
                _buildQuickLink(
                  title: isBn ? 'আমাদের লক্ষ্য ও পরিচিতি' : 'About Dishari',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AboutScreen(),
                      ),
                    );
                  },
                ),
                _buildQuickLink(
                  title: isBn ? 'নাগরিক ড্যাশবোর্ড ও লকার' : 'Citizen Dashboard & Locker',
                  onTap: () => onNavigateTab?.call(4),
                ),

                const SizedBox(height: 20),

                // Column 3: Emergency Helplines
                Container(
                  padding: const EdgeInsets.only(bottom: 6),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFF0D8262), width: 1.5),
                    ),
                  ),
                  child: Text(
                    isBn ? 'জরুরি হেল্পলাইন' : 'EMERGENCY HELPLINES',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildHelplineItem(
                  number: '333',
                  label: isBn ? '৩৩৩ — সরকারি তথ্য ও সেবা' : '333 — Civic Information & Services',
                ),
                _buildHelplineItem(
                  number: '999',
                  label: isBn ? '৯৯৯ — জাতীয় জরুরি সেবা (পুলিশ, অ্যাম্বুলেন্স)' : '999 — National Emergency',
                ),
                _buildHelplineItem(
                  number: '106',
                  label: isBn ? '১০৬ — দুর্নীতি দমন কমিশন (দুদক)' : '106 — Anti-Corruption Commission',
                ),

                const SizedBox(height: 20),

                // Bottom Bar: Copyright & Built By
                const Divider(color: Color(0xFF065F46)),
                const SizedBox(height: 8),
                Text(
                  isBn
                      ? '© ২০২৬ দিশারী। সর্বস্বত্ব সংরক্ষিত।'
                      : '© 2026 Dishari. All rights reserved.',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 10.5,
                    color: const Color(0xFFA7F3D0),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isBn
                      ? 'গণপ্রজাতন্ত্রী বাংলাদেশ সরকারের ডিজিটাল রূপকল্প বাস্তবায়নে নির্মিত।'
                      : 'Built in alignment with the digital vision of the Government of Bangladesh.',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 9.5,
                    color: const Color(0xFF6EE7B7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLink({required String title, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            const Icon(Icons.arrow_right, size: 16, color: Color(0xFFA7F3D0)),
            const SizedBox(width: 4),
            Text(
              title,
              style: GoogleFonts.notoSansBengali(
                fontSize: 12,
                color: const Color(0xFFD1FAE5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelplineItem({required String number, required String label}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () => _callHelpline(number),
        child: Row(
          children: [
            const Icon(Icons.phone_in_talk, size: 14, color: Color(0xFF6EE7B7)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.notoSansBengali(
                  fontSize: 11.5,
                  color: const Color(0xFFD1FAE5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
