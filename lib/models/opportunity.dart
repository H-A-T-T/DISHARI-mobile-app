class OpportunityItem {
  final String id;
  final String titleBn;
  final String titleEn;
  final String authorityBn;
  final String authorityEn;
  final String category;
  final String benefitBn;
  final String benefitEn;
  final String deadlineBn;
  final String deadlineEn;
  final String ageRange;
  final String minEducation; // 'none' | 'ssc' | 'hsc' | 'degree'
  final List<String> targetOccupations;
  final List<String> divisions;
  final String descBn;
  final String descEn;
  final List<String> docsBn;
  final String? applySlug;
  final String? officialLink;

  const OpportunityItem({
    required this.id,
    required this.titleBn,
    required this.titleEn,
    required this.authorityBn,
    required this.authorityEn,
    required this.category,
    required this.benefitBn,
    required this.benefitEn,
    required this.deadlineBn,
    required this.deadlineEn,
    required this.ageRange,
    required this.minEducation,
    required this.targetOccupations,
    required this.divisions,
    required this.descBn,
    required this.descEn,
    required this.docsBn,
    this.applySlug,
    this.officialLink,
  });
}

const List<OpportunityItem> officialOpportunities = [
  OpportunityItem(
    id: 'pm-scholarship',
    titleBn: 'প্রধানমন্ত্রীর শিক্ষা সহায়তা ট্রাস্ট সমন্বিত উপবৃত্তি',
    titleEn: 'PM Education Assistance Trust Integrated Stipend',
    authorityBn: 'শিক্ষা মন্ত্রণালয়',
    authorityEn: 'Ministry of Education',
    category: 'education',
    benefitBn: 'বার্ষিক ৫,০০০ - ১০,০০০ টাকা এককালীন অনুদান + মাসিক ফি সহায়তা',
    benefitEn: 'Annual ৳5,000 - ৳10,000 grant + monthly tuition aid',
    deadlineBn: '১৫ ডিসেম্বর ২০২৬',
    deadlineEn: 'December 15, 2026',
    ageRange: '১২-২৫',
    minEducation: 'ssc',
    targetOccupations: ['student'],
    divisions: ['all'],
    descBn:
        'মাধ্যমিক, উচ্চ মাধ্যমিক ও স্নাতক পর্যায়ের অসচ্ছল ও মেধাবী শিক্ষার্থীদের পড়াশোনা অব্যাহত রাখার জন্য সরকারি আর্থিক সহায়তা।',
    descEn:
        'Government financial assistance for underprivileged meritorious students at secondary and higher secondary levels.',
    docsBn: [
      'শিক্ষাপ্রতিষ্ঠানের প্রত্যয়নপত্র',
      'অভিভাবকের আয়ের সনদ',
      'শিক্ষার্থীর জন্মনিবন্ধন / NID',
      'নগদ/বিকাশ একাউন্ট নম্বর'
    ],
    applySlug: 'scholarship',
    officialLink: 'https://pmeat.gov.bd',
  ),
  OpportunityItem(
    id: 'youth-training-loan',
    titleBn: 'যুব উন্নয়ন অধিদপ্তর কারিগরি প্রশিক্ষণ ও আত্মকর্মসংস্থান ঋণ',
    titleEn:
        'Dept of Youth Development Skills Training & Self-Employment Loan',
    authorityBn: 'যুব ও ক্রীড়া মন্ত্রণালয়',
    authorityEn: 'Ministry of Youth and Sports',
    category: 'youth',
    benefitBn:
        'বিনামূল্যে ৩-৬ মাসের প্রশিক্ষণ + ৫০,০০০ থেকে ২,০০,০০০ টাকা সহজ শর্তে ঋণ',
    benefitEn:
        'Free 3-6 months skill training + ৳50,000 to ৳2,00,000 soft loan',
    deadlineBn: 'প্রতি ত্রৈমাসিকে উন্মুক্ত (চলমান)',
    deadlineEn: 'Open quarterly (Ongoing)',
    ageRange: '১৮-৩৫',
    minEducation: 'none',
    targetOccupations: ['unemployed', 'sme'],
    divisions: ['all'],
    descBn:
        'ডিগ্রী পাস বা ড্রপআউট বেকার যুবক ও যুবতীদের জন্য আইটি, গবাদিপশু পালন, ইলেকট্রিক্যাল ও মৎস্য চাষে বাস্তবমুখী প্রশিক্ষণ ও ঋণ সুবিধা।',
    descEn:
        'Hands-on technical training and seed capital loans for unemployed youth, degree holders, and fresh entrepreneurs.',
    docsBn: [
      'NID কার্ডের মূল ও ফটোকপি',
      'শিক্ষাগত যোগ্যতার সনদ',
      'চেয়ারম্যানের নাগরিকত্ব সনদ',
      '৩ কপি পাসপোর্ট ছবি'
    ],
    applySlug: 'trade-license',
    officialLink: 'https://dyd.gov.bd',
  ),
  OpportunityItem(
    id: 'widow-allowance-gov',
    titleBn: 'বিধবা ও স্বামী নিগৃহীতা মহিলা সরকারি ভাতা',
    titleEn: 'National Widow & Deserted Women Allowance',
    authorityBn: 'সমাজসেবা অধিদপ্তর, সমাজকল্যাণ মন্ত্রণালয়',
    authorityEn: 'Department of Social Services, Ministry of Social Welfare',
    category: 'welfare',
    benefitBn: 'মাসিক ৮৫০ টাকা সরাসরি মোবাইল ব্যাংকিং একাউন্টে (G2P)',
    benefitEn: 'Monthly ৳850 sent directly to mobile banking (G2P)',
    deadlineBn: 'ইউনিয়ন পরিষদ সময়সূচি অনুযায়ী (প্রতি বছর সেপ্টেম্বর-ডিসেম্বর)',
    deadlineEn: 'Per Union Parishad cycle (Annual Sep-Dec renewal)',
    ageRange: '১৮+',
    minEducation: 'none',
    targetOccupations: ['widow'],
    divisions: ['all'],
    descBn:
        'হতদরিদ্র বিধবা ও স্বামী পরিত্যক্ত নারীদের জন্য সামাজিক নিরাপত্তা বেষ্টনীর আওতায় স্থায়ী মাসিক অর্থ সহায়তা। কোনো দালাল ছাড়াই অনলাইনে তালিকাভুক্তি।',
    descEn:
        'Direct social security monthly cash allowance for underprivileged widows and deserted women without intermediaries.',
    docsBn: [
      'আবেদনকারীর ডিজিটাল NID',
      'স্বামীর মৃত্যু সনদ / বিবাহবিচ্ছেদ প্রত্যয়ন',
      'ইউনিয়ন পরিষদ চেয়ারম্যানের ওয়ারিশান ও নাগরিক সনদ',
      'সক্রিয় মোবাইল ব্যাংকিং হিসাব'
    ],
    applySlug: 'widow-allowance',
    officialLink: 'https://dss.gov.bd',
  ),
  OpportunityItem(
    id: 'probashi-rehab-loan',
    titleBn: 'প্রবাসী কল্যাণ ব্যাংক পুনর্বাসন ও অভিবাসী উদ্যোক্তা ঋণ',
    titleEn: 'Probashi Kallyan Bank Returnee Rehabilitation Loan',
    authorityBn: 'প্রবাসী কল্যাণ ও বৈদেশিক কর্মসংস্থান মন্ত্রণালয়',
    authorityEn:
        'Ministry of Expatriates Welfare and Overseas Employment',
    category: 'overseas',
    benefitBn:
        '২,০০,০০০ থেকে ২০,০০,০০০ টাকা স্বল্প সুদে জামানতবিহীন/সহজ শর্তে ঋণ',
    benefitEn:
        '৳2,00,000 to ৳20,00,000 low-interest rehabilitation loan',
    deadlineBn: 'সারা বছর আবেদনযোগ্য',
    deadlineEn: 'Open year-round',
    ageRange: '২১-৬৫',
    minEducation: 'none',
    targetOccupations: ['returnee', 'sme'],
    divisions: ['all'],
    descBn:
        'বিদেশ ফেরত কর্মীদের দেশে পুনর্বাসন, নতুন ব্যবসা প্রতিষ্ঠা এবং নিরাপদ অভিবাসনের খরচ মেটাতে বিশেষ সরকারি আর্থিক স্কিম।',
    descEn:
        'Dedicated financing scheme to help returnee migrant workers re-integrate, start local businesses, or migrate safely.',
    docsBn: [
      'পাসপোর্টের ভিসা ও আগমন সিল কপি',
      'প্রবাসী কল্যাণ কার্ড / BMET স্মার্টকার্ড',
      'ব্যবসা বা খামার প্রকল্পের বিবরণী',
      'ট্রেড লাইসেন্স ও NID'
    ],
    applySlug: 'overseas-welfare-card',
    officialLink: 'https://pkb.gov.bd',
  ),
  OpportunityItem(
    id: 'agri-stimulus-input',
    titleBn: 'ক্ষুদ্র ও প্রান্তিক কৃষক কৃষি প্রণোদনা (বিনামূল্যে বীজ ও সার)',
    titleEn:
        'Smallholder Farmer Agricultural Incentive (Free Seeds & Fertilizer)',
    authorityBn: 'কৃষি মন্ত্রণালয় (কৃষি সম্প্রসারণ অধিদপ্তর)',
    authorityEn: 'Ministry of Agriculture (DAE)',
    category: 'agri',
    benefitBn:
        'বিনামূল্যে উচ্চফলনশীল বোরো/রবি বীজ ও ডিএপি/এমওপি সার প্যাকেজ',
    benefitEn: 'Free high-yielding seed kit + DAP/MOP fertilizer bag',
    deadlineBn: 'মৌসুম শুরুর আগে (উপজেলা কৃষি অফিস অনুযায়ী)',
    deadlineEn: 'Prior to planting season (Upazila Agri Office)',
    ageRange: '১৮+',
    minEducation: 'none',
    targetOccupations: ['farmer'],
    divisions: ['all'],
    descBn:
        'বন্যা, খরা বা হাওর এলাকায় ক্ষতিগ্রস্ত এবং প্রান্তিক কৃষকদের জন্য কৃষি পুনর্বাসন সহায়তা। কৃষক কার্ডের মাধ্যমে বিতরণ।',
    descEn:
        'Agri rehabilitation support for marginal farmers affected by floods, climate hazards, and haor waterlogging.',
    docsBn: [
      'কৃষি উপকরণ সহায়তা কার্ড (কৃষক কার্ড)',
      'NID কার্ডের ফটোকপি',
      'উপসহকারী কৃষি কর্মকর্তার সুপারিশ স্লিপ'
    ],
    applySlug: 'land-mutation',
    officialLink: 'https://dae.gov.bd',
  ),
  OpportunityItem(
    id: 'cht-ethnic-grant',
    titleBn: 'পার্বত্য চট্টগ্রাম ও সমতল ক্ষুদ্র নৃগোষ্ঠী বিশেষ উন্নয়ন অনুদান',
    titleEn:
        'CHT & Plainland Ethnic Minority Special Development Grant',
    authorityBn:
        'পার্বত্য চট্টগ্রাম বিষয়ক মন্ত্রণালয় / প্রধানমন্ত্রীর কার্যালয়',
    authorityEn:
        'Ministry of CHT Affairs / Prime Minister Office',
    category: 'ethnic',
    benefitBn: 'এককালীন ২৫,০০০ - ৫০,০০০ টাকা শিক্ষা ও ক্ষুদ্র উদ্যোক্তা অনুদান',
    benefitEn:
        'One-time ৳25,000 - ৳50,000 education & micro-enterprise grant',
    deadlineBn: '২৮ ফেব্রুয়ারি ২০২৭',
    deadlineEn: 'February 28, 2027',
    ageRange: '১৫-৪০',
    minEducation: 'none',
    targetOccupations: ['ethnic', 'student', 'sme'],
    divisions: ['chattogram', 'sylhet', 'rangpur', 'mymensingh'],
    descBn:
        'মারমা, চাকমা, ত্রিপুরা, গারো, সাঁওতালসহ সকল ক্ষুদ্র নৃগোষ্ঠীর তরুণ-তরুণীদের শিক্ষা এবং আত্মকর্মসংস্থানে সরকারি বিশেষ কোটা ও অনুদান।',
    descEn:
        'Targeted government grant and education quota support for Marma, Chakma, Garo, Santal and other indigenous ethnic youth.',
    docsBn: [
      'সার্কেল চিফ / উপজেলা নির্বাহী কর্মকর্তার ক্ষুদ্র নৃগোষ্ঠী সনদ',
      'NID বা জন্মনিবন্ধন',
      'শিক্ষাগত বা প্রকল্পের প্রত্যয়ন'
    ],
    applySlug: 'scholarship',
    officialLink: 'https://mochta.gov.bd',
  ),
  OpportunityItem(
    id: 'sme-cottage-credit',
    titleBn: 'এসএমই ফাউন্ডেশন ও বিসিক কুটির শিল্প প্রণোদনা তহবিল',
    titleEn: 'SME Foundation & BSCIC Cottage Industry Stimulus Fund',
    authorityBn: 'শিল্প মন্ত্রণালয়',
    authorityEn: 'Ministry of Industries',
    category: 'sme',
    benefitBn: '৪% হ্রাসকৃত সুদে ১,০০,০০০ থেকে ৫,০০,০০০ টাকা জামানতবিহীন ঋণ',
    benefitEn:
        '৳1,00,000 - ৳5,00,000 collateral-free loan at 4% concessional rate',
    deadlineBn: 'চলমান কোটা ভিত্তিক',
    deadlineEn: 'Ongoing quota-based',
    ageRange: '১৮-৫০',
    minEducation: 'none',
    targetOccupations: ['sme', 'unemployed'],
    divisions: ['all'],
    descBn:
        'স্থানীয় হস্তশিল্প, খাদ্য প্রক্রিয়াকরণ ও ছোট ব্যবসায়ীদের জন্য দালালমুক্ত সরকারি ঋণ সহায়তা ও পণ্য বিপণন মেলায় অংশ নেওয়ার সুযোগ।',
    descEn:
        'Collateral-free low-interest microcredit for cottage artisans, food processors, and small business owners.',
    docsBn: [
      'ইউনিয়ন বা পৌরসভা ট্রেড লাইসেন্স',
      'TIN সার্টিফিকেট ও NID',
      'দোকান বা কারখানার অবস্থান প্রমাণ',
      'ব্যাংক হিসাব বিবরণী'
    ],
    applySlug: 'trade-license',
    officialLink: 'https://smef.gov.bd',
  ),
];
