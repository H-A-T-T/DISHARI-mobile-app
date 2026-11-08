import 'package:flutter/material.dart';
import '../models/document.dart';
import '../models/application.dart';
import '../models/deadline.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/seed_data.dart';

class DashboardProvider extends ChangeNotifier {
  List<CitizenDocument> _documents = [];
  List<CitizenApplication> _applications = [];
  List<CitizenDeadline> _deadlines = SeedData.defaultDeadlines;
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  int _activeTab = 0; // Sub-tab index within Dashboard: 0: Overview, 1: Applications, 2: Profile

  List<CitizenDocument> get documents => _documents;
  List<CitizenApplication> get applications => _applications;
  List<CitizenDeadline> get deadlines => _deadlines;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  int get activeTab => _activeTab;

  int get completenessPercent {
    return (_documents.length / 5 * 100).clamp(0, 100).round();
  }

  void setActiveTab(int index) {
    _activeTab = index;
    notifyListeners();
  }

  DashboardProvider() {
    _initLocalData();
  }

  Future<void> _initLocalData() async {
    try {
      final localDocs = await StorageService.getDocuments();
      final localApps = await StorageService.getApplications();
      if (localDocs.isNotEmpty || localApps.isNotEmpty) {
        if (localDocs.isNotEmpty) _documents = localDocs;
        if (localApps.isNotEmpty) _applications = localApps;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Local data initialization error: $e');
    }
  }

  Future<void> loadDashboardData(int? userId, {bool isDemo = false}) async {
    try {
      if (_documents.isEmpty && _applications.isEmpty) {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
        notifyListeners();
      }

      // 1. Immediately ensure local/cached/demo data is ready
      List<CitizenDocument> localDocs = await StorageService.getDocuments();
      List<CitizenApplication> localApps = await StorageService.getApplications();

      if (localDocs.isEmpty && (isDemo || userId == 1)) {
        localDocs = List.from(SeedData.demoDocuments);
        await StorageService.saveDocuments(localDocs);
      }
      if (localApps.isEmpty && (isDemo || userId == 1)) {
        localApps = List.from(SeedData.demoApplications);
        await StorageService.saveApplications(localApps);
      }

      _documents = localDocs;
      _applications = localApps;
      _deadlines = SeedData.defaultDeadlines;
      _isLoading = false;
      notifyListeners();

      // 2. Safely attempt background synchronization with backend API
      final netDocs = await ApiService.fetchDocuments(userId: userId);
      final netApps = await ApiService.fetchApplications(userId: userId);
      final netDeadlines = await ApiService.fetchDeadlines();

      if (netDocs.isNotEmpty) {
        _documents = netDocs;
        await StorageService.saveDocuments(netDocs);
      }
      if (netApps.isNotEmpty) {
        _applications = netApps;
        await StorageService.saveApplications(netApps);
      }
      if (netDeadlines.isNotEmpty) {
        _deadlines = netDeadlines;
      }

      _hasError = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Dashboard data fetch notice: $e');
      _hasError = false;
      // Guarantee fallback to seed data so screens never crash or stay blank
      if (_documents.isEmpty && (isDemo || userId == 1)) {
        _documents = List.from(SeedData.demoDocuments);
      }
      if (_applications.isEmpty && (isDemo || userId == 1)) {
        _applications = List.from(SeedData.demoApplications);
      }
      if (_deadlines.isEmpty) {
        _deadlines = List.from(SeedData.defaultDeadlines);
      }
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> seedDemoData() async {
    _documents = List.from(SeedData.demoDocuments);
    _applications = List.from(SeedData.demoApplications);
    _deadlines = List.from(SeedData.defaultDeadlines);
    await StorageService.saveDocuments(_documents);
    await StorageService.saveApplications(_applications);
    _isLoading = false;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> clearSessionData() async {
    _documents = [];
    _applications = [];
    _activeTab = 0;
    _hasError = false;
    _errorMessage = null;
    await StorageService.saveDocuments([]);
    await StorageService.saveApplications([]);
    notifyListeners();
  }

  Future<bool> uploadDocument({
    int? userId,
    required String docType,
    required String fileName,
    required int fileSize,
    required String mimeType,
    required String fileData,
    Map<String, dynamic>? extractedMeta,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await ApiService.uploadDocument(
        userId: userId,
        docType: docType,
        fileName: fileName,
        fileSize: fileSize,
        mimeType: mimeType,
        fileData: fileData,
        extractedMeta: extractedMeta,
      );

      if (res.success && res.document != null) {
        _documents.insert(0, res.document!);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Upload document error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> deleteDocument(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await ApiService.deleteDocument(id);
      if (success) {
        _documents.removeWhere((d) => d.id == id);
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint('Delete document error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<({bool success, CitizenApplication? application, String? error})> createApplication({
    int? userId,
    required String serviceSlug,
    required String serviceNameBn,
    required String serviceNameEn,
    required Map<String, dynamic> applicantData,
    required List<String> documentsAttached,
    String? officialPortalUrl,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await ApiService.createApplication(
        userId: userId,
        serviceSlug: serviceSlug,
        serviceNameBn: serviceNameBn,
        serviceNameEn: serviceNameEn,
        applicantData: applicantData,
        documentsAttached: documentsAttached,
        officialPortalUrl: officialPortalUrl,
      );

      if (res.success && res.application != null) {
        _applications.insert(0, res.application!);
        _isLoading = false;
        notifyListeners();
        return (success: true, application: res.application, error: null);
      } else {
        _isLoading = false;
        notifyListeners();
        return (success: false, application: null, error: res.error);
      }
    } catch (e) {
      debugPrint('Create application error: $e');
      _isLoading = false;
      notifyListeners();
      return (success: false, application: null, error: 'Network error creating application');
    }
  }
}
