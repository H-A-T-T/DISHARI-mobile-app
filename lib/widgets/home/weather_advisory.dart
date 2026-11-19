import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../providers/language_provider.dart';
import '../common/jonobondhu_chat_overlay.dart';

class DivisionWeather {
  final String divisionBn;
  final String divisionEn;
  final String districtBn;
  final String districtEn;
  final int temp;
  final String conditionBn;
  final String conditionEn;
  final String icon; // 'sun', 'rain', 'cloud'
  final int rainProb;
  final int humidity;
  final int windKm;
  final String advisoryType; // 'alert', 'advisory', 'normal'
  final String advisoryTitleBn;
  final String advisoryTitleEn;
  final String advisoryDescBn;
  final String advisoryDescEn;
  final String cropAdviceBn;
  final String cropAdviceEn;

  const DivisionWeather({
    required this.divisionBn,
    required this.divisionEn,
    required this.districtBn,
    required this.districtEn,
    required this.temp,
    required this.conditionBn,
    required this.conditionEn,
    required this.icon,
    required this.rainProb,
    required this.humidity,
    required this.windKm,
    required this.advisoryType,
    required this.advisoryTitleBn,
    required this.advisoryTitleEn,
    required this.advisoryDescBn,
    required this.advisoryDescEn,
    required this.cropAdviceBn,
    required this.cropAdviceEn,
  });
}

