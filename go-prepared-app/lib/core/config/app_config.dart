import 'package:flutter/foundation.dart';

/// Resolves API base URL at runtime (Flutter web) or from `--dart-define`.
class AppConfig {
  static late final String apiBaseUrl;

  static const enableChecklist = true;
  static const enableKnowledge = true;
  static const enableCommunity = true;

  static const googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID', defaultValue: '');
  static const microsoftClientId = String.fromEnvironment('MICROSOFT_CLIENT_ID', defaultValue: '');
  static const microsoftTenantId = String.fromEnvironment('MICROSOFT_TENANT_ID', defaultValue: 'common');
  static const microsoftRedirectUri = String.fromEnvironment('MICROSOFT_REDIRECT_URI', defaultValue: '');
  static const devAuthEnabled = bool.fromEnvironment('DEV_AUTH_ENABLED', defaultValue: true);

  /// OAuth redirect URI for Microsoft (must match Entra app registration).
  /// Web uses `{origin}/auth` — register e.g. https://goprepared.example.com/auth
  static String get oauthRedirectUri {
    if (microsoftRedirectUri.isNotEmpty) {
      return microsoftRedirectUri;
    }
    if (kIsWeb) {
      final base = Uri.base;
      final port = base.hasPort && base.port != 80 && base.port != 443 ? ':${base.port}' : '';
      return '${base.scheme}://${base.host}$port/auth';
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'msauth.com.goprepared.goPreparedApp://auth';
    }
    return 'msauth://com.goprepared.go_prepared_app/callback';
  }

  static void init() {
    const fromDefine = String.fromEnvironment('API_BASE_URL');
    if (fromDefine.isNotEmpty) {
      apiBaseUrl = fromDefine;
      return;
    }

    if (kIsWeb) {
      final page = Uri.base;
      final host = page.host;
      // Local Flutter web dev → Spring Boot on :8080
      if (host == 'localhost' || host == '127.0.0.1') {
        apiBaseUrl = 'http://$host:8080/api/v1';
        return;
      }
      // Deployed PWA (nginx proxies /api/ to Spring Boot on same host)
      final port = page.hasPort && page.port != 80 && page.port != 443 ? ':${page.port}' : '';
      apiBaseUrl = '${page.scheme}://$host$port/api/v1';
      return;
    }

    apiBaseUrl = 'http://localhost:8080/api/v1';
  }

  static String get displayApiHost {
    final uri = Uri.tryParse(apiBaseUrl);
    return uri != null ? '${uri.host}${uri.hasPort ? ':${uri.port}' : ''}' : apiBaseUrl;
  }
}
