import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/env.dart';

class AgentService {
  static const String _systemPromptBn = '''
আপনি দিশারীর (Dishari) ভার্চুয়াল নাগরিক সেবা সহকারী 'জনবন্ধু AI' (Jonobondhu AI)।
আপনার কাজ হলো বাংলাদেশের সাধারণ নাগরিকদের সরকারি সেবা (যেমন: ই-পাসপোর্ট, জাতীয় পরিচয়পত্র/NID সংশোধন, ডিজিটাল জন্ম ও মৃত্যু নিবন্ধন, ই-নামজারি ও জমির খতিয়ান, ই-ট্রেড লাইসেন্স, সামাজিক নিরাপত্তা ভাতা যেমন বয়স্ক/বিধবা/প্রতিবন্ধী ভাতা, ই-টিআইএন ও আয়কর রিটার্ন, বিএমইটি স্মার্ট কার্ড, ড্রাইভিং লাইসেন্স, পুলিশ ক্লিয়ারেন্স ইত্যাদি) সম্পর্কে সঠিক, নির্ভরযোগ্য ও সহজবোধ্য তথ্য দেওয়া।

নিয়মাবলী:
১. উত্তর সবসময় বিনম্র, স্পষ্ট ও সহজ বাংলায় দিন (ব্যবহারকারী ইংরেজিতে লিখলে ইংরেজিতে উত্তর দিন)।
২. প্রযোজ্য ক্ষেত্রে সরকারি সঠিক ফি (টাকা), প্রয়োজনীয় কাগজপত্রের তালিকা, অফিশিয়াল সরকারি ওয়েবসাইট (.gov.bd) এবং আবেদন প্রক্রিয়ার ধাপগুলো সংক্ষেপে পয়েন্ট আকারে উল্লেখ করুন।
৩. কোনো প্রকার বিভ্রান্তিকর বা অনানুষ্ঠানিক দালালি তথ্য দেবেন না। নাগরিকদের সচেতন ও স্বাবলম্বী করুন।
৪. অ্যাপের সংশ্লিষ্ট স্ক্রিনে নেভিগেশন: যখনই ব্যবহারকারী কোনো সেবা বা অ্যাপ সেকশন (যেমন: পাসপোর্ট, NID সংশোধন, লকার, সুযোগ হাব, ডেডলাইন ইত্যাদি) সম্পর্কে জানতে চান বা পেজে যেতে চান, উত্তরের শেষে নিচের ফরম্যাটে একটি অ্যাকশন ট্যাগ যুক্ত করবেন:
   - পাসপোর্ট সেবায় যেতে: [ACTION:service:passport:পাসপোর্ট আবেদন পেজে যান]
   - NID সংশোধনে যেতে: [ACTION:service:nid-correction:NID সংশোধন পেজে যান]
   - জন্ম নিবন্ধনে যেতে: [ACTION:service:birth-registration:জন্ম নিবন্ধন পেজে যান]
   - ট্রেড লাইসেন্সে যেতে: [ACTION:service:trade-license:ট্রেড লাইসেন্স পেজে যান]
   - ই-নামজারিতে যেতে: [ACTION:service:land-mutation:নামজারি পেজে যান]
   - নাগরিক লকারে যেতে: [ACTION:tab:2:নাগরিক লকারে যান]
   - সুযোগ ও অনুদান হাবে যেতে: [ACTION:screen:opportunities:সুযোগ ও অনুদান হাব খুলুন]
   - ডেডলাইন দেখতে: [ACTION:tab:3:ডেডলাইন তালিকা খুলুন]
   - আমাদের সম্পর্কে বা লক্ষ্য জানতে: [ACTION:screen:about:আমাদের সম্পর্কে জানুন]
''';

  static const String _systemPromptEn = '''
You are 'Jonobondhu AI' (জনবন্ধু AI), the civic service assistant for Dishari (দিশারী) in Bangladesh.
Your mission is to assist citizens with accurate, official information regarding Bangladesh government services (such as e-Passport, National ID / NID correction, Birth Registration, e-Namjari land records, e-Trade license, social allowances, e-TIN, driving license, BMET expatriate card, etc.).

Guidelines:
1. Provide concise, clear, polite, and step-by-step guidance.
2. Include official government fees (in BDT), required documents, official government portals (.gov.bd), and expected processing timelines where relevant.
3. Help citizens avoid unauthorized middlemen and empower them to complete applications transparently.
4. Navigation: Whenever the user inquires about or asks to open a specific service or feature in the app, append a direct navigation tag at the end of your response:
   - Passport: [ACTION:service:passport:Go to Passport Page]
   - NID: [ACTION:service:nid-correction:Go to NID Correction]
   - Birth: [ACTION:service:birth-registration:Go to Birth Registration]
   - Trade License: [ACTION:service:trade-license:Go to Trade License]
   - Land Mutation: [ACTION:service:land-mutation:Go to Land Mutation]
   - Locker: [ACTION:tab:2:Open Document Locker]
   - Opportunities: [ACTION:screen:opportunities:Open Opportunities Hub]
   - Deadlines: [ACTION:tab:3:View Deadlines]
   - About Dishari: [ACTION:screen:about:Learn About Dishari]
''';

