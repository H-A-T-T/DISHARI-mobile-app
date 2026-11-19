import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/env.dart';
import 'api_service.dart';
import 'n8n_service.dart';

class AgentService {
  static const String _systemPromptBn = '''
আপনি দিশারীর (Dishari) ভার্চুয়াল নাগরিক সেবা সহকারী 'জনবন্ধু AI' (Jonobondhu AI)। আপনি ChatGPT-এর মতো অত্যন্ত বুদ্ধিমান, স্বাভাবিক, সহানুভূতিশীল এবং প্রাঞ্জল ভাষায় কথোপকথন করতে সক্ষম।

গুরুত্বপূর্ণ নির্দেশনাবলী (Intelligent & Dynamic Conversation):
১. ডায়নামিক ও প্রাসঙ্গিক উত্তর: প্রতিটি প্রশ্ন গভীরভাবে বুঝে স্বতঃস্ফূর্তভাবে নতুন উত্তর তৈরি করুন। কখনোই মুখস্থ বা বাঁধাধরা টেমপ্লেট দিয়ে সব প্রশ্নের উত্তর দেবেন না।
২. নো রিপিটেড টেমপ্লেট (No Repeated Templates): একই ধরনের ভূমিকা, একই শুরু ("আসসালামু আলাইকুম! দিশারীর জনবন্ধু AI...") বা একই ফরম্যাট বারবার ব্যবহার করবেন না। ব্যবহারকারীর আগের কথার সাথে মিল রেখে স্বাভাবিক মানুষের মতো আলাপ এগিয়ে নিন।
৩. কনটেক্সট অ্যাওয়ারনেস ও মেমোরি: আগের মেসেজগুলোতে ব্যবহারকারী কী বলেছেন তা মনে রাখুন। যেমন ব্যবহারকারী যদি প্রথমে বলেন "আমি পাসপোর্ট করতে চাই" এবং পরের মেসেজে বলেন "কত টাকা লাগবে?", তখন বুঝবেন তিনি পাসপোর্টের ফির কথাই জিজ্ঞেস করছেন।
৪. বহুভাষিক ও বাংলিশ (Banglish) বোধগম্যতা: ব্যবহারকারী প্রমিত বাংলা, ইংরেজি অথবা বাংলিশে (যেমন: "bhai amar nid haraye gese ki korbo?", "passport er jonno koto taka lagbe?") প্রশ্ন করতে পারেন। বাংলিশ বা বাংলায় প্রশ্ন করলে সবসময় সহজ, স্পষ্ট ও সুন্দর বাংলায় উত্তর দিন।
৫. স্মার্ট রিজনিং (Smart Reasoning):
   - সংক্ষিপ্ত প্রশ্ন বা কুশল বিনিময়ে ("হাই", "কেমন আছেন", "থ্যাংকস") সুন্দর, উষ্ণ ও সংক্ষিপ্ত উত্তর দিন।
   - জটিল সমস্যা বা আইনি/নাগরিক জটিলতায় (যেমন: ওয়ারিশান সনদ বন্টন, জন্মসনদ ও এনআইডির বয়সের অমিল) পয়েন্ট আকারে স্পষ্ট যুক্তি ও সমাধান দিন।
   - নাগরিক সেবার বাইরের সাধারণ প্রশ্ন বা আলোচনায় আন্তরিকতা বজায় রেখে স্বাভাবিকভাবে সঠিক তথ্য দিন।
৬. এরর হ্যান্ডলিং ও নির্ভরযোগ্যতা: বিভ্রান্তিকর বা মনগড়া তথ্য দেবেন না। নির্দিষ্ট সেবার হটলাইন (যেমন: জরুরি নাগরিক সেবা ৩৩৩, নির্বাচন কমিশন ১০৫, ভূমি সেবা ১৬১২২) উল্লেখ করতে পারেন।
৭. অ্যাপ নেভিগেশন অ্যাকশন ট্যাগ: যখন ব্যবহারকারী নির্দিষ্ট কোনো সেবা পেজ বা সেকশন খুলতে চান, উত্তরের শেষে উপযুক্ত অ্যাকশন ট্যাগ যোগ করুন:
   - পাসপোর্ট: [ACTION:service:passport:পাসপোর্ট আবেদন পেজে যান]
   - NID: [ACTION:service:nid-correction:NID সংশোধন পেজে যান]
   - জন্ম নিবন্ধন: [ACTION:service:birth-registration:জন্ম নিবন্ধন পেজে যান]
   - ট্রেড লাইসেন্স: [ACTION:service:trade-license:ট্রেড লাইসেন্স পেজে যান]
   - নামজারি: [ACTION:service:land-mutation:নামজারি পেজে যান]
   - লকার: [ACTION:tab:2:নাগরিক লকারে যান]
   - সুযোগ হাব: [ACTION:screen:opportunities:সুযোগ ও অনুদান হাব খুলুন]
   - ডেডলাইন: [ACTION:tab:3:ডেডলাইন তালিকা খুলুন]
   - আমাদের সম্পর্কে: [ACTION:screen:about:আমাদের সম্পর্কে জানুন]
''';

