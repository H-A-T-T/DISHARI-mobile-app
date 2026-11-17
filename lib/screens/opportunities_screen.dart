import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../models/opportunity.dart';
import '../providers/language_provider.dart';
import 'service_detail_screen.dart';
import '../services/url_service.dart';

class OpportunitiesScreen extends StatefulWidget {
  final bool isEmbedded;

  const OpportunitiesScreen({
    super.key,
    this.isEmbedded = false,
  });

  @override
  State<OpportunitiesScreen> createState() => _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends State<OpportunitiesScreen> {
  String _selectedOccupation = 'all';
  String _selectedDivision = 'all';
  String _selectedEdu = 'all';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _selectedOccupation = 'all';
      _selectedDivision = 'all';
      _selectedEdu = 'all';
      _searchController.clear();
      _searchQuery = '';
    });
  }

  Future<void> _openOfficialLink(String? url) async {
    await UrlService.openUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final isBn = langProvider.isBn;

    final filtered = officialOpportunities.where((item) {
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final matchTitle = item.titleBn.toLowerCase().contains(q) ||
            item.titleEn.toLowerCase().contains(q);
        final matchAuth = item.authorityBn.toLowerCase().contains(q) ||
            item.authorityEn.toLowerCase().contains(q);
        final matchDesc = item.descBn.toLowerCase().contains(q) ||
            item.descEn.toLowerCase().contains(q);
        if (!matchTitle && !matchAuth && !matchDesc) return false;
      }

      if (_selectedOccupation != 'all') {
        if (!item.targetOccupations.contains(_selectedOccupation)) return false;
      }

      if (_selectedDivision != 'all') {
        if (!item.divisions.contains('all') &&
            !item.divisions.contains(_selectedDivision)) {
          return false;
        }
      }

      if (_selectedEdu != 'all') {
        const eduRanks = {'none': 0, 'ssc': 1, 'hsc': 2, 'degree': 3};
        final userRank = eduRanks[_selectedEdu] ?? 0;
        final reqRank = eduRanks[item.minEducation] ?? 0;
        if (userRank < reqRank) return false;
      }

      return true;
    }).toList();

    final content = SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Hero Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: AppColors.bgSurface,
                border: Border(
                  top: BorderSide(color: AppColors.primaryGreen, width: 3),
                  left: BorderSide(color: AppColors.border, width: 1),
                  right: BorderSide(color: AppColors.border, width: 1),
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        color: AppColors.lightGreen50,
                        child: Text(
                          isBn ? 'নাগরিক সুযোগ রাডার' : 'CITIZEN RADAR',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isBn ? 'গেজেট ও মন্ত্রণালয় সমন্বিত' : 'Ministry Verified',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isBn
                        ? 'আপনার জন্য প্রযোজ্য সরকারি সুযোগ ও সহায়তা'
                        : 'Targeted Government Opportunities & Benefits',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isBn
                        ? 'সরকার প্রতি বছর সাধারণ নাগরিকদের জন্য নানা ধরণের উপবৃত্তি, যুব প্রশিক্ষণ, কৃষি প্রণোদনা ও ভাতা ঘোষণা করে। নিজের বয়স, শিক্ষা ও এলাকা নির্বাচন করে জেনে নিন কোন কোন সুবিধা আপনি পেতে পারেন।'
                        : 'Discover official stipends, youth skill development training, farmer incentives, and welfare allowances tailored to your profile.',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() => _searchQuery = val);
                      },
                      style: GoogleFonts.notoSansBengali(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: isBn
                            ? 'সুযোগ বা ভাতার নাম দিয়ে খুঁজুন...'
                            : 'Search opportunity or benefit...',
                        hintStyle: GoogleFonts.notoSansBengali(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Filter Dropdowns
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.tune, size: 16, color: AppColors.primaryGreen),
                          const SizedBox(width: 6),
                          Text(
                            isBn ? 'প্রোফাইল ফিল্টার' : 'Profile Filters',
                            style: GoogleFonts.notoSansBengali(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: _resetFilters,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          child: Text(
                            isBn ? 'রিসেট' : 'Reset All',
                            style: GoogleFonts.notoSansBengali(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Occupation Filter
                  Text(
                    isBn ? 'পেশা / শ্রেণী' : 'Status / Occupation',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.bgMuted,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedOccupation,
                        isExpanded: true,
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedOccupation = val);
                        },
                        items: [
                          DropdownMenuItem(
                              value: 'all', child: Text(isBn ? 'সকল শ্রেণী' : 'All Categories')),
                          DropdownMenuItem(
                              value: 'unemployed',
                              child: Text(isBn ? 'বেকার যুবক/যুবতী' : 'Unemployed Youth')),
                          DropdownMenuItem(
                              value: 'student', child: Text(isBn ? 'শিক্ষার্থী' : 'Student')),
                          DropdownMenuItem(
                              value: 'widow',
                              child: Text(isBn ? 'বিধবা / স্বামী নিগৃহীতা' : 'Widow / Deserted')),
                          DropdownMenuItem(
                              value: 'farmer', child: Text(isBn ? 'কৃষক / চাষী' : 'Farmer')),
                          DropdownMenuItem(
                              value: 'sme',
                              child: Text(isBn ? 'ক্ষুদ্র উদ্যোক্তা' : 'Micro Entrepreneur')),
                          DropdownMenuItem(
                              value: 'returnee',
                              child: Text(isBn ? 'প্রবাসী / বিদেশ ফেরত' : 'Migrant Returnee')),
                          DropdownMenuItem(
                              value: 'ethnic',
                              child: Text(isBn ? 'ক্ষুদ্র নৃগোষ্ঠী' : 'Ethnic Minority')),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Division Filter
                  Text(
                    isBn ? 'বিভাগ / এলাকা' : 'Division',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.bgMuted,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedDivision,
                        isExpanded: true,
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedDivision = val);
                        },
                        items: [
                          DropdownMenuItem(
                              value: 'all', child: Text(isBn ? 'সারাদেশ (সকল বিভাগ)' : 'All Divisions')),
                          DropdownMenuItem(
                              value: 'dhaka', child: Text(isBn ? 'ঢাকা বিভাগ' : 'Dhaka')),
                          DropdownMenuItem(
                              value: 'chattogram', child: Text(isBn ? 'চট্টগ্রাম বিভাগ' : 'Chattogram')),
                          DropdownMenuItem(
                              value: 'rajshahi', child: Text(isBn ? 'রাজশাহী বিভাগ' : 'Rajshahi')),
                          DropdownMenuItem(
                              value: 'khulna', child: Text(isBn ? 'খুলনা বিভাগ' : 'Khulna')),
                          DropdownMenuItem(
                              value: 'barishal', child: Text(isBn ? 'বরিশাল বিভাগ' : 'Barishal')),
                          DropdownMenuItem(
                              value: 'sylhet', child: Text(isBn ? 'সিলেট বিভাগ' : 'Sylhet')),
                          DropdownMenuItem(
                              value: 'rangpur', child: Text(isBn ? 'রংপুর বিভাগ' : 'Rangpur')),
                          DropdownMenuItem(
                              value: 'mymensingh', child: Text(isBn ? 'ময়মনসিংহ বিভাগ' : 'Mymensingh')),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Results Count Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isBn
                      ? '${AppConstants.toBengaliNumber(filtered.length)}টি সরকারি সুযোগ পাওয়া গেছে'
                      : '${filtered.length} Opportunities Found',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Opportunities Cards List
            if (filtered.isEmpty)
              Container(
                padding: const EdgeInsets.all(28),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.search_off, size: 36, color: AppColors.textMuted),
                    const SizedBox(height: 8),
                    Text(
                      isBn
                          ? 'আপনার নির্বাচিত ফিল্টারের সাথে কোনো সুযোগ মেলেনি'
                          : 'No opportunities matched your filters',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _resetFilters,
                      child: Text(
                        isBn ? 'সব ফিল্টার মুছুন' : 'Reset Filters',
                        style: GoogleFonts.notoSansBengali(color: AppColors.primaryGreen),
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = filtered[index];

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      color: AppColors.bgSurface,
                      border: Border(
                        top: BorderSide(color: AppColors.primaryGreen, width: 3),
                        left: BorderSide(color: AppColors.border, width: 1),
                        right: BorderSide(color: AppColors.border, width: 1),
                        bottom: BorderSide(color: AppColors.border, width: 1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Authority + Deadline
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                isBn ? item.authorityBn : item.authorityEn,
                                style: GoogleFonts.notoSansBengali(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              color: AppColors.lightGreen50,
                              child: Text(
                                isBn ? item.deadlineBn : item.deadlineEn,
                                style: GoogleFonts.notoSansBengali(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Title
                        Text(
                          isBn ? item.titleBn : item.titleEn,
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Benefit Amount Banner
                        Container(
                          padding: const EdgeInsets.all(8),
                          color: AppColors.lightGreen50,
                          child: Row(
                            children: [
                              const Icon(Icons.card_giftcard,
                                  size: 15, color: AppColors.primaryGreen),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  isBn ? item.benefitBn : item.benefitEn,
                                  style: GoogleFonts.notoSansBengali(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Description
                        Text(
                          isBn ? item.descBn : item.descEn,
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Required Docs Chips
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: item.docsBn.map((doc) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1.5),
                              color: AppColors.bgMuted,
                              child: Text(
                                doc,
                                style: GoogleFonts.notoSansBengali(
                                  fontSize: 9,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: 10),

                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (item.applySlug != null)
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ServiceDetailScreen(
                                        slug: item.applySlug!,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  color: AppColors.primaryGreen,
                                  child: Row(
                                    children: [
                                      Text(
                                        isBn ? 'আবেদন নির্দেশিকা' : 'How to Apply',
                                        style: GoogleFonts.notoSansBengali(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.arrow_forward,
                                          size: 12, color: Colors.white),
                                    ],
                                  ),
                                ),
                              ),
                            if (item.officialLink != null)
                              InkWell(
                                onTap: () => _openOfficialLink(item.officialLink),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.bgMuted,
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        isBn ? 'অফিসিয়াল পোর্টাল' : 'Gov Portal',
                                        style: GoogleFonts.notoSansBengali(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.open_in_new,
                                          size: 12, color: AppColors.textSecondary),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 30),
          ],
        ),
      );

    if (widget.isEmbedded) {
      return Container(
        color: AppColors.bgPage,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        title: Text(
          isBn ? 'সরকারি সুযোগ ও সহায়তা হাব' : 'Citizen Opportunity Hub',
          style: GoogleFonts.notoSansBengali(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: content,
    );
  }
}