const Map<String, DivisionWeather> districtWeatherData = {
  'netrokona': DivisionWeather(
    divisionBn: 'ময়মনসিংহ',
    divisionEn: 'Mymensingh',
    districtBn: 'নেত্রকোনা ও হাওড়াঞ্চল',
    districtEn: 'Netrokona & Haor Basin',
    temp: 26,
    conditionBn: 'মেঘলা ও হালকা গুঁড়ি গুঁড়ি বৃষ্টি',
    conditionEn: 'Overcast with Light Drizzle',
    icon: 'rain',
    rainProb: 65,
    humidity: 84,
    windKm: 18,
    advisoryType: 'alert',
    advisoryTitleBn: 'হাওড়াঞ্চলের জন্য কৃষি ও বৃষ্টির জরুরি বার্তা',
    advisoryTitleEn: 'Urgent Rain Advisory for Haor Region',
    advisoryDescBn:
        'নেত্রকোনা, খালিয়াজুরী ও সংলগ্ন হাওর এলাকায় আগামী ২৪ ঘণ্টায় মাঝারি থেকে ভারী বৃষ্টির সম্ভাবনা রয়েছে। খলা ও নিচু জমির ফসল নিরাপদ স্থানে রাখুন।',
    advisoryDescEn:
        'Moderate to heavy rainfall expected across Netrokona and Haor areas in 24h. Secure harvested crops from low lands.',
    cropAdviceBn:
        'হাওরের নিচু জমিতে পাকা ধান থাকলে দ্রুত কাটাই ও মাড়াই সম্পন্ন করে উঁচু স্থানে সংরক্ষণ করুন।',
    cropAdviceEn:
        'Promptly harvest and thrash mature crops from low-lying haor areas and store on elevated ground.',
  ),
  'dhaka': DivisionWeather(
    divisionBn: 'ঢাকা',
    divisionEn: 'Dhaka',
    districtBn: 'ঢাকা সদর ও পার্শ্ববর্তী এলাকা',
    districtEn: 'Dhaka & Surroundings',
    temp: 29,
    conditionBn: 'পরিষ্কার ও মৃদু কুয়াশা',
    conditionEn: 'Clear & Mild Fog',
    icon: 'sun',
    rainProb: 10,
    humidity: 62,
    windKm: 12,
    advisoryType: 'normal',
    advisoryTitleBn: 'স্বাভাবিক আবহাওয়া সতর্কতা',
    advisoryTitleEn: 'Normal Weather Advisory',
    advisoryDescBn:
        'আগামী ৪৮ ঘণ্টায় ঢাকায় ভারী বৃষ্টির কোনো সম্ভাবনা নেই। স্বাভাবিক নাগরিক কাজ নির্বিঘ্নে সম্পন্ন করা যাবে।',
    advisoryDescEn:
        'No heavy rainfall expected in Dhaka for the next 48 hours. Routine civic activities can proceed normally.',
    cropAdviceBn:
        'শীতকালীন শাকসবজি ও চারাগাছে নিয়মিত হালকা সেচ প্রদান করতে পারেন।',
    cropAdviceEn:
        'Provide regular light irrigation for winter vegetables and seedlings.',
  ),
  'chattogram': DivisionWeather(
    divisionBn: 'চট্টগ্রাম',
    divisionEn: 'Chattogram',
    districtBn: 'চট্টগ্রাম ও উপকূলীয় এলাকা',
    districtEn: 'Chattogram & Coastal Belt',
    temp: 28,
    conditionBn: 'আংশিক মেঘলা ও আর্দ্র',
    conditionEn: 'Partly Cloudy & Humid',
    icon: 'cloud',
    rainProb: 25,
    humidity: 75,
    windKm: 22,
    advisoryType: 'advisory',
    advisoryTitleBn: 'উপকূলীয় আবহাওয়া সতর্কতা',
    advisoryTitleEn: 'Coastal Weather Notice',
    advisoryDescBn:
        'সমুদ্রের মোহনা ও উপকূলীয় অঞ্চলে স্বাভাবিকের চেয়ে দমকা হাওয়া বইতে পারে। স্থানীয় জেলেদের সতর্কতার সাথে চলাচলের পরামর্শ দেওয়া হচ্ছে।',
    advisoryDescEn:
        'Gusty winds may blow along the coast. Local fishermen are advised to navigate cautiously.',
    cropAdviceBn:
        'লবণাক্ততা নিয়ন্ত্রণ ও উপকূলীয় পানের বরজে বাতাস থেকে সুরক্ষামূলক বেড়া নিশ্চিত করুন।',
    cropAdviceEn:
        'Ensure windbreakers for betel leaf enclosures and monitor coastal soil salinity.',
  ),
  'sylhet': DivisionWeather(
    divisionBn: 'সিলেট',
    divisionEn: 'Sylhet',
    districtBn: 'সিলেট সদর ও সুনামগঞ্জ',
    districtEn: 'Sylhet & Sunamganj',
    temp: 25,
    conditionBn: 'বজ্রসহ বৃষ্টিপাত হতে পারে',
    conditionEn: 'Thunderstorms Expected',
    icon: 'rain',
    rainProb: 75,
    humidity: 88,
    windKm: 16,
    advisoryType: 'alert',
    advisoryTitleBn: 'বজ্রপাত ও পাহাড়ি ঢল সতর্কতা',
    advisoryTitleEn: 'Flash Flood & Lightning Alert',
    advisoryDescBn:
        'সুরমা ও কুশিয়ারা অববাহিকায় আকস্মিক পানির চাপ বাড়তে পারে। খোলা মাঠে কাজ করার সময় মেঘের ডাক শুনলে দ্রুত নিরাপদ আশ্রয়ে যান।',
    advisoryDescEn:
        'Water levels in Surma and Kushiyara may rise. Take shelter indoors immediately during lightning.',
    cropAdviceBn:
        'চা বাগান ও ফসলি জমিতে পানি নিষ্কাশন নালা পরিষ্কার রাখুন যেন জলাবদ্ধতা না ঘটে।',
    cropAdviceEn:
        'Clear drainage canals in tea estates and fields to prevent waterlogging.',
  ),
  'rajshahi': DivisionWeather(
    divisionBn: 'রাজশাহী',
    divisionEn: 'Rajshahi',
    districtBn: 'রাজশাহী ও বরেন্দ্র অঞ্চল',
    districtEn: 'Rajshahi & Barind Tract',
    temp: 31,
    conditionBn: 'রোদেলা ও শুষ্ক আবহাওয়া',
    conditionEn: 'Sunny & Dry Weather',
    icon: 'sun',
    rainProb: 5,
    humidity: 50,
    windKm: 10,
    advisoryType: 'normal',
    advisoryTitleBn: 'শুষ্ক বরেন্দ্র অঞ্চল নির্দেশনা',
    advisoryTitleEn: 'Dry Barind Zone Advisory',
    advisoryDescBn:
        'রাজশাহী ও বরেন্দ্র এলাকায় রোদ অব্যাহত থাকবে। গম ও রবি শস্যের চারা রোপণের উপযোগী পরিবেশ বিরাজ করছে।',
    advisoryDescEn:
        'Sunny weather persists in Barind. Optimal conditions for planting wheat and Rabi winter crops.',
    cropAdviceBn:
        'মাটির আর্দ্রতা ধরে রাখতে রবি ফসলে সময়মতো জৈব মালচিং এবং পরিমিত সেচ প্রয়োগ করুন।',
    cropAdviceEn:
        'Apply organic mulching and scheduled irrigation to retain soil moisture for crops.',
  ),
  'rangpur': DivisionWeather(
    divisionBn: 'রংপুর',
    divisionEn: 'Rangpur',
    districtBn: 'রংপুর ও কুড়িগ্রাম চরাঞ্চল',
    districtEn: 'Rangpur & Kurigram Char',
    temp: 24,
    conditionBn: 'ঘন কুয়াশা ও হিমেল হাওয়া',
    conditionEn: 'Dense Fog & Cold Breeze',
    icon: 'cloud',
    rainProb: 15,
    humidity: 82,
    windKm: 14,
    advisoryType: 'advisory',
    advisoryTitleBn: 'কুয়াশা ও চরাঞ্চলীয় কৃষি বার্তা',
    advisoryTitleEn: 'Fog & Char Area Farming Notice',
    advisoryDescBn:
        'তিস্তা ও ব্রহ্মপুত্র তীরবর্তী চরাঞ্চলে রাত থেকে সকাল পর্যন্ত মাঝারি থেকে ঘন কুয়াশার সম্ভাবনা রয়েছে। সড়ক ও নৌপথে সতর্ক থাকুন।',
    advisoryDescEn:
        'Moderate to dense fog expected across Teesta and Brahmaputra char lands. Drive and navigate cautiously.',
    cropAdviceBn:
        'আলুর জমিতে লেট ব্লাইট (নাবি ধসা) রোগ প্রতিরোধে অনুমোদিত ছত্রাকনাশক স্প্রে করুন।',
    cropAdviceEn:
        'Apply approved fungicide to prevent late blight disease in potato crops.',
  ),
  'khulna': DivisionWeather(
    divisionBn: 'খুলনা',
    divisionEn: 'Khulna',
    districtBn: 'খুলনা ও সাতক্ষীরা উপকূল',
    districtEn: 'Khulna & Satkhira Belt',
    temp: 28,
    conditionBn: 'পরিষ্কার ও মৃদু বাতাস',
    conditionEn: 'Clear with Gentle Breeze',
    icon: 'sun',
    rainProb: 15,
    humidity: 68,
    windKm: 15,
    advisoryType: 'normal',
    advisoryTitleBn: 'উপকূলীয় মৎস্য ও কৃষি নির্দেশিকা',
    advisoryTitleEn: 'Coastal Fisheries & Agriculture Guide',
    advisoryDescBn:
        'সুন্দরবন সংলগ্ন অঞ্চলে স্বাভাবিক জলবায়ু বিরাজ করছে। ঘেরে চিংড়ি চাষ ও মাছের খাবার প্রদানে অনুকূল অবস্থা বিদ্যমান।',
    advisoryDescEn:
        'Favorable weather conditions around the Sundarbans belt for shrimp farming and fisheries.',
    cropAdviceBn:
        'লবণাক্ততা বৃদ্ধি রোধে পুকুর ও ঘেরের পাড়ে মাটি বাঁধ মজবুত রাখুন।',
    cropAdviceEn:
        'Strengthen embankments of fish enclosures to prevent saline water intrusion.',
  ),
  'barishal': DivisionWeather(
    divisionBn: 'বরিশাল',
    divisionEn: 'Barishal',
    districtBn: 'বরিশাল ও ভোলা নদী অববাহিকা',
    districtEn: 'Barishal & Bhola Riverine',
    temp: 27,
    conditionBn: 'আংশিক মেঘলা আকাশ',
    conditionEn: 'Partly Cloudy Skies',
    icon: 'cloud',
    rainProb: 30,
    humidity: 78,
    windKm: 17,
    advisoryType: 'normal',
    advisoryTitleBn: 'নদীতীরবর্তী নাগরিক বার্তা',
    advisoryTitleEn: 'Riverine Civic Advisory',
    advisoryDescBn:
        'মেঘনা ও কীর্তনখোলা অববাহিকায় নদীপথের নৌযানসমূহ স্বাভাবিকভাবে চলাচল করতে পারছে। নৌযাত্রায় সরকারি নিরাপত্তা জ্যাকেট ব্যবহার নিশ্চিত করুন।',
    advisoryDescEn:
        'Waterways along Meghna and Kirtankhola are running safely. Always wear certified lifejackets during river transit.',
    cropAdviceBn:
        'পান বরজ ও শীতকালীন ডাল ফসলে পানি নিষ্কাশন ব্যবস্থা সচল রাখুন।',
    cropAdviceEn:
        'Keep drainage clear in betel vine sheds and winter pulse fields.',
  ),
};

