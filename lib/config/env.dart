import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String normalizeApiUrl(String url) {
    var trimmed = url.trim();
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    if (!trimmed.endsWith('/api')) {
      trimmed = '$trimmed/api';
    }
    return trimmed;
  }

  static String get apiBaseUrl {
    // 1. Check compile-time environment variable (--dart-define=API_BASE_URL=...)
    const dartDefineUrl = String.fromEnvironment('API_BASE_URL');
    if (dartDefineUrl.trim().isNotEmpty) {
      final url = dartDefineUrl.trim();
      if (kIsWeb && url.contains('10.0.2.2')) {
        return normalizeApiUrl(url.replaceAll('10.0.2.2', 'localhost'));
      }
      return normalizeApiUrl(url);
    }

    // 2. Check runtime .env file
    try {
      final envUrl = dotenv.env['API_BASE_URL']?.trim();
      if (envUrl != null && envUrl.isNotEmpty) {
        if (kIsWeb && envUrl.contains('10.0.2.2')) {
          return normalizeApiUrl(envUrl.replaceAll('10.0.2.2', 'localhost'));
        }
        return normalizeApiUrl(envUrl);
      }
    } catch (_) {}

    // 3. Fallback based on runtime platform
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api';
    }
    return 'http://localhost:5000/api';
  }

  static String get appName {
    const dartDefineName = String.fromEnvironment('APP_NAME');
    if (dartDefineName.isNotEmpty) return dartDefineName;
    try {
      return dotenv.env['APP_NAME'] ?? 'দিশারী';
    } catch (_) {
      return 'দিশারী';
    }
  }

  /// Google Gemini API Key from --dart-define or .env
  static String get geminiApiKey {
    const dartDefineKey = String.fromEnvironment('GEMINI_API_KEY');
    if (dartDefineKey.isNotEmpty) return dartDefineKey;
    const dartDefineAiKey = String.fromEnvironment('AI_API_KEY');
    if (dartDefineAiKey.isNotEmpty) return dartDefineAiKey;

    try {
      return dotenv.env['GEMINI_API_KEY']?.trim() ??
          dotenv.env['AI_API_KEY']?.trim() ??
          '';
    } catch (_) {
      return '';
    }
  }

  /// OpenAI API Key from --dart-define or .env
  static String get openaiApiKey {
    const dartDefineKey = String.fromEnvironment('OPENAI_API_KEY');
    if (dartDefineKey.isNotEmpty) return dartDefineKey;
    try {
      return dotenv.env['OPENAI_API_KEY']?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Custom Agent or Proxy API URL from --dart-define or .env
  static String get aiApiUrl {
    const dartDefineUrl = String.fromEnvironment('AI_API_URL');
    if (dartDefineUrl.isNotEmpty) return dartDefineUrl;
    try {
      return dotenv.env['AI_API_URL']?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  /// n8n Webhook URL for image extraction
  static String get n8nWebhookUrl {
    const dartDefineUrl = String.fromEnvironment('N8N_WEBHOOK_URL');
    if (dartDefineUrl.isNotEmpty) return dartDefineUrl;

    try {
      final envUrl = dotenv.env['N8N_WEBHOOK_URL']?.trim();
      if (envUrl != null && envUrl.isNotEmpty) {
        if (kIsWeb && envUrl.contains('10.0.2.2')) {
          return envUrl.replaceAll('10.0.2.2', 'localhost');
        }
        return envUrl;
      }
    } catch (_) {}

    if (kIsWeb) {
      return 'http://localhost:5678/webhook/extract-image';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5678/webhook/extract-image';
    }
    return 'http://localhost:5678/webhook/extract-image';
  }

  /// Returns true if any AI API key or URL is configured
  static bool get hasAiConfigured {
    return geminiApiKey.isNotEmpty ||
        openaiApiKey.isNotEmpty ||
        aiApiUrl.isNotEmpty;
  }
}
