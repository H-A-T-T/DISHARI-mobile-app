import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../providers/language_provider.dart';
import '../providers/services_provider.dart';
import '../widgets/services/service_card.dart';
import 'service_detail_screen.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categoryFilterKeys = [
    'all',
    'identity',
    'education',
    'land',
    'welfare',
    'business',
    'tax',
    'overseas',
    'health',
  ];

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ServicesProvider>(context, listen: false);
    _searchController.text = provider.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final servicesProvider = context.watch<ServicesProvider>();
    final isBn = langProvider.isBn;

    final services = servicesProvider.filteredServices;
    final activeCat = servicesProvider.selectedCategory ?? 'all';

    return Container(
      color: AppColors.bgPage,
      child: CustomScrollView(
        slivers: [
          // Official Header Banner
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.bgSurface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    color: AppColors.lightGreen50,
                    child: Text(
                      langProvider.t('services.govtStamp'),
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    langProvider.t('services.headline'),
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    langProvider.t('services.subheadline'),
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      border: Border.all(color: AppColors.borderStrong),
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(Icons.search, size: 18, color: AppColors.textMuted),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) {
                              servicesProvider.setSearchQuery(val);
                            },
                            style: GoogleFonts.notoSansBengali(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: isBn
                                  ? 'কোন সরকারি সেবাটি খুঁজছেন?'
                                  : 'Search for any government service...',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 16, color: AppColors.textMuted),
                            onPressed: () {
                              _searchController.clear();
                              servicesProvider.setSearchQuery('');
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Horizontal Category Pills
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.bgSurface,
              padding: const EdgeInsets.only(bottom: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: _categoryFilterKeys.map((catKey) {
                    final isSelected = activeCat == catKey;
                    String label;
                    if (catKey == 'all') {
                      label = langProvider.t('services.allServicesTab');
                    } else {
                      final meta = AppConstants.categories[catKey]!;
                      label = isBn ? meta.nameBn : meta.nameEn;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        onTap: () {
                          servicesProvider.setCategory(catKey);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryGreen : AppColors.bgMuted,
                            border: Border.all(
                              color: isSelected ? AppColors.primaryGreen : AppColors.border,
                            ),
                          ),
                          child: Text(
                            label,
                            style: GoogleFonts.notoSansBengali(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // Listed Count Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isBn
                        ? '${AppConstants.toBengaliNumber(services.length)} টি সেবা তালিকাভুক্ত'
                        : '${services.length} services listed',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (activeCat != 'all' || _searchController.text.isNotEmpty)
                    InkWell(
                      onTap: () {
                        _searchController.clear();
                        servicesProvider.clearFilters();
                      },
                      child: Text(
                        langProvider.t('services.clearAllFilters'),
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryRed,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Services List
          if (services.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search_off, size: 40, color: AppColors.textMuted),
                    const SizedBox(height: 8),
                    Text(
                      langProvider.t('services.noResults'),
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final service = services[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ServiceCard(
                        service: service,
                        isBn: isBn,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ServiceDetailScreen(slug: service.slug),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  childCount: services.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 70),
          ),
        ],
      ),
    );
  }
}