// --- Region coordinates (same as web) ---
const Map<String, List<double>> _regionLatLon = {
  'netrokona': [24.8732, 90.7279],
  'dhaka': [23.8103, 90.4125],
  'chattogram': [22.3569, 91.7832],
  'sylhet': [24.8949, 91.8687],
  'rajshahi': [24.3745, 88.6042],
  'rangpur': [25.7439, 89.2752],
  'khulna': [22.8456, 89.5403],
  'barishal': [22.7010, 90.3535],
};

String _mapWmoCode(int code, bool isBn) {
  if (code == 0) return isBn ? 'পরিষ্কার আকাশ' : 'Clear Sky';
  if (code <= 3) return isBn ? 'আংশিক মেঘলা' : 'Partly Cloudy';
  if (code <= 48) return isBn ? 'কুয়াশাচ্ছন্ন' : 'Foggy';
  if (code <= 57) return isBn ? 'গুঁড়ি গুঁড়ি বৃষ্টি' : 'Drizzle';
  if (code <= 67) return isBn ? 'বৃষ্টিপাত' : 'Rainy';
  if (code <= 77) return isBn ? 'তুষারপাত' : 'Snowy';
  if (code <= 82) return isBn ? 'বৃষ্টির ঝাপটা' : 'Rain Showers';
  if (code <= 86) return isBn ? 'তুষার ঝাপটা' : 'Snow Showers';
  if (code <= 99) return isBn ? 'বজ্রবৃষ্টি' : 'Thunderstorm';
  return isBn ? 'অজানা' : 'Unknown';
}

