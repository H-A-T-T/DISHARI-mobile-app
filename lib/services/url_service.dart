import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlService {
  /// Opens an external URL in the user's browser (Chrome, system browser).
  /// Automatically fixes missing schemes (e.g. "epassport.gov.bd" -> "https://epassport.gov.bd"),
  /// trims whitespace, and uses robust fallbacks so the link always launches.
  static Future<bool> openUrl(String? rawUrl) async {
    if (rawUrl == null) return false;
    var trimmed = rawUrl.trim();
    if (trimmed.isEmpty || trimmed == '#' || trimmed == '/') return false;

    // Ensure scheme is present so Uri parses properly
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      trimmed = 'https://$trimmed';
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return false;

    try {
      // Primary attempt: launch in external application (Chrome / default browser)
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return true;
    } catch (e) {
      debugPrint('LaunchMode.externalApplication failed: $e');
    }

    try {
      // Fallback: platformDefault
      return await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
      );
    } catch (e) {
      debugPrint('LaunchMode.platformDefault failed: $e');
    }

    return false;
  }
}