  /// Sends a query to the AI agent.
  /// If an API key is provided in .env (GEMINI_API_KEY / OPENAI_API_KEY / AI_API_URL),
  /// it dynamically queries the AI. Otherwise, or on network failure, it smoothly falls back
  /// to the built-in civic service knowledge base.
  static Future<String> getReply({
    required String prompt,
    required bool isBn,
    List<({bool isUser, String text})>? history,
  }) async {
    final cleanPrompt = prompt.trim();
    if (cleanPrompt.isEmpty) return '';

    // 1. Try Google Gemini API if GEMINI_API_KEY is present
    if (EnvConfig.geminiApiKey.isNotEmpty) {
      try {
        final geminiReply = await _callGeminiApi(
          apiKey: EnvConfig.geminiApiKey,
          prompt: cleanPrompt,
          isBn: isBn,
          history: history,
        );
        if (geminiReply != null && geminiReply.isNotEmpty) {
          return geminiReply;
        }
      } catch (e) {
        debugPrint('Gemini API error, falling back to civic knowledge base: $e');
      }
    }

    // 2. Try OpenAI API if OPENAI_API_KEY is present
    if (EnvConfig.openaiApiKey.isNotEmpty) {
      try {
        final openaiReply = await _callOpenAiApi(
          apiKey: EnvConfig.openaiApiKey,
          prompt: cleanPrompt,
          isBn: isBn,
          history: history,
        );
        if (openaiReply != null && openaiReply.isNotEmpty) {
          return openaiReply;
        }
      } catch (e) {
        debugPrint('OpenAI API error, falling back to civic knowledge base: $e');
      }
    }

    // 3. Try custom AI_API_URL if configured
    if (EnvConfig.aiApiUrl.isNotEmpty) {
      try {
        final customReply = await _callCustomAiApi(
          url: EnvConfig.aiApiUrl,
          prompt: cleanPrompt,
          isBn: isBn,
        );
        if (customReply != null && customReply.isNotEmpty) {
          return customReply;
        }
      } catch (e) {
        debugPrint('Custom AI API error, falling back to civic knowledge base: $e');
      }
    }

    // 4. Default / Offline / Fallback knowledge base
    return getLocalFallbackReply(cleanPrompt, isBn);
  }

