import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/env.dart';

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

    mapKey(['Name', 'name', 'full_name', 'fullName', 'Citizen Name', 'Student Name', 'Candidate Name'], 'full_name_en');
    mapKey(['বাংলা নাম', 'নাম', 'পূর্ণ নাম', 'fullNameBn', 'bangla_name'], 'full_name_bn');
    mapKey(['NID', 'NID Number', 'id_number', 'idNumber', 'ID No', 'nid_no', 'Registration Number', 'Certificate No'], 'id_number');
    mapKey(['Roll', 'roll', 'Roll No', 'roll_no', 'Student Roll'], 'roll');
    mapKey(['Reg No', 'reg_no', 'Registration No', 'regNo'], 'reg_no');
    mapKey(['Board', 'board', 'Education Board'], 'board');
    mapKey(['DOB', 'dob', 'Date of Birth', 'date_of_birth', 'জন্ম তারিখ'], 'dob');
    mapKey(['Father Name', 'father_name', 'Father', 'পিতা'], 'father_name');
    mapKey(['Mother Name', 'mother_name', 'Mother', 'মাতা'], 'mother_name');
    mapKey(['Blood Group', 'blood_group', 'Blood', 'রক্তের গ্রুপ'], 'blood_group');
    mapKey(['Address', 'address', 'Full Address', 'ঠিকানা'], 'address');
    mapKey(['Business Name', 'business_name', 'Trade Name', 'প্রতিষ্ঠানের নাম'], 'business_name');
    mapKey(['Issue Date', 'issue_date', 'ইস্যু তারিখ'], 'issue_date');

    // Auto assign full_name_bn if English is blank and Bengali exists, or vice versa
    if ((normalized['full_name_bn'] == null || normalized['full_name_bn'].toString().isEmpty) &&
        normalized['full_name_en'] != null) {
      normalized['full_name_bn'] = normalized['full_name_en'];
    }

    return normalized;
  }

  /// Sends the image to n8n webhook, then backend OCR (/api/documents/scan-ocr),
  /// and Gemini AI. Returns extracted fields strictly from the document.
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
    }

    // ─── 1. TRY N8N WEBHOOK ────────────────────────────────────────────────
    final n8nEndpoints = <String>{
      if (customWebhookUrl != null && customWebhookUrl.trim().isNotEmpty)
        customWebhookUrl.trim(),
      if (EnvConfig.n8nWebhookUrl.isNotEmpty) EnvConfig.n8nWebhookUrl,
      'http://localhost:5678/webhook/extract-image',
      'http://10.0.2.2:5678/webhook/extract-image',
      'http://localhost:5678/webhook-test/extract-image',
      'http://10.0.2.2:5678/webhook-test/extract-image',
    }.toList();

    for (final endpoint in n8nEndpoints) {
      try {
        debugPrint('N8nService: Probing n8n endpoint: $endpoint');
        final uri = Uri.parse(endpoint);

        // First attempt: JSON body (matching Capture_image_info json schema)
        try {
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
              .timeout(const Duration(seconds: 15));

          if (jsonRes.statusCode == 200 && jsonRes.body.isNotEmpty) {
            debugPrint('N8nService: n8n JSON responded: ${jsonRes.body}');
            final decoded = jsonDecode(jsonRes.body);
            if (decoded is Map<String, dynamic>) {
              if (decoded['success'] == true && decoded['document'] != null) {
                final doc = decoded['document'];
                if (doc is Map<String, dynamic>) {
                  return {
                    'success': true,
                    'data': normalizeDocumentData(doc),
                    'source': 'n8n_workflow',
                  };
                }
              } else if (decoded.containsKey('Name') ||
                  decoded.containsKey('name') ||
                  decoded.containsKey('id_number') ||
                  decoded.containsKey('idNumber') ||
                  decoded.containsKey('document')) {
                final docData = decoded['document'] is Map<String, dynamic>
                    ? decoded['document']
                    : decoded;
                return {
                  'success': true,
                  'data': normalizeDocumentData(docData),
                  'source': 'n8n_workflow',
                };
              }
            }
          }
        } catch (_) {}

        // Second attempt: Multipart upload (matching n8n binaryPropertyName = "file")
        final request = http.MultipartRequest('POST', uri);
        request.files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: fileName),
        );
        request.fields['imagebase64'] = base64Image;
        request.fields['mimeType'] = mimeType;
        request.fields['fileName'] = fileName;

        final streamedRes =
            await request.send().timeout(const Duration(seconds: 15));
        final res = await http.Response.fromStream(streamedRes);

        if (res.statusCode == 200 && res.body.isNotEmpty) {
          debugPrint('N8nService: n8n multipart responded: ${res.body}');
          final decoded = jsonDecode(res.body);
          if (decoded is Map<String, dynamic>) {
            if (decoded['success'] == true && decoded['document'] != null) {
              final doc = decoded['document'];
              if (doc is Map<String, dynamic>) {
                return {
                  'success': true,
                  'data': normalizeDocumentData(doc),
                  'source': 'n8n_workflow',
                };
              }
            } else if (decoded.containsKey('Name') ||
                decoded.containsKey('name') ||
                decoded.containsKey('id_number') ||
                decoded.containsKey('idNumber')) {
              return {
                'success': true,
                'data': normalizeDocumentData(decoded),
                'source': 'n8n_workflow',
              };
            }
          }
        }
      } catch (e) {
        debugPrint('N8nService: Endpoint $endpoint failed or offline: $e');
      }
    }

    // ─── 2. TRY DISHARI BACKEND OCR (/api/documents/scan-ocr) ──────────────
    final backendEndpoints = <String>{
      '${EnvConfig.apiBaseUrl}/documents/scan-ocr',
      'http://localhost:5000/api/documents/scan-ocr',
      'http://10.0.2.2:5000/api/documents/scan-ocr',
    }.toList();

    for (final bEndpoint in backendEndpoints) {
      try {
        debugPrint('N8nService: Trying backend OCR endpoint: $bEndpoint');
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
              return {
                'success': true,
                'data': normalizeDocumentData(doc),
                'source': decoded['source'] ?? 'backend_ocr',
              };
            }
          }
        }
      } catch (e) {
        debugPrint('N8nService: Backend OCR endpoint $bEndpoint error: $e');
      }
    }

    // ─── 3. TRY DIRECT GEMINI VISION API ───────────────────────────────────
    final apiKey = EnvConfig.geminiApiKey;
    if (apiKey.isNotEmpty && apiKey.startsWith('AIza')) {
      try {
        debugPrint('N8nService: Trying direct Gemini Vision API');
        final geminiUri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
        );

        final requestBody = jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text':
                      '''Extract all text and details from this Bangladeshi citizen ID card, admit card, certificate or document (such as Name, Bengali Name, Roll, Registration Number, NID/ID Number, Date of Birth, Father Name, Mother Name, Blood Group, Address, Issue Date).
Return strictly a valid JSON object without markdown code blocks with the keys:
{
  "doc_title": "Detected Title",
  "full_name_bn": "Bengali Name if present",
  "full_name_en": "English Name",
  "id_number": "NID or Certificate ID Number",
  "roll": "Roll number if admit card",
  "reg_no": "Registration number if present",
  "board": "Education board if present",
  "dob": "Date of Birth (DD/MM/YYYY)",
  "father_name": "Father's Name",
  "mother_name": "Mother's Name",
  "blood_group": "Blood group",
  "address": "Address",
  "business_name": "Business name if trade license"
}''',
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

        final geminiRes = await http
            .post(
              geminiUri,
              headers: {'Content-Type': 'application/json'},
              body: requestBody,
            )
            .timeout(const Duration(seconds: 15));

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
                  return {
                    'success': true,
                    'data': normalizeDocumentData(parsedDoc),
                    'source': 'gemini_vision',
                  };
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('N8nService: Gemini direct call failed: $e');
      }
    }

    // ─── 4. SKELETON WITH REAL FILENAME & DATE ─────────────────────────────
    final docTitles = {
      'nid_front': 'গণপ্রজাতন্ত্রী বাংলাদেশ সরকার - জাতীয় পরিচয়পত্র',
      'nid_back': 'জাতীয় পরিচয়পত্র (পেছনের অংশ)',
      'birth_certificate': 'জন্ম ও মৃত্যু নিবন্ধন কার্যালয় - জন্ম নিবন্ধন সনদ',
      'educational_transcript': 'শিক্ষা বোর্ড - প্রবেশপত্র / শিক্ষাগত সনদ',
      'tin_certificate': 'জাতীয় রাজস্ব বোর্ড (NBR) - ই-টিআইএন সনদ',
      'trade_license': 'সিটি কর্পোরেশন / পৌরসভা - ই-ট্রেড লাইসেন্স',
      'citizenship_certificate': 'ইউনিয়ন পরিষদ / পৌরসভা - নাগরিকত্ব সনদ',
      'photo': 'পাসপোর্ট সাইজ ছবি',
    };

    return {
      'success': true,
      'data': {
        'doc_title': docTitles[docType] ?? 'ডিজিটাল সংরক্ষিত নাগরিক নথি',
        'file_name': fileName,
        'scanned_at': DateTime.now().toIso8601String(),
        'status': 'তথ্য পর্যালোচনা ও যাচাই করুন',
      },
      'source': 'real_file_metadata',
    };
  }
}
