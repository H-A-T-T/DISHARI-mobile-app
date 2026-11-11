import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get apiBaseUrl {
    try {
      final envUrl = dotenv.env['API_BASE_URL']?.trim();
      if (envUrl != null && envUrl.isNotEmpty) {
        // If running in browser or desktop where 10.0.2.2 cannot be routed, substitute with localhost
        if (kIsWeb && envUrl.contains('10.0.2.2')) {
          return envUrl.replaceAll('10.0.2.2', 'localhost');
        }
        return envUrl;
      }
    } catch (_) {}

    // Auto-detect host based on platform
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api';
    }
    return 'http://localhost:5000/api';
  }

  static String get appName {
    try {
      return dotenv.env['APP_NAME'] ?? 'দিশারী';
    } catch (_) {
      return 'দিশারী';
    }
  }

  /// Google Gemini API Key from .env
  static String get geminiApiKey {
    try {
      return dotenv.env['GEMINI_API_KEY']?.trim() ??
          dotenv.env['AI_API_KEY']?.trim() ??
          '';
    } catch (_) {
      return '';
    }
  }

  /// OpenAI API Key from .env
  static String get openaiApiKey {
    try {
      return dotenv.env['OPENAI_API_KEY']?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Custom Agent or Proxy API URL from .env
  static String get aiApiUrl {
    try {
      return dotenv.env['AI_API_URL']?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Returns true if any AI API key or URL is configured
  static bool get hasAiConfigured {
    return geminiApiKey.isNotEmpty ||
        openaiApiKey.isNotEmpty ||
        aiApiUrl.isNotEmpty;
  }
}