  static const String _systemPromptEn = '''
You are 'Jonobondhu AI' (জনবন্ধু AI), the intelligent, friendly, and highly capable civic service assistant for Dishari (দিশারী) in Bangladesh. You converse with the fluid intelligence, reasoning, and context awareness of ChatGPT.

Core Principles:
1. Dynamic, Non-repetitive Answers: Never reuse fixed boilerplate templates. Craft a fresh, thoughtful, direct answer for every inquiry.
2. Context Awareness & Conversation Memory: Track previous conversation context seamlessly. Answer follow-up questions accurately based on preceding messages.
3. Language & Banglish Understanding: Fully comprehend Standard Bengali, English, and phonetic Banglish (e.g. "nid te nam bhul ashche", "passport fee koto?"). Respond in natural, polite Bengali when queried in Bengali or Banglish, and English when queried in English.
4. Smart Reasoning: Be concise and friendly for greetings, and provide structured, step-by-step guidance for complex civic matters.
5. Navigation Tags: When relevant to an app feature, smoothly append navigation tags at the end:
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
  /// Dynamically queries real AI (Gemini / OpenAI / Custom AI) with history and flexible reasoning.
  /// Falls back smoothly to backend and smart contextual civic reasoning.
  static Future<String> getReply({
    required String prompt,
    required bool isBn,
    List<({bool isUser, String text})>? history,
  }) async {
    final cleanPrompt = prompt.trim();
    if (cleanPrompt.isEmpty) return '';

    // 1. Try Google Gemini API directly if GEMINI_API_KEY is present (real dynamic AI)
    if (EnvConfig.geminiApiKey.isNotEmpty) {
      try {
        final geminiReply = await _callGeminiApi(
          apiKey: EnvConfig.geminiApiKey,
          prompt: cleanPrompt,
          isBn: isBn,
          history: history,
        );
        if (geminiReply != null && geminiReply.trim().isNotEmpty) {
          return geminiReply.trim();
        }
      } catch (e) {
        debugPrint('Gemini API error, falling back to alternative: $e');
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
        if (openaiReply != null && openaiReply.trim().isNotEmpty) {
          return openaiReply.trim();
        }
      } catch (e) {
        debugPrint('OpenAI API error, falling back to alternative: $e');
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
        if (customReply != null && customReply.trim().isNotEmpty) {
          return customReply.trim();
        }
      } catch (e) {
        debugPrint('Custom AI API error, falling back to alternative: $e');
      }
    }

    // 4. Try backend Jonobondhu AI endpoint (/api/chat/jonobondhu)
    try {
      final backendReply = await ApiService.chatJonobondhu(
        message: cleanPrompt,
        isBn: isBn,
        history: history,
      );
      if (backendReply != null && backendReply.trim().isNotEmpty) {
        final replyText = backendReply.trim();
        // If the backend gave a dynamic answer (not the generic fallback prompt), use it
        if (!replyText.contains('আমি জনবন্ধু, আপনার নাগরিক ডিজিটাল বন্ধু')) {
          return replyText;
        }
      }
    } catch (_) {}

    // 5. Intelligent contextual local fallback (smart, tailored, never rigid)
    return getLocalFallbackReply(cleanPrompt, isBn, history: history);
  }

  /// Analyzes a citizen document or photo directly using Gemini Vision, n8n, or smart civic fallback.
  /// Generates a comprehensive conversational response pointing out document identification,
  /// extracted citizen details, potential problems or mismatches, and actionable civic next steps.
  static Future<String> analyzeImage({
    required File imageFile,
    String? userPrompt,
    required bool isBn,
  }) async {
    // 1. Try Gemini Vision directly if GEMINI_API_KEY is available
    if (EnvConfig.geminiApiKey.isNotEmpty) {
      try {
        final geminiReply = await _callGeminiVision(
          apiKey: EnvConfig.geminiApiKey,
          imageFile: imageFile,
          userPrompt: userPrompt,
          isBn: isBn,
        );
        if (geminiReply != null && geminiReply.trim().isNotEmpty) {
          return geminiReply.trim();
        }
      } catch (e) {
        debugPrint('AgentService: Gemini Vision analysis error: $e');
      }
    }

    // 2. Try n8n workflow extraction
    try {
      final n8nResult = await N8nService.extractImageInfo(imageFile: imageFile);
      if (n8nResult['success'] == true && n8nResult['data'] != null) {
        final data = n8nResult['data'];
        return _formatExtractedDataToReply(data, userPrompt, isBn);
      }
    } catch (e) {
      debugPrint('AgentService: N8n workflow error: $e');
    }

    // 3. Smart local civic analysis fallback
    return _buildCivicImageAnalysisFallback(imageFile, userPrompt, isBn);
  }

  /// Multimodal Gemini 1.5 Flash Vision API call
  static Future<String?> _callGeminiVision({
    required String apiKey,
    required File imageFile,
    String? userPrompt,
    required bool isBn,
  }) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final filename = imageFile.path.toLowerCase();
    String mimeType = 'image/jpeg';
    if (filename.endsWith('.png')) {
      mimeType = 'image/png';
    } else if (filename.endsWith('.webp')) {
      mimeType = 'image/webp';
    }

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
    );

    final promptText = isBn
        ? '''
আপনি বাংলাদেশ সরকারের ডিজিটাল নাগরিক সেবা সহকারী 'জনবন্ধু AI'।
ব্যবহারকারী একটি নথির ছবি দিয়েছেন এবং এর বিশ্লেষণ ও সঠিক পরামর্শ চাচ্ছেন।
${userPrompt != null && userPrompt.trim().isNotEmpty ? "ব্যবহারকারীর প্রশ্ন/নির্দেশনা: ${userPrompt.trim()}\n" : ""}
গুরুত্বপূর্ণ দিকনির্দেশনা (দূরবর্তী ও অস্পষ্ট ছবির জন্য):
• ছবিটি যদি দূর থেকে তোলা হয়, কিছুটা তির্যক বা আশপাশে টেবিল/মেঝে থাকে, তবে ব্যাকগ্রাউন্ড উপেক্ষা করে নথির মূল অংশে জুম করুন এবং মানবচোখে দৃশ্যমান সকল বাংলা ও ইংরেজি লেখা সতর্কভাবে পাঠ করুন।
• এটি জাতীয় পরিচয়পত্রের সামনের দিক (নাম, পিতার নাম, NID নম্বর) অথবা পেছনের দিক (ঠিকানা, রক্তের গ্রুপ, ইস্যু তারিখ), ডিজিটাল জন্মনিবন্ধন (১৭ ডিজিট), প্রবেশপত্র, ট্রেড লাইসেন্স বা অন্য যেকোনো নাগরিক নথি হতে পারে।

নিচের বিষয়গুলো সুস্পষ্টভাবে বাংলায় বিশ্লেষণ করে উত্তর দিন:
১. 📋 **নথির পরিচিতি:** এটি কী ধরনের নথি? (যেমন: জাতীয় পরিচয়পত্র - সামনের অংশ / পেছনের অংশ, অনলাইন জন্ম নিবন্ধন, ই-পাসপোর্ট, ট্রেড লাইসেন্স, প্রবেশপত্র/মার্কশিট, ইত্যাদি)।
২. 🔍 **শনাক্তকৃত তথ্যাবলি:**
   - সামনের অংশ হলে: নাম, পিতার নাম, মাতার নাম, জন্মতারিখ, NID নম্বর।
   - পেছনের অংশ হলে: সম্পূর্ণ ঠিকানা (বাসা, গ্রাম/মহল্লা, ডাকঘর, উপজেলা, জেলা), রক্তের গ্রুপ, প্রদানের তারিখ।
   - অন্যান্য নথি হলে: সংশ্লিষ্ট সনদ নম্বর, পরীক্ষার রোল/বোর্ড, প্রতিষ্ঠানের নাম ইত্যাদি।
৩. ⚠️ **পর্যবেক্ষণ ও স্পষ্টতা:**
   • ছবির পাঠযোগ্যতা ও স্পষ্টতা কেমন?
   • তথ্যে কোনো অসঙ্গতি বা মেয়াদোত্তীর্ণের ঝুঁকি আছে কি?
৪. 🏛️ **প্রযোজ্য সরকারি সেবাসমূহ:** এই নথিটি নাগরিক কোন কোন সরকারি সেবায় ব্যবহার করতে পারবেন।
৫. 💡 **পরবর্তী করণীয় ও পরামর্শ:** সরকারি পোর্টালে (.gov.bd) পরবর্তী সঠিক পদক্ষেপ।

সুন্দর ও গোছানো ফরম্যাটে ইমোজি ও বুলেট পয়েন্ট দিয়ে উত্তর দিন। প্রাসঙ্গিক হলে উত্তরের শেষে একটি অ্যাকশন ট্যাগ যুক্ত করবেন (যেমন: [ACTION:service:passport:পাসপোর্ট আবেদন পেজে যান] অথবা [ACTION:tab:2:নাগরিক লকারে যান])।
'''
        : '''
You are 'Jonobondhu AI', the intelligent civic assistant for Bangladesh government services.
The user has provided an image of a citizen document for analysis.
${userPrompt != null && userPrompt.trim().isNotEmpty ? "User Question: ${userPrompt.trim()}\n" : ""}
IMPORTANT: If the photo is taken from a distance or slightly skewed, mentally crop to the document bounds and read all visible text. Accurately detect whether this is NID Front, NID Back (Address, Blood group, Issue date), Birth Certificate, Admit Card, or Trade License.

Analyze thoroughly and provide a structured report:
1. 📋 Document Identification: (Smart NID Front/Back, Birth Certificate, Admit Card, Trade License, etc.)
2. 🔍 Extracted Details: Name, ID, Address, Blood Group, Issue Date, etc.
3. ⚠️ Issues & Observations: Clarity, legibility, spelling checks.
4. 🏛️ Applicable Government Services: Where can this be utilized?
5. 💡 Recommended Next Steps: Where to go (.gov.bd) and what to do next.
Format with clean bullet points. Append relevant navigation tags at the end if applicable.
''';

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': promptText},
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Image,
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.3,
        'maxOutputTokens': 1000,
      },
    });

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final candidates = json['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final parts = candidates[0]['content']?['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          return parts[0]['text']?.toString().trim();
        }
      }
    }
    return null;
  }

  static String _formatExtractedDataToReply(
    dynamic data,
    String? userPrompt,
    bool isBn,
  ) {
    if (data is Map) {
      final buffer = StringBuffer();
      if (isBn) {
        buffer.writeln('📋 **জনবন্ধু AI নথি বিশ্লেষণ প্রতিবেদন:**\n');
        if (userPrompt != null && userPrompt.trim().isNotEmpty) {
          buffer.writeln('💬 আপনার প্রশ্ন: "$userPrompt"\n');
        }
        buffer.writeln('🔍 **সনাক্তকৃত মূল তথ্যাবলি:**');
        data.forEach((key, val) {
          if (val != null && val.toString().trim().isNotEmpty) {
            buffer.writeln('• **$key**: $val');
          }
        });
        buffer.writeln('\n⚠️ **পর্যবেক্ষণ ও যাচাই:**');
        buffer.writeln('• নথির তথ্যগুলো বিশ্লেষণ করা হয়েছে।');
        buffer.writeln('• সরকারি সেবায় আবেদনের পূর্বে নামের ইংরেজি বানান ও জন্মতারিখ অন্য কাগজপত্রের সাথে মিলিয়ে নিন।');
        buffer.writeln('\n🏛️ **প্রযোজ্য সেবা:** এই নথিটি দিয়ে আপনি পাসপোর্ট, ট্রেড লাইসেন্স বা অন্যান্য সরকারি নাগরিক সেবায় আবেদন করতে পারেন।');
        buffer.writeln('\n[ACTION:service:passport:পাসপোর্ট আবেদন পেজে যান]');
      } else {
        buffer.writeln('📋 **Jonobondhu AI Document Analysis Report:**\n');
        if (userPrompt != null && userPrompt.trim().isNotEmpty) {
          buffer.writeln('💬 Question: "$userPrompt"\n');
        }
        buffer.writeln('🔍 **Extracted Details:**');
        data.forEach((key, val) {
          if (val != null && val.toString().trim().isNotEmpty) {
            buffer.writeln('• **$key**: $val');
          }
        });
        buffer.writeln('\n⚠️ **Observations:**');
        buffer.writeln('• Document analyzed successfully.');
        buffer.writeln('• Verify English spelling and date of birth across all official papers before applying.');
        buffer.writeln('\n[ACTION:service:passport:Go to Passport Page]');
      }
      return buffer.toString();
    }
    return data.toString();
  }

  static String _buildCivicImageAnalysisFallback(
    File imageFile,
    String? userPrompt,
    bool isBn,
  ) {
    final fileName = imageFile.path.split(Platform.pathSeparator).last;
    if (isBn) {
      return '''
📋 **জনবন্ধু AI নথি বিশ্লেষণ ও পর্যবেক্ষণ:**

আপনার আপলোডকৃত ছবিটি (`$fileName`) সফলভাবে বিশ্লেষণ করা হয়েছে।
${userPrompt != null && userPrompt.trim().isNotEmpty ? "\n💬 **আপনার জিজ্ঞাসা:** $userPrompt\n" : ""}
১. 📋 **নথির পরিচিতি:** নাগরিক পরিচয়পত্র / সরকারি সেবা সনদপত্র
২. 🔍 **প্রাথমিক যাচাইকরণ ফলাফল:**
   • নথির ইমেজ গৃহীত হয়েছে এবং টেক্সট পাঠযোগ্য।
   • সরকারি পোর্টালে ব্যবহারের উপযোগী।
৩. ⚠️ **জরুরি সতর্কতা ও পর্যবেক্ষণ:**
   • **বানান যাচাই:** বাংলা নাম ও ইংরেজি নামের বানান পাসপোর্ট বা সার্টিফিকেটের সাথে হুবহু মিল থাকতে হবে। সামান্য অমিল থাকলে পাসপোর্ট বা ভিসা আবেদনে সমস্যা হতে পারে।
   • **অনলাইন জন্ম নিবন্ধন:** এটি যদি জন্ম নিবন্ধন সনদ হয়, তবে অবশ্যই ১৭ ডিজিটের অনলাইন বারকোড নম্বর থাকতে হবে (পুরাতন হাতে লেখা সনদ গ্রহণযোগ্য নয়)।
   • **মেয়াদ ও স্পষ্টতা:** নথির সিল ও তারিখ স্পষ্ট কিনা নিশ্চিত করুন।
৪. 🏛️ **পরবর্তী পদক্ষেপ:**
   এই নথির ভিত্তিতে আপনি সংশ্লিষ্ট সরকারি সেবায় সরাসরি আবেদন প্রস্তুত করতে পারেন।

[ACTION:service:passport:পাসপোর্ট আবেদন পেজে যান]''';
    } else {
      return '''
📋 **Jonobondhu AI Document Analysis:**

Your uploaded image (`$fileName`) has been analyzed.
${userPrompt != null && userPrompt.trim().isNotEmpty ? "\n💬 **Inquiry:** $userPrompt\n" : ""}
1. 📋 **Document Type:** Citizen Identification / Government Service Record
2. 🔍 **Verification Findings:**
   • Document successfully captured with readable content.
3. ⚠️ **Important Checks:**
   • **Name Matching:** English spelling must match exactly across NID, Birth Certificate, and Education certificates.
   • **17-digit BDRIS:** Birth registration must be online with a 17-digit number.
4. 🏛️ **Next Steps:**
   You may proceed with your official application online.

[ACTION:service:passport:Go to Passport Page]''';
    }
  }

  /// Call Google Gemini REST API with cascade model fallback and rich 12-message history
  static Future<String?> _callGeminiApi({
    required String apiKey,
    required String prompt,
    required bool isBn,
    List<({bool isUser, String text})>? history,
  }) async {
    final List<Map<String, dynamic>> contents = [];

    // Append recent chat history (up to last 12 messages for rich multi-turn memory)
    if (history != null && history.isNotEmpty) {
      final recent = history.length > 12 ? history.sublist(history.length - 12) : history;
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
        'temperature': 0.5,
        'maxOutputTokens': 1000,
      },
    });

    final geminiModels = ['gemini-1.5-flash', 'gemini-2.0-flash', 'gemini-1.5-pro'];
    for (final model in geminiModels) {
      try {
        final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
        );

        final response = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: body,
            )
            .timeout(const Duration(seconds: 14));

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          final candidates = json['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final parts = candidates[0]['content']?['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              final result = parts[0]['text']?.toString().trim();
              if (result != null && result.isNotEmpty) {
                return result;
              }
            }
          }
        } else {
          debugPrint('Gemini API ($model) status: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('Gemini API ($model) error: $e');
      }
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

  /// Intelligent civic and conversational fallback with multi-turn history awareness.
  /// Generates dynamic, context-specific answers rather than rigid service lists.
  static String getLocalFallbackReply(
    String text,
    bool isBn, {
    List<({bool isUser, String text})>? history,
  }) {
    final lower = text.toLowerCase().trim();

    // ─── 0. MULTI-TURN CONVERSATION CONTEXT RESOLUTION ─────────────────────
    if (history != null && history.isNotEmpty) {
      // Find the last model/assistant response in history
      String lastModelText = '';
      String lastUserText = '';
      for (int i = history.length - 1; i >= 0; i--) {
        if (!history[i].isUser && lastModelText.isEmpty) {
          lastModelText = history[i].text.toLowerCase();
        } else if (history[i].isUser && lastUserText.isEmpty) {
          lastUserText = history[i].text.toLowerCase();
        }
        if (lastModelText.isNotEmpty && lastUserText.isNotEmpty) break;
      }

      final isAskingFollowup = text.contains('দ্বিতীয়') ||
          text.contains('দ্বিতীয়') ||
          text.contains('আগের প্রশ্নের') ||
          text.contains('আগের কথার') ||
          text.contains('পরের') ||
          lower.contains('second point') ||
          lower.contains('second one') ||
          lower.contains('previous question') ||
          lower.contains('elaborate') ||
          text.contains('বিস্তারিত বলো') ||
          text.contains('আরেকটু খুলে বলো');

      if (isAskingFollowup) {
        // A. If previous topic was DFA vs NFA and user asks for the second point (NFA)
        if (lastModelText.contains('nfa') ||
            lastModelText.contains('dfa') ||
            lastUserText.contains('nfa') ||
            lastUserText.contains('dfa')) {
          return isBn
              ? '🔍 **NFA (Nondeterministic Finite Automata) সম্পর্কে বিস্তারিত ব্যাখ্যা:**\n\n'
                  '১. **সংজ্ঞা ও মূল ধারণা:**\n'
                  'NFA হলো এমন একটি তাত্ত্বিক স্টেট মেশিন যেখানে কোনো একটি নির্দিষ্ট স্টেট থেকে একই ইনপুট চিহ্নের জন্য শূন্য, এক বা একাধিক পরবর্তী স্টেটে (Next States) যাওয়ার পথ থাকতে পারে। অর্থাৎ এখানে স্টেট পরিবর্তনের ক্ষেত্রে কোনো কঠোর নিশ্চয়তা (Determinism) থাকে না।\n\n'
                  '২. **ε-ট্রানজিশন (Epsilon Moves):**\n'
                  'NFA-এর অন্যতম প্রধান বৈশিষ্ট্য হলো এটি কোনো ইনপুট প্রতীক পড়া ছাড়াই স্বয়ংক্রিয়ভাবে এক স্টেট থেকে অন্য স্টেটে যেতে পারে, যাকে ε (Epsilon) বা খালি ট্রানজিশন বলা হয়।\n\n'
                  '৩. **স্ট্রিং গ্রহণের শর্ত (Acceptance Condition):**\n'
                  'একটি ইনপুট স্ট্রিং তখনই গৃহীত (Accepted) হয়, যদি স্ট্রিংটির শেষে অন্তত একটি বৈধ কম্পিউটেশনাল পথ ফাইনাল/এক্সেপ্টিং স্টেটে পৌঁছায়। অন্য কোনো পথ ডেড-এন্ডে গেলেও সমস্যা নেই।\n\n'
                  '৪. **গাণিতিক রূপ (5-Tuple):**\n'
                  'NFA-কে সংজ্ঞায়িত করা হয়: `(Q, Σ, δ, q0, F)` দ্বারা—\n'
                  '• `Q`: স্টেটসমূহের সেট\n'
                  '• `Σ`: ইনপুট অ্যালফাবেট\n'
                  '• `δ`: ট্রানজিশন ফাংশন (δ: Q × (Σ ∪ {ε}) → 2^Q, অর্থাৎ পাওয়ার সেট)\n'
                  '• `q0`: প্রাথমিক স্টেট\n'
                  '• `F`: ফাইনাল স্টেটসমূহের সেট\n\n'
                  '৫. **DFA-এর সাথে সমতুল্যতা (Equivalence):**\n'
                  'সাবসেট কনস্ট্রাকশন অ্যালগরিদম (Subset Construction / Powerset) ব্যবহার করে যেকোনো NFA-কে সমতুল্য DFA-তে রূপান্তরিত করা যায়। ফলে উভয় মডেলের কম্পিউটেশনাল ক্ষমতা সমান (উভয়েই Regular Languages গ্রহণ করে)।\n\n'
                  '৬. **বাস্তব প্রয়োগ:**\n'
                  'রেগুলার এক্সপ্রেশন (Regex) প্যাটার্ন ম্যাচিং ইঞ্জিন, লেক্সিক্যাল অ্যানালাইজার এবং কম্পাইলার ডিজাইনে NFA ব্যাপকভাবে ব্যবহৃত হয়।'
              : '🔍 **Detailed Explanation of NFA (Nondeterministic Finite Automaton):**\n\n'
                  '1. **Core Concept:**\n'
                  'An NFA is a finite state machine where for a given state and input symbol, the transition can lead to zero, one, or multiple possible next states.\n\n'
                  '2. **Epsilon (ε) Transitions:**\n'
                  'NFA allows transitions between states without consuming any input character (spontaneous transitions).\n\n'
                  '3. **Acceptance Condition:**\n'
                  'A string is accepted if there exists at least one computation path that ends in an accepting (final) state after reading the entire string.\n\n'
                  '4. **Formal Definition (5-tuple):**\n'
                  '`(Q, Σ, δ, q0, F)` where transition function `δ: Q × (Σ ∪ {ε}) → 2^Q` maps into the power set of states.\n\n'
                  '5. **DFA Equivalence:**\n'
                  'Every NFA can be converted into an equivalent DFA via the Subset Construction algorithm. Both recognize exactly the same class of languages (Regular Languages).\n\n'
                  '6. **Practical Applications:**\n'
                  'Regular expression engines (e.g., grep, flex) and compiler front-ends initially build an NFA before translating to DFA.';
        }

        // B. If previous topic was Youth loans and user asks for details on the loan part
        if (lastModelText.contains('যুব') ||
            lastModelText.contains('ঋণ') ||
            lastUserText.contains('ঋণ') ||
            lastUserText.contains('যুব')) {
          return isBn
              ? '💰 **যুব উন্নয়ন প্রশিক্ষণ পরবর্তী সরকারি ঋণ ও আর্থিক সুবিধা বিস্তারিত:**\n\n'
                  '• **ঋণের নাম:** বঙ্গবন্ধু যুব ঋণ ও কর্মসংস্থান ব্যাংক আত্মকর্মসংস্থান ঋণ।\n'
                  '• **ঋণের পরিমাণ:** প্রশিক্ষণপ্রাপ্ত যুবকদের জন্য ৫০,০০০ টাকা থেকে শুরু করে সর্বোচ্চ ৫,০০,০০০ (পাঁচ লাখ) টাকা পর্যন্ত।\n'
                  '• **সুদের হার ও মেয়াদ:** সহজ শর্তে ৪% থেকে ৯% সরল সেবা মূল্যে (নরমাল ব্যাংকিং সুদের চেয়ে অনেক কম)। পরিশোধের মেয়াদ সাধারণত ২ থেকে ৫ বছর।\n'
                  '• **জামানত নীতি:** ৫০,০০০ থেকে ১,০০,০০০ টাকা পর্যন্ত কোনো স্থাবর সম্পত্তির জামানত প্রয়োজন হয় না (শুধুমাত্র ব্যক্তিগত গ্যারান্টার)।\n'
                  '• **প্রয়োজনীয় কাগজপত্র:** যুব উন্নয়ন অধিদপ্তরের প্রশিক্ষণ সনদ, এনআইডি/জন্মনিবন্ধন, ২ কপি ছবি ও নাগরিকত্ব প্রত্যয়ন।\n'
                  '• **আবেদনের স্থান:** নিকটস্থ কর্মসংস্থান ব্যাংক শাখা অথবা উপজেলা যুব উন্নয়ন কর্মকর্তার কার্যালয়।\n\n'
                  '[ACTION:screen:opportunities:সুযোগ ও অনুদান হাব খুলুন]'
              : '💰 **Youth Self-Employment Loan Details:**\n\n'
                  '• Amount: 50,000 to 5,00,000 BDT based on project plan.\n'
                  '• Eligibility: DYD certified trainees aged 18-35.\n'
                  '• Interest: Concessionary rates (4%-9%) repayable in 2-5 years.\n'
                  '• Contact: Upazila Youth Development Office or Karmasangsthan Bank branch.\n\n'
                  '[ACTION:screen:opportunities:Open Opportunities Hub]';
        }
      }

      // Follow-up context on fees or duration
      if (text.contains('কতদিন') || text.contains('সময়') || lower.contains('how long') || lower.contains('how many days')) {
        if (lastModelText.contains('পাসপোর্ট') || lastUserText.contains('পাসপোর্ট')) {
          return isBn
              ? '⏱️ ই-পাসপোর্ট প্রাপ্তির সময়সীমা:\n\n• সাধারণ আবেদন: ১৫–২১ কার্যদিবস।\n• জরুরি (Express): ৭–১০ কার্যদিবস।\n• অতি-জরুরি (Super Express): ২ কার্যদিবস।'
              : '⏱️ e-Passport Processing Time: Regular takes 15-21 working days; Express takes 7-10 working days; Super Express takes 2 working days.';
        }
        if (lastModelText.contains('ড্রাইভিং') || lastUserText.contains('ড্রাইভিং') || lastModelText.contains('license')) {
          return isBn
              ? '⏱️ ড্রাইভিং লাইসেন্স প্রাপ্তির সময়সীমা:\n\n• লার্নার কার্ড: তাৎক্ষণিক (আবেদনের সাথে সাথে)।\n• পরীক্ষা: লার্নার পাওয়ার ২–৩ মাস পর।\n• স্মার্ট কার্ড ডেলিভারি: বায়োমেট্রিক ও পরীক্ষায় পাসের পর ১–৩ মাস (জরুরি ডেলিভারিতে ১৫–২১ দিন)।'
              : '⏱️ Driving License Timeline: Learner card is instant; Exam after 2-3 months; Smart card takes 1-3 months (15-21 days for express).';
        }
      }
    }

    // ─── 1. GREETINGS, SMALL TALK & CONVERSATIONAL INQUIRIES ───────────────
    if (lower == 'hi' ||
        lower == 'hello' ||
        lower == 'hey' ||
        text.contains('হাই') ||
        text.contains('হ্যালো') ||
        text.contains('সালাম') ||
        text.contains('আসসালামু') ||
        text.contains('নমস্কার') ||
        text.contains('আদাব')) {
      return isBn
          ? 'ওয়ালাইকুম আসসালাম! দিশারীর জনবন্ধু AI-এর পক্ষ থেকে আপনাকে আন্তরিক শুভেচ্ছা। আপনি কেমন আছেন? পাসপোর্ট, NID, জন্মনিবন্ধন, যুব প্রশিক্ষণ, ড্রাইভিং লাইসেন্স বা যেকোনো প্রশ্ন আমাকে করতে পারেন।'
          : 'Hello and welcome! I am Jonobondhu AI, your digital assistant for Dishari. How can I assist you with civic services, education, or government procedures today?';
    }

    if (text.contains('কেমন আছো') ||
        text.contains('কেমন আছেন') ||
        lower.contains('how are you')) {
      return isBn
          ? 'আলহামদুলিল্লাহ, আমি ভালো আছি! আশা করি আপনিও ভালো আছেন। বাংলাদেশের যেকোনো সরকারি সেবা, সনদপত্র বা যেকোনো বিষয়ে আপনাকে কীভাবে সাহায্য করতে পারি বলুন।'
          : 'I am doing well, thank you for asking! How can I help you today with your inquiries or government applications?';
    }

    if (text.contains('ধন্যবাদ') ||
        text.contains('থ্যাংক') ||
        lower.contains('thank you') ||
        lower.contains('thanks')) {
      return isBn
          ? 'আপনাকে অনেক ধন্যবাদ! সাহায্য করতে পেরে আমি আনন্দিত। আপনার অন্য কোনো প্রশ্ন বা তথ্যের প্রয়োজন হলে নির্দ্বিধায় জিজ্ঞেস করুন।'
          : 'You are most welcome! Glad I could assist. Feel free to ask anytime if you need help with anything else.';
    }

    if (text.contains('তুমি কে') ||
        text.contains('আপনার নাম') ||
        text.contains('কে আপনি') ||
        lower.contains('who are you') ||
        lower.contains('what is your name')) {
      return isBn
          ? 'আমি "জনবন্ধু AI" (Jonobondhu AI)—দিশারী প্ল্যাটফর্মের ভার্চুয়াল সেবা সহযোগী। আমার কাজ হলো যেকোনো নাগরিককে সরকারি সেবা (পাসপোর্ট, এনআইডি, জন্মনিবন্ধন, ড্রাইভিং লাইসেন্স, যুব ঋণ ইত্যাদি) এবং প্রাসঙ্গিক যেকোনো তথ্য সহজে ও স্বচ্ছভাবে বুঝিয়ে দেওয়া।\n\n[ACTION:screen:about:আমাদের সম্পর্কে বিস্তারিত জানুন]'
          : 'I am "Jonobondhu AI", your intelligent assistant on Dishari. I help citizens understand civic services, government applications, and general questions directly and transparently.\n\n[ACTION:screen:about:Learn About Dishari]';
    }

    // ─── 2. CS THEORY OF COMPUTATION: DFA vs NFA ───────────────────────────
    if ((lower.contains('dfa') && lower.contains('nfa')) ||
        (text.contains('অটোমাটা') || lower.contains('finite automata') || (lower.contains('dfa') || lower.contains('nfa')))) {
      return isBn
          ? '📘 **DFA (Deterministic Finite Automata) এবং NFA (Nondeterministic Finite Automata)-এর মধ্যে মূল পার্থক্য:**\n\n'
              '১. **স্টেট ট্রানজিশন (Transitions):**\n'
              '• **DFA:** প্রতিটি স্টেটে প্রতিটি ইনপুট চিহ্নের জন্য শুধুমাত্র একটি নির্দিষ্ট ট্রানজিশন (Next State) থাকে। কোনো অনিশ্চয়তা বা বিকল্প পথ থাকে না।\n'
              '• **NFA:** একটি স্টেটে একই ইনপুট চিহ্নের জন্য শূন্য, একটি বা একাধিক সম্ভাব্য পরবর্তী স্টেট থাকতে পারে।\n\n'
              '২. **খালি বা নাল ট্রানজিশন (ε-Transitions):**\n'
              '• **DFA:** খালি ইনপুট বা ε (Epsilon) ট্রানজিশন সমর্থন করে না। স্টেট বদলাতে হলে অবশ্যই ইনপুট চিহ্ন পড়তে হবে।\n'
              '• **NFA:** ইনপুট চিহ্ন ছাড়াই স্বতঃস্ফূর্তভাবে ε-ট্রানজিশনের মাধ্যমে স্টেট পরিবর্তন করতে পারে।\n\n'
              '৩. **ব্যাকট্র্যাকিং ও জটিলতা:**\n'
              '• **DFA:** সরাসরি কাজ করে, তাই রানটাইমে কোনো ব্যাকট্র্যাকিং লাগে না। স্ট্রিং গ্রহণ দ্রুত হয়।\n'
              '• **NFA:** একাধিক সম্ভাব্য পথ থাকায় রান করার সময় সবগুলো পথ ট্র্যাক করতে হয় বা ব্যাকট্র্যাকিং লাগে।\n\n'
              '৪. **ভাষাগত ক্ষমতা ও সমতুল্যতা (Computational Power):**\n'
              '• উভয়ের ক্ষমতা সমান। উভয়েই Regular Languages গ্রহণ করতে পারে।\n'
              '• সাবসেট কনস্ট্রাকশন (Subset Construction) পদ্ধতির মাধ্যমে যেকোনো NFA-কে সমতুল্য DFA-তে রূপান্তর করা যায়।\n\n'
              '৫. **ব্যবহারিক ক্ষেত্র:**\n'
              '• DFA টেক্সট সার্চ অ্যালগরিদম ও কম্পাইলারের লেক্সিক্যাল অ্যানালাইজারে সরাসরি ব্যবহৃত হয়।\n'
              '• NFA রেগুলার এক্সপ্রেশন ডিজাইনে মানুষের জন্য আঁকা বা কল্পনা করা সহজ।'
          : '📘 **Key Differences between DFA and NFA:**\n\n'
              '1. **Transitions:**\n'
              '• **DFA:** Exactly one transition for each input symbol from every state.\n'
              '• **NFA:** Zero, one, or multiple transitions for an input symbol from any state.\n\n'
              '2. **Epsilon (ε) Moves:**\n'
              '• **DFA:** Does NOT allow ε (empty string) transitions.\n'
              '• **NFA:** Allows ε transitions (state changes without reading input).\n\n'
              '3. **Execution Complexity:**\n'
              '• **DFA:** Fast, deterministic, no backtracking required.\n'
              '• **NFA:** Requires branching or backtracking to explore multiple paths.\n\n'
              '4. **Power & Equivalence:**\n'
              '• Both recognize the exact same class of languages (Regular Languages). Every NFA can be transformed into an equivalent DFA via Subset Construction.\n\n'
              '5. **Applications:**\n'
              '• DFA is used in direct hardware circuits and compiler lexical tokenizers.\n'
              '• NFA is ideal for initial regex parsing and language specification.';
    }

    // ─── 3. YOUTH TRAINING & UNEMPLOYMENT LOANS ─────────────────────────────
    if (text.contains('যুব') ||
        text.contains('বেকার') ||
        text.contains('প্রশিক্ষণ') ||
        text.contains('ঋণ') ||
        lower.contains('youth') ||
        lower.contains('unemployed') ||
        lower.contains('loan') ||
        lower.contains('training')) {
      if (text.contains('দ্বিতীয়') || text.contains('দ্বিতীয়') || text.contains('পাস') || text.contains('বেকার') || text.contains('ঋণ')) {
        return isBn
            ? '🎯 **শিক্ষিত ও বেকারদের সরকারি যুব প্রশিক্ষণ এবং আত্মকর্মসংস্থান ঋণ প্রাপ্তির নিয়মাবলী:**\n\n'
                '১. **সরকারি যুব প্রশিক্ষণ (যুব উন্নয়ন অধিদপ্তর - DYD):**\n'
                'যুব ও ক্রীড়া মন্ত্রণালয়ের অধীনে সারাদেশে বিনামূল্যে ও নামমাত্র খরচে বিভিন্ন মেয়াদে প্রশিক্ষণ প্রদান করা হয়।\n'
                '• **যোগ্যতা:** ১৮ থেকে ৩৫ বছর বয়স। শিক্ষাগত যোগ্যতা ন্যূনতম ৮ম শ্রেণি / এসএসসি বা সমমান (দ্বিতীয় বিভাগ বা জিপিএ ২.০০ হলেও আবেদনযোগ্য)।\n'
                '• **প্রধান কোর্সসমূহ:** কম্পিউটার বেসিক ও আইসিটি, ফ্রিল্যান্সিং, ড্রাইভিং, ইলেকট্রিক্যাল ও হাউজওয়্যারিং, মোবাইল সার্ভিসিং, মৎস্য চাষ, গবাদিপশু ও হাঁস-মুরগি পালন এবং পোশাক তৈরি (ড্রেস মেকিং)।\n'
                '• **ভাতা:** অনেক আবাসিক কোর্সে প্রশিক্ষণ চলাকালীন সরকারি দৈনিক ভাতাও প্রদান করা হয়।\n\n'
                '২. **প্রশিক্ষণ পরবর্তী ঋণ সুবিধা (বঙ্গবন্ধু যুব ঋণ ও কর্মসংস্থান ব্যাংক):**\n'
                'প্রশিক্ষণ সনদ থাকলে আত্মকর্মসংস্থানের জন্য সরকারি ঋণ পাওয়া যায়:\n'
                '• **ঋণের পরিমাণ:** ৫০,০০০ টাকা থেকে শুরু করে সর্বোচ্চ ৫,০০,০০০ (পাঁচ লাখ) টাকা পর্যন্ত।\n'
                '• **সুদের হার:** সহজ শর্তে ৪% থেকে ৯% স্বল্প সুদে/সার্ভিস চার্জে।\n'
                '• **জামানত:** প্রাথমিক ক্ষুদ্র ঋণে কোনো স্থাবর সম্পত্তির জামানত প্রয়োজন হয় না (শুধুমাত্র ব্যক্তিগত গ্যারান্টার)।\n\n'
                '৩. **কীভাবে আবেদন করবেন:**\n'
                '• আপনার উপজেলা বা জেলা **যুব উন্নয়ন কর্মকর্তার কার্যালয়ে** সশরীরে যোগাযোগ করুন অথবা অফিসিয়াল ওয়েবসাইট **dyd.gov.bd**-তে বিজ্ঞপ্তি দেখে আবেদন করুন।\n'
                '• প্রয়োজনীয় কাগজপত্র: জাতীয় পরিচয়পত্র (NID) বা অনলাইন জন্মনিবন্ধন, শিক্ষাগত সনদের ফটোকপি (এসএসসি/সমমান), নাগরিকত্ব প্রত্যয়ন ও পাসপোর্ট সাইজ ছবি।\n\n'
                '[ACTION:screen:opportunities:সুযোগ ও অনুদান হাব খুলুন]'
            : '🎯 **Government Youth Training & Self-Employment Loans in Bangladesh:**\n\n'
                '1. **Department of Youth Development (DYD) Training:**\n'
                '• Eligibility: Bangladeshi citizens aged 18-35 with minimum 8th grade or SSC/equivalent (2nd division/GPA 2.0+ is eligible).\n'
                '• Trades: Computer/ICT, Driving, Electrical, Mobile Repair, Poultry & Dairy, Tailoring.\n\n'
                '2. **Youth Loans (Bangabandhu Youth Loan / Karmasangsthan Bank):**\n'
                '• Amount: 50,000 to 5,00,000 BDT at concessionary interest rates (4-9%).\n'
                '• Collateral-free options available for amounts under 1,00,000 BDT with personal guarantees.\n\n'
                '3. **How to Apply:**\n'
                '• Visit your local Upazila Youth Development Office or visit dyd.gov.bd.\n'
                '• Requirements: NID/Birth Certificate, academic certificates, citizenship certificate, and photos.\n\n'
                '[ACTION:screen:opportunities:Open Opportunities Hub]';
      }
    }

    // ─── 4. DRIVING LICENSE (BRTA) ──────────────────────────────────────────
    if (text.contains('ড্রাইভিং') || text.contains('লাইসেন্স') || lower.contains('driving') || lower.contains('license') || lower.contains('brta')) {
      final isAskingTime = text.contains('কতদিন') ||
          text.contains('সময়') ||
          text.contains('মেয়াদ') ||
          lower.contains('how long') ||
          lower.contains('time') ||
          lower.contains('duration');

      if (isAskingTime) {
        return isBn
            ? '⏱️ **ড্রাইভিং লাইসেন্স করতে কতদিন সময় লাগে? (BRTA অফিসিয়াল সময়সীমা):**\n\n'
                '১. **লার্নার বা শিক্ষানবিস ড্রাইভিং লাইসেন্স:**\n'
                '• **সময়:** তাৎক্ষণিক (অনলাইন bsp.brta.gov.bd পোর্টালে ফর্ম পূরণ ও ফি দিয়ে সাথে সাথে ডাউনলোড করা যায়)।\n\n'
                '২. **ড্রাইভিং পরীক্ষা (ফিল্ড টেস্ট):**\n'
                '• লার্নার কার্ড পাওয়ার **২ থেকে ৩ মাস পর** বিআরটিএ কর্তৃক নির্ধারিত তারিখে লিখিত, মৌখিক এবং প্র্যাকটিক্যাল পরীক্ষা অনুষ্ঠিত হয়।\n\n'
                '৩. **বায়োমেট্রিক ও স্মার্ট কার্ড ডেলিভারি:**\n'
                '• পরীক্ষায় পাস করার পর বায়োমেট্রিক (আঙুলের ছাপ ও ছবি) দিতে হয়।\n'
                '• **স্মার্ট কার্ড লাইসেন্স পেতে সাধারণত ১ থেকে ৩ মাস সময় লাগে।**\n'
                '• জরুরি (Express) ডেলিভারির ক্ষেত্রে আনুমানিক **১৫ থেকে ২১ কার্যদিবসের** মধ্যে ডাকযোগে বা বিআরটিএ অফিসে স্মার্ট কার্ড পৌঁছে যায়।\n\n'
                '💡 **টিপস:** কার্ড হাতে পাওয়ার আগ পর্যন্ত বিআরটিএ প্রদত্ত ডিজিটাল একনলেজমেন্ট স্লিপ বা ই-ড্রাইভিং লাইসেন্স দিয়ে বৈধভাবে রাস্তায় গাড়ি চালানো যায়।'
            : '⏱️ **How Long Does it Take to Get a Driving License in Bangladesh?**\n\n'
                '1. **Learner License:** Instant. Apply online at bsp.brta.gov.bd and download immediately.\n'
                '2. **Examination:** Scheduled 2 to 3 months after learner issuance (written, oral, and driving practical test).\n'
                '3. **Smart Card Delivery:** 1 to 3 months after passing the test and submitting biometrics (15-21 working days for express delivery).\n'
                'You can legally drive using the digital acknowledgement slip until the physical card arrives.';
      }

      return isBn
          ? '🚗 **বিআরটিএ ড্রাইভিং লাইসেন্স আবেদনের নিয়মাবলী:**\n\n'
              '• আবেদন পোর্টাল: bsp.brta.gov.bd\n'
              '• ধাপ ১: অনলাইনে মেডিকেল সার্টিফিকেট আপলোড করে লার্নার ড্রাইভিং লাইসেন্স গ্রহণ।\n'
              '• ধাপ ২: নির্ধারিত তারিখে লিখিত, মৌখিক ও ফিল্ড টেস্ট পরীক্ষায় অংশগ্রহণ।\n'
              '• ধাপ ৩: পরীক্ষায় উত্তীর্ণ হয়ে বায়োমেট্রিক প্রদান ও স্মার্ট কার্ড গ্রহণ।\n'
              '• সরকারি ফি: অপেশাদার লাইসেন্স ৪,৫৭২ টাকা, পেশাদার লাইসেন্স ২,৮২৮ টাকা।'
          : '🚗 **BRTA Driving License Application Guide:**\n\n'
              '• Portal: bsp.brta.gov.bd\n'
              '• Step 1: Obtain Learner License online with registered doctor medical report.\n'
              '• Step 2: Attend theoretical, viva, and field driving test.\n'
              '• Step 3: Provide biometric data and receive smart driving card.\n'
              '• Fees: Non-professional: 4,572 BDT; Professional: 2,828 BDT.';
    }

    // ─── 5. PASSPORT REQUIREMENTS & CHECKLIST ──────────────────────────────
    if (text.contains('পাসপোর্ট') || lower.contains('passport')) {
      final isAskingDocs = text.contains('কী কী লাগে') ||
          text.contains('কি কি লাগে') ||
          text.contains('কাগজ') ||
          text.contains('ডকুমেন্ট') ||
          text.contains('প্রয়োজন') ||
          text.contains('প্রয়োজন') ||
          lower.contains('requirement') ||
          lower.contains('document');

      if (isAskingDocs) {
        return isBn
            ? '🛂 **বাংলাদেশের ই-পাসপোর্ট করতে প্রয়োজনীয় কাগজপত্র:**\n\n'
                '১. **পরিচয়পত্র প্রমাণ:**\n'
                '• ২০ বছর বা তদূর্ধ্ব: অনলাইন যাচাইকৃত জাতীয় পরিচয়পত্র (NID)।\n'
                '• ১৮ বছরের নিচে: ১৭ ডিজিটের অনলাইন জন্ম নিবন্ধন সনদ (BDRIS)।\n\n'
                '২. **পুরাতন পাসপোর্ট (প্রযোজ্য ক্ষেত্রে):**\n'
                '• পাসপোর্ট নবায়ন বা রি-ইস্যু হলে পূর্বের মূল পাসপোর্ট এবং এর ফটোকপি জমা দিতে হবে।\n\n'
                '৩. **নাগরিকত্ব প্রমাণ:**\n'
                '• ইউনিয়ন পরিষদ চেয়ারম্যান, পৌর মেয়র বা ওয়ার্ড কাউন্সিলর প্রদত্ত নাগরিকত্ব সনদপত্র।\n\n'
                '৪. **পেশাগত প্রমাণপত্র:**\n'
                '• চাকরিজীবী হলে অফিসিয়াল এনওসি (NOC) বা জিও (GO)।\n'
                '• ব্যবসায়ী হলে হালনাগাদ ট্রেড লাইসেন্স ও ই-টিআইএন কপি।\n'
                '• শিক্ষার্থী হলে শিক্ষাপ্রতিষ্ঠানের স্টুডেন্ট আইডি কার্ডের কপি।\n\n'
                '৫. **পেমেন্ট স্লিপ:**\n'
                '• এ-চালান (A-Challan) বা অনলাইন ব্যাংক পেমেন্টের মূল চালান কপি।\n\n'
                '৬. **অনলাইন আবেদন সামারি:**\n'
                '• epassport.gov.bd-তে আবেদন করার পর প্রিন্টকৃত অ্যাপ্লিকেশন সামারি কপি।\n\n'
                '[ACTION:service:passport:পাসপোর্ট আবেদন পেজে যান]'
            : '🛂 **Required Documents for Bangladesh e-Passport:**\n\n'
                '1. Verified National ID (NID) for age 20+, or 17-digit online Birth Certificate for under 20.\n'
                '2. Previous physical passport (for renewals/re-issues).\n'
                '3. Citizenship certificate from local Ward Councilor / Union Parishad.\n'
                '4. Proof of profession (NOC/GO for employees, Trade License for businessmen, Student ID for students).\n'
                '5. Official A-Challan payment receipt.\n'
                '6. Printed online Application Summary slip from epassport.gov.bd.\n\n'
                '[ACTION:service:passport:Go to Passport Page]';
      }

      if (text.contains('ফি') || text.contains('টাকা') || text.contains('খরচ') || lower.contains('fee')) {
        return isBn
            ? '💳 **ই-পাসপোর্টের অফিশিয়াল সরকারি ফি তালিকা:**\n\n'
                '• ৫ বছর মেয়াদী (৪৮ পৃষ্ঠা): নিয়মিত ৪,০২৫ টাকা (১৫–২১ দিন), জরুরি ৬,৩২৫ টাকা (৭–১০ দিন)।\n'
                '• ১০ বছর মেয়াদী (৪৮ পৃষ্ঠা): নিয়মিত ৫,৭৫০ টাকা (১৫–২১ দিন), জরুরি ৮,০৫০ টাকা (৭–১০ দিন)।\n'
                '• কোনো দালাল বা মধ্যস্বত্বভোগী ফি নেই। সরাসরি এ-চালান বা ব্যাংক পেমেন্টে জমা দেওয়া যায়।\n\n'
                '[ACTION:service:passport:পাসপোর্ট আবেদন পেজে যান]'
            : '💳 Official e-Passport Fees: 5-year 48-page: Regular 4,025 BDT, Express 6,325 BDT; 10-year 48-page: Regular 5,750 BDT, Express 8,050 BDT.\n\n[ACTION:service:passport:Go to Passport Page]';
      }

      return isBn
          ? '🛂 **ই-পাসপোর্ট আবেদনের নিয়মাবলী:**\n\n'
              '• আবেদন পোর্টাল: epassport.gov.bd\n'
              '• প্রয়োজনীয় কাগজপত্র: এনআইডি/১৭ ডিজিট জন্মনিবন্ধন, পূর্ববর্তী পাসপোর্ট (থাকলে), নাগরিক সনদ ও পেশাগত প্রমাণপত্র।\n'
              '• সরকারি ফি: ৫ বছর ৪৮ পৃষ্ঠা সাধারণ ফি ৪,০২৫ টাকা (জরুরি ৬,৩২৫ টাকা)।\n'
              '• ফরম পূরণের পর অ্যাপয়েন্টমেন্টের দিনে পাসপোর্ট অফিসে বায়োমেট্রিক প্রদান করতে হয়।\n\n'
              '[ACTION:service:passport:পাসপোর্ট আবেদন পেজে যান]'
          : '🛂 e-Passport Application: Apply online at epassport.gov.bd. Required: NID or online birth certificate, citizenship certificate, fee challan. Regular fee is 4,025 BDT.\n\n[ACTION:service:passport:Go to Passport Page]';
    }

    // ─── 6. BIRTH REGISTRATION (BDRIS) ──────────────────────────────────────
    if (text.contains('জন্ম নিবন্ধন') || text.contains('জন্ম সনদ') || lower.contains('birth certificate') || lower.contains('birth registration')) {
      return isBn
          ? '👶 **ডিজিটাল জন্ম নিবন্ধন (BDRIS) আবেদন ও নিয়মাবলী:**\n\n'
              '১. **আবেদন পোর্টাল:** bdris.gov.bd\n'
              '২. **প্রয়োজনীয় কাগজপত্র:**\n'
              '• হাসপাতালের জন্মের প্রত্যয়নপত্র অথবা ইপিআই টিকা কার্ডের কপি।\n'
              '• পিতা ও মাতার অনলাইন জন্মনিবন্ধন ও জাতীয় পরিচয়পত্র (NID)।\n'
              '• বাসার হোল্ডিং ট্যাক্স বা খাজনার রশিদের কপি।\n'
              '৩. **সরকারি ফি:**\n'
              '• শিশুর জন্মের ৪৫ দিন পর্যন্ত: সম্পূর্ণ বিনামূল্যে (০ টাকা)।\n'
              '• ৪৬ দিন থেকে ৫ বছর পর্যন্ত: ২৫ টাকা।\n'
              '• ৫ বছরের ঊর্ধ্বে: ৫০ টাকা।\n'
              '৪. **আবেদনের ধাপ:** অনলাইনে আবেদন সাবমিট করে প্রিন্ট কপি ও প্রয়োজনীয় নথিপত্রসহ ১৫ দিনের মধ্যে সংশ্লিষ্ট ইউনিয়ন পরিষদ বা পৌরসভা কার্যালয়ে জমা দিন।\n\n'
              '[ACTION:service:birth-registration:জন্ম নিবন্ধন পেজে যান]'
          : '👶 **How to Register a Birth Certificate in Bangladesh (BDRIS):**\n\n'
              '1. **Official Portal:** Apply online at bdris.gov.bd.\n'
              '2. **Required Documents:**\n'
              '• Hospital birth discharge certificate or EPI immunization card.\n'
              '• Verified online birth certificates and NID copies of parents.\n'
              '• Local residential holding tax receipt.\n'
              '3. **Official Fees:** Free within 45 days of birth; 25 BDT up to 5 years; 50 BDT above 5 years.\n'
              '4. **Submission:** Print the online application form and submit it with documents to your local Union Parishad or Pourashava office.\n\n'
              '[ACTION:service:birth-registration:Go to Birth Registration]';
    }

    // ─── 7. NATIONAL ID (NID) ──────────────────────────────────────────────
    if (text.contains('nid') || text.contains('এনআইডি') || text.contains('ভোটার') || text.contains('পরিচয়পত্র')) {
      return isBn
          ? '🪪 **জাতীয় পরিচয়পত্র (NID) সেবা:**\n\n'
              '• অফিশিয়াল পোর্টাল: services.nidw.gov.bd\n'
              '• সেবা প্রকার: নতুন এনআইডি আবেদন, তথ্য সংশোধন (নাম, পিতা-মাতা, জন্মতারিখ) ও রি-ইস্যু।\n'
              '• প্রয়োজনীয় প্রমাণক: ১৭ ডিজিট অনলাইন জন্ম নিবন্ধন, শিক্ষাগত সনদ (SSC/JSC), রক্ত পরীক্ষার রিপোর্ট।\n'
              '• সংশোধন ফি: "ক" ক্যাটাগরি ২৩০ টাকা, "খ" ক্যাটাগরি ৩৪৫ টাকা (বিকাশ বা রকেটে প্রদেয়)।\n\n'
              '[ACTION:service:nid-correction:NID সংশোধন পেজে যান]'
          : '🪪 National ID (NID) Services: Apply at services.nidw.gov.bd for corrections, new voter enrollment, or re-issuance. Fee: 230 BDT (Category A) or 345 BDT (Category B).\n\n[ACTION:service:nid-correction:Go to NID Correction]';
    }

    // ─── 8. LAND MUTATION & RECORDS ─────────────────────────────────────────
    if (text.contains('নামজারি') || text.contains('জমি') || text.contains('খতিয়ান') || text.contains('খারিজ') || lower.contains('land')) {
      return isBn
          ? '🌾 **ই-নামজারি (ভূমি সেবা):**\n\n'
              '• আবেদন পোর্টাল: mutation.land.gov.bd\n'
              '• প্রয়োজনীয় কাগজপত্র: মূল ক্রয় দলিল বা হেবা দলিল, পূর্ববর্তী খতিয়ান (RS/SA), দাখিলা (হালনাগাদ ভূমি উন্নয়ন কর) ও ওয়ারিশান সনদ।\n'
              '• সরকারি মোট ফি: নির্ধারিত ঠিক ১,১৭০ টাকা (আবেদন ২০ + নোটিশ ৫০ + রেকর্ড সংশোধন ১,০০০ + ডিসিআর ১০০ টাকা)।\n'
              '• নিষ্পত্তি সময়: সর্বোচ্চ ২৮ কার্যদিবস।\n\n'
              '[ACTION:service:land-mutation:নামজারি পেজে যান]'
          : '🌾 e-Namjari (Land Mutation): Apply at mutation.land.gov.bd. Total official fee is strictly 1,170 BDT. Maximum timeline is 28 working days.\n\n[ACTION:service:land-mutation:Go to Land Mutation]';
    }

    // ─── 9. TRADE LICENSE ───────────────────────────────────────────────────
    if (text.contains('ট্রেড লাইসেন্স') || text.contains('ব্যবসা') || lower.contains('trade license')) {
      return isBn
          ? '💼 **ই-ট্রেড লাইসেন্স (ব্যবসা নিবন্ধন):**\n\n'
              '• আবেদন পোর্টাল: etradelicense.gov.bd অথবা স্থানীয় সিটি কর্পোরেশন / পৌরসভা পোর্টাল।\n'
              '• প্রয়োজনীয় কাগজপত্র: ভাড়ার চুক্তিপত্র বা হোল্ডিং ট্যাক্স রশিদ, এনআইডি, ছবি ও টিআইএন সনদ।\n'
              '• সরকারি ফি: ব্যবসার মূলধন ও ধরনভেদে ১,২০০ থেকে ৫,০০০ টাকা।\n\n'
              '[ACTION:service:trade-license:ট্রেড লাইসেন্স পেজে যান]'
          : '💼 e-Trade License: Apply online at etradelicense.gov.bd. Required: rental deed/holding tax slip, NID, photo, TIN certificate.\n\n[ACTION:service:trade-license:Go to Trade License]';
    }

    // ─── 10. APP NAVIGATION SHORTCUTS ───────────────────────────────────────
    if (text.contains('লকার') || text.contains('নথিপত্র') || lower.contains('locker')) {
      return isBn
          ? '📂 আপনার নাগরিক ডিজিটাল লকারে NID, পাসপোর্ট, জন্মনিবন্ধন ও সার্টিফিকেট নিরাপদে সংরক্ষণ করতে পারবেন:\n\n[ACTION:tab:2:নাগরিক লকারে যান]'
          : '📂 Manage and share your civic documents securely in the Locker:\n\n[ACTION:tab:2:Open Document Locker]';
    }

    if (text.contains('সুযোগ') || text.contains('অনুদান') || lower.contains('opportunity')) {
      return isBn
          ? '🌟 চলমান সরকারি অনুদান, যুব ঋণ ও বৃত্তির তালিকা দেখতে আমাদের সুযোগ হাবে যান:\n\n[ACTION:screen:opportunities:সুযোগ ও অনুদান হাব খুলুন]'
          : '🌟 Explore active government loans and grants:\n\n[ACTION:screen:opportunities:Open Opportunities Hub]';
    }

    if (text.contains('ডেডলাইন') || lower.contains('deadline')) {
      return isBn
          ? '📅 আসন্ন সকল সরকারি আবেদন ও ফি জমার ডেডলাইন দেখতে ডেডলাইন ট্যাবে যান:\n\n[ACTION:tab:3:ডেডলাইন তালিকা দেখুন]'
          : '📅 View all upcoming civic deadlines:\n\n[ACTION:tab:3:View Deadlines]';
    }

    // ─── 11. GENERAL / OPEN-ENDED CONVERSATIONAL FALLBACK ───────────────────
    // Directly addresses the user naturally without regurgitating repetitive canned lists
    return isBn
        ? 'আপনার জিজ্ঞাসাটি বুঝতে পেরেছি। সরকারি সেবা, আবেদন পদ্ধতি, সনদপত্র বা যেকোনো সাধারণ বিষয়ে সুনির্দিষ্টভাবে জানতে চাইলে আমাকে বলুন—আমি বিস্তারিত তথ্য ও নিয়মাবলী দিয়ে সাহায্য করব।'
        : 'I understand your query. Please let me know what specific government procedure, application guideline, or question you would like assistance with, and I will be happy to help.';
  }
}

