import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../config/translations.dart';

class LanguageProvider extends ChangeNotifier {
  String _language = 'bn';

  String get language => _language;
  bool get isBn => _language == 'bn';

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    _language = await StorageService.getLanguage();
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    if (lang != _language && (lang == 'bn' || lang == 'en')) {
      _language = lang;
      await StorageService.saveLanguage(lang);
      notifyListeners();
    }
  }

  Future<void> toggleLanguage() async {
    final next = _language == 'bn' ? 'en' : 'bn';
    await setLanguage(next);
  }

  String t(String key) {
    return AppTranslations.get(key, isBn);
  }
}

