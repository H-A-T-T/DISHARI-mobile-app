import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/seed_data.dart';

class AuthProvider extends ChangeNotifier {
  UserProfile? _user;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String _citizenId = 'BD-USER-782';

  UserProfile? get user => _user;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String get citizenId => _user?.citizenId ?? _citizenId;

  AuthProvider() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    _user = await StorageService.getUser();
    _isLoggedIn = _user != null;
    if (_user != null) {
      _citizenId = _user!.citizenId;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<({bool success, String? error})> login({
    required String identifier,
    String? password,
  }) async {
    _isLoading = true;
    notifyListeners();

    final result = await ApiService.loginUser(
      identifier: identifier,
      password: password,
    );

    if (result.success && result.user != null) {
      _user = result.user;
      _isLoggedIn = true;
      _citizenId = _user!.citizenId;
      _isLoading = false;
      notifyListeners();
      return (success: true, error: null);
    } else {
      _isLoading = false;
      notifyListeners();
      return (success: false, error: result.error);
    }
  }

  Future<({bool success, String? error})> register({
    required String fullName,
    required String phone,
    String? email,
    String? password,
  }) async {
    _isLoading = true;
    notifyListeners();

    final result = await ApiService.registerUser(
      fullName: fullName,
      phone: phone,
      email: email,
      password: password,
    );

    if (result.success && result.user != null) {
      _user = result.user;
      _isLoggedIn = true;
      _citizenId = _user!.citizenId;
      _isLoading = false;
      notifyListeners();
      return (success: true, error: null);
    } else {
      _isLoading = false;
      notifyListeners();
      return (success: false, error: result.error);
    }
  }

  Future<void> loginAsDemoCitizen() async {
    final demo = SeedData.demoUser;
    await StorageService.saveUser(demo);
    _user = demo;
    _isLoggedIn = true;
    _citizenId = demo.citizenId;
    notifyListeners();
  }

  Future<void> logout() async {
    await StorageService.clearUser();
    _user = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  Future<void> updateProfile({required String fullName, String? email}) async {
    if (_user != null) {
      final updated = _user!.copyWith(fullName: fullName, email: email);
      await StorageService.saveUser(updated);
      _user = updated;
      notifyListeners();
    }
  }
}
