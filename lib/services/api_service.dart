import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../config/env.dart';
import '../models/service.dart';
import '../models/document.dart';
import '../models/application.dart';
import '../models/deadline.dart';
import '../models/user_profile.dart';
import 'storage_service.dart';
import 'seed_data.dart';

class ApiService {
  static String get baseUrl => EnvConfig.apiBaseUrl;

  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ─── SERVICES ─────────────────────────────────────────────────────────────

  static Future<List<Service>> fetchAllServices({String? category, String? query}) async {
    try {
      final uri = Uri.parse('$baseUrl/services').replace(queryParameters: {
        if (category != null && category != 'all') 'category': category,
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      });

      final response = await http.get(uri, headers: defaultHeaders).timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        final List jsonList = jsonDecode(response.body);
        final services = jsonList.map((item) => Service.fromJson(Map<String, dynamic>.from(item))).toList();
        if (services.isNotEmpty) {
          return services;
        }
      }
    } catch (_) {
      // Fallback below
    }

    // Offline / Local seed filter fallback
    var list = SeedData.officialServices;
    if (category != null && category != 'all') {
      list = list.where((s) => s.category == category).toList();
    }
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      list = list.where((s) =>
        s.nameBn.toLowerCase().contains(q) ||
        s.nameEn.toLowerCase().contains(q) ||
        s.slug.toLowerCase().contains(q)
      ).toList();
    }
    return list;
  }

  static Future<Service?> fetchServiceBySlug(String slug) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/services/$slug'), headers: defaultHeaders)
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return Service.fromJson(jsonDecode(response.body));
      }
    } catch (_) {
      // Fallback below
    }

    // Fallback to seed data
    try {
      return SeedData.officialServices.firstWhere((s) => s.slug == slug);
    } catch (_) {
      return null;
    }
  }

  // ─── AUTHENTICATION ───────────────────────────────────────────────────────

  static Future<({bool success, UserProfile? user, String? error})> registerUser({
    required String fullName,
    required String phone,
    String? email,
    String? password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: defaultHeaders,
            body: jsonEncode({
              'fullName': fullName,
              'phone': phone,
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 5));

      final json = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final user = UserProfile.fromJson(json['user']);
        await StorageService.saveUser(user);
        return (success: true, user: user, error: null);
      } else {
        return (success: false, user: null, error: json['error']?.toString() ?? 'Registration failed');
      }
    } catch (_) {
      // Offline fallback demo user matching web client
      final fallbackUser = UserProfile(
        id: 1,
        fullName: fullName,
        phone: phone,
        email: email,
        citizenId: 'BD-USER-${100 + Random().nextInt(900)}',
      );
      await StorageService.saveUser(fallbackUser);
      return (success: true, user: fallbackUser, error: null);
    }
  }

  static Future<({bool success, UserProfile? user, String? error})> loginUser({
    required String identifier,
    String? password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: defaultHeaders,
            body: jsonEncode({
              'identifier': identifier,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 5));

      final json = jsonDecode(response.body);
      if (response.statusCode == 200 && json['success'] == true) {
        final user = UserProfile.fromJson(json['user']);
        await StorageService.saveUser(user);
        return (success: true, user: user, error: null);
      } else {
        return (success: false, user: null, error: json['error']?.toString() ?? 'Login failed');
      }
    } catch (_) {
      // Offline fallback demo user matching web client
      final fallbackUser = UserProfile(
        id: 1,
        fullName: 'নাগরিক',
        phone: identifier,
        email: identifier.contains('@') ? identifier : null,
        citizenId: 'BD-USER-782',
      );
      await StorageService.saveUser(fallbackUser);
      return (success: true, user: fallbackUser, error: null);
    }
  }

  // ─── DOCUMENT LOCKER ─────────────────────────────────────────────────────

  static Future<List<CitizenDocument>> fetchDocuments({int? userId}) async {
    try {
      final uri = Uri.parse('$baseUrl/documents').replace(queryParameters: {
        if (userId != null) 'userId': userId.toString(),
      });

      final response = await http.get(uri, headers: defaultHeaders).timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        final List jsonList = jsonDecode(response.body);
        final docs = jsonList.map((item) => CitizenDocument.fromJson(Map<String, dynamic>.from(item))).toList();
        await StorageService.saveDocuments(docs);
        return docs;
      }
    } catch (_) {
      // Fallback below
    }

    // Load from local storage with demo seed fallback
    final local = await StorageService.getDocuments();
    if (local.isNotEmpty) return local;
    if (userId == 1) return SeedData.demoDocuments;
    return [];
  }

  static Future<({bool success, CitizenDocument? document, String? error})> uploadDocument({
    int? userId,
    required String docType,
    required String fileName,
    required int fileSize,
    required String mimeType,
    required String fileData,
    Map<String, dynamic>? extractedMeta,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/documents/upload'),
            headers: defaultHeaders,
            body: jsonEncode({
              'userId': userId ?? 1,
              'docType': docType,
              'fileName': fileName,
              'fileSize': fileSize,
              'mimeType': mimeType,
              'fileData': fileData,
              'extractedMeta': extractedMeta ?? {},
            }),
          )
          .timeout(const Duration(seconds: 6));

      final json = jsonDecode(response.body);
      if (response.statusCode == 201 && json['success'] == true) {
        final doc = CitizenDocument.fromJson(json['document']);
        final cached = await StorageService.getDocuments();
        cached.insert(0, doc);
        await StorageService.saveDocuments(cached);
        return (success: true, document: doc, error: null);
      }
    } catch (_) {
      // Offline fallback
    }

    // Local fallback matching web
    final mockDoc = CitizenDocument(
      id: DateTime.now().millisecondsSinceEpoch,
      userId: userId ?? 1,
      docType: docType,
      fileName: fileName,
      fileSize: fileSize,
      mimeType: mimeType,
      verified: true,
      extractedMeta: extractedMeta ?? {},
      uploadedAt: DateTime.now().toIso8601String(),
      fileData: fileData,
    );
    final cached = await StorageService.getDocuments();
    cached.insert(0, mockDoc);
    await StorageService.saveDocuments(cached);
    return (success: true, document: mockDoc, error: null);
  }

  static Future<bool> deleteDocument(int id) async {
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl/documents/$id'), headers: defaultHeaders)
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final cached = await StorageService.getDocuments();
        cached.removeWhere((d) => d.id == id);
        await StorageService.saveDocuments(cached);
        return true;
      }
    } catch (_) {
      // Local removal
    }

    final cached = await StorageService.getDocuments();
    cached.removeWhere((d) => d.id == id);
    await StorageService.saveDocuments(cached);
    return true;
  }

  // ─── CITIZEN APPLICATION DOCKETS ─────────────────────────────────────────

  static Future<List<CitizenApplication>> fetchApplications({int? userId}) async {
    try {
      final uri = Uri.parse('$baseUrl/applications').replace(queryParameters: {
        if (userId != null) 'userId': userId.toString(),
      });

      final response = await http.get(uri, headers: defaultHeaders).timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        final List jsonList = jsonDecode(response.body);
        final apps = jsonList.map((item) => CitizenApplication.fromJson(Map<String, dynamic>.from(item))).toList();
        await StorageService.saveApplications(apps);
        return apps;
      }
    } catch (_) {
      // Fallback
    }

    final local = await StorageService.getApplications();
    if (local.isNotEmpty) return local;
    if (userId == 1) return SeedData.demoApplications;
    return [];
  }

  static Future<({bool success, CitizenApplication? application, String? error})> createApplication({
    int? userId,
    required String serviceSlug,
    required String serviceNameBn,
    required String serviceNameEn,
    required Map<String, dynamic> applicantData,
    required List<String> documentsAttached,
    String? officialPortalUrl,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/applications'),
            headers: defaultHeaders,
            body: jsonEncode({
              'userId': userId ?? 1,
              'serviceSlug': serviceSlug,
              'serviceNameBn': serviceNameBn,
              'serviceNameEn': serviceNameEn,
              'applicantData': applicantData,
              'documentsAttached': documentsAttached,
              'officialPortalUrl': officialPortalUrl,
            }),
          )
          .timeout(const Duration(seconds: 6));

      final json = jsonDecode(response.body);
      if (response.statusCode == 201 && json['success'] == true) {
        final app = CitizenApplication.fromJson(json['application']);
        final cached = await StorageService.getApplications();
        cached.insert(0, app);
        await StorageService.saveApplications(cached);
        return (success: true, application: app, error: null);
      }
    } catch (_) {
      // Offline fallback
    }

    // Local fallback matching web
    final docketId = 'BD-APP-${DateTime.now().year}-${10000 + Random().nextInt(90000)}';
    final fallbackApp = CitizenApplication(
      id: DateTime.now().millisecondsSinceEpoch,
      docketId: docketId,
      userId: userId ?? 1,
      serviceSlug: serviceSlug,
      serviceNameBn: serviceNameBn,
      serviceNameEn: serviceNameEn,
      status: 'ready',
      applicantData: applicantData,
      documentsAttached: documentsAttached,
      feeStatus: 'unpaid',
      officialPortalUrl: officialPortalUrl,
      submittedAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );

    final cached = await StorageService.getApplications();
    cached.insert(0, fallbackApp);
    await StorageService.saveApplications(cached);
    return (success: true, application: fallbackApp, error: null);
  }

  // ─── DEADLINES ───────────────────────────────────────────────────────────

  static Future<List<CitizenDeadline>> fetchDeadlines() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/deadlines'), headers: defaultHeaders)
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List jsonList = jsonDecode(response.body);
        return jsonList.map((item) => CitizenDeadline.fromJson(Map<String, dynamic>.from(item))).toList();
      }
    } catch (_) {
      // Fallback
    }

    return SeedData.defaultDeadlines;
  }
}