String _wmoIcon(int code) {
  if (code == 0 || code == 1) return 'sun';
  if (code <= 48) return 'cloud';
  return 'rain';
}

class WeatherAdvisory extends StatefulWidget {
  const WeatherAdvisory({super.key});

  @override
  State<WeatherAdvisory> createState() => _WeatherAdvisoryState();
}

class _WeatherAdvisoryState extends State<WeatherAdvisory> {
  String _selectedRegion = 'netrokona';
  bool _isLoadingLive = false;
  Map<String, dynamic>? _liveData; // null = use static fallback

  @override
  void initState() {
    super.initState();
    _fetchLiveWeather(_selectedRegion);
  }

  Future<void> _fetchLiveWeather(String region) async {
    final coords = _regionLatLon[region];
    if (coords == null) return;
    setState(() => _isLoadingLive = true);
    try {
      final lat = coords[0];
      final lon = coords[1];
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat&longitude=$lon'
        '&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m'
        '&hourly=precipitation_probability'
        '&forecast_days=1'
        '&timezone=Asia%2FDhaka',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final current = json['current'] as Map<String, dynamic>;
        final hourlyProb = (json['hourly']?['precipitation_probability'] as List?) ?? [];
        final rainProb = hourlyProb.isNotEmpty
            ? (hourlyProb[0] as num).toInt()
            : 0;
        setState(() {
          _liveData = {
            'temp': (current['temperature_2m'] as num).round(),
            'humidity': (current['relative_humidity_2m'] as num).round(),
            'windKm': (current['wind_speed_10m'] as num).round(),
            'wmoCode': (current['weather_code'] as num).toInt(),
            'rainProb': rainProb,
          };
          _isLoadingLive = false;
        });
        return;
      }
    } catch (_) {}
    // fallback to static on error
    setState(() {
      _liveData = null;
      _isLoadingLive = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final isBn = langProvider.isBn;
    final staticData = districtWeatherData[_selectedRegion] ?? districtWeatherData['dhaka']!;

    // Merge live API data over static fallback
    final int temp = _liveData?['temp'] ?? staticData.temp;
    final int humidity = _liveData?['humidity'] ?? staticData.humidity;
    final int windKm = _liveData?['windKm'] ?? staticData.windKm;
    final int rainProb = _liveData?['rainProb'] ?? staticData.rainProb;
    final int wmoCode = _liveData?['wmoCode'] ?? 0;
    final String conditionBn = _liveData != null
        ? _mapWmoCode(wmoCode, true)
        : staticData.conditionBn;
    final String conditionEn = _liveData != null
        ? _mapWmoCode(wmoCode, false)
        : staticData.conditionEn;
    final String icon = _liveData != null ? _wmoIcon(wmoCode) : staticData.icon;

    final isAlert = staticData.advisoryType == 'alert';
    final isAdvisory = staticData.advisoryType == 'advisory';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.lightGreen50,
                            border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(
                            Icons.wb_sunny_outlined,
                            size: 18,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  isBn ? 'আবহাওয়া ও গ্রামীণ বার্তা' : 'Weather & Civic Alert',
                                  style: GoogleFonts.notoSansBengali(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  color: AppColors.lightGreen50,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 5,
                                        height: 5,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.primaryGreen,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isBn ? 'লাইভ' : 'LIVE',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primaryGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              isBn
                                  ? 'কৃষি ও দুর্যোগ প্রস্তুতি'
                                  : 'Agriculture & Disaster Preparedness',
                              style: GoogleFonts.notoSansBengali(
                                fontSize: 10,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Region Selector Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.bgMuted,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedRegion,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryGreen),
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      onChanged: (String? val) {
                        if (val != null) {
                          setState(() => _selectedRegion = val);
                          _fetchLiveWeather(val);
                        }
                      },
                      items: districtWeatherData.entries.map((e) {
                        final d = e.value;
                        return DropdownMenuItem<String>(
                          value: e.key,
                          child: Text(isBn ? d.districtBn : d.districtEn),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Weather Snapshot Card
          Padding(
            padding: const EdgeInsets.all(14),
            child: _isLoadingLive
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(
                        color: AppColors.primaryGreen,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isBn ? '${staticData.divisionBn} বিভাগ' : '${staticData.divisionEn} Division',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        if (_liveData != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            color: AppColors.primaryGreen,
                            child: Text(
                              isBn ? 'লাইভ ডেটা' : 'LIVE',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        const SizedBox(width: 4),
                        Text(
                          isBn ? 'আজকের পূর্বাভাস' : "Today's Forecast",
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Temperature + Condition
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Icon(
                        icon == 'sun'
                            ? Icons.wb_sunny
                            : icon == 'rain'
                                ? Icons.water_drop
                                : Icons.cloud,
                        size: 26,
                        color: icon == 'sun'
                            ? Colors.amber[700]
                            : icon == 'rain'
                                ? Colors.blue[600]
                                : AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${isBn ? AppConstants.toBengaliNumber(temp) : temp}°C',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          isBn ? conditionBn : conditionEn,
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Metrics Row (Rain %, Humidity %, Wind km/h)
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        color: AppColors.bgMuted,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isBn ? 'বৃষ্টির সম্ভাবনা' : 'Rain Prob',
                              style: GoogleFonts.notoSansBengali(
                                fontSize: 9,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${isBn ? AppConstants.toBengaliNumber(rainProb) : rainProb}%',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        color: AppColors.bgMuted,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isBn ? 'বাতাসের আর্দ্রতা' : 'Humidity',
                              style: GoogleFonts.notoSansBengali(
                                fontSize: 9,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${isBn ? AppConstants.toBengaliNumber(humidity) : humidity}%',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        color: AppColors.bgMuted,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isBn ? 'বাতাসের গতি' : 'Wind Speed',
                              style: GoogleFonts.notoSansBengali(
                                fontSize: 9,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${isBn ? AppConstants.toBengaliNumber(windKm) : windKm} ${isBn ? "কিমি/ঘ" : "km/h"}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Urgent / Notice Alert Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isAlert
                        ? AppColors.lightRed50
                        : isAdvisory
                            ? AppColors.amber50
                            : AppColors.lightGreen50,
                    border: Border(
                      left: BorderSide(
                        color: isAlert
                            ? AppColors.primaryRed
                            : isAdvisory
                                ? AppColors.amber500
                                : AppColors.primaryGreen,
                        width: 3,
                      ),
                      top: const BorderSide(color: AppColors.border, width: 1),
                      right: const BorderSide(color: AppColors.border, width: 1),
                      bottom: const BorderSide(color: AppColors.border, width: 1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isAlert ? Icons.warning_amber_rounded : Icons.info_outline,
                            size: 15,
                            color: isAlert
                                ? AppColors.primaryRed
                                : isAdvisory
                                    ? Colors.amber[800]
                                    : AppColors.primaryGreen,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              isBn ? staticData.advisoryTitleBn : staticData.advisoryTitleEn,
                              style: GoogleFonts.notoSansBengali(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isAlert
                                    ? AppColors.primaryRed
                                    : isAdvisory
                                        ? Colors.amber[900]
                                        : AppColors.darkGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isBn ? staticData.advisoryDescBn : staticData.advisoryDescEn,
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 11,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Crop & Agricultural Advisory Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppColors.lightGreen50,
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
                        children: [
                          const Icon(Icons.eco_outlined, size: 15, color: AppColors.primaryGreen),
                          const SizedBox(width: 6),
                          Text(
                            isBn ? 'কৃষি ও ফসল সুরক্ষা নির্দেশিকা' : 'Crop & Farm Protection',
                            style: GoogleFonts.notoSansBengali(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isBn ? staticData.cropAdviceBn : staticData.cropAdviceEn,
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Button to ask Jonobondhu AI
                InkWell(
                  onTap: () {
                    JonobondhuChatOverlay.openChat(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      border: Border.all(color: AppColors.primaryGreen),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          isBn
                              ? 'আবহাওয়া ও কৃষি নিয়ে AI-কে প্রশ্ন করুন'
                              : 'Ask Jonobondhu AI About Weather',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
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
