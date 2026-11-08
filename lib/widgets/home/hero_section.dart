import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../models/service.dart';
import '../../providers/language_provider.dart';
import '../../providers/services_provider.dart';

class HeroSection extends StatefulWidget {
  final Function(String slug) onSelectService;
  final Function(String query) onSearchSubmit;

  const HeroSection({
    super.key,
    required this.onSelectService,
    required this.onSearchSubmit,
  });

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection> {
  final TextEditingController _searchController = TextEditingController();
  List<Service> _suggestions = [];
  Timer? _debounceTimer;

  final List<({String labelBn, String labelEn, String queryBn, String queryEn})> _quickTags = [
    (labelBn: 'পাসপোর্ট', labelEn: 'Passport', queryBn: 'পাসপোর্ট', queryEn: 'passport'),
    (labelBn: 'NID সংশোধন', labelEn: 'NID Correction', queryBn: 'NID', queryEn: 'nid'),
    (labelBn: 'জন্ম নিবন্ধন', labelEn: 'Birth Reg', queryBn: 'জন্ম নিবন্ধন', queryEn: 'birth'),
    (labelBn: 'উপবৃত্তি', labelEn: 'Scholarship', queryBn: 'উপবৃত্তি', queryEn: 'scholarship'),
    (labelBn: 'ভাতা', labelEn: 'Allowance', queryBn: 'ভাতা', queryEn: 'allowance'),
    (labelBn: 'ট্রেড লাইসেন্স', labelEn: 'Trade License', queryBn: 'ট্রেড লাইসেন্স', queryEn: 'trade'),
  ];

  void _onSearchChanged(String text) {
    _debounceTimer?.cancel();
    if (text.trim().isEmpty) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      final allServices = Provider.of<ServicesProvider>(context, listen: false).services;
      final query = text.trim().toLowerCase();
      final matches = allServices.where((s) {
        return s.nameBn.toLowerCase().contains(query) ||
            s.nameEn.toLowerCase().contains(query) ||
            s.slug.toLowerCase().contains(query);
      }).take(4).toList();

      if (mounted) {
        setState(() {
          _suggestions = matches;
        });
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final isBn = langProvider.isBn;

    return Container(
      color: AppColors.bgSurface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trust Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: const BoxDecoration(
              color: AppColors.lightGreen50,
              border: Border(
                left: BorderSide(color: AppColors.primaryGreen, width: 3),
              ),
            ),
            child: Text(
              langProvider.t('hero.badge'),
              style: GoogleFonts.notoSansBengali(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Main Headline with Bangladesh Green Accent
          RichText(
            text: TextSpan(
              style: GoogleFonts.notoSansBengali(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
              children: [
                TextSpan(text: langProvider.t('hero.headlinePart1')),
                TextSpan(
                  text: langProvider.t('hero.headlinePart2'),
                  style: const TextStyle(color: AppColors.primaryGreen),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Subheadline
          Text(
            langProvider.t('hero.subheadline'),
            style: GoogleFonts.notoSansBengali(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          // Windows 10 Flat Modern Search Terminal
          Container(
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              border: Border.all(color: AppColors.borderStrong),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(Icons.search, size: 20, color: AppColors.textMuted),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        onSubmitted: (val) {
                          if (val.trim().isNotEmpty) {
                            widget.onSearchSubmit(val.trim());
                          }
                        },
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: langProvider.t('hero.searchPlaceholder'),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 16, color: AppColors.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      ),
                    InkWell(
                      onTap: () {
                        if (_searchController.text.trim().isNotEmpty) {
                          widget.onSearchSubmit(_searchController.text.trim());
                        }
                      },
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        color: AppColors.primaryGreen,
                        alignment: Alignment.center,
                        child: Text(
                          langProvider.t('hero.searchButton'),
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Autocomplete Suggestions Dropdown
                if (_suggestions.isNotEmpty)
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: AppColors.border)),
                      color: AppColors.bgSurface,
                    ),
                    child: Column(
                      children: _suggestions.map((item) {
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _suggestions = [];
                              _searchController.clear();
                            });
                            widget.onSelectService(item.slug);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.description_outlined,
                                    size: 16, color: AppColors.primaryGreen),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isBn ? item.nameBn : item.nameEn,
                                        style: GoogleFonts.notoSansBengali(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${item.fee} · ${item.processingTimeBn}',
                                        style: GoogleFonts.notoSansBengali(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios,
                                    size: 12, color: AppColors.textMuted),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Quick Filter Tags Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  langProvider.t('hero.popular'),
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 6),
                ..._quickTags.map((tag) {
                  final label = isBn ? tag.labelBn : tag.labelEn;
                  final query = isBn ? tag.queryBn : tag.queryEn;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () {
                        _searchController.text = query;
                        widget.onSearchSubmit(query);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.bgMuted,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          label,
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Flat Civic Info Strip
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_user_outlined, size: 14, color: AppColors.primaryGreen),
                    const SizedBox(width: 4),
                    Text(
                      isBn ? 'সরকারি নির্দেশিকা' : 'Official Guidelines',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.phone_in_talk_outlined, size: 14, color: AppColors.primaryGreen),
                    const SizedBox(width: 4),
                    Text(
                      isBn ? '৩৩৩ হেল্পলাইন' : '333 Helpline',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  isBn ? '১০০% বিনামূল্যে' : '100% Free',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
