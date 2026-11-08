import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/document.dart';
import '../models/application.dart';

class StorageService {
  static const String keyUser = 'dishari_user';
  static const String keyLoggedIn = 'dishari_logged_in';
  static const String keyLanguage = 'dishari_language';
  static const String keyCachedDocs = 'dishari_cached_docs';
  static const String keyCachedApps = 'dishari_cached_apps';
  static const String keyReadNotifs = 'dishari_read_notifs';

  static Future<void> saveUser(UserProfile user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyUser, jsonEncode(user.toJson()));
    await prefs.setBool(keyLoggedIn, true);
  }

  static Future<UserProfile?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(keyUser);
    final loggedIn = prefs.getBool(keyLoggedIn) ?? false;
    if (raw != null && loggedIn) {
      try {
        return UserProfile.fromJson(jsonDecode(raw));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyUser);
    await prefs.setBool(keyLoggedIn, false);
  }

  static Future<void> saveLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyLanguage, lang);
  }

  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyLanguage) ?? 'bn';
  }

  static Future<void> saveDocuments(List<CitizenDocument> docs) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = docs.map((d) => d.toJson()).toList();
    await prefs.setString(keyCachedDocs, jsonEncode(jsonList));
  }

  static Future<List<CitizenDocument>> getDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(keyCachedDocs);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        return list.map((item) => CitizenDocument.fromJson(Map<String, dynamic>.from(item))).toList();
      } catch (_) {
        return [];
      }
    }
    return [];
  }

  static Future<void> saveApplications(List<CitizenApplication> apps) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = apps.map((a) => a.toJson()).toList();
    await prefs.setString(keyCachedApps, jsonEncode(jsonList));
  }

  static Future<List<CitizenApplication>> getApplications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(keyCachedApps);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        return list.map((item) => CitizenApplication.fromJson(Map<String, dynamic>.from(item))).toList();
      } catch (_) {
        return [];
      }
    }
    return [];
  }

  static Future<List<String>> getReadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(keyReadNotifs) ?? [];
  }

  static Future<void> markNotificationRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(keyReadNotifs) ?? [];
    if (!current.contains(id)) {
      current.add(id);
      await prefs.setStringList(keyReadNotifs, current);
    }
  }
}

