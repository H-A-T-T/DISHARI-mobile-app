import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/constants.dart';
import '../../providers/language_provider.dart';

class StatsSection extends StatefulWidget {
  const StatsSection({super.key});

  @override
  State<StatsSection> createState() => _StatsSectionState();
}

class _StatsSectionState extends State<StatsSection> {
  int _tickerIndex = 0;
  Timer? _tickerTimer;
  int _activeTab = 0; // 0: impact, 1: gateways, 2: hotlines

  @override
  void initState() {
    super.initState();
    _tickerTimer = Timer.periodic(const Duration(milliseconds: 4500), (_) {
      if (!mounted) return;
      setState(() {
        _tickerIndex = (_tickerIndex + 1) % 5;
      });
    });
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final isBn = langProvider.isBn;

    final tickerItems = isBn
        ? [
            'গেজেট স্বচ্ছতা: নামজারি আবেদনের মোট সরকারি ফি ১,১৭০ টাকা — কোনো দালালকে বাড়তি টাকা দেবেন না',
            'ই-পাসপোর্ট নির্দেশিকা: ৪৮ পাতা ৫ বছর সাধারণ ফি ৪,০২৫ টাকা, মূল এনআইডি বা ১৭-ডিজিট জন্মসনদ বাধ্যতামূলক',
            'সমাজসেবা অধিদপ্তর: বিধবা ও বয়স্ক ভাতা ১০০% বিনামূল্যে সরাসরি বিকাশ/নগদে (G2P) পৌঁছে যায়',
            'ডিজিটাল লকার: এনআইডি ও সার্টিফিকেট এনক্রিপ্ট করে আজীবন সুরক্ষিত রাখুন',
            'জনবন্ধু AI: মুখে বলুন "এনআইডি তে নিয়ে যাও" বা "পাসপোর্ট ফি কত" — তাৎক্ষণিক স্বয়ংক্রিয় সমাধান',
          ]
        : [
            'Official Gazette: Land mutation total legal fee is 1,170 BDT — never pay unauthorized broker charges',
            'E-Passport Advisory: 48-page 5-year regular fee 4,025 BDT with verified Smart NID / birth record',
            'Social Welfare: Widow & elderly allowances are 100% free, delivered straight to mobile banking',
            'Document Vault: 256-bit encrypted permanent citizen vault for auto-generating dockets',
            'Jonobondhu AI: Speak naturally: "take me to NID" or ask for official gazette fee schedules',
          ];

    final impactStats = [
      {
        'num': isBn ? '৳০' : '₳0',
        'label': isBn ? 'ব্রোকার/লুকানো ফি' : 'Broker/Hidden Fee',
        'sub': isBn ? 'গেজেট অনুমোদিত' : 'Gazette Verified',
        'desc': isBn
            ? 'প্রতিটি সরকারি সেবার সঠিক সরকারি গেজেট ফি দৃশ্যমান। কোনো কম্পিউটার দোকান বা মধ্যস্বত্বভোগীর হয়রানি শূন্য।'
            : 'Every government service shows the official gazette fee. Zero broker harassment or hidden charges.',
        'footer': isBn ? 'গেজেট ফি যাচাই করুন →' : 'Verify gazette fees →',
        'borderColor': AppColors.primaryGreen,
      },
      {
        'num': isBn ? '<২ সেকেন্ড' : '<2s',
        'label': isBn ? 'ওসিআর স্ক্যান গতি' : 'OCR Scan Speed',
        'sub': isBn ? 'বাংলা-ইংরেজি দ্বিভাষিক' : 'Bilingual AI Engine',
        'desc': isBn
            ? 'স্মার্ট এনআইডি ও সনদ স্ক্যান করে মুহূর্তেই প্রস্তুত হয় সম্পূর্ণ আবেদনপত্র ও কোর্ট-রেডি ডিজিটাল কার্যপত্র।'
            : 'Smart NID & certificate scan instantly generates complete application forms and court-ready digital documents.',
        'footer': isBn ? 'এনআইডি স্ক্যান করুন →' : 'Try NID Scan →',
        'borderColor': const Color(0xFF10B981),
      },
      {
        'num': isBn ? '৫০+' : '50+',
        'label': isBn ? 'সরকারি সেবা' : 'Govt Services',
        'sub': isBn ? '৪৯৫ উপজেলা যাচাইকৃত' : '495 Upazilas Verified',
        'desc': isBn
            ? 'পাসপোর্ট, ভূমি নামজারি, কর, বিএমইটি প্রবাসী কার্ড ও সামাজিক ভাতা—৮ বিভাগের ৪৯৫ উপজেলার জন্য যাচাইকৃত।'
            : 'Passport, land mutation, tax, BMET overseas card & social allowances — verified for 495 upazilas in 8 divisions.',
        'footer': isBn ? 'সব সেবা দেখুন →' : 'Browse all services →',
        'borderColor': const Color(0xFF06B6D4),
      },
      {
        'num': isBn ? '২৪/৭' : '24/7',
        'label': isBn ? 'জনবন্ধু AI' : 'Jonobondhu AI',
        'sub': isBn ? 'আঞ্চলিক ভাষা সহায়তা' : 'Dialect-Aware Support',
        'desc': isBn
            ? 'আঞ্চলিক উপভাষা ও সাধারণ বাংলায় মুখে বলুন "এনআইডি তে নিয়ে যাও" বা "পাসপোর্ট ফি কত"—মুহূর্তেই পৌঁছে যাবেন।'
            : 'Speak naturally in any dialect: "take me to NID" or "passport fee" — instantly navigated.',
        'footer': isBn ? 'AI-কে জিজ্ঞেস করুন →' : 'Ask Jonobondhu AI →',
        'borderColor': const Color(0xFFF59E0B),
      },
    ];

    final gateways = [
      {'name': 'epassport.gov.bd', 'desc': isBn ? 'বহিরাগমন ও পাসপোর্ট অধিদপ্তর' : 'Department of Passports'},
      {'name': 'services.nidw.gov.bd', 'desc': isBn ? 'জাতীয় পরিচয় নিবন্ধন অণুবিভাগ' : 'NID Wing, Election Commission'},
      {'name': 'bdris.gov.bd', 'desc': isBn ? 'জন্ম ও মৃত্যু নিবন্ধন রেজিস্ট্রার' : 'Registrar General, BDRIS'},
      {'name': 'mutation.land.gov.bd', 'desc': isBn ? 'ভূমি মন্ত্রণালয় ই-নামজারি সেবা' : 'Ministry of Land Mutation'},
    ];

    final hotlines = [
      {'num': '৩৩৩', 'name': isBn ? 'সরকারি তথ্য ও নাগরিক সেবা' : 'Govt Services & Info'},
      {'num': '৯৯৯', 'name': isBn ? 'জাতীয় জরুরি পুলিশ ও অ্যাম্বুলেন্স' : 'National Emergency 999'},
      {'num': '১০৬', 'name': isBn ? 'দুদক দুর্নীতি দমন অভিযোগ' : 'Anti-Corruption ACC'},
      {'num': '১০৯', 'name': isBn ? 'নারী ও শিশু নির্যাতন প্রতিরোধ' : 'Violence Prevention'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── 1. Live Gazette Transparency Ticker ──────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF003627),
              border: Border(left: BorderSide(color: Color(0xFF00E599), width: 3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  color: const Color(0xFFC8102E),
                  child: Text(
                    isBn ? 'গেজেট বুলেটিন' : 'GAZETTE',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      tickerItems[_tickerIndex % tickerItems.length],
                      key: ValueKey<int>(_tickerIndex),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 11,
                        color: const Color(0xFFA7F3D0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── 2. Header & 3-Tab Filter Deck ────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isBn ? 'সিস্টেম টেলিমেট্রি ও নাগরিক মানদণ্ড' : 'LIVE CIVIC TELEMETRY',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryGreen,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      isBn ? 'গেজেট সিনক্রোনাইজড' : 'Gazette Synced',
                      style: GoogleFonts.notoSansBengali(fontSize: 10, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 3 Segmented Tabs
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.bgMuted,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      _buildTabBtn(0, isBn ? 'নাগরিক প্রভাব' : 'Civic Impact'),
                      _buildTabBtn(1, isBn ? 'সরকারি পোর্টাল' : 'Gov Gateways'),
                      _buildTabBtn(2, isBn ? 'জরুরি হটলাইন' : 'Hotlines'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ─── 3. Tab Contents ─────────────────────────────────────────
                if (_activeTab == 0) ...[
                  // Impact 4 Metric Tiles — single column for descriptions
                  ...impactStats.map((stat) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildMetricTile(stat),
                  )),
                ] else if (_activeTab == 1) ...[
                  // Official Government Gateways
                  ...gateways.map((g) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: const BoxDecoration(
                        color: AppColors.bgMuted,
                        border: Border(left: BorderSide(color: AppColors.primaryGreen, width: 2.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_outlined, size: 14, color: AppColors.primaryGreen),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  g['name']!,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  g['desc']!,
                                  style: GoogleFonts.notoSansBengali(fontSize: 10, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () async {
                              final uri = Uri.parse('https://${g['name']}');
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            },
                            child: const Icon(Icons.open_in_new, size: 14, color: AppColors.primaryGreen),
                          ),
                        ],
                      ),
                    );
                  }),
                ] else ...[
                  // Emergency Helpline Numbers
                  ...hotlines.map((h) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: const BoxDecoration(
                        color: AppColors.bgMuted,
                        border: Border(left: BorderSide(color: Color(0xFFC8102E), width: 2.5)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            color: const Color(0xFFC8102E),
                            child: Text(
                              h['num']!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              h['name']!,
                              style: GoogleFonts.notoSansBengali(fontSize: 11.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                          InkWell(
                            onTap: () async {
                              final uri = Uri.parse('tel:${h['num']}');
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              }
                            },
                            child: const Icon(Icons.phone_in_talk, size: 16, color: AppColors.primaryGreen),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBtn(int index, String label) {
    final isSelected = _activeTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          color: isSelected ? AppColors.primaryGreen : Colors.transparent,
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.notoSansBengali(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile(Map<String, dynamic> item) {
    final Color borderColor = item['borderColor'] as Color? ?? AppColors.primaryGreen;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: AppColors.bgMuted,
        border: Border(
          top: BorderSide(color: borderColor, width: 3),
          left: const BorderSide(color: AppColors.border),
          right: const BorderSide(color: AppColors.border),
          bottom: const BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item['num']!,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item['label']!,
            style: GoogleFonts.notoSansBengali(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            item['sub']!,
            style: GoogleFonts.notoSansBengali(
              fontSize: 9.5,
              color: AppColors.textMuted,
            ),
          ),
          if (item['desc'] != null) ...[
            const SizedBox(height: 6),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 6),
            Text(
              item['desc']!,
              style: GoogleFonts.notoSansBengali(
                fontSize: 10,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          if (item['footer'] != null) ...[
            const SizedBox(height: 6),
            Text(
              item['footer']!,
              style: GoogleFonts.notoSansBengali(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryGreen,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
