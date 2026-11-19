import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/env.dart';

/// High-precision ICAO Doc 9303 Type 3 (TD3) MRZ Parser for Bangladesh e-Passports & Passports
class MrzParser {
  static Map<String, dynamic>? parse2LineMrz(String line1, String line2) {
    line1 = line1.trim().toUpperCase().replaceAll(' ', '');
    line2 = line2.trim().toUpperCase().replaceAll(' ', '');
    if (line1.length < 28 || line2.length < 28) return null;

    try {
      final docCode = line1.substring(0, 1);
      final issuingCountry = line1.length >= 5 ? line1.substring(2, 5) : '';

      // Line 1: Surname and Given names separated by <<
      String namesPart = line1.length >= 6 ? line1.substring(5) : '';
      namesPart = namesPart.replaceAll(RegExp(r'<+$'), '');
      final nameSplit = namesPart.split('<<');
      final surname = nameSplit.isNotEmpty ? nameSplit[0].replaceAll('<', ' ').trim() : '';
      final givenNames = nameSplit.length > 1 ? nameSplit[1].replaceAll('<', ' ').trim() : '';
      final fullName = '$givenNames $surname'.trim().isNotEmpty ? '$givenNames $surname'.trim() : surname;

      // Line 2: Passport Number (first 9 characters)
      final passportNoRaw = line2.substring(0, line2.length >= 9 ? 9 : line2.length);
      final passportNo = passportNoRaw.replaceAll('<', '').trim();

      // Nationality (chars 10-13)
      final nationalityRaw = line2.length >= 13 ? line2.substring(10, 13).replaceAll('<', '') : '';
      final nationality = nationalityRaw == 'BGD' ? 'Bangladeshi (বাংলাদেশী)' : nationalityRaw;

      // Date of Birth (chars 13-19: YYMMDD)
      String dob = '';
      if (line2.length >= 19) {
        final dobRaw = line2.substring(13, 19);
        dob = _parseMrzDate(dobRaw, isBirth: true);
      }

      // Sex (char 20)
      String sex = '';
      if (line2.length >= 21) {
        final s = line2.substring(20, 21);
        if (s == 'M') sex = 'Male (পুরুষ)';
        else if (s == 'F') sex = 'Female (মহিলা)';
        else sex = s;
      }

      // Expiry Date (chars 21-27: YYMMDD)
      String expiry = '';
      if (line2.length >= 27) {
        final expRaw = line2.substring(21, 27);
        expiry = _parseMrzDate(expRaw, isBirth: false);
      }

      // Personal Number / NID (chars 28-42)
      String personalNo = '';
      if (line2.length >= 42) {
        personalNo = line2.substring(28, 42).replaceAll('<', '').trim();
      }

      return {
        'doc_type': 'passport',
        'doc_code': docCode,
        'issuing_country': issuingCountry,
        'full_name_en': fullName,
        'passport_number': passportNo,
        'id_number': passportNo,
        'nationality': nationality,
        'dob': dob,
        'gender': sex,
        'expiry_date': expiry,
        if (personalNo.isNotEmpty) 'personal_number': personalNo,
        'mrz_line1': line1,
        'mrz_line2': line2,
      };
    } catch (_) {
      return null;
    }
  }

  static String _parseMrzDate(String yymmdd, {required bool isBirth}) {
    if (yymmdd.length != 6) return yymmdd;
    try {
      final yy = int.parse(yymmdd.substring(0, 2));
      final mm = yymmdd.substring(2, 4);
      final dd = yymmdd.substring(4, 6);
      final currentYear = DateTime.now().year % 100;
      final fullYear = isBirth
          ? (yy > currentYear ? 1900 + yy : 2000 + yy)
          : (yy < 70 ? 2000 + yy : 1900 + yy);
      return '$fullYear-$mm-$dd';
    } catch (_) {
      return yymmdd;
    }
  }
}

