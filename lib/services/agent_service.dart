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
''';

  static const String _systemPromptEn = '''
You are 'Jonobondhu AI' (জনবন্ধু AI), the civic service assistant for Dishari (দিশারী) in Bangladesh.
Your mission is to assist citizens with accurate, official information regarding Bangladesh government services (such as e-Passport, National ID / NID correction, Birth Registration, e-Namjari land records, e-Trade license, social allowances, e-TIN, driving license, BMET expatriate card, etc.).

Guidelines:
1. Provide concise, clear, polite, and step-by-step guidance.
2. Include official government fees (in BDT), required documents, official government portals (.gov.bd), and expected processing timelines where relevant.
3. Help citizens avoid unauthorized middlemen and empower them to complete applications transparently.
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

    // 1. Passport
    if (text.contains('পাসপোর্ট') || lower.contains('passport')) {
      return isBn
          ? '🛂 ই-পাসপোর্ট আবেদনের নিয়মাবলী:\n\n'
              '• আবেদন পোর্টাল: epassport.gov.bd\n'
              '• প্রয়োজনীয় কাগজপত্র: অনলাইন জন্ম নিবন্ধন বা এনআইডি (NID), পূর্বের পাসপোর্ট (থাকলে), নাগরিক সনদ ও পেশাগত প্রমাণপত্র।\n'
              '• সরকারি ফি: সাধারণ ফি ৪৮ পাতা ৫ বছর মেয়াদে ৪,০২৫ টাকা (২১ কার্যদিবস), জরুরি ফি ৬,৩২৫ টাকা (১০ কার্যদিবস)।\n'
              '• টিপস: কোনো দালালের সাহায্য ছাড়াই অনলাইন পোর্টালে ফর্ম পূরণ করে এ-চালান (A-Challan) এর মাধ্যমে ফি জমা দেওয়া যায়।'
          : '🛂 e-Passport Application Guidelines:\n\n'
              '• Portal: epassport.gov.bd\n'
              '• Required Documents: Online verified Birth Certificate or NID, previous passport (if renewal), citizenship certificate.\n'
              '• Official Fee: Regular 48-page 5-year is 4,025 BDT (21 working days); Express is 6,325 BDT (10 working days).\n'
              '• Tips: Pay directly via A-Challan or bank without intermediaries.';
    }

    // 2. Birth Registration (BDRIS)
    if (text.contains('জন্ম নিবন্ধন') || text.contains('জন্ম') || lower.contains('birth')) {
      return isBn
          ? '👶 অনলাইন জন্ম নিবন্ধন ও সংশোধন:\n\n'
              '• আবেদন পোর্টাল: bdris.gov.bd\n'
              '• প্রয়োজনীয় তথ্য: ইপিআই কার্ড/টিকা কার্ড, হাসপাতাল ছাড়পত্র, পিতা-মাতার এনআইডি ও হোল্ডিং ট্যাক্স রশিদ।\n'
              '• সরকারি ফি: শিশুর জন্মের ৪৫ দিন পর্যন্ত বিনামূল্যে, ৫ বছর পর্যন্ত ২৫ টাকা, ৫ বছরের ঊর্ধ্বে ৫০ টাকা। সংশোধন ফি ৫০-১০০ টাকা।\n'
              '• আবেদনের পর প্রাপ্ত আবেদনপত্র ও কাগজপত্র স্থানীয় ইউনিয়ন পরিষদ বা পৌরসভা কার্যালয়ে জমা দিতে হয়।'
          : '👶 Online Birth Registration & Amendment:\n\n'
              '• Portal: bdris.gov.bd\n'
              '• Required: Hospital birth card/EPI card, parents\' verified NIDs, local holding tax slip.\n'
              '• Official Fee: Free within 45 days of birth, 25 BDT up to 5 years, 50 BDT above 5 years. Amendments: 50–100 BDT.';
    }

    // 3. National ID (NID)
    if (text.contains('NID') || text.contains('এনআইডি') || text.contains('পরিচয়পত্র') || lower.contains('nid')) {
      return isBn
          ? '🪪 জাতীয় পরিচয়পত্র (NID) সেবা:\n\n'
              '• অফিশিয়াল পোর্টাল: services.nidw.gov.bd\n'
              '• সেবা প্রকার: নতুন এনআইডি আবেদন, তথ্য সংশোধন (নাম, পিতা-মাতা, জন্মতারিখ) ও রি-ইস্যু।\n'
              '• প্রয়োজনীয় প্রমাণক: অনলাইন জন্ম নিবন্ধন, শিক্ষাগত সার্টিফিকেট (SSC/JSC), পাসপোর্ট বা রক্তের গ্রুপ রিপোর্ট।\n'
              '• সংশোধন ফি: "ক" ক্যাটাগরি ২৩০ টাকা, "খ" ক্যাটাগরি ৩৪৫ টাকা (বিকাশ বা রকেটের মাধ্যমে প্রদেয়)।'
          : '🪪 National ID (NID) Services:\n\n'
              '• Official Portal: services.nidw.gov.bd\n'
              '• Services: New citizen registration, data correction, and re-issue.\n'
              '• Required Evidence: Online birth certificate, SSC certificate, blood group report.\n'
              '• Fees: Category A: 230 BDT, Category B: 345 BDT (payable via bKash/Rocket).';
    }

    // 4. Social Safety Allowance (DSS)
    if (text.contains('ভাতা') || text.contains('বয়স্ক') || text.contains('বিধবা') || lower.contains('allowance')) {
      return isBn
          ? '🤝 সামাজিক নিরাপত্তা ভাতা (সমাজসেবা অধিদপ্তর):\n\n'
              '• সেবা প্রকার: বয়স্ক ভাতা (পুরুষ ৬৫+, নারী ৬২+), বিধবা ও স্বামী নিগৃহীতা ভাতা, অসচ্ছল প্রতিবন্ধী ভাতা।\n'
              '• আবেদন পদ্ধতি: dss.gov.bd বা mis.bhata.gov.bd অথবা স্থানীয় ইউনিয়ন পরিষদে সরাসরি।\n'
              '• সরকারি ফি: সম্পূর্ণ বিনামূল্যে (০ টাকা)।\n'
              '• ভাতার অর্থ: প্রতি মাসে সরাসরি নাগরিকের নগদ (Nagad) বা বিকাশ মোবাইল ওয়ালেটে জমা হয়।'
          : '🤝 Social Safety Allowances (DSS):\n\n'
              '• Coverage: Old-age allowance (Male 65+, Female 62+), Widow allowance, Disability allowance.\n'
              '• Application: Apply at dss.gov.bd or local Union Parishad.\n'
              '• Official Fee: 100% Free (0 BDT).\n'
              '• Disbursement: Directly deposited monthly into citizen\'s mobile financial wallet (Nagad).';
    }

    // 5. Trade License
    if (text.contains('ট্রেড লাইসেন্স') || text.contains('ব্যবসা') || lower.contains('trade')) {
      return isBn
          ? '💼 ই-ট্রেড লাইসেন্স (ব্যবসা):\n\n'
              '• আবেদন পোর্টাল: etradelicense.gov.bd অথবা সংশ্লিষ্ট সিটি কর্পোরেশন / পৌরসভা পোর্টাল।\n'
              '• প্রয়োজনীয় কাগজপত্র: ভাড়ার চুক্তিপত্র বা নিজের জায়গার হোল্ডিং ট্যাক্স রশিদ, এনআইডি ও ৩ কপি পাসপোর্ট ছবি। লিমিটেড কোম্পানির ক্ষেত্রে মেমোরেন্ডাম ও সার্টিফিকেট অব ইনকর্পোরেশন।\n'
              '• সরকারি ফি: ব্যবসার মূলধন ও ক্যাটাগরিভেদে ১,২০০ থেকে ৫,০০০ টাকা।'
          : '💼 e-Trade License (Business Registration):\n\n'
              '• Portal: etradelicense.gov.bd or local City Corporation portal.\n'
              '• Required: Commercial rental deed or holding tax receipt, NID, photo, TIN certificate.\n'
              '• Fee: Ranges from 1,200 to 5,000 BDT depending on business category and capital.';
    }

    // 6. Land mutation / e-Namjari
    if (text.contains('নামজারি') || text.contains('জমি') || text.contains('খতিয়ান') || text.contains('খারিজ') || lower.contains('land') || lower.contains('mutation')) {
      return isBn
          ? '🌾 ই-নামজারি (ভূমি সেবা):\n\n'
              '• আবেদন পোর্টাল: mutation.land.gov.bd\n'
              '• প্রয়োজনীয় কাগজপত্র: মূল ক্রয় দলিল বা হেবা দলিল, পূর্ববর্তী খতিয়ান (RS/SA), দাখিলা (হালনাগাদ ভূমি উন্নয়ন কর) ও ওয়ারিশান সনদ (প্রযোজ্য ক্ষেত্রে)।\n'
              '• সরকারি মোট ফি: আবেদন ফি ২০ টাকা + নোটিশ জারি ৫০ টাকা + রেকর্ড সংশোধন ১,০০০ টাকা + ডিসিআর ১০০ টাকা = মোট ১,১৭০ টাকা।\n'
              '• নিষ্পত্তি সময়: সর্বোচ্চ ২৮ কার্যদিবস।'
          : '🌾 e-Namjari (Land Mutation & Records):\n\n'
              '• Portal: mutation.land.gov.bd\n'
              '• Required: Registered property deed, previous khatian, up-to-date land tax receipt.\n'
              '• Total Official Fee: Exactly 1,170 BDT (Application 20 + Notice 50 + Record 1000 + DCR 100).\n'
              '• Service Timeline: 28 working days.';
    }

    // 7. TIN Certificate / Tax
    if (text.contains('টিআইএন') || text.contains('TIN') || text.contains('ট্যাক্স') || text.contains('রিটার্ন') || lower.contains('tax') || lower.contains('tin')) {
      return isBn
          ? '📊 ই-টিআইএন ও আয়কর রিটার্ন (NBR):\n\n'
              '• ই-টিআইএন পোর্টাল: secure.incometax.gov.bd\n'
              '• ই-রিটার্ন পোর্টাল: etaxnbr.gov.bd\n'
              '• প্রয়োজনীয় কাগজপত্র: এনআইডি ও বায়োমেট্রিক সিম নম্বর।\n'
              '• সরকারি ফি: ০ টাকা (সম্পূর্ণ বিনামূল্যে তৎক্ষণাৎ ১২ ডিজিটের TIN তৈরি হয়)।\n'
              '• সময়সীমা: প্রতি অর্থবছরে ৩০ নভেম্বরের মধ্যে বার্ষিক ট্যাক্স রিটার্ন দাখিল করতে হয়।'
          : '📊 e-TIN & Tax Return (NBR):\n\n'
              '• e-TIN Portal: secure.incometax.gov.bd\n'
              '• e-Return Portal: etaxnbr.gov.bd\n'
              '• Required: NID and verified registered mobile number.\n'
              '• Official Fee: 0 BDT (Free instant 12-digit e-TIN).\n'
              '• Deadline: Annual tax return deadline is November 30.';
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