  /// Call Google Gemini REST API (gemini-1.5-flash)
  static Future<String?> _callGeminiApi({
    required String apiKey,
    required String prompt,
    required bool isBn,
    List<({bool isUser, String text})>? history,
  }) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
    );

    final List<Map<String, dynamic>> contents = [];

    // Append recent chat history (up to last 4 messages for context)
    if (history != null && history.isNotEmpty) {
      final recent = history.length > 4 ? history.sublist(history.length - 4) : history;
      for (final msg in recent) {
        contents.add({
          'role': msg.isUser ? 'user' : 'model',
          'parts': [{'text': msg.text}],
        });
      }
    }

    // Append current prompt
    contents.add({
      'role': 'user',
      'parts': [{'text': prompt}],
    });

    final body = jsonEncode({
      'system_instruction': {
        'parts': [
          {'text': isBn ? _systemPromptBn : _systemPromptEn}
        ]
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.4,
        'maxOutputTokens': 800,
      },
    });

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final candidates = json['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final parts = candidates[0]['content']?['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          return parts[0]['text']?.toString().trim();
        }
      }
    } else {
      debugPrint('Gemini API status: ${response.statusCode}, body: ${response.body}');
    }
    return null;
  }

  /// Call OpenAI Chat Completions API
  static Future<String?> _callOpenAiApi({
    required String apiKey,
    required String prompt,
    required bool isBn,
    List<({bool isUser, String text})>? history,
  }) async {
    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');

    final List<Map<String, String>> messages = [
      {'role': 'system', 'content': isBn ? _systemPromptBn : _systemPromptEn},
    ];

    if (history != null && history.isNotEmpty) {
      final recent = history.length > 4 ? history.sublist(history.length - 4) : history;
      for (final msg in recent) {
        messages.add({
          'role': msg.isUser ? 'user' : 'assistant',
          'content': msg.text,
        });
      }
    }

    messages.add({'role': 'user', 'content': prompt});

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': 'gpt-4o-mini',
            'messages': messages,
            'temperature': 0.4,
            'max_tokens': 600,
          }),
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final choices = json['choices'] as List?;
      if (choices != null && choices.isNotEmpty) {
        return choices[0]['message']?['content']?.toString().trim();
      }
    }
    return null;
  }

  /// Call custom webhook / proxy / FastAPI AI endpoint
  static Future<String?> _callCustomAiApi({
    required String url,
    required String prompt,
    required bool isBn,
  }) async {
    final uri = Uri.parse(url);
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'prompt': prompt,
            'language': isBn ? 'bn' : 'en',
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['reply'] ?? json['response'] ?? json['text'] ?? json['message'];
    }
    return null;
  }

  /// Comprehensive civic fallback matching verified Bangladesh government service rules
  static String getLocalFallbackReply(String text, bool isBn) {
    final lower = text.toLowerCase();

    // Direct Passport section / change passport query
    if (text.contains('পাসপোর্ট') &&
        (text.contains('কোথায়') ||
            text.contains('পরিবর্তন') ||
            text.contains('সেকশন') ||
            text.contains('পেজ') ||
            text.contains('আবেদন'))) {
      return isBn
          ? '🛂 পাসপোর্ট পরিবর্তন বা নতুন আবেদনের জন্য দিশারী অ্যাপের ডেডিকেটেড ‘ই-পাসপোর্ট’ সেকশন রয়েছে।\n\n'
              'সেখানে আপনি প্রয়োজনীয় কাগজপত্রের তালিকা, স্মার্ট ডকুমেন্ট ব্যাগ চেকার এবং সরাসরি সরকারি আবেদন নির্দেশিকা পাবেন।\n\n'
              '[ACTION:service:passport:পাসপোর্ট আবেদন পেজে যান]'
          : '🛂 For e-Passport renewal, change, or new application, please visit our dedicated Passport Service section:\n\n'
              '[ACTION:service:passport:Go to Passport Page]';
    }

    // Document locker query
    if (text.contains('লকার') ||
        text.contains('নথিপত্র') ||
        lower.contains('locker') ||
        (text.contains('ডকুমেন্ট') && text.contains('কোথায়'))) {
      return isBn
          ? '📂 আপনার নাগরিক লকারে NID, জন্ম নিবন্ধন, ছবি ও সার্টিফিকেট নিরাপদে জমা রাখতে পারবেন। নতুন নথি স্ক্যান ও AI যাচাই করতে নিচের বাটনে চাপ দিন:\n\n'
              '[ACTION:tab:2:নাগরিক লকারে যান]'
          : '📂 Manage your citizen documents, NID, and certificates in Document Locker:\n\n'
              '[ACTION:tab:2:Open Document Locker]';
    }

    // Opportunities Hub query
    if (text.contains('সুযোগ') ||
        text.contains('অনুদান') ||
        text.contains('স্কলারশিপ') ||
        text.contains('উপবৃত্তি') ||
        lower.contains('opportunity')) {
      return isBn
          ? '🌟 চলমান সরকারি অনুদান, যুব ঋণ, কৃষক প্রণোদনা ও শিক্ষাবৃত্তির তালিকা দেখতে আমাদের সুযোগ হাবে প্রবেশ করুন:\n\n'
              '[ACTION:screen:opportunities:সুযোগ ও অনুদান হাব খুলুন]'
          : '🌟 Explore active government loans, stipends, and subsidies:\n\n'
              '[ACTION:screen:opportunities:Open Opportunities Hub]';
    }

    // Deadlines query
    if (text.contains('ডেডলাইন') ||
        text.contains('সময়সীমা') ||
        text.contains('তারিখ') ||
        lower.contains('deadline')) {
      return isBn
          ? '📅 আসন্ন সকল সরকারি আবেদন, ফি জমা ও ট্যাক্স রিটার্নের ডেডলাইন এবং কাউন্টডাউন দেখতে ডেডলাইন ট্যাবে যান:\n\n'
              '[ACTION:tab:3:ডেডলাইন তালিকা দেখুন]'
          : '📅 View all upcoming civic deadlines and countdown timers:\n\n'
              '[ACTION:tab:3:View Deadlines]';
    }

    // About Dishari query
    if (text.contains('আমাদের সম্পর্কে') ||
        text.contains('দিশারী কী') ||
        text.contains('লক্ষ্য') ||
        lower.contains('about') ||
        lower.contains('who are you') ||
        lower.contains('what is dishari')) {
      return isBn
          ? '🏛️ দিশারী একটি নাগরিক-সহায়তাকারী প্ল্যাটফর্ম যা বাংলাদেশের সাধারণ মানুষকে কোনো দালাল বা মধ্যস্বত্বভোগী ছাড়াই সরকারি সেবা বুঝে নিতে এবং আবেদন সম্পন্ন করতে সাহায্য করে।\n\n'
              '[ACTION:screen:about:আমাদের সম্পর্কে বিস্তারিত জানুন]'
          : '🏛️ Dishari is a civic companion designed to empower Bangladeshi citizens to navigate government services with transparency and without middleman exploitation.\n\n'
              '[ACTION:screen:about:Learn About Dishari]';
    }

    // 0. Invalid passport troubleshooting
    if (text.contains('ইনভ্যালিড') ||
        lower.contains('invalid') ||
        (text.contains('পাসপোর্ট') &&
            (text.contains('ভুল') || text.contains('সমস্যা')))) {
      return isBn
          ? '⚠️ পাসপোর্ট আবেদনে ইনভ্যালিড দেখানোর প্রধান কারণ ও সমাধান:\n\n'
              '১. NID ও জন্মনিবন্ধনের নামের ইংরেজি বানানে অমিল থাকলে এমন হতে পারে।\n'
              '২. ১৭ ডিজিটের অনলাইন ডিজিটাল সনদের পরিবর্তে পুরাতন হাতে লেখা নম্বর প্রদান করলে পোর্টাল ইনভ্যালিড দেখায়।\n'
              '৩. epassport.gov.bd-তে ডাটা মিলিয়ে পুনরায় যাচাই করুন।'
          : '⚠️ Invalid Passport Error Troubleshooting:\n\n'
              '1. Discrepancy between English spelling on NID and digital birth certificate.\n'
              '2. Using old handwritten birth certificate instead of verified 17-digit online BDRIS.\n'
              '3. Verify records at epassport.gov.bd and ensure exact character matching.';
    }

    // 0.1 Inheritance land mutation
    if (text.contains('বাবার মৃত্যু') ||
        text.contains('ওয়ারিশ') ||
        text.contains('পৈত্রিক')) {
      return isBn
          ? '📜 ওয়ারিশান সূত্রে জমির ই-নামজারি করার নিয়ম:\n\n'
              '১. ইউনিয়ন পরিষদ/পৌরসভা থেকে ওয়ারিশান সনদ ও পিতার মৃত্যু সনদ সংগ্রহ করুন।\n'
              '২. mutation.land.gov.bd পোর্টালে "ওয়ারিশান নামজারি" বিকল্প বেছে আবেদন করুন।\n'
              '৩. সকল ওয়ারিশের ডিজিটাল NID ও জমির পূর্ববর্তী খতিয়ান/হালনাগাদ দাখিলা আপলোড করুন।\n'
              '৪. মোট সরকারি ফি ১,১৭০ টাকা অনলাইনে পরিশোধ করুন (আবেদন ২০ + নোটিশ ৫০ + রেকর্ড সংশোধন ১,০০০ + ডিসিআর ১০০)। কোনো অতিরিক্ত দালাল ফি নেই।'
          : '📜 Land Mutation (Inheritance / Warishan):\n\n'
              '1. Obtain Warishan certificate & death certificate from local Union Parishad.\n'
              '2. Apply online at mutation.land.gov.bd choosing "Inheritance Mutation".\n'
              '3. Upload all heirs\' NIDs, registered title deeds, and up-to-date land tax receipts.\n'
              '4. Official fee is strictly 1,170 BDT. No broker or extra fees required.';
    }

    // 0.2 Middleman / broker alert for allowance
    if ((text.contains('বিধবা') || text.contains('ভাতা')) &&
        (text.contains('দালাল') ||
            text.contains('টাকা লাগে') ||
            text.contains('ঘুষ') ||
            text.contains('ফি'))) {
      return isBn
          ? '🚫 সতর্কবার্তা: বিধবা ভাতার জন্য কোনো ফি বা দালাল লাগে না!\n\n'
              '• সমাজসেবা অধিদপ্তরের বিধবা ভাতা আবেদন সম্পূর্ণ বিনামূল্যে (০ টাকা)।\n'
              '• কোনো মধ্যস্বত্বভোগী বা দালালকে ১ টাকাও দেবেন না।\n'
              '• সরাসরি ইউনিয়ন পরিষদ বা dss.gov.bd-তে আবেদন করুন। ভাতার টাকা প্রতি মাসে সরাসরি আপনার নিজস্ব মোবাইল ব্যাংকিং (নগদ/বিকাশ) একাউন্টে আসবে।'
          : '🚫 Warning: Widow Allowance is 100% Free!\n\n'
              '• No official fee or middlemen required (0 BDT).\n'
              '• Never pay any brokers or intermediaries.\n'
              '• Apply directly via Union Parishad or dss.gov.bd. Allowance is credited directly to your mobile wallet.';
    }

    // 0.3 Youth skill training & soft loans
    if (text.contains('বেকার') ||
        text.contains('যুব') ||
        text.contains('ঋণ') ||
        text.contains('প্রশিক্ষণ')) {
      return isBn
          ? '🎓 বেকার যুবকদের জন্য সরকারি প্রশিক্ষণ ও আত্মকর্মসংস্থান ঋণ:\n\n'
              '• যুব উন্নয়ন অধিদপ্তর (dyd.gov.bd): বিনামূল্যে ৩-৬ মাসের আইটি, গবাদিপশু পালন ও কারিগরি প্রশিক্ষণ এবং ৫০,০০০ থেকে ২,০০,০০০ টাকা সহজ শর্তে ঋণ।\n'
              '• প্রবাসী কল্যাণ ব্যাংক (pkb.gov.bd): বিদেশ ফেরত ও অভিবাসীদের জন্য ২ থেকে ২০ লাখ টাকা পুনর্বাসন ঋণ।\n'
              '• এসএমই ফাউন্ডেশন: ৪% সহজ সুদে কুটির শিল্প ও ক্ষুদ্র উদ্যোক্তা ঋণ।'
          : '🎓 Government Youth Skill Training & Loans:\n\n'
              '• Department of Youth Development (dyd.gov.bd): Free 3-6 month technical training + 50k–200k BDT soft loans.\n'
              '• Probashi Kallyan Bank (pkb.gov.bd): 200k–2,000k BDT rehabilitation loan for returnee migrants.\n'
              '• SME Foundation: 4% concessional credit for small entrepreneurs.';
    }

    // 1. Passport
    if (text.contains('পাসপোর্ট') || lower.contains('passport')) {
      return isBn
          ? '🛂 ই-পাসপোর্ট আবেদনের নিয়মাবলী:\n\n'
              '• আবেদন পোর্টাল: epassport.gov.bd\n'
              '• প্রয়োজনীয় কাগজপত্র: অনলাইন জন্ম নিবন্ধন বা এনআইডি (NID), পূর্বের পাসপোর্ট (থাকলে), নাগরিক সনদ ও পেশাগত প্রমাণপত্র।\n'
              '• সরকারি ফি: সাধারণ ফি ৪৮ পাতা ৫ বছর মেয়াদে ৪,০২৫ টাকা (২১ কার্যদিবস), জরুরি ফি ৬,৩২৫ টাকা (১০ কার্যদিবস)।\n'
              '• টিপস: কোনো দালালের সাহায্য ছাড়াই অনলাইন পোর্টালে ফর্ম পূরণ করে এ-চালান (A-Challan) এর মাধ্যমে ফি জমা দেওয়া যায়।\n\n'
              '[ACTION:service:passport:পাসপোর্ট আবেদন পেজে যান]'
          : '🛂 e-Passport Application Guidelines:\n\n'
              '• Portal: epassport.gov.bd\n'
              '• Required Documents: Online verified Birth Certificate or NID, previous passport (if renewal), citizenship certificate.\n'
              '• Official Fee: Regular 48-page 5-year is 4,025 BDT (21 working days); Express is 6,325 BDT (10 working days).\n'
              '• Tips: Pay directly via A-Challan or bank without intermediaries.\n\n'
              '[ACTION:service:passport:Go to Passport Page]';
    }

    // 2. Birth Registration (BDRIS)
    if (text.contains('জন্ম নিবন্ধন') || text.contains('জন্ম') || lower.contains('birth')) {
      return isBn
          ? '👶 অনলাইন জন্ম নিবন্ধন ও সংশোধন:\n\n'
              '• আবেদন পোর্টাল: bdris.gov.bd\n'
              '• প্রয়োজনীয় তথ্য: ইপিআই কার্ড/টিকা কার্ড, হাসপাতাল ছাড়পত্র, পিতা-মাতার এনআইডি ও হোল্ডিং ট্যাক্স রশিদ।\n'
              '• সরকারি ফি: শিশুর জন্মের ৪৫ দিন পর্যন্ত বিনামূল্যে, ৫ বছর পর্যন্ত ২৫ টাকা, ৫ বছরের ঊর্ধ্বে ৫০ টাকা। সংশোধন ফি ৫০-১০০ টাকা।\n'
              '• আবেদনের পর প্রাপ্ত আবেদনপত্র ও কাগজপত্র স্থানীয় ইউনিয়ন পরিষদ বা পৌরসভা কার্যালয়ে জমা দিতে হয়।\n\n'
              '[ACTION:service:birth-registration:জন্ম নিবন্ধন পেজে যান]'
          : '👶 Online Birth Registration & Amendment:\n\n'
              '• Portal: bdris.gov.bd\n'
              '• Required: Hospital birth card/EPI card, parents\' verified NIDs, local holding tax slip.\n'
              '• Official Fee: Free within 45 days of birth, 25 BDT up to 5 years, 50 BDT above 5 years. Amendments: 50–100 BDT.\n\n'
              '[ACTION:service:birth-registration:Go to Birth Registration]';
    }

    // 3. National ID (NID)
    if (text.contains('NID') || text.contains('এনআইডি') || text.contains('পরিচয়পত্র') || lower.contains('nid')) {
      return isBn
          ? '🪪 জাতীয় পরিচয়পত্র (NID) সেবা:\n\n'
              '• অফিশিয়াল পোর্টাল: services.nidw.gov.bd\n'
              '• সেবা প্রকার: নতুন এনআইডি আবেদন, তথ্য সংশোধন (নাম, পিতা-মাতা, জন্মতারিখ) ও রি-ইস্যু।\n'
              '• প্রয়োজনীয় প্রমাণক: অনলাইন জন্ম নিবন্ধন, শিক্ষাগত সার্টিফিকেট (SSC/JSC), পাসপোর্ট বা রক্তের গ্রুপ রিপোর্ট।\n'
              '• সংশোধন ফি: "ক" ক্যাটাগরি ২৩০ টাকা, "খ" ক্যাটাগরি ৩৪৫ টাকা (বিকাশ বা রকেটের মাধ্যমে প্রদেয়)।\n\n'
              '[ACTION:service:nid-correction:NID সংশোধন পেজে যান]'
          : '🪪 National ID (NID) Services:\n\n'
              '• Official Portal: services.nidw.gov.bd\n'
              '• Services: New citizen registration, data correction, and re-issue.\n'
              '• Required Evidence: Online birth certificate, SSC certificate, blood group report.\n'
              '• Fees: Category A: 230 BDT, Category B: 345 BDT (payable via bKash/Rocket).\n\n'
              '[ACTION:service:nid-correction:Go to NID Correction]';
    }

    // 4. Social Safety Allowance (DSS)
    if (text.contains('ভাতা') || text.contains('বয়স্ক') || text.contains('বিধবা') || lower.contains('allowance')) {
      return isBn
          ? '🤝 সামাজিক নিরাপত্তা ভাতা (সমাজসেবা অধিদপ্তর):\n\n'
              '• সেবা প্রকার: বয়স্ক ভাতা (পুরুষ ৬৫+, নারী ৬২+), বিধবা ও স্বামী নিগৃহীতা ভাতা, অসচ্ছল প্রতিবন্ধী ভাতা।\n'
              '• আবেদন পদ্ধতি: dss.gov.bd বা mis.bhata.gov.bd অথবা স্থানীয় ইউনিয়ন পরিষদে সরাসরি।\n'
              '• সরকারি ফি: সম্পূর্ণ বিনামূল্যে (০ টাকা)।\n'
              '• ভাতার অর্থ: প্রতি মাসে সরাসরি নাগরিকের নগদ (Nagad) বা বিকাশ মোবাইল ওয়ালেটে জমা হয়।\n\n'
              '[ACTION:service:widow-allowance:বিধবা ভাতা সেবায় যান]'
          : '🤝 Social Safety Allowances (DSS):\n\n'
              '• Coverage: Old-age allowance (Male 65+, Female 62+), Widow allowance, Disability allowance.\n'
              '• Application: Apply at dss.gov.bd or local Union Parishad.\n'
              '• Official Fee: 100% Free (0 BDT).\n'
              '• Disbursement: Directly deposited monthly into citizen\'s mobile financial wallet (Nagad).\n\n'
              '[ACTION:service:widow-allowance:Go to Allowance Page]';
    }

    // 5. Trade License
    if (text.contains('ট্রেড লাইসেন্স') || text.contains('ব্যবসা') || lower.contains('trade')) {
      return isBn
          ? '💼 ই-ট্রেড লাইসেন্স (ব্যবসা):\n\n'
              '• আবেদন পোর্টাল: etradelicense.gov.bd অথবা সংশ্লিষ্ট সিটি কর্পোরেশন / পৌরসভা পোর্টাল।\n'
              '• প্রয়োজনীয় কাগজপত্র: ভাড়ার চুক্তিপত্র বা নিজের জায়গার হোল্ডিং ট্যাক্স রশিদ, এনআইডি ও ৩ কপি পাসপোর্ট ছবি। লিমিটেড কোম্পানির ক্ষেত্রে মেমোরেন্ডাম ও সার্টিফিকেট অব ইনকর্পোরেশন।\n'
              '• সরকারি ফি: ব্যবসার মূলধন ও ক্যাটাগরিভেদে ১,২০০ থেকে ৫,০০০ টাকা।\n\n'
              '[ACTION:service:trade-license:ট্রেড লাইসেন্স পেজে যান]'
          : '💼 e-Trade License (Business Registration):\n\n'
              '• Portal: etradelicense.gov.bd or local City Corporation portal.\n'
              '• Required: Commercial rental deed or holding tax receipt, NID, photo, TIN certificate.\n'
              '• Fee: Ranges from 1,200 to 5,000 BDT depending on business category and capital.\n\n'
              '[ACTION:service:trade-license:Go to Trade License]';
    }

    // 6. Land mutation / e-Namjari
    if (text.contains('নামজারি') || text.contains('জমি') || text.contains('খতিয়ান') || text.contains('খারিজ') || lower.contains('land') || lower.contains('mutation')) {
      return isBn
          ? '🌾 ই-নামজারি (ভূমি সেবা):\n\n'
              '• আবেদন পোর্টাল: mutation.land.gov.bd\n'
              '• প্রয়োজনীয় কাগজপত্র: মূল ক্রয় দলিল বা হেবা দলিল, পূর্ববর্তী খতিয়ান (RS/SA), দাখিলা (হালনাগাদ ভূমি উন্নয়ন কর) ও ওয়ারিশান সনদ (প্রযোজ্য ক্ষেত্রে)।\n'
              '• সরকারি মোট ফি: আবেদন ফি ২০ টাকা + নোটিশ জারি ৫০ টাকা + রেকর্ড সংশোধন ১,০০০ টাকা + ডিসিআর ১০০ টাকা = মোট ১,১৭০ টাকা।\n'
              '• নিষ্পত্তি সময়: সর্বোচ্চ ২৮ কার্যদিবস।\n\n'
              '[ACTION:service:land-mutation:নামজারি পেজে যান]'
          : '🌾 e-Namjari (Land Mutation & Records):\n\n'
              '• Portal: mutation.land.gov.bd\n'
              '• Required: Registered property deed, previous khatian, up-to-date land tax receipt.\n'
              '• Total Official Fee: Exactly 1,170 BDT (Application 20 + Notice 50 + Record 1000 + DCR 100).\n'
              '• Service Timeline: 28 working days.\n\n'
              '[ACTION:service:land-mutation:Go to Land Mutation]';
    }

    // 7. TIN Certificate / Tax
    if (text.contains('টিআইএন') || text.contains('TIN') || text.contains('ট্যাক্স') || text.contains('রিটার্ন') || lower.contains('tax') || lower.contains('tin')) {
      return isBn
          ? '📊 ই-টিআইএন ও আয়কর রিটার্ন (NBR):\n\n'
              '• ই-টিআইএন পোর্টাল: secure.incometax.gov.bd\n'
              '• ই-রিটার্ন পোর্টাল: etaxnbr.gov.bd\n'
              '• প্রয়োজনীয় কাগজপত্র: এনআইডি ও বায়োমেট্রিক সিম নম্বর।\n'
              '• সরকারি ফি: ০ টাকা (সম্পূর্ণ বিনামূল্যে তৎক্ষণাৎ ১২ ডিজিটের TIN তৈরি হয়)।\n'
              '• সময়সীমা: প্রতি অর্থবছরে ৩০ নভেম্বরের মধ্যে বার্ষিক ট্যাক্স রিটার্ন দাখিল করতে হয়।\n\n'
              '[ACTION:service:tin-certificate:ই-টিআইএন পেজে যান]'
          : '📊 e-TIN & Tax Return (NBR):\n\n'
              '• e-TIN Portal: secure.incometax.gov.bd\n'
              '• e-Return Portal: etaxnbr.gov.bd\n'
              '• Required: NID and verified registered mobile number.\n'
              '• Official Fee: 0 BDT (Free instant 12-digit e-TIN).\n'
              '• Deadline: Annual tax return deadline is November 30.\n\n'
              '[ACTION:service:tin-certificate:Go to e-TIN Page]';
    }

    // 8. BMET / Expatriate Welfare
    if (text.contains('বিএমইটি') || text.contains('প্রবাসী') || text.contains('প্রবাসী কল্যাণ') || text.contains('স্মার্ট কার্ড') || lower.contains('bmet') || lower.contains('overseas')) {
      return isBn
          ? '✈️ বিএমইটি ইমিগ্রেশন স্মার্ট কার্ড:\n\n'
              '• আবেদন প্ল্যাটফর্ম: আমি প্রবাসী (Ami Probashi) অ্যাপ বা bmet.gov.bd\n'
              '• প্রয়োজনীয় কাগজপত্র: বৈধ পাসপোর্ট, ভিসা, মেডিকেল ফিটনেস সনদ, বাধ্যতামূলক বীমা ও ৩ দিনের প্রি-ডিপার্চার ওরিয়েন্টেশন (PDO) সনদ।\n'
              '• সরকারি ফি: মোট প্রায় ৪,২০০ টাকা (কল্যাণ তহবিল, স্মার্ট কার্ড ও বীমা সহ)।'
          : '✈️ BMET Expatriate Smart Card:\n\n'
              '• Platform: Ami Probashi App or bmet.gov.bd\n'
              '• Required: Valid Passport, Employment Visa, Medical Fitness, PDO training certificate.\n'
              '• Official Fee: ~4,200 BDT (including welfare fund and insurance).';
    }

    // 9. Driving License
    if (text.contains('ড্রাইভিং') || text.contains('লাইসেন্স') || text.contains('বিআরটিএ') || lower.contains('driving') || lower.contains('brta')) {
      return isBn
          ? '🚗 ড্রাইভিং লাইসেন্স (BRTA):\n\n'
              '• আবেদন পোর্টাল: bsp.brta.gov.bd\n'
              '• ধাপসমূহ: ১. লার্নার লাইসেন্স গ্রহণ ২. ডোপ টেস্ট ও মেডিকেল সনদ ৩. লিখিত, মৌখিক ও প্র্যাকটিক্যাল পরীক্ষা ৪. স্মার্ট কার্ড লাইসেন্স ডেলিভারি।\n'
              '• ফি: পেশাদার প্রায় ২,৫৪০ টাকা, অপেশাদার প্রায় ৩,৯৪০ টাকা।'
          : '🚗 Driving License (BRTA):\n\n'
              '• Portal: bsp.brta.gov.bd\n'
              '• Steps: 1. Learner License 2. Dope Test & Medical 3. Exam 4. Biometrics.\n'
              '• Fee: Professional ~2,540 BDT, Non-Professional ~3,940 BDT.';
    }

    // 10. General / Greeting / Fallback
    return isBn
        ? 'আসসালামু আলাইকুম! দিশারীর "জনবন্ধু AI" আপনার সেবায় প্রস্তুত।\n\n'
            'আমি পাসপোর্ট, এনআইডি সংশোধন, ডিজিটাল জন্ম নিবন্ধন, নামজারি, ট্রেড লাইসেন্স, বয়স্ক/বিধবা ভাতা, ট্যাক্স এবং বিএমইটি সেবা সংক্রান্ত যেকোনো তথ্য দিতে পারি।\n\n'
            'আপনার কাঙ্ক্ষিত সরকারি সেবার নামটি লিখুন (যেমন: "পাসপোর্ট করতে কী লাগে?") অথবা জরুরি নাগরিক সহায়তায় সরকারি ৩৩৩ হটলাইনে যোগাযোগ করুন।'
        : 'Welcome! I am Dishari\'s "Jonobondhu AI" Civic Assistant.\n\n'
            'I can provide official guidelines on e-Passport, NID correction, Birth Registration, Land e-Namjari, Trade License, Allowances, and Taxes in Bangladesh.\n\n'
            'Ask me your query (e.g. "What documents are required for passport?") or call government hotline 333 for emergency support.';
  }
}