class N8nService {
  /// Maps raw extracted keys from diverse n8n/AI models into consistent citizen document fields
  static Map<String, dynamic> normalizeDocumentData(Map<String, dynamic> raw) {
    final normalized = Map<String, dynamic>.from(raw);

    void mapKey(List<String> sources, String target) {
      if (normalized.containsKey(target) &&
          normalized[target] != null &&
          normalized[target].toString().trim().isNotEmpty) {
        return;
      }
      for (final src in sources) {
        if (raw.containsKey(src) &&
            raw[src] != null &&
            raw[src].toString().trim().isNotEmpty) {
          normalized[target] = raw[src].toString().trim();
          break;
        }
      }
    }

    mapKey([
      'full_name_en',
      'name_en',
      'english_name',
      'Name',
      'name',
      'full_name',
      'fullName',
      'Citizen Name',
      'Student Name',
      'Candidate Name',
      'candidate_name',
    ], 'full_name_en');

    mapKey([
      'full_name_bn',
      'name_bn',
      'bangla_name',
      'বাংলা নাম',
      'নাম',
      'পূর্ণ নাম',
      'fullNameBn',
      'full_name',
      'name',
    ], 'full_name_bn');

    mapKey([
      'id_number',
      'nid_number',
      'nid',
      'NID',
      'NID Number',
      'idNumber',
      'ID No',
      'nid_no',
      'Registration Number',
      'Certificate No',
      'brn_number',
      'tin_number',
      'id',
    ], 'id_number');

    mapKey(['Roll', 'roll', 'Roll No', 'roll_no', 'Student Roll'], 'roll');
    mapKey(['Reg No', 'reg_no', 'Registration No', 'regNo'], 'reg_no');
    mapKey(['Board', 'board', 'Education Board'], 'board');
    mapKey(['Exam', 'exam', 'exam_name', 'পরীক্ষা'], 'exam_name');
    mapKey(['GPA', 'gpa', 'result', 'জিকে', 'ফলাফল', 'cgpa'], 'gpa');
    mapKey(['Passing Year', 'passing_year', 'year', 'session', 'পাসের সন'], 'passing_year');
    mapKey(['Institution', 'institution', 'institute', 'school', 'college', 'university', 'শিক্ষা প্রতিষ্ঠান'], 'institution');
    mapKey(['DOB', 'dob', 'Date of Birth', 'date_of_birth', 'birth_date', 'birthDate', 'জন্ম তারিখ'], 'dob');
    mapKey(['Father Name', 'father_name', 'Father', 'father', 'পিতা', 'পিতার নাম'], 'father_name');
    mapKey(['Mother Name', 'mother_name', 'Mother', 'mother', 'মাতা', 'মাতার নাম'], 'mother_name');
    mapKey(['Blood Group', 'blood_group', 'Blood', 'blood', 'bloodGroup', 'রক্তের গ্রুপ'], 'blood_group');
    mapKey(['Address', 'address', 'Full Address', 'ঠিকানা', 'present_address', 'permanent_address'], 'address');
    mapKey(['Postal Code', 'post_code', 'postal_code', 'ডাকঘর', 'পোস্ট কোড'], 'postal_code');
    mapKey(['District', 'district', 'জেলা'], 'district');
    mapKey(['Upazila', 'upazila', 'থানা', 'উপজেলা'], 'upazila');
    mapKey(['Business Name', 'business_name', 'Trade Name', 'প্রতিষ্ঠানের নাম', 'trade_name'], 'business_name');
    mapKey(['Issue Date', 'issue_date', 'প্রদানের তারিখ', 'ইস্যু তারিখ'], 'issue_date');
    mapKey(['Doc Type', 'doc_type', 'document_type', 'type'], 'doc_type');
    mapKey(['Doc Title', 'doc_title', 'title'], 'doc_title');

    // Passport fields
    mapKey(['Passport No', 'passport_no', 'passport_number', 'Passport Number', 'পাসপোর্ট নম্বর'], 'passport_number');
    mapKey(['Nationality', 'nationality', 'জাতীয়তা'], 'nationality');
    mapKey(['Expiry Date', 'expiry_date', 'date_of_expiry', 'মেয়াদ উত্তীর্ণের তারিখ'], 'expiry_date');
    mapKey(['MRZ Line 1', 'mrz_line1', 'mrz1', 'mrz_1'], 'mrz_line1');
    mapKey(['MRZ Line 2', 'mrz_line2', 'mrz2', 'mrz_2'], 'mrz_line2');
    mapKey(['Issuing Country', 'issuing_country', 'country_code', 'দেশ'], 'issuing_country');
    mapKey(['Gender', 'gender', 'sex', 'লিঙ্গ'], 'gender');

    // Utility Bill fields
    mapKey(['Account Number', 'account_no', 'account_number', 'customer_no', 'হিসাব নম্বর', 'গ্রাহক নং'], 'account_number');
    mapKey(['Meter Number', 'meter_no', 'meter_number', 'মিটার নং'], 'meter_number');
    mapKey(['Bill Month', 'bill_month', 'billing_month', 'মাসের নাম'], 'bill_month');
    mapKey(['Bill Amount', 'bill_amount', 'total_amount', 'payable_amount', 'মোট টাকা', 'বিল টাকার পরিমাণ'], 'bill_amount');
    mapKey(['Due Date', 'due_date', 'পরিশোধের শেষ তারিখ'], 'due_date');

    // Driving License fields
    mapKey(['License Number', 'license_no', 'license_number', 'লাইসেন্স নম্বর'], 'license_number');
    mapKey(['Vehicle Class', 'vehicle_class', 'class_of_vehicle', 'যানবাহনের শ্রেণি'], 'vehicle_class');

    // Confidence Score
    mapKey(['Confidence', 'confidence', 'confidence_score', 'accuracy'], 'confidence_score');

    // If MRZ lines are present, parse with MrzParser for complete accuracy
    final mrz1 = normalized['mrz_line1']?.toString().trim();
    final mrz2 = normalized['mrz_line2']?.toString().trim();
    if (mrz1 != null && mrz2 != null && mrz1.isNotEmpty && mrz2.isNotEmpty) {
      final parsedMrz = MrzParser.parse2LineMrz(mrz1, mrz2);
      if (parsedMrz != null) {
        parsedMrz.forEach((k, v) {
          if (v != null && v.toString().trim().isNotEmpty) {
            if (!normalized.containsKey(k) || normalized[k] == null || normalized[k].toString().trim().isEmpty) {
              normalized[k] = v;
            }
          }
        });
      }
    }

    // Default id_number fallbacks for Passport, Driving License, or Utility
    final currentId = normalized['id_number']?.toString().trim() ?? '';
    if (currentId.isEmpty) {
      final pNo = normalized['passport_number']?.toString().trim() ?? '';
      final lNo = normalized['license_number']?.toString().trim() ?? '';
      final aNo = normalized['account_number']?.toString().trim() ?? '';
      if (pNo.isNotEmpty) normalized['id_number'] = pNo;
      else if (lNo.isNotEmpty) normalized['id_number'] = lNo;
      else if (aNo.isNotEmpty) normalized['id_number'] = aNo;
    }

    // Default Confidence Score if missing (derive from extracted field richness)
    if (!normalized.containsKey('confidence_score') || normalized['confidence_score'] == null) {
      int score = 88;
      if (normalized['id_number'] != null && normalized['id_number'].toString().isNotEmpty) score += 5;
      if (normalized['full_name_bn'] != null && normalized['full_name_bn'].toString().isNotEmpty) score += 3;
      if (normalized['dob'] != null && normalized['dob'].toString().isNotEmpty) score += 2;
      normalized['confidence_score'] = score.clamp(75, 99);
    }

    // Cross-fill Bengali and English names if one is present and the other is blank
    final bnName = normalized['full_name_bn']?.toString().trim();
    final enName = normalized['full_name_en']?.toString().trim();
    if ((bnName == null || bnName.isEmpty) && enName != null && enName.isNotEmpty) {
      normalized['full_name_bn'] = enName;
    } else if ((enName == null || enName.isEmpty) && bnName != null && bnName.isNotEmpty) {
      normalized['full_name_en'] = bnName;
    }

    return normalized;
  }

