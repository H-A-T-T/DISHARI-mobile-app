import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../providers/language_provider.dart';
import '../widgets/common/dishari_logo.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final isBn = langProvider.isBn;

    final personas = [
      (
        num: isBn ? '০১' : '01',
        name: isBn ? 'রহিম মিয়া' : 'Rahim Mia',
        tag: isBn ? 'ভূমি সেবা ও উত্তরাধিকার' : 'Land Services & Inheritance',
        location: isBn ? 'নেত্রকোনা' : 'Netrokona',
        story: isBn
            ? 'বাবার মৃত্যুর পর পৈতৃক জমির নামজারি ও খতিয়ান ঠিক করতে হবে। কিন্তু কোন কাগজ লাগবে এবং সরকারি ফি কত—তা না জানায় বারবার দালালদের শরণাপন্ন হতে হচ্ছিল।'
            : 'Needed to mutate ancestral land deeds without broker extortion after losing his father.',
      ),
      (
        num: isBn ? '০২' : '02',
        name: isBn ? 'মোসাম্মৎ রাবেয়া' : 'Mosammat Rabeya',
        tag: isBn ? 'শিক্ষা ও উপবৃত্তি' : 'Education & Scholarship',
        location: isBn ? 'কুড়িগ্রাম' : 'Kurigram',
        story: isBn
            ? 'মেধাবী ছাত্রী হিসেবে প্রধানমন্ত্রীর শিক্ষা সহায়তা ট্রাস্টের উপবৃত্তির জন্য আবেদন করতে চায়। কিন্তু প্রত্যয়ন ও আবেদনের শেষ সময় আগে থেকে নিশ্চিত ছিল না।'
            : 'Meritorious student applying for PM education trust scholarship while staying on top of critical deadlines.',
      ),
      (
        num: isBn ? '০৩' : '03',
        name: isBn ? 'সবুজ আহমেদ' : 'Sobuj Ahmed',
        tag: isBn ? 'ব্যবসা ও ট্রেড লাইসেন্স' : 'Business & Trade License',
        location: isBn ? 'বগুড়া' : 'Bogra',
        story: isBn
            ? 'নিজের তৈরি কুটির শিল্পজাত পণ্য অনলাইনে বিক্রির জন্য প্রথমবারের মতো ই-ট্রেড লাইসেন্স করতে চান। ইউনিয়ন পরিষদ নাকি পৌরসভায় যেতে হবে তা জানতেন না।'
            : 'Cottage craft entrepreneur setting up an e-trade license for the first time without intermediaries.',
      ),
      (
        num: isBn ? '০৪' : '04',
        name: isBn ? 'ফারুক হোসেন' : 'Faruk Hossain',
        tag: isBn ? 'প্রবাসী কল্যাণ ও স্মার্ট কার্ড' : 'Expatriate Welfare & Smart Card',
        location: isBn ? 'কুমিল্লা' : 'Cumilla',
        story: isBn
            ? 'মধ্যপ্রাচ্যে কর্মসংস্থানের জন্য বিএমইটি ইমিগ্রেশন কার্ড ও প্রাক-বহির্গমন ওরিয়েন্টেশন সনদ সংগ্রহ করতে দিশারীর নির্দেশনা নিয়েছেন।'
            : 'Securing BMET smart card and orientation clearance smoothly prior to overseas departure.',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        title: Text(
          isBn ? 'আমাদের সম্পর্কে' : 'About Us',
          style: GoogleFonts.notoSansBengali(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mission Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: AppColors.darkGreen,
                border: Border(top: BorderSide(color: AppColors.primaryRed, width: 3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DishariLogo(height: 32, isDark: true, isBn: isBn),
                  const SizedBox(height: 12),
                  Text(
                    isBn
                        ? 'সরকারি সেবা এখন আপনার হাতের মুঠোয়'
                        : 'Government Services, Now Within Your Reach',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isBn
                        ? 'দিশারী একটি নাগরিক-সহায়তাকারী প্ল্যাটফর্ম যা বাংলাদেশের সাধারণ মানুষকে — বিশেষ করে গ্রামীণ ও ডিজিটাল সেবায় অনভিজ্ঞ নাগরিকদের — কোনো দালাল বা কম্পিউটার দোকানে বাড়তি খরচ ছাড়াই সরকারি সেবা বুঝে নিতে এবং আবেদন সম্পন্ন করতে সাহায্য করে।'
                        : 'Dishari is a civic companion designed to empower Bangladeshi citizens to navigate government services with transparency and without middleman exploitation.',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 12,
                      color: const Color(0xFFD1FAE5),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Target Personas Section
            Text(
              isBn ? 'কাদের জন্য দিশারী?' : 'Who is Dishari Built For?',
              style: GoogleFonts.notoSansBengali(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            ...personas.map((p) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${p.name} · ${p.location}',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          color: AppColors.lightGreen50,
                          child: Text(
                            p.tag,
                            style: GoogleFonts.notoSansBengali(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      p.story,
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 70),
          ],
        ),
      ),
    );
  }
}