  /// Checks if extracted data contains meaningful fields for the given document type
  static bool _hasMeaningfulData(Map<String, dynamic> data, String? expectedDocType) {
    final id = data['id_number']?.toString().trim();
    final nameBn = data['full_name_bn']?.toString().trim();
    final nameEn = data['full_name_en']?.toString().trim();
    final addr = data['address']?.toString().trim();
    final blood = data['blood_group']?.toString().trim();
    final roll = data['roll']?.toString().trim();
    final reg = data['reg_no']?.toString().trim();
    final bName = data['business_name']?.toString().trim();
    final issue = data['issue_date']?.toString().trim();
    final dob = data['dob']?.toString().trim();
    final passNo = data['passport_number']?.toString().trim();
    final mrz1 = data['mrz_line1']?.toString().trim();
    final licNo = data['license_number']?.toString().trim();
    final accNo = data['account_number']?.toString().trim();
    final billAmt = data['bill_amount']?.toString().trim();

    if (expectedDocType == 'passport' || (passNo != null && passNo.isNotEmpty) || (mrz1 != null && mrz1.isNotEmpty)) {
      return (passNo != null && passNo.isNotEmpty) || (mrz1 != null && mrz1.isNotEmpty) || (nameEn != null && nameEn.isNotEmpty);
    }
    if (expectedDocType == 'utility_bill' || (accNo != null && accNo.isNotEmpty) || (billAmt != null && billAmt.isNotEmpty)) {
      return (accNo != null && accNo.isNotEmpty) || (billAmt != null && billAmt.isNotEmpty) || (addr != null && addr.isNotEmpty);
    }
    if (expectedDocType == 'driving_license' || (licNo != null && licNo.isNotEmpty)) {
      return (licNo != null && licNo.isNotEmpty) || (nameEn != null && nameEn.isNotEmpty) || (nameBn != null && nameBn.isNotEmpty);
    }
    if (expectedDocType == 'nid_back' ||
        (addr != null && addr.isNotEmpty) ||
        (issue != null && issue.isNotEmpty)) {
      return (addr != null && addr.isNotEmpty) ||
          (blood != null && blood.isNotEmpty) ||
          (issue != null && issue.isNotEmpty);
    }
    if (expectedDocType == 'educational_transcript' || (roll != null && roll.isNotEmpty)) {
      return (roll != null && roll.isNotEmpty) ||
          (reg != null && reg.isNotEmpty) ||
          (nameBn != null && nameBn.isNotEmpty) ||
          (nameEn != null && nameEn.isNotEmpty);
    }
    if (expectedDocType == 'trade_license' || (bName != null && bName.isNotEmpty)) {
      return (bName != null && bName.isNotEmpty) || (id != null && id.isNotEmpty);
    }
    return (id != null && id.isNotEmpty) ||
        (nameBn != null && nameBn.isNotEmpty) ||
        (nameEn != null && nameEn.isNotEmpty) ||
        (addr != null && addr.isNotEmpty) ||
        (dob != null && dob.isNotEmpty) ||
        (blood != null && blood.isNotEmpty) ||
        (roll != null && roll.isNotEmpty) ||
        (passNo != null && passNo.isNotEmpty);
  }

  /// Sends the image to backend OCR (/api/documents/scan-ocr), Gemini Vision AI,
  /// or optional n8n webhook. Returns extracted fields strictly from the document.
  static Future<Map<String, dynamic>> extractImageInfo({
    required File imageFile,
    String? customWebhookUrl,
    String? docType,
  }) async {
    final fileName = imageFile.path.split(Platform.pathSeparator).last;
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final filenameLower = fileName.toLowerCase();
    String mimeType = 'image/jpeg';
    if (filenameLower.endsWith('.png')) {
      mimeType = 'image/png';
    } else if (filenameLower.endsWith('.webp')) {
      mimeType = 'image/webp';
    } else if (filenameLower.endsWith('.pdf')) {
      mimeType = 'application/pdf';
    }

    // ─── 1. TRY DISHARI BACKEND OCR (/api/documents/scan-ocr) ──────────────
    // This is the exact primary endpoint used by the web application
    final primaryBackend = EnvConfig.apiBaseUrl;
    final backendEndpoints = <String>{
      '$primaryBackend/documents/scan-ocr',
      if (primaryBackend.contains('localhost'))
        primaryBackend.replaceAll('localhost', '10.0.2.2') + '/documents/scan-ocr',
      if (primaryBackend.contains('10.0.2.2'))
        primaryBackend.replaceAll('10.0.2.2', 'localhost') + '/documents/scan-ocr',
      'http://10.0.2.2:5000/api/documents/scan-ocr',
      'http://localhost:5000/api/documents/scan-ocr',
    }.toList();

    for (final bEndpoint in backendEndpoints) {
      try {
        debugPrint('N8nService: Connecting to backend OCR endpoint: $bEndpoint');
        final res = await http
            .post(
              Uri.parse(bEndpoint),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'imageBase64': base64Image,
                'mimeType': mimeType,
                'docType': docType ?? 'nid_front',
                'fileName': fileName,
              }),
            )
            .timeout(const Duration(seconds: 15));

        if (res.statusCode == 200 && res.body.isNotEmpty) {
          final decoded = jsonDecode(res.body);
          if (decoded is Map<String, dynamic> && decoded['document'] != null) {
            final doc = decoded['document'];
            if (doc is Map<String, dynamic>) {
              final normalized = normalizeDocumentData(doc);
              if (_hasMeaningfulData(normalized, docType)) {
                return {
                  'success': true,
                  'data': normalized,
                  'source': decoded['source'] ?? 'backend_ocr',
                };
              }
            }
          }
        }
      } catch (e) {
        debugPrint('N8nService: Backend OCR endpoint $bEndpoint notice: $e');
      }
    }

    // ─── 2. TRY DIRECT GEMINI VISION API (CASCADE MODELS) ─────────────────
    final apiKey = EnvConfig.geminiApiKey;
    if (apiKey.isNotEmpty) {
      final extractionPrompt = '''You are an expert AI Universal OCR & document parsing system specializing in Bangladeshi and international citizen documents.
USER EXPECTED DOCUMENT TYPE: ${docType ?? "Auto-detect"}

IMPORTANT INSTRUCTIONS FOR ROBUST & DISTANT RECOGNITION:
1. DISTANT OR IMPERFECT CAPTURE: The photo may have been taken from a distance, may contain desk/table/floor/hand backgrounds, may be slightly tilted, angled, dimly lit, or not perfectly sharp. Locate the document boundaries within the image, mentally crop to the document, and carefully read all visible Bengali (বাংলা) and English text.
2. UNIVERSAL DOCUMENT TYPES SUPPORTED:
   - "nid_front": Bangladesh National ID (front) with "গণপ্রজাতন্ত্রী বাংলাদেশ সরকার", "National ID Card", Bengali Name, English Name, Father's Name, Mother's Name, Date of Birth, NID Number.
   - "nid_back": Bangladesh National ID (back) with Address ("ঠিকানা: বাসা/হোল্ডিং, গ্রাম/রাস্তা, ডাকঘর, উপজেলা/থানা, জেলা"), Blood Group ("রক্তের গ্রুপ"), Issue Date ("প্রদানের তারিখ").
   - "passport": Bangladesh / International Passport. Extract Passport Number, Full Name, Date of Birth, Nationality, Date of Expiry, Issue Date, Gender. CRITICAL: Read the 2-line MRZ (Machine Readable Zone with '<' characters at the bottom) verbatim into "mrz_line1" and "mrz_line2".
   - "birth_certificate": Digital Birth Registration (জন্ম নিবন্ধন সনদ) with 17-digit BRN (রেজিস্ট্রেশন নম্বর), Date of Birth, Child's Name, Father's Name, Mother's Name.
   - "educational_transcript": HSC/SSC/Degree Admit Card, Marksheet, or Transcript with Exam Name, Roll, Registration Number, Board/University, GPA, Passing Year, Institution.
   - "academic_certificate": Graduation/Board certificate.
   - "driving_license": BRTA Driving License with Driving License Number, Vehicle Class, Issue Date, Expiry Date, Blood Group.
   - "utility_bill": DESCO, DPDC, REB, Titas Gas, WASA bill with Account/Meter/Customer Number, Bill Month, Total Amount, Due Date.
   - "tin_certificate": e-TIN Certificate with 12-digit TIN, Taxpayer Name, Taxes Zone, Circle.
   - "trade_license": e-Trade License with Trade License Number, Business Name, Owner Name, Address.
   - "citizenship_certificate": Local council / Ward / Union Parishad certificate.

3. FOR NID BACK SIDE:
   Extract the complete Address into "address", blood group into "blood_group", issue date into "issue_date", postal code into "postal_code", upazila into "upazila", district into "district". Set "doc_type": "nid_back".

4. CONFIDENCE SCORE:
   Estimate overall reading confidence from 75 to 99 based on image sharpness and character clarity into "confidence_score".

Return STRICTLY a JSON object without markdown fences, conforming to:
{
  "doc_type": "nid_front" | "nid_back" | "passport" | "birth_certificate" | "educational_transcript" | "academic_certificate" | "driving_license" | "utility_bill" | "tin_certificate" | "trade_license" | "citizenship_certificate" | "other",
  "doc_title": "Bengali descriptive document title",
  "full_name_bn": "Bengali name",
  "full_name_en": "English name",
  "id_number": "Main ID, Passport, or Certificate number",
  "passport_number": "Passport number if passport",
  "nationality": "Nationality",
  "expiry_date": "Expiry date (YYYY-MM-DD or DD/MM/YYYY)",
  "mrz_line1": "First line of passport MRZ if passport",
  "mrz_line2": "Second line of passport MRZ if passport",
  "dob": "Date of Birth (YYYY-MM-DD or DD/MM/YYYY)",
  "gender": "Gender",
  "father_name": "Father's name",
  "mother_name": "Mother's name",
  "blood_group": "Blood group (e.g. A+, B+, O+, AB+)",
  "address": "Full Bengali address",
  "issue_date": "Issue date",
  "postal_code": "Post code",
  "district": "District",
  "upazila": "Upazila/Thana",
  "roll": "Roll number if exam/admit card",
  "reg_no": "Registration number",
  "board": "Board / University name",
  "exam_name": "Exam name",
  "gpa": "GPA / CGPA / Grade",
  "passing_year": "Passing year",
  "institution": "Institute name",
  "license_number": "Driving license number",
  "vehicle_class": "Vehicle class (Motorcycle/Light)",
  "account_number": "Utility customer/account number",
  "meter_number": "Utility meter number",
  "bill_month": "Billing month",
  "bill_amount": "Total payable bill amount",
  "due_date": "Bill due date",
  "business_name": "Business name if trade license",
  "confidence_score": 95
}''';

      final requestBody = jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text': extractionPrompt,
              },
              {
                'inline_data': {
                  'mime_type': mimeType,
                  'data': base64Image,
                }
              }
            ]
          }
        ]
      });

      final geminiModels = ['gemini-1.5-flash', 'gemini-2.0-flash', 'gemini-1.5-pro'];
      for (final model in geminiModels) {
        try {
          debugPrint('N8nService: Trying direct Gemini Vision API ($model) for docType: $docType');
          final geminiUri = Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
          );

          final geminiRes = await http
              .post(
                geminiUri,
                headers: {'Content-Type': 'application/json'},
                body: requestBody,
              )
              .timeout(const Duration(seconds: 18));

          if (geminiRes.statusCode == 200) {
            final decoded = jsonDecode(geminiRes.body);
            final candidates = decoded['candidates'] as List?;
            if (candidates != null && candidates.isNotEmpty) {
              final parts = candidates[0]['content']?['parts'] as List?;
              if (parts != null && parts.isNotEmpty) {
                final text = parts[0]['text']?.toString() ?? '';
                final jsonMatch = RegExp(r'```(?:json)?\s*([\s\S]*?)```',
                        caseSensitive: false)
                    .firstMatch(text);
                String jsonText = '';
                if (jsonMatch != null) {
                  jsonText = jsonMatch.group(1)!.trim();
                } else {
                  final start = text.indexOf('{');
                  final end = text.lastIndexOf('}');
                  if (start != -1 && end != -1) {
                    jsonText = text.substring(start, end + 1);
                  }
                }

                if (jsonText.isNotEmpty) {
                  final parsedDoc = jsonDecode(jsonText);
                  if (parsedDoc is Map<String, dynamic>) {
                    final normalized = normalizeDocumentData(parsedDoc);
                    if (_hasMeaningfulData(normalized, docType)) {
                      return {
                        'success': true,
                        'data': normalized,
                        'source': 'gemini_vision_$model',
                      };
                    }
                  }
                }
              }
            }
          }
        } catch (e) {
          debugPrint('N8nService: Gemini direct call ($model) notice: $e');
        }
      }
    }

    // ─── 3. TRY OPTIONAL N8N WEBHOOK IF CONFIGURED ─────────────────────────
    if ((customWebhookUrl != null && customWebhookUrl.trim().isNotEmpty) ||
        EnvConfig.n8nWebhookUrl.isNotEmpty) {
      final n8nEndpoints = <String>{
        if (customWebhookUrl != null && customWebhookUrl.trim().isNotEmpty)
          customWebhookUrl.trim(),
        if (EnvConfig.n8nWebhookUrl.isNotEmpty) EnvConfig.n8nWebhookUrl,
      }.toList();

      for (final endpoint in n8nEndpoints) {
        try {
          debugPrint('N8nService: Probing n8n endpoint: $endpoint');
          final uri = Uri.parse(endpoint);

          final jsonRes = await http
              .post(
                uri,
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'imagebase64': base64Image,
                  'imageBase64': base64Image,
                  'mimeType': mimeType,
                  'fileName': fileName,
                  'docType': docType,
                }),
              )
              .timeout(const Duration(seconds: 10));

          if (jsonRes.statusCode == 200 && jsonRes.body.isNotEmpty) {
            final decoded = jsonDecode(jsonRes.body);
            if (decoded is Map<String, dynamic>) {
              if (decoded['success'] == true && decoded['document'] != null) {
                final doc = decoded['document'];
                if (doc is Map<String, dynamic>) {
                  final normalized = normalizeDocumentData(doc);
                  if (_hasMeaningfulData(normalized, docType)) {
                    return {
                      'success': true,
                      'data': normalized,
                      'source': 'n8n_workflow',
                    };
                  }
                }
              }
            }
          }
        } catch (e) {
          debugPrint('N8nService: Optional n8n endpoint notice: $e');
        }
      }
    }

    // ─── 4. OCR FAILED TO EXTRACT ──────────────────────────────────────────
    // Never return fake/mock citizen data as "success".
    return {
      'success': false,
      'error': 'নথিটি স্ক্যান করতে সমস্যা হয়েছে। অনুগ্রহ করে স্পষ্ট আলোতে সম্পূর্ণ নথির ছবি তুলুন বা পুনরায় চেষ্টা করুন।',
      'data': <String, dynamic>{
        'file_name': fileName,
        'scanned_at': DateTime.now().toIso8601String(),
      },
      'source': 'ocr_failed',
    };
  }
}
